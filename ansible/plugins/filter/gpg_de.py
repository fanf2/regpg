import subprocess

def gpg_de(file, pubring=None):
    if pubring:
        argv = [ 'regpg', 'decrypt', '-k', pubring, file, '-' ]
    else:
        argv = [ 'regpg', 'decrypt', file, '-' ]
    return subprocess.check_output(argv)

class FilterModule(object):
    def filters(self):
        return {
            'gpg_de': gpg_de
        }
