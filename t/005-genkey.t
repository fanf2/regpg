#!/usr/bin/perl

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use Test::More;

use T;

################################################################

my @genkey = qw(gpg --gen-key --batch --quiet);
push @genkey, '--quick-random' if $gpgvers lt "2.0";

for my $key (qw(one two)) {
	works "generated key $key", <<"GENKEY" => @genkey;
Key-Type: RSA
Key-Length: 2048
Key-Usage: encrypt,sign
Name-Email: regpg-$key\@testing.example
%no-ask-passphrase
%no-protection
%transient-key
%commit
GENKEY
}

################################################################

done_testing;
exit;
