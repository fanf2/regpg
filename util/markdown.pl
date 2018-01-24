#!/usr/bin/perl
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

use warnings;
use strict;

use File::Basename;
use File::Spec::Functions qw(abs2rel);
use Text::Markdown;

die "usage: markdown.pl <in.md> <out.html>\n" unless @ARGV == 2;

my ($in,$out) = @ARGV;

my $css = abs2rel 'doc/style.css', dirname $in;

open my $hin, '<', $in or die "open < $in: $!\n";
undef $/;
my $md = <$hin>;

die "stray tabs!\n" if $md =~ m{\t};

$md =~ s{£}{&pound;}g;
$md =~ m{^([^\n]*)\n};
my $title = $1;

my $body = Text::Markdown::markdown($md);

open my $hout, '>', $out or die "open > $out: $!\n";
print $hout <<HTML;
<!DOCTYPE html>
<html lang="en">
 <head>
  <meta charset="utf-8" />
  <link rel="stylesheet" href="$css" type="text/css" />
  <title>$title</title>
 </head>
 <body>
$body
 </body>
</html>
HTML
