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
our $gpgconf;
our $work;

our $status;
our $stdin;
our $stdout;
our $stderr;

our @EXPORT = qw(
	$regpg
	$gnupg
	$gpgconf
	$work

	$status
	$stdin
	$stdout
	$stderr

	run
	fails
	works

	gpg_batch_yes
    );

BEGIN {
	my $dir = "$FindBin::Bin";

	$regpg = "$dir/../regpg";
	$gnupg = "$dir/gnupg";
	$gpgconf = "$gnupg/gpg.conf";
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

sub gpg_batch_yes {
	open my $h, '>', $gpgconf or die "open $gpgconf: $!\n";
	print $h "batch\nyes\nno-tty\n";
	close $h;
}

sub note_lines {
	my $ok = shift;
	my $tag = shift;
	my $text = shift;
	$text =~ s{^(.*)$}{$tag: $1}gm;
	$ok ? note $text : diag $text;
}

sub note_stdio {
	my $ok = shift;
	note_lines $ok, IN  => $stdin;
	note_lines $ok, OUT => $stdout;
	note_lines $ok, ERR => $stderr;
}

sub fails {
	my $name = shift;
	run @_;
	note_stdio isnt $status, 0, $name;
}

sub works {
	my $name = shift;
	run @_;
	note_stdio is $status, 0, $name;
}

__PACKAGE__
__END__
