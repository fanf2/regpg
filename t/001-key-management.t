#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

my $k1 = 'regpg-one@testing.example';
my $k2 = 'regpg-two@testing.example';
my $kd = 'dummy@this-key-is.invalid';

works 'import key one',
    '' => $regpg, 'addkey', $k1;

works 'list keys (one)',
    '' => $regpg, qw(ls);

like $stdout, qr{$k1}, 'list contains key one';
unlike $stdout, qr{$k2}, 'list omits key two';
unlike $stdout, qr{$kd}, 'list omits dummy key';

done_testing;
exit;
