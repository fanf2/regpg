package T;

use strict;
use warnings;

use Exporter;
use FindBin;

our $gnupg;
our $regpg;
our $work;

our @EXPORT = qw(
	$gnupg
	$regpg
	$work
    );

BEGIN {
	my $dir = "$FindBin::Bin";

	$gnupg = "$dir/gnupg";
	$regpg = "$dir/../regpg";
	$work  = "$dir/work";

	chdir $work; # ignore failure

	$ENV{GNUPGHOME} = "$gnupg";
};

__PACKAGE__
__END__
