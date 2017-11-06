package T;

use strict;
use warnings;

use Exporter qw(import);
use File::Temp qw(tempfile);
use FindBin;
use POSIX;
use Test::More;

our $regpg;
our $gnupg;
our $work;

our $status;
our $stdin;
our $stdout;
our $stderr;

our @EXPORT = qw(
	$regpg
	$gnupg
	$work

	$status
	$stdin
	$stdout
	$stderr

	fails
	run
	works
    );

BEGIN {
	my $dir = "$FindBin::Bin";

	$regpg = "$dir/../regpg";
	$gnupg = "$dir/gnupg";
	$work  = "$dir/work";

	chdir $work; # ignore failure

	$ENV{GNUPGHOME} = "$gnupg";
};

sub run {
	$stdin = shift;

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

	$status = system @_;

	open STDIN,  '<&', $si or die "dup: $!\n";
	open STDOUT, '>&', $so or die "dup: $!\n";
	open STDERR, '>&', $se or die "dup: $!\n";

	close $si;
	close $so;
	close $se;

	local $/ = undef;

	open my $ro, '<', $no or die "open $no: $!\n";
	open my $re, '<', $ne or die "open $ne: $!\n";

	$stdout = <$ro>;
	$stderr = <$re>;

	close $ro;
	close $re;

	unlink $ni;
	unlink $no;
	unlink $ne;
}

sub note_lines {
	my $tag = shift;
	my $text = shift;
	$text =~ s{^(.*)$}{$tag: $1}gm;
	note $text;
}

sub note_stdio {
	note_lines IN  => $stdin;
	note_lines OUT => $stdout;
	note_lines ERR => $stderr;
}

sub fails {
	my $name = shift;
	run @_;
	isnt $status, 0, $name;
	note_stdio;
}

sub works {
	my $name = shift;
	run @_;
	is $status, 0, $name;
	note_stdio;
}

__PACKAGE__
__END__
