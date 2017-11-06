#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

print STDERR "$T::regpg\n";

ok 0 == (system $T::regpg, qw(addkey regpg-one@testing.example)),
    'import key one';

done_testing;
exit;
