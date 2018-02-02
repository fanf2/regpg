#!/usr/bin/perl
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

use warnings;
use strict;

my $V = qx(git describe);
chomp $V;
$V =~ s{-(\d+)-\w+}{.$1};
# prune the commit number on .X commit so that after a release
# the bare script is uploaded without .1 in its version number
$V =~ s{\.1$}{};

while (<>) {
	if (m{^my\s+(\S+)\s+=\s+INSERT_HERE\s+'(\S+)';$}) {
		open my $f, '<', $2
		    or die "open < $2: $!\n";
		print "my $1 = <<'END';\n";
		print <$f>;
		print "END\n\n";
	} else {
		s{regpg-\d+(\.\d+|\.X)+}{$V};
		print;
	}
}
