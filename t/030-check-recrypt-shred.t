#!/usr/bin/perl

use strict;
use warnings;

use Term::ANSIColor qw(colorstrip :constants);
use Test::More;

use T;

my $k2 = 'regpg-two@testing.example';
my $q2 = quotemeta $k2;
my $r = quotemeta RED;
my $g = quotemeta GREEN;
my $b = quotemeta RESET;

works 'create encrypted file1',
    'secret1' => qw(regpg encrypt file1.asc);

works 'check file1',
    '' => qw(regpg check);
like $stdout, qr{file1\.asc}, 'check mentions file1';
is $stderr, '', 'check stderr quiet';

spew 'file1';
fails 'check finds cleartext',
    '' => qw(regpg check);
like $stdout, qr{CLEARTEXT}, 'check mentions cleartext';
is $stderr, '', 'check stderr quiet';

fails 'shred requires -r',
    '' => qw(regpg shred);
is $stdout, '', 'shred stdout quiet';
like $stderr, qr{ use -r }, 'shred stderr saye use -r';

works 'create encrypted file2',
    'secret2' => qw(regpg encrypt file2.asc);

works 'shred -r',
    '' => qw(regpg shred -r);
is $stdout, '', 'shred stdout quiet';
like $stderr, qr{running .*/file}, 'shred stderr verbosity';
isnt -f 'file1', 'shred removed cleartext file1';

unlink 'file2.asc';

gpg_batch_yes;
works 'delete a key', '' => qw(regpg del), $k2;
unlink $gpgconf;

fails 'check finds missing key (long form)',
    '' => qw(regpg check);
like colorstrip($stdout), qr{^[-]\w+\s.*\s<?$q2>?\s*$}m, 'check shows key deleted';
like $stderr, qr{public key not found|No public key},
    'check complains about missing key';

fails 'recrypt requires -r',
    '' => qw(regpg recrypt);
is $stdout, '', 'recrypt stdout quiet';
like $stderr, qr{ use -r }, 'recrypt stderr says use -r';

fails 'recrypt short alias',
    '' => qw(regpg re);
is $stdout, '', 're stdout quiet';
like $stderr, qr{ use -r }, 're stderr says use -r';

works 'recrypt -r (del)',
    '' => qw(regpg recrypt -r);
is $stdout, '', 'recrypt stdout quiet';
is $stderr, '', 'recrypt stderr quiet';

works 'check after recrypt (del)',
    '' => qw(regpg check);
like $stdout, qr{file1\.asc}, 'check mentions file1';
is $stderr, '', 'check stderr quiet';

works 'add a key', '' => qw(regpg add), $k2;

fails 'check finds new key',
    '' => qw(regpg check);
like colorstrip($stdout), qr{^[+]\w+\s.*\s<?$q2>?\s*$}m, 'check shows new key';
is $stderr, '', 'check stderr quiet';

works 'recrypt -r (add)',
    '' => qw(regpg recrypt -r);
is $stdout, '', 'recrypt stdout quiet';
is $stderr, '', 'recrypt stderr quiet';

works 'check after recrypt (add)',
    '' => qw(regpg check);
like $stdout, qr{file1\.asc}, 'check mentions file1';
is $stderr, '', 'check stderr quiet';

works 'create encrypted file2',
    'secret2' => qw(regpg encrypt file2.asc);

gpg_batch_yes;
works 'delete a key', '' => qw(regpg del), $k2;
unlink $gpgconf;

fails 'check finds missing key (short form)',
    '' => qw(regpg check);
like $stdout, qr{\s+$r[-]\w+$b\s*$}m, 'check shows key deleted';
like $stdout, qr{file1\.asc}, 'check mentions file1';
like $stdout, qr{file2\.asc}, 'check mentions file2';
is $stderr, '', 'check stderr quiet';

works 'recrypt -r (add)',
    '' => qw(regpg recrypt -r);
is $stdout, '', 'recrypt stdout quiet';
is $stderr, '', 'recrypt stderr quiet';

works 'check after recrypt (two files)',
    '' => qw(regpg check);
like $stdout, qr{file1\.asc}, 'check mentions file1';
like $stdout, qr{file2\.asc}, 'check mentions file2';
is $stderr, '', 'check stderr quiet';

works 'add a key', '' => qw(regpg add), $k2;

fails 'check finds new key (short form)',
    '' => qw(regpg check);
like $stdout, qr{\s+$g[+]\w+$b\s*$}m, 'check shows key added';
like $stdout, qr{file1\.asc}, 'check mentions file1';
like $stdout, qr{file2\.asc}, 'check mentions file2';
is $stderr, '', 'check stderr quiet';

works 'recrypt -r (del)',
    '' => qw(regpg recrypt -r);
is $stdout, '', 'recrypt stdout quiet';
is $stderr, '', 'recrypt stderr quiet';

works 'check after recrypt (two files)',
    '' => qw(regpg check);
like $stdout, qr{file1\.asc}, 'check mentions file1';
like $stdout, qr{file2\.asc}, 'check mentions file2';
is $stderr, '', 'check stderr quiet';

works 'decrypt file1',
    '' => qw(regpg decrypt file1.asc);
is $stdout, 'secret1', 'decrypt file1 OK';
is $stderr, '', 'decrypt file1 stderr quiet';

works 'decrypt file2',
    '' => qw(regpg decrypt file2.asc);
is $stdout, 'secret2', 'decrypt file2 OK';
is $stderr, '', 'decrypt file2 stderr quiet';

works 'shred files',
    '' => qw(regpg shred file1.asc file2.asc);
isnt -f 'file1.asc', 'shred removed file1.asc';
isnt -f 'file2.asc', 'shred removed file2.asc';

done_testing;
exit;
