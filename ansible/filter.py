# Ansible/Jinja2 filter for regpg
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

import ansible
import subprocess

try:
    # ansible-2.2 and later
    from ansible.module_utils._text import to_native
except:
    from ansible.utils.unicode import to_native

def gpg_d(file):
    try:
        output = subprocess.check_output(
            ['gpg', '--use-agent', '--batch', '--quiet', '--decrypt', file])
    except subprocess.CalledProcessError as e:
        raise ansible.errors.AnsibleFilterError(
            'gpg --decrypt '+file+' failed: '+e.output)
    if output == "":
        raise ansible.errors.AnsibleFilterError(
            'gpg --decrypt '+file+' produced no output')
    return to_native(output)

class FilterModule(object):
    def filters(self):
        return {
            'gpg_d': gpg_d
        }
