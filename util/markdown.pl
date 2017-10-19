#!/usr/bin/perl

use warnings;
use strict;

use File::Basename;
use File::Slurp;
use File::Spec::Functions qw(abs2rel);
use Text::Markdown;

die "usage: markdown.pl <in.md> <out.html>\n" unless @ARGV == 2;

my ($in,$out) = @ARGV;

my $css = abs2rel 'doc/style.css', dirname $in;

my $md = read_file $in;

die "stray tabs!\n" if $md =~ m{\t};

$md =~ s{£}{&pound;}g;
$md =~ m{^([^\n]*)\n};
my $title = $1;

my $body = Text::Markdown::Markdown($md);

write_file $out, <<HTML;
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
