#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

unless (canexec 'dnssec-keygen') {
	done_testing;
	exit;
}

unlink glob '*';
works 'add', '' => qw(regpg add testing.example);

my $kre = qr{^(Kexample\.\+013\+.....)\n$};

works 'dnssec keygen',
    '' => qw(regpg dnssec keygen -a13 example);
like $stdout, $kre,
    'dnssec keygen name printed to stdout';
my ($name) = $stdout =~ $kre;
ok -f "$name.key",
    "dnssec keygen wrote public key for $name";
ok ! -f "$name.private",
    "dnssec keygen deleted private key for $name";
ok -f "$name.private.asc",
    "dnssec keygen wrote encrypted private key for $name";
ok -f "$name.private.sha256",
    "dnssec keygen wrote private key digest for $name";

works "decrypt private key for $name (1)",
    '' => qw(regpg decrypt), "$name.private.asc", "$name.private";
works "openssl dgst $name.private",
    '' => qw(openssl dgst -sha256), "$name.private";
my ($digest) = $stdout =~ m{ (\S+\s*)$};
my $sha256 = slurp "$name.private.sha256";
is $sha256, $digest,
    "digests match for $name.private";

my $oldpriv = slurp "$name.private.asc";
works 'dnssec recrypt with present sha',
    '' => qw(regpg dnssec recrypt), $name;
my $newpriv = slurp "$name.private.asc";
is $oldpriv, $newpriv,
    "dnssec recrypt kept $name.priavte.asc";

works 'dnssec-settime raw',
    '' => qw(dnssec-settime -R now+1d), $name;
works 'dnssec recrypt with changed key',
    '' => qw(regpg dnssec recrypt), $name;
$newpriv = slurp "$name.private.asc";
isnt $oldpriv, $newpriv,
    "dnssec recrypt rewrote $name.priavte.asc";
my $newsha = slurp "$name.private.sha256";
isnt $sha256, $newsha,
    "digest changed for $name.private";

unlink "$name.private.sha256";
works 'dnssec recrypt with missing sha',
    '' => qw(regpg dnssec recrypt), $name;
$newpriv = slurp "$name.private.asc";
isnt $oldpriv, $newpriv,
    "dnssec recrypt rewrote $name.priavte.asc";
ok -f "$name.private",
    "dnssec recrypt kept $name.private";
ok -f "$name.private.sha256",
    "dnssec recrypt updated digest for $name";

unlike slurp("$name.key"), qr{Delete},
    "public $name not yet Deleted";
unlike slurp("$name.private"), qr{Delete},
    "private $name not yet Deleted";
works 'dnssec settime -D',
    '' => qw(regpg dnssec settime -D now), $name;
like slurp("$name.key"), qr{Delete},
    "public $name is now Deleted";
like slurp("$name.private"), qr{Delete},
    "private $name is now Deleted";

unlike slurp("$name.key"), qr{Inactive},
    "public $name not yet Inactive";
unlike slurp("$name.private"), qr{Inactive},
    "private $name not yet Inactive";
unlink "$name.private";
works 'dnssec settime -I',
    '' => qw(regpg dnssec settime -I now), $name;
ok ! -f "$name.private",
    "dnssec settime deleted private key for $name";
like slurp("$name.key"), qr{Inactive},
    "public $name is now Inactive";
works "decrypt private key for $name (2)",
    '' => qw(regpg decrypt), "$name.private.asc";
like $stdout, qr{Inactive},
    "encrypted $name is now Inactive";

fails 'dnssec settime invalid time',
    '' => qw(regpg dnssec settime -I 123), $name;

done_testing;
exit;
