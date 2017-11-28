#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use File::Path;
use Test::More;

use T;

unlink glob '*';
works 'add', '' => qw(regpg add testing.example);

local $ENV{ANSIBLE_NOCOWS} = 'yes';
local $ENV{GPG_AGENT_INFO} = 'dummy';

spew 'ansible.cfg', <<'ANSIBLE_CFG';
[defaults]
inventory = inventory
ANSIBLE_CFG
spew 'inventory', <<'INVENTORY';
localhost ansible_connection=local
INVENTORY

unless (canexec 'ansible-playbook') {
	done_testing;
	exit;
}

works 'init ansible', '' => qw(regpg init ansible);
works 'try ansible', '' => qw(ansible-playbook gpg-preload.yml);
like $stdout, qr{All assertions passed}, 'gpg_d filter worked';

spew 'binary', pack "C*", 0..255;
works 'encrypt binary', '' => qw(regpg en binary binary.asc);

fails 'binary in a template',
    '' => qw(ansible -m debug -a msg={{"binary.asc"|gpg_d}} localhost);
like $stdout, qr{'ascii' codec can't decode byte},
    'binary codec error';

my $cwd = getcwd;

spew 'playbook.yml', <<"YAML";
---
- hosts: localhost
  tasks:
    - name: test action plugin
      gpg_d:
        src: $cwd/binary.asc
        dest: $cwd/installed
        mode: 0640
YAML

works 'install a file (check)',
    '' => qw(ansible-playbook --check --diff playbook.yml);
like $stdout, qr{changed=1}, 'ansible will change';

works 'install a file',
    '' => qw(ansible-playbook playbook.yml);
like $stdout, qr{changed=1}, 'ansible did change';
ok -f 'installed', 'file was installed';
is slurp('installed'), slurp('binary'), 'correct file contents';

works 'install a file (idempotent)',
    '' => qw(ansible-playbook playbook.yml);
like $stdout, qr{changed=0}, 'ansible did not change';

chmod 0600, 'installed';

works 'install a file (change mode)',
    '' => qw(ansible-playbook --diff playbook.yml);
like $stdout, qr{changed=1}, 'ansible changed';
like $stdout, qr{\-\s+"mode": "0600",}, 'wrong mode';
like $stdout, qr{\+\s+"mode": "0640",}, 'correct mode';

done_testing;
exit;
