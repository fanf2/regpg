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
    # prefer gpg1, if it is available, because it is more reliable than gpg2
    gpg = 'gpg1'
    # there is some risk of corruption here, if gpg writes to stderr without
    # setting tis exit status, but subprocess.DEVNULL is not always available
    stderr = subprocess.PIPE
    tries = 3
    while True:
        try:
            output = subprocess.check_output(
                [gpg, '--use-agent', '--batch', '--quiet', '--decrypt', file],
                stderr=stderr)
            break
        except subprocess.CalledProcessError as e:
            gpg = 'gpg'
            stderr = None
            tries -= 1
            if tries > 0:
                continue
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
