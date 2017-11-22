#!/usr/bin/perl

use strict;
use warnings;

use File::Path;
use Test::More;

use T;

local $ENV{USER} = 'testing.example';

unlink glob '*';
works 'addself', '' => $regpg, 'addself';
works 'ls', '' => $regpg, 'ls';
my $ls = $stdout;

unlink glob '*';
works 'init', '' => $regpg, 'init';
is $stdout, '', 'regpg stdout quiet';
like $stderr, qr{imported:}, 'regpg stderr noisy';
ok -f 'pubring.gpg', 'init created keyring';

works 'ls', '' => $regpg, 'ls';
is $stdout, $ls, 'regpg init like addself';

gpg_batch_yes;
works 'del', '' => $regpg, 'del', 'regpg-two';
unlink $gpgconf;

works 'init', '' => $regpg, 'init';
is $stdout, '', 'regpg stdout quiet';
like $stderr, qr{done init}, 'regpg stderr noisy';

works 'ls', '' => $regpg, 'ls';
isnt $stdout, $ls, 'regpg init unlike addself for existing keyring';

local $ENV{HOME} = $work;
local $ENV{XDG_CONFIG_HOME} = undef;
local $ENV{GIT_CONFIG_NOSYSTEM} = 'yes';

rmtree '.git';

SKIP: {
	skip 'gitless', 10 unless canexec 'git';

	works 'git init',   '' => qw(git init);
	works 'git add',    '' => qw(git add pubring.gpg);
	works 'git commit', '' => qw(git commit -m pubring);
	works 'git log',    '' => qw(git log --patch);
	like $stdout, qr{Binary files .* differ},
	    'uninit git binary diff';

	works 'init git', '' => $regpg, qw(init git);
	is $stdout, '', 'regpg stdout quiet';
	like $stderr, qr{running git config}, 'regpg stderr noisy';

	works 'git log',    '' => qw(git log --patch);
	like $stdout, qr{^[+]\w+\s.*\s<regpg-one[@]}m,
	    'init git text diff';
}

local $ENV{ANSIBLE_NOCOWS} = 'yes';
local $ENV{GPG_AGENT_INFO} = 'dummy';

spew 'ansible.cfg', <<'ANSIBLE_CFG';
[defaults]
hostfile = inventory
ANSIBLE_CFG
spew 'inventory', <<'INVENTORY';
localhost ansible_connection=local
INVENTORY

SKIP: {
	skip 'ansible-nope', 3 unless canexec 'ansible-playbook';

	works 'init ansible', '' => $regpg, qw(init ansible);
	works 'try ansible', '' => qw(ansible-playbook gpg-preload.yml);
	like $stdout, qr{All assertions passed}, 'gpg_d plugin worked';
}

SKIP: {
	skip 'ansible-revault', 18 unless canexec 'ansible-vault';

	unlink 'secret', 'secret.asc';
	works 'init ansible-vault', '' => $regpg, qw(init ansible-vault);
	ok -f 'vault.open', 'init created vault.open';
	ok -f 'vault.pwd.asc', 'init created vault.pwd.asc';
	spew 'secret', 'otterly badgered';
	works 'ansible-vault encrypt',
	    '' => qw(ansible-vault encrypt secret);
	isnt slurp('secret'), 'otterly badgered', 'file is now encrypted';
	works 'ansible-vault decrypt',
	    '' => qw(ansible-vault decrypt --output - secret);
	is $stdout, 'otterly badgered', 'vault can be decrypted';
	works 'regpg ansible-vault list',
	    '' => qw(regpg conv ansible-vault);
	is $stderr, '', 'regpg stderr is quiet';
	like $stdout, qr{secret}, 'lists encrypted file';
	works 'regpg ansible-vault convert',
	    '' => qw(regpg conv ansible-vault secret secret.asc);
	is $stderr, '', 'regpg stderr is quiet';
	is $stdout, '', 'regpg stdout is quiet';
	ok -f 'secret.asc', 'conv created file';
	like slurp('secret.asc'), $pgpmsg, 'from vault to pgp';
	works 'decrypt converted file',
	    '' => qw(regpg decrypt secret.asc);
	is $stdout, 'otterly badgered', 'correctly decrypted';
}

done_testing;
exit;
