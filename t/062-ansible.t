#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use File::Path;
use Test::More;

use T;

die "chdir $work: $!" unless chdir $work;
unlink glob '*';
works 'add', '' => qw(regpg add testing.example);

local $ENV{ANSIBLE_NOCOWS} = 'yes';
local $ENV{GPG_AGENT_INFO} = 'dummy';

spew 'ansible.cfg', <<'ANSIBLE_CFG';
[defaults]
inventory = inventory
action_plugins = /etc/ansible/plugins/action
interpreter_python = auto_silent
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
like slurp('ansible.cfg'),
    qr{filter_plugins = plugins/filter},
    'ansible filter plugin setting added';
like slurp('ansible.cfg'),
    qr{action_plugins = /etc/ansible/plugins/action:plugins/action},
    'ansible action plugin setting extended';
works 'try ansible', '' => qw(ansible-playbook gpg-preload.yml);
like $stdout, qr{All assertions passed}, 'gpg_d filter worked';

spew 'binary', pack "C*", 0..255;
works 'encrypt binary', '' => qw(regpg en binary binary.asc);

run '' => qw(ansible -m debug -a msg={{"binary.asc"|gpg_d}} localhost);
if ($status == 0) {
	like $stderr, qr{Non UTF-8 encoded data replaced},
	    'binary corrupted';
} else {
	like $stdout, qr{'ascii' codec can't decode byte},
	    'binary codec error';
}

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

mkpath 'roles/wombat/files';
symlink '../../../binary.asc' => 'roles/wombat/files/echidna.asc';
mkpath 'roles/wombat/tasks';
spew 'roles/wombat/tasks/main.yml', <<"YAML";
---
- name: test plugin in a role
  gpg_d:
    src: echidna.asc
    dest: $cwd/installed
    mode: 0640
YAML
spew 'role.yml', <<"YAML";
---
- hosts: localhost
  roles:
    - wombat
YAML

# https://github.com/ansible/ansible/issues/21982
my $stderr_quiet_broken_python = qr{^(
	Exception\s+ignored\s+in:\s+<function\s+
	WeakValueDictionary\.__init__\.<locals>\.remove\s+at\s+\w+>\s+
	Traceback\s+\(most\s+recent\s+call\s+last\):\s+
	File\s+"/usr/lib/python3\.\d/weakref\.py",\s+
	line\s+\d+,\s+in\s+remove\s+
	TypeError:\s+'NoneType'\s+object\s+is\s+not\s+callable\s+
)*$}x;

sub test_playbook {
	my $v = shift;

	unlink 'installed';

	works "ansible $v gpg-preload",
	    '' => qw(ansible-playbook gpg-preload.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{ensure gpg agent is ready\W+ok:},
	    "$v gpg_d filter worked";

	works "ansible $v install a file (check)",
	    '' => qw(ansible-playbook --check --diff playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v will change";

	works "ansible $v install a file",
	    '' => qw(ansible-playbook playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v did change";
	ok -f 'installed', 'file was installed';
	is slurp('installed'), slurp('binary'), 'correct file contents';

	works "ansible $v install a file (idempotent)",
	    '' => qw(ansible-playbook playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=0}, "ansible $v did not change";

	chmod 0600, 'installed';

	works "ansible $v install a file (check mode)",
	    '' => qw(ansible-playbook --check playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v changed 1";

	works "ansible $v install a file (change mode)",
	    '' => qw(ansible-playbook --diff playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v changed 2";
	if ($v ne 'stable-2.0') {
		like $stdout, qr{\-\s+"mode": "0600",}, "wrong mode $v";
		like $stdout, qr{\+\s+"mode": "0640",}, "correct mode $v";
	}

	spew 'installed', 'garbage';

	works "ansible $v install a file (check modified)",
	    '' => qw(ansible-playbook --check playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v changed 3";

	works "ansible $v install a file (fix modification)",
	    '' => qw(ansible-playbook playbook.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v changed 4";

	spew 'installed', 'garbage';

	works "ansible $v role (check modified)",
	    '' => qw(ansible-playbook --check role.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v changed 5";

	works "ansible $v role (fix modification)",
	    '' => qw(ansible-playbook role.yml);
	like $stderr, $stderr_quiet_broken_python, "stderr quiet $v";
	like $stdout, qr{changed=1}, "ansible $v changed 6";
}

unless (-d "$testansible/.git") {
	test_playbook 'system';
	done_testing;
	exit;
}

spew "$testbin/gpg1", <<END;
#!/bin/sh
echo gpg1 failed 1>&2
exit 1
END
chmod 0755, "$testbin/gpg1";
test_playbook "gpg1 broken";
unlink "$testbin/gpg1";

$ENV{ANSIBLE_HOME} = $testansible;
$ENV{PYTHONPATH} = "$testansible/lib:". ($ENV{PYTHONPATH} // "");

my @python;
for my $pyv (qw{python2 python3}) {
	for my $dir (split /:/, $ENV{PATH}) {
		if (-x "$dir/$pyv") {
			push @python, "$dir/$pyv";
			last;
		}
	}
}
my @py = (undef);

for my $tag (qw{
		stable-2.0
		v2.1.1.0-1
		stable-2.1
		stable-2.2
		stable-2.3
		stable-2.4
		stable-2.5
		stable-2.6
		stable-2.7
		devel
	   }) {

	# do this before we switch to a noisy version
	if ($tag =~ m{devel|stable-2\.[8-9]}) {
		works 'suppress ansible warnings',
		    '' => qw(ansible localhost -c local -m ini_file -a),
		    "section=defaults option=interpreter_python ".
		    "value=auto_silent dest=ansible.cfg";
	}

	ok chdir($testansible), "chdir $testansible";
	works 'deinit submodules',
	    '' => qw(git submodule deinit --all --force);
	# can't use works() here because git deletes its tempfiles
	system qw(git clean -dfx);
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

	my $version =
	    $tag =~ m{stable-(\d+\.\d+)} ? "ansible $1." :
	    $tag =~ m{v(\d+\.\d+\.\d+\.\d+)-\d} ? "ansible $1" :
	    "ansible";
	my $vere = quotemeta $version;

	my @py = ('python');
	if ($tag =~ m{devel|stable-2\.[4-9]}) {
		@py = @python;
	}
	for my $py (@py) {
		unlink "$testbin/python";
		my $v = $tag;
		if ($py ne 'python') {
			symlink $py, "$testbin/python";
			$v = "$tag ($py)";
		}
		works "ansible $v smoke test",
		    '' => qw(ansible --version);
		like $stdout, qr{$vere}, "ansible version matches $v";
		test_playbook $v;
	}
}

done_testing;
exit;
