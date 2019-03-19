#!/usr/bin/perl

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use FindBin;
use Test::More;

chdir "$FindBin::Bin";

ok rmtree('gnupg'), 'clean t/gnupg';
ok rmtree('regpg'), 'clean t/regpg';
ok rmtree('bin'), 'clean t/bin';
ok rmtree('work'), 'clean t/work';

done_testing;
exit;
