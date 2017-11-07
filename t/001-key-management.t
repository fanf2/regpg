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
	works 'list keys', '' => $regpg, qw(lskeys);
	for my $k (@{$k{like}}) {
		my $qk = quotemeta $k;
		like $stdout, qr{$qk}, "list contains $k";
	}
	for my $k (@{$k{unlike}}) {
		my $qk = quotemeta $k;
		unlike $stdout, qr{$qk}, "list omits $k";
	}
}

works 'import key one', '' => $regpg, 'addkey', $k1;
is $stdout, '', 'import stdout is quiet';
like $stderr, qr{imported}, 'import stderr is noisy';

subtest 'list keys (one)' => sub {
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

works 'import key two', '' => $regpg, 'addkey', $k2;

subtest 'list keys (both)' => sub {
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

gpg_batch_yes;
works 'delete key one', '' => $regpg, 'delkey', $k1;
unlink $gpgconf;

subtest 'list keys (two)' => sub {
	checklist like => [ $k2 ],
	    unlike => [ $k1, $kd ];
};

my $so = $stdout;
my $se = $stderr;
subtest 'ls synonym', => sub {
	works 'ls', '' => $regpg, 'ls';
	is $stdout, $so, 'stdout matches';
	is $stderr, $se, 'stderr matches';
};

subtest 'add synonym', => sub {
	works 'add', '' => $regpg, 'add', $k1;
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'del synonym', => sub {
	gpg_batch_yes;
	works 'del', '' => $regpg, 'del', $k2;
	unlink $gpgconf;
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

subtest 'del all', => sub {
	gpg_batch_yes;
	works 'del', '' => $regpg, 'del', $k1;
	unlink $gpgconf;
	checklist like => [ ],
	    unlike => [ $k1, $k2, $kd ];
	ok -z 'pubring.gpg', 'empty keyring';
};

subtest 'dummy re-init of empty keyring', => sub {
	works 'add', '' => $regpg, 'add', '-v', $k1;
	like $stderr, qr{--delete-key}, 'delete dummy key';
	like $stderr, qr{0xA3F96E2C6131531B}, 'dummy key id';
	checklist like => [ $k1 ],
	    unlike => [ $k2, $kd ];
};

subtest 'add both', => sub {
	open my $trunc, '>', 'pubring.gpg';
	checklist like => [ ], unlike => [ $k1, $k2, $kd ];
	works 'add', '' => $regpg, 'add', $k1, $k2;
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

subtest 'addself', => sub {
	open my $trunc, '>', 'pubring.gpg';
	checklist like => [ ], unlike => [ $k1, $k2, $kd ];
	local $ENV{USER} = 'testing.example';
	works 'addself', '' => $regpg, 'addself', '-v';
	checklist like => [ $k1, $k2 ],
	    unlike => [ $kd ];
};

done_testing;
exit;
