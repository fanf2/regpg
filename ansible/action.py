# Ansible action plugin for regpg
# based on lib/ansible/plugins/action/template.py
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import subprocess

from ansible import __version__ as ansible_version
from ansible.errors import AnsibleError
from ansible.plugins.action import ActionBase
from ansible.utils.hashing import checksum_s

try:
    # ansible-2.2 and later
    from ansible.module_utils._text import to_bytes
except:
    from ansible.utils.unicode import to_bytes

try:
    # ansible-2.2
    from ansible.utils.boolean import boolean
except:
    try:
        # ansible-2.4
        from ansible.module_utils.parsing.convert_bool import boolean
    except:
        # ansible-2.3
        from ansible.constants import mk_boolean as boolean

class ActionModule(ActionBase):

    TRANSFERS_FILES = True

    def run(self, tmp=None, task_vars=None):
        if task_vars is None:
            task_vars = dict()

        result = super(ActionModule, self).run(tmp, task_vars)

        src    = self._task.args.get('src', None)
        dest   = self._task.args.get('dest', None)
        state  = self._task.args.get('state', None)
        force  = boolean(self._task.args.get('force', True))

        if state is not None:
            result['failed'] = True
            result['msg'] = "'state' cannot be specified on a template"
        elif src is None or dest is None:
            result['failed'] = True
            result['msg'] = "src and dest are required"
        else:
            if self._task._role is not None:
                path = self._task._role._role_path
            else:
                path = self._loader.get_basedir()
            src = self._loader.path_dwim_relative(path, 'files', src)

        if 'failed' in result:
            return result

        # Expand any user home dir specification
        dest = self._remote_expand_user(dest)

        directory_prepended = False
        if dest.endswith(os.sep):
            directory_prepended = True
            base = os.path.basename(src)
            dest = os.path.join(dest, base)

        # decrypt the src file locally & get ready to transfer
        try:
            cleartext = subprocess.check_output(
                ['gpg', '--use-agent', '--batch', '--quiet', '--decrypt', src])
        except subprocess.CalledProcessError as e:
            result['failed'] = True
            result['msg'] = 'gpg --decrypt '+src+' failed: '+e.output
            return result

        if cleartext == "":
            result['failed'] = True
            result['msg'] = 'gpg --decrypt '+src+' produced no output'
            return result

        local_checksum = checksum_s(cleartext)

        remote_user = (task_vars.get('ansible_ssh_user') or
                       self._play_context.remote_user)
        if not tmp:
            if ansible_version[:4] == '2.0.':
                tmp = self._make_tmp_path()
            else:
                tmp = self._make_tmp_path(remote_user)
            self._connection._shell.tmpdir = tmp
            self._cleanup_remote_tmp = True
            created_tmp = True

        try:
            dest_stat = self.remote_stat_compat(dest, task_vars, tmp)

            if (dest_stat['exists'] and dest_stat['isdir']
                    and not directory_prepended):
                base = os.path.basename(src)
                dest = os.path.join(dest, base)
                dest_stat = self.remote_stat_compat(dest, task_vars, tmp)

        except Exception as e:
            result['failed'] = True
            result['msg'] = 'could not get remote checksum: '+to_bytes(e)
            return result

        remote_checksum = dest_stat['checksum']

        new_module_args = self._task.args.copy()

        result['changed'] = ((remote_checksum == '1') or
                             (force and local_checksum != remote_checksum))

        # do actual work through copy or file modules
        if result['changed'] and not self._play_context.check_mode:

            xfered = self._connection._shell.join_path(tmp, 'src')
            self._transfer_data(xfered, cleartext)

            if (ansible_version[:4] != '2.0.' and
                ansible_version[:4] != '2.1.'):
                # fix file permissions when the copy is done as a different user
                self._fixup_perms2((tmp, xfered), remote_user)
            elif (self._play_context.become and
                  self._play_context.become_user != 'root'):
                self._remote_chmod('a+r', xfered)

            # run the copy module
            new_module_args.update(
                src=xfered,
                dest=dest,
            )
            result.update(self.install_cleartext(src, 'copy', new_module_args,
                                                 task_vars, tmp))

        elif not result['changed']:
            # only check remote file if it is present
            new_module_args.update(
                src=None,
            )
            result.update(self.install_cleartext(src, 'file', new_module_args,
                                                 task_vars, tmp))

        if 'diff' not in result:
            result['diff'] = { 'before': {}, 'after': {} }

        result['diff']['before']['checksum'] = remote_checksum
        result['diff']['after']['checksum'] = local_checksum

        if created_tmp:
            self._remove_tmp_path(tmp)

        return result

    def remote_stat_compat(self, dest, task_vars, tmp):
        if ansible_version[:4] < '2.5.':
            return self._execute_remote_stat(dest, all_vars=task_vars,
                                             follow=False, tmp=tmp)
        else:
            return self._execute_remote_stat(dest, all_vars=task_vars,
                                             follow=False)

    def install_cleartext(self, src, module, args, task_vars, tmp):
        args.update(follow=True)
        if ansible_version[:4] < '2.6.':
            args.update(original_basename=os.path.basename(src))
        else:
            args.update(_original_basename=os.path.basename(src))
        if ansible_version[:4] < '2.5.':
            return self._execute_module(module_name=module,
                                        module_args=args,
                                        task_vars=task_vars, tmp=tmp,
                                        delete_remote_tmp=False)
        else:
            return self._execute_module(module_name=module,
                                        module_args=args,
                                        task_vars=task_vars)
