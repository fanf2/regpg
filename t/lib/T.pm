package T;

use strict;
use warnings;

use Exporter qw(import);
use File::Temp qw(tempfile);
use FindBin;
use POSIX;
use Test::More;

our $gnupg;
our $regpg;
our $work;

our @EXPORT = qw(
	$gnupg
	$regpg
	$work

	fails
	run
	works
    );

BEGIN {
	my $dir = "$FindBin::Bin";

	$gnupg = "$dir/gnupg";
	$regpg = "$dir/../regpg";
	$work  = "$dir/work";

	chdir $work; # ignore failure

	$ENV{GNUPGHOME} = "$gnupg";
};


sub run {
	my $stdin = shift;
	my $r = { stdin => $stdin };

	open my $si, '<&STDIN'  or die "dup: $!\n";
	open my $so, '>&STDOUT' or die "dup: $!\n";
	open my $se, '>&STDERR' or die "dup: $!\n";

	my ($hi,$ni) = tempfile "stdin.XXXXXXXX";
	my ($ho,$no) = tempfile "stdout.XXXXXXXX";
	my ($he,$ne) = tempfile "stderr.XXXXXXXX";

	print $hi $stdin;

	open STDIN,  '<',  $ni or die "open $ni: $!\n";
	open STDOUT, '>&', $ho or die "dup: $!\n";
	open STDERR, '>&', $he or die "dup: $!\n";

	close $hi;
	close $ho;
	close $he;

	$r->{status} = system @_;

	open STDIN,  '<&', $si or die "dup: $!\n";
	open STDOUT, '>&', $so or die "dup: $!\n";
	open STDERR, '>&', $se or die "dup: $!\n";

	local $/ = undef;

	open my $ro, '<', $no or die "open $no: $!\n";
	open my $re, '<', $ne or die "open $ne: $!\n";

	$r->{stdout} = <$ro>;
	$r->{stderr} = <$re>;

	close $ro;
	close $re;

	unlink $ni;
	unlink $no;
	unlink $ne;

	return $r;
}

sub note_lines {
	my $tag = shift;
	my $text = shift;
	$text =~ s{^(.*)$}{$tag: $1}gm;
	note $text;
}

sub note_stdio {
	my $r = shift;
	note_lines IN => $r->{stdin};
	note_lines OUT => $r->{stdout};
	note_lines ERR => $r->{stderr};
	return $r;
}

sub fails {
	my $name = shift;
	my $r = run @_;
	isnt $r->{status}, 0, $name;
	return note_stdio $r;
}

sub works {
	my $name = shift;
	my $r = run @_;
	is $r->{status}, 0, $name;
	return note_stdio $r;
}

__PACKAGE__
__END__
