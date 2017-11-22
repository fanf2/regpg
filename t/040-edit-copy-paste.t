#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

sub canxclip {
	return defined $ENV{DISPLAY} && canexec 'xclip';
}

works 'create encrypted file',
    'foo bar zig' => qw(regpg encrypt file.asc);

spew 'editor', <<'EDITOR';
#!/bin/sh
perl -pi -e 's{ bar }{ pub }' "$@"
EDITOR
chmod 0755, 'editor';

$ENV{EDITOR} = './editor';
gpg_batch_yes;
works 'edit encrypted file',
    '' => qw(regpg edit file.asc);
is $stdout, '', 'edit stdout quiet';
is $stderr, '', 'edit stderr quiet';
unlink $gpgconf;
undef $ENV{EDITOR};

works 'decrypt edited file',
    '' => qw(regpg decrypt file.asc);
is $stdout, 'foo pub zig', 'correctly edited file';
is $stderr, '', 'decrypt stderr quiet';

spew 'editor', <<'EDITOR';
#!/bin/sh
printf 'new file' >"$*"
EDITOR
chmod 0755, 'editor';
unlink 'newfile.asc';

$ENV{EDITOR} = './editor';
gpg_batch_yes;
works 'edit new file',
    '' => qw(regpg edit newfile.asc);
is $stdout, '', 'edit stdout quiet';
is $stderr, '', 'edit stderr quiet';
unlink $gpgconf;
undef $ENV{EDITOR};

ok -f 'newfile.asc', 'edit created file';
works 'decrypt new edited file',
    '' => qw(regpg decrypt newfile.asc);
is $stdout, 'new file', 'edit created correct file';
is $stderr, '', 'decrypt stderr quiet';

TODO: {
	todo_skip 'dunno how to deal with the SIGINT', 1;
	works 'regpg pbcopy',
	    '' => qw(regpg pbcopy file.asc);
}
SKIP: {
	skip 'no pbcopy', 1 unless canexec 'pbcopy';
	works 'pbcopy',
	    'secret' => 'pbcopy';
}
SKIP: {
	skip 'no xclip', 1 unless canxclip;
	works 'xclip -i',
	    'secret' => qw(xclip -i);
}
SKIP: {
	skip 'no pbpaste/xclip', 9 unless canexec 'pbpaste'
				    or canxclip;
	works 'repgp pbpaste',
	    '' => qw(regpg pbpaste);
	like $stdout, $pgpmsg, 'regpg stdout encrypted';
	is $stderr, '', 'regpg stderr quiet';
	works 'repgp decrypt',
	    $stdout => qw(regpg decrypt);
	is $stdout, 'secret', 'regpg decrypt OK';
	is $stderr, '', 'regpg stderr quiet';
	fails 'repgp pbpaste twice',
	    '' => qw(regpg pbpaste);
	is $stdout, '', 'regpg stdout quiet';
	like $stderr, qr{clipboard is empty}, 'regpg cliboard clear';
}
SKIP: {
	skip 'no pbcopy', 1 unless canexec 'pbcopy';
	works 'pbcopy',
	    'secret' => 'pbcopy';
}
SKIP: {
	skip 'no xclip', 1 unless canxclip;
	works 'xclip -i',
	    'secret' => qw(xclip -i);
}
SKIP: {
	skip 'no pbpaste/xclip', 6 unless canexec 'pbpaste'
				    or canxclip;
	works 'repgp pbpaste file',
	    '' => qw(regpg pbpaste paste.asc);
	is $stdout, '', 'regpg stdout quiet';
	is $stderr, '', 'regpg stderr quiet';
	works 'repgp decrypt',
	    '' => qw(regpg decrypt paste.asc);
	is $stdout, 'secret', 'regpg decrypt OK';
	is $stderr, '', 'regpg stderr quiet';
}

done_testing;
exit;
