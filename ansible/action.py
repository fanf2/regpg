from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import subprocess

from ansible.errors import AnsibleError
from ansible.module_utils._text import to_bytes, to_native, to_text
from ansible.plugins.action import ActionBase
from ansible.utils.hashing import checksum_s
from ansible.utils.boolean import boolean

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
            try:
                src = self._find_needle('templates', src)
            except AnsibleError as e:
                result['failed'] = True
                result['msg'] = to_native(e)

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
            tmp = self._make_tmp_path(remote_user)
            self._cleanup_remote_tmp = True

        try:
            dest_stat = self._execute_remote_stat(dest, all_vars=task_vars,
                                                  follow=False, tmp=tmp)

            if (dest_stat['exists'] and dest_stat['isdir']
                    and not directory_prepended):
                base = os.path.basename(src)
                dest = os.path.join(dest, base)
                dest_stat = self._execute_remote_stat(dest, all_vars=task_vars,
                                                      follow=False, tmp=tmp)

        except Exception as e:
            result['failed'] = True
            result['msg'] = to_bytes(e)
            return result

        remote_checksum = dest_stat['checksum']

        new_module_args = self._task.args.copy()

        result['changed'] = ((remote_checksum == '1') or
                             (force and local_checksum != remote_checksum))

        # do actual work through copy or file modules
        if result['changed'] and not self._play_context.check_mode:

            xfered = self._connection._shell.join_path(tmp, 'src')
            self._transfer_data(xfered, cleartext)

            # fix file permissions when the copy is done as a different user
            self._fixup_perms2((tmp, xfered), remote_user)

            # run the copy module
            new_module_args.update(
                dict(
                    src=xfered,
                    dest=dest,
                    original_basename=os.path.basename(src),
                    follow=True,
                ),
            )
            result.update(self._execute_module(module_name='copy',
                                               module_args=new_module_args,
                                               task_vars=task_vars, tmp=tmp,
                                               delete_remote_tmp=False))

            result['diff'] = { 'before': { 'checksum': remote_checksum },
                               'after': { 'checksum': local_checksum } }

        else:
            new_module_args.update(
                dict(
                    src=None,
                    original_basename=os.path.basename(src),
                    follow=True,
                ),
            )
            result.update(self._execute_module(module_name='file',
                                               module_args=new_module_args,
                                               task_vars=task_vars, tmp=tmp,
                                               delete_remote_tmp=False))

            result['diff']['before']['checksum'] = remote_checksum
            result['diff']['after']['checksum'] = local_checksum

        self._remove_tmp_path(tmp)

        return result
