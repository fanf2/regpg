import subprocess

from ansible import errors

def gpg_d(file, pubring=None):
    if pubring:
        argv = [ 'regpg', 'decrypt', '-k', pubring, file ]
    else:
        argv = [ 'regpg', 'decrypt', file ]
    try:
        output = subprocess.check_output(argv)
    except CalledProcessError as e:
        raise errors.AnsibleFilterError('regpg decrypt '+file+' failed: '+e.output)
    if output == "":
        raise errors.AnsibleFilterError('regpg decrypt '+file+' produced no output')
    return output

class FilterModule(object):
    def filters(self):
        return {
            'gpg_d': gpg_d
        }
