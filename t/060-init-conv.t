#!/usr/bin/perl

use strict;
use warnings;

use File::Path;
use Test::More;

use T;

local $ENV{USER} = 'testing.example';

unlink glob '*';
works 'addself', '' => qw(regpg addself);
works 'ls', '' => qw(regpg ls);
my $ls = $stdout;

unlink glob '*';
works 'init', '' => qw(regpg init);
is $stdout, '', 'regpg stdout quiet';
like $stderr, qr{imported:}, 'regpg stderr noisy';
ok -f 'pubring.gpg', 'init created keyring';

works 'ls', '' => qw(regpg ls);
is $stdout, $ls, 'regpg init like addself';

gpg_batch_yes;
works 'del', '' => qw(regpg del regpg-two);
unlink $gpgconf;

works 'init', '' => qw(regpg init);
is $stdout, '', 'regpg stdout quiet';
like $stderr, qr{done init}, 'regpg stderr noisy';

works 'ls', '' => qw(regpg ls);
isnt $stdout, $ls, 'regpg init unlike addself for existing keyring';

local $ENV{HOME} = $work;
local $ENV{XDG_CONFIG_HOME} = undef;
local $ENV{GIT_CONFIG_NOSYSTEM} = 'yes';

rmtree '.git';

SKIP: {
	skip 'gitless', 10 unless canexec 'git';

	unlink 'secret.asc';
	works 'encrypt a file',
	    'otterly badgered' => qw(regpg en secret.asc);

	works 'git init',   '' => qw(git init);
	works 'git config name',
	    '' => qw(git config user.name Testing123);
	works 'git config email',
	    '' => qw(git config user.email username@example.com);
	works 'git add',    '' => qw(git add pubring.gpg secret.asc);
	works 'git commit', '' => qw(git commit -m pubring);
	works 'git log',    '' => qw(git log --patch);
	like $stdout, qr{Binary files .* differ},
	    'uninit git binary diff';
	like $stdout, qr{-BEGIN PGP MESSAGE-},
	    'uninit git PGP message';

	works 'init git', '' => qw(regpg init git);
	is $stdout, '', 'regpg stdout quiet';
	like $stderr, qr{running git config}, 'regpg stderr noisy';

	works 'git log',    '' => qw(git log --patch);
	like $stdout, qr{^[+]\w+\s.*\s<?regpg-one[@]}m,
	    'init git text diff';
	unlike $stdout, qr{-BEGIN PGP MESSAGE-},
	    'init git no PGP message';
}

local $ENV{ANSIBLE_NOCOWS} = 'yes';
local $ENV{GPG_AGENT_INFO} = 'dummy';

spew 'ansible.cfg', <<'ANSIBLE_CFG';
[defaults]
inventory = inventory
ANSIBLE_CFG
spew 'inventory', <<'INVENTORY';
localhost ansible_connection=local
INVENTORY

SKIP: {
	skip 'ansible-revault', 18 unless canexec 'ansible-vault';

	unlink 'secret', 'secret.asc';
	works 'init ansible-vault', '' => qw(regpg init ansible-vault);
	ok -f 'vault.open', 'init created vault.open';
	ok -f 'vault.pwd.asc', 'init created vault.pwd.asc';
	spew 'secret', 'otterly badgered';
	works 'ansible-vault encrypt',
	    '' => qw(ansible-vault encrypt secret);
	isnt slurp('secret'), 'otterly badgered', 'file is now encrypted';
	works 'ansible-vault decrypt',
	    '' => qw(ansible-vault decrypt --output spew secret);
	is slurp('spew'), 'otterly badgered', 'vault can be decrypted';
	works 'regpg ansible-vault list',
	    '' => qw(regpg conv ansible-vault);
	is $stderr, '', 'regpg stderr is quiet';
	like $stdout, qr{secret}, 'lists encrypted file';
	works 'ansible-vault version',
	    '' => qw(ansible-vault --version);
	unless ($stdout =~ m{ansible-vault 2\.4\.0\.0}) {
		works 'regpg ansible-vault convert',
		    '' => qw(regpg conv ansible-vault secret secret.asc);
		is $stderr, '', 'regpg stderr is quiet';
		is $stdout, '', 'regpg stdout is quiet';
		ok -f 'secret.asc', 'conv created file';
		ok ! -f '-', 'conv avoided ansible-vault --output bug';
		like slurp('secret.asc'), $pgpmsg, 'from vault to pgp';
		works 'decrypt converted file',
		    '' => qw(regpg decrypt secret.asc);
		is $stdout, 'otterly badgered', 'correctly decrypted';
	}
}

done_testing;
exit;
