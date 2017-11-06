#!/usr/bin/perl

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use Test::More;

use T;

################################################################

chdir $FindBin::Bin;

rmtree $T::gnupg;
mkpath $T::gnupg;
chmod 0700, $T::gnupg;

ok -d $T::gnupg, 'created gnupg home';
is 0777 & (stat _)[2], 0700, 'permissions on gnupg home';

rmtree $T::work;
mkpath $T::work;
ok -d $T::work, 'created working directory';

################################################################

for my $key (qw(one two)) {
	my $stdin = <<"GENKEY";
Key-Type: RSA
Key-Usage: encrypt,sign
Key-Length: 2048
Name-Email: regpg-$key\@testing.example
%no-ask-passphrase
%no-protection
%transient-key
%commit
GENKEY
	ok T::run($stdin => qw(gpg --gen-key --batch --quiet)),
	    "generated key $key";
}

################################################################

done_testing;
exit;
