#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

works 'import key one',
    '' => $regpg, qw(addkey regpg-one@testing.example);

done_testing;
exit;
