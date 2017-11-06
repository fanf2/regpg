#!/usr/bin/perl

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use Test::More;

use T;

################################################################

chdir $FindBin::Bin;

rmtree $gnupg;
mkpath $gnupg;
chmod 0700, $gnupg;

ok -d $gnupg, 'created gnupg home';
is 0777 & (stat _)[2], 0700, 'permissions on gnupg home';

rmtree $work;
mkpath $work;
ok -d $work, 'created working directory';

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
	works "generated key $key",
	    $stdin => qw(gpg --gen-key --batch --quiet);
}

################################################################

done_testing;
exit;
