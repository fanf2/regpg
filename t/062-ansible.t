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

unlink "$testbin/ansible", "$testbin/ansible-playbook";

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

sub test_playbook {
	my $version = shift;

	unlink 'installed';
	works "ansible $version install a file (check)",
	    '' => qw(ansible-playbook --check --diff playbook.yml);
	like $stdout, qr{changed=1}, 'ansible will change';

	works "ansible $version install a file",
	    '' => qw(ansible-playbook playbook.yml);
	like $stdout, qr{changed=1}, 'ansible did change';
	ok -f 'installed', 'file was installed';
	is slurp('installed'), slurp('binary'), 'correct file contents';

	works "ansible $version install a file (idempotent)",
	    '' => qw(ansible-playbook playbook.yml);
	like $stdout, qr{changed=0}, 'ansible did not change';

	chmod 0600, 'installed';

	works "ansible $version install a file (change mode)",
	    '' => qw(ansible-playbook --diff playbook.yml);
	like $stdout, qr{changed=1}, 'ansible changed';
	like $stdout, qr{\-\s+"mode": "0600",}, 'wrong mode';
	like $stdout, qr{\+\s+"mode": "0640",}, 'correct mode';
}

test_playbook 'system';

unless (-d "$testansible/.git") {
	done_testing;
	exit;
}

$ENV{ANSIBLE_HOME} = $testansible;
$ENV{PYTHONPATH} = "$testansible/lib"
    . ($ENV{PYTHONPATH} ? ":$ENV{PYTHONPATH}" : '');

for my $tag (qw(
		stable-2.4
	   )) {
	ok chdir($testansible), "chdir $testansible";
	works 'deinit submodules',
	    '' => qw(git submodule deinit --all --force);
	works "switch branch to $tag",
	    '' => qw(git checkout), $tag;
	works 'update submodules',
	    '' => qw(git submodule update --init --recursive);
	ok chdir($work), "chdir $work";
	unlink "$testbin/ansible", "$testbin/ansible-playbook";
	symlink "$testansible/bin/ansible"
		     => "$testbin/ansible";
	symlink "$testansible/bin/ansible-playbook"
		     => "$testbin/ansible-playbook";
	my $version = $tag =~ s{stable-(\d+)\.(\d+)}{ansible $1\\.$2\\.}r;
	works "ansible $tag smoke test",
	    '' => qw(ansible --version);
	like $stdout, qr{$version}, "ansible version matches $tag";
	test_playbook $tag;
}

done_testing;
exit;
