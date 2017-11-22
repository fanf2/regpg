#!/usr/bin/perl

use warnings;
use strict;

use File::Path qw(rmtree);

sub exec_path {
	my @exec = grep { -x "$_/@_" } split /:/, $ENV{PATH};
	return @exec && "$exec[0]/@_";
}

if (exec_path 'perlcritic') {
	system qw(perlcritic regpg);
	exit $? if $?;
}

mkdir 't/bin';
unlink glob 't/bin/*';
for my $gpg (qw(gpg gpg1 gpg2)) {
	my $path = exec_path $gpg;
	next unless $path;
	print STDERR "testing with gpg => $path\n";
	unlink 't/bin/gpg';
	symlink $path => 't/bin/gpg'
	    or die "symlink $path => t/bin/gpg: $!\n";
	system 'prove';
	exit $? if $?;
}
