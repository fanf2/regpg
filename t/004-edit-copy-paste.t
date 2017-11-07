#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

sub canexec {
	return scalar grep { -x "$_/@_" } split /:/, $ENV{PATH};
}

works 'create encrypted file',
    'foo bar zig' => $regpg, 'encrypt', 'file.asc';

spew 'editor', <<'EDITOR';
#!/bin/sh
perl -pi -e 's{ bar }{ pub }' "$@"
EDITOR
chmod 0755, 'editor';
$ENV{EDITOR} = './editor';

gpg_batch_yes;
works 'edit encrypted file',
    '' => $regpg, 'edit', 'file.asc';
is $stdout, '', 'edit stdout quiet';
is $stderr, '', 'edit stderr quiet';
unlink $gpgconf;

works 'decrypt edited file',
    '' => $regpg, 'decrypt', 'file.asc';
is $stdout, 'foo pub zig', 'correctly edited file';
is $stderr, '', 'decrypt stderr quiet';

TODO: {
	todo_skip 'dunno how to deal with the SIGINT', 1;
	works 'regpg pbcopy',
	    '' => $regpg, 'pbcopy', 'file.asc';
}
SKIP: {
	skip 'no pbcopy', 1 unless canexec 'pbcopy';
	works 'pbcopy',
	    'secret' => 'pbcopy';
}
SKIP: {
	skip 'no xclip', 1 unless canexec 'xclip';
	works 'xclip -i',
	    'secret' => 'xclip', '-i';
}
SKIP: {
	skip 'no pbpaste/xclip', 9 unless canexec 'pbpaste'
				    or canexec 'xclip';
	works 'repgp pbpaste',
	    '' => $regpg, 'pbpaste';
	like $stdout, $pgpmsg, 'regpg stdout encrypted';
	is $stderr, '', 'regpg stderr quiet';
	works 'repgp decrypt',
	    $stdout => $regpg, 'decrypt';
	is $stdout, 'secret', 'regpg decrypt OK';
	is $stderr, '', 'regpg stderr quiet';
	fails 'repgp pbpaste twice',
	    '' => $regpg, 'pbpaste';
	is $stdout, '', 'regpg stdout quiet';
	like $stderr, qr{clipboard is empty}, 'regpg cliboard clear';
}
SKIP: {
	skip 'no pbcopy', 1 unless canexec 'pbcopy';
	works 'pbcopy',
	    'secret' => 'pbcopy';
}
SKIP: {
	skip 'no xclip', 1 unless canexec 'xclip';
	works 'xclip -i',
	    'secret' => 'xclip', '-i';
}
SKIP: {
	skip 'no pbpaste/xclip', 6 unless canexec 'pbpaste'
				    or canexec 'xclip';
	works 'repgp pbpaste file',
	    '' => $regpg, 'pbpaste', 'paste.asc';
	is $stdout, '', 'regpg stdout quiet';
	is $stderr, '', 'regpg stderr quiet';
	works 'repgp decrypt',
	    '' => $regpg, 'decrypt', 'paste.asc';
	is $stdout, 'secret', 'regpg decrypt OK';
	is $stderr, '', 'regpg stderr quiet';
}

done_testing;
exit;
