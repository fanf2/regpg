#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

my $k1 = 'regpg-one@testing.example';
my $k2 = 'regpg-two@testing.example';
my $kd = 'dummy@this-key-is.invalid';

sub checklist {
	my %k = @_;
	works 'list keys', '' => qw(regpg lskeys);
	for my $k (@{$k{like}}) {
		my $qk = quotemeta $k;
		like $stdout, qr{$qk}, "list contains $k";
	}
	for my $k (@{$k{unlike}}) {
		my $qk = quotemeta $k;
		unlike $stdout, qr{$qk}, "list omits $k";
	}
}

works 'add key one', '' => qw(regpg addkey), $k1;
is $stdout, '', 'add stdout is quiet';
like $stderr, qr{imported}, 'add stderr is noisy';

subtest 'list keys (one)' => sub {
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

works 'import key two', '' => qw(regpg addkey), $k2;

subtest 'list keys (both)' => sub {
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'list keys (error cases)' => sub {
	fails 'list missing file', '' => qw(regpg lskeys missing.asc);
	is $stdout, '', 'lskeys stdout quiet';
	like $stderr, qr{can't open}, 'lskeys file not found';
	fails 'list two arguments', '' => qw(regpg lskeys one two);
	is $stdout, '', 'lskeys stdout quiet';
	like $stderr, qr{usage:}, 'lskeys usage error';
};

gpg_batch_yes;
works 'delete key one', '' => qw(regpg delkey), $k1;
unlink $gpgconf;

subtest 'list keys (two)' => sub {
	checklist like => [ $k2 ],
	    unlike => [ $k1, $kd ];
};

my $so = $stdout;
my $se = $stderr;
subtest 'ls synonym', => sub {
	works 'ls', '' => qw(regpg ls);
	is $stdout, $so, 'stdout matches';
	is $stderr, $se, 'stderr matches';
};

subtest 'add synonym', => sub {
	works 'add', '' => qw(regpg add), $k1;
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'del synonym', => sub {
	gpg_batch_yes;
	works 'del', '' => qw(regpg del), $k2;
	unlink $gpgconf;
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

subtest 'del all', => sub {
	gpg_batch_yes;
	works 'del', '' => qw(regpg del), $k1;
	unlink $gpgconf;
	checklist like => [ ],
	    unlike => [ $k1, $k2, $kd ];
	# gpg-2.2 does not completely truncate the file, so force it
	# to make the next test actually reinitializes the keyring
	open my $dummy, '>', 'pubring.gpg' if 8 == -s 'pubring.gpg';
	ok -z 'pubring.gpg', 'empty keyring';
};

subtest 'dummy re-init of empty keyring', => sub {
	works 'add', '' => qw(regpg add -v), $k1;
	like $stderr, qr{--delete-key}, 'delete dummy key';
	like $stderr, qr{0xA3F96E2C6131531B}, 'dummy key id';
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

subtest 'add both', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'add', '' => qw(regpg add), $k1, $k2;
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'addself', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	local $ENV{USER} = 'testing.example';
	works 'addself', '' => qw(regpg addself);
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

my $pubkey = qr{-----BEGIN PGP PUBLIC KEY BLOCK-----};
subtest 'export all', => sub {
	works 'export keys',
	    '' => qw(regpg exportkey);
	is $stderr, '', 'export stderr is quiet';
	like $stdout, $pubkey, 'exported public key';
	spew 'export', $stdout;
};
subtest 'export one', => sub {
	works 'export key one',
	    '' => qw(regpg exportkey), $k1;
	is $stderr, '', 'export stderr is quiet';
	like $stdout, $pubkey, 'exported public key';
	spew 'one', $stdout;
};
subtest 'export two', => sub {
	works 'export key two',
	    '' => qw(regpg exportkey), $k2;
	is $stderr, '', 'export stderr is quiet';
	like $stdout, $pubkey, 'exported public key';
	spew 'two', $stdout;
};

subtest 'importkey pipe', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'importkey',
	    slurp('export') => qw(regpg importkey);
	like $stderr, qr{imported}, 'import stderr is noisy';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};
subtest 'importkey file', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'importkey',
	    '' => qw(regpg importkey export);
	like $stderr, qr{imported}, 'import stderr is noisy';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};
subtest 'importkey files', => sub {
	unlink 'pubring.gpg', 'pubring.gpg~';
	works 'importkey',
	    '' => qw(regpg importkey one two);
	like $stderr, qr{imported}, 'import stderr is noisy';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

unlink 'export';

done_testing;
exit;
