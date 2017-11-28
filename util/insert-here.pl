#!/usr/bin/perl

use warnings;
use strict;

my $V = qx(git describe);
$V =~ s{-(\d+)-\w+\s*}{.$1};

while (<>) {
	if (m{^my\s+(\S+)\s+=\s+INSERT_HERE\s+'(\S+)';$}) {
		open my $f, '<', $2
		    or die "open < $2: $!\n";
		print "my $1 = <<'END';\n";
		print <$f>;
		print "END\n\n";
	} else {
		s{regpg-\d+(\.\d+)+(\.X)?}{$V};
		print;
	}
}
