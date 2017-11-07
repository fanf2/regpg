#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

my $cleartext = 'sooper sekrit';

works 'encrypt pipe in / pipe out',
    $cleartext => $regpg, 'encrypt';
like $stdout, $pgpmsg, 'encrypt pipe out is encrypted';
is $stderr, '', 'encrypt pipe stderr quiet';

works 'encrypt - -',
    $cleartext => $regpg, 'encrypt', '-', '-';
like $stdout, $pgpmsg, 'encrypt - - out is encrypted';
is $stderr, '', 'encrypt - - stderr quiet';

my $ciphertext = $stdout;

works 'decrypt pipe in / pipe out',
    $ciphertext => $regpg, 'decrypt';
is $stdout, $cleartext, 'decrypt pipe out is cleartext';
is $stderr, '', 'decrypt pipe stderr quiet';

works 'decrypt - -',
    $ciphertext => $regpg, 'decrypt', '-', '-';
is $stdout, $cleartext, 'decrypt - - out is cleartext';
is $stderr, '', 'decrypt - - stderr quiet';

works 'encrypt one argument',
    $cleartext => $regpg, 'encrypt', 'secret.asc';
is $stdout, '', 'encrypt one stdout quiet';
is $stderr, '', 'encrypt one stderr quiet';
ok -f 'secret.asc', 'encrypt one wrote file';
like slurp('secret.asc'), $pgpmsg, 'encrypt one file is a PGP message';

unlink 'secret.asc';
works 'encrypt - out arguments',
    $cleartext => $regpg, 'encrypt', '-', 'secret.asc';
is $stdout, '', 'encrypt - out stdout quiet';
is $stderr, '', 'encrypt - out stderr quiet';
ok -f 'secret.asc', 'encrypt - out wrote file';
like slurp('secret.asc'), $pgpmsg, 'encrypt - out file is a PGP message';

works 'decrypt one argument',
    '' => $regpg, 'decrypt', 'secret.asc';
is $stdout, $cleartext, 'decrypt one stdout is cleartext';
is $stderr, '', 'decrypt one stderr quiet';

works 'decrypt in - arguments',
    '' => $regpg, 'decrypt', 'secret.asc', '-';
is $stdout, $cleartext, 'decrypt in - stdout is cleartext';
is $stderr, '', 'decrypt in - stderr quiet';

spew 'secret', $cleartext;
unlink 'secret.asc';

works 'encrypt in - arguments',
    $cleartext => $regpg, 'encrypt', 'secret', '-';
like $stdout, $pgpmsg, 'encrypt in - stdout is a PGP message';
is $stderr, '', 'encrypt in - stderr quiet';
is slurp('secret'), $cleartext, 'encrypt in - input unchanged';
isnt -f 'secret.asc', 'encrypt in - no output file';

works 'encrypt two arguments',
    '' => $regpg, 'encrypt', 'secret', 'secret.asc';
is $stdout, '', 'encrypt two stdout quiet';
is $stderr, '', 'encrypt two stderr quiet';
is slurp('secret'), $cleartext, 'encrypt two input unchanged';
ok -f 'secret.asc', 'encrypt two wrote file';
$ciphertext = slurp('secret.asc');
like $ciphertext, $pgpmsg, 'encrypt two file is a PGP message';

works 'decrypt - out arguments',
    $ciphertext => $regpg, 'decrypt', '-', 'secout';
is $stdout, '', 'decrypt - out stdout quiet';
is $stderr, '', 'decrypt - out stderr quiet';
ok -f 'secout', 'decrypt - out wrote file';
is slurp('secout'), $cleartext, 'decrypt - out correct output';

unlink 'secout';

works 'decrypt two arguments',
    '' => $regpg, 'decrypt', 'secret.asc', 'secout';
is $stdout, '', 'decrypt two stdout quiet';
is $stderr, '', 'decrypt two stderr quiet';
is slurp('secret.asc'), $ciphertext, 'decrypt two input unchanged';
ok -f 'secout', 'decrypt two wrote file';
is slurp('secout'), $cleartext, 'decrypt two correct output';

fails 'encrypt three arguments',
    '' => $regpg, qw(encrypt one two three);

fails 'decrypt three arguments',
    '' => $regpg, qw(decrypt one two three);

works 'en short synonym',
    $cleartext => $regpg, 'en';
like $stdout, $pgpmsg, 'en stdout encrypted';
is $stderr, '', 'en stderr quiet';

fails 'de short synonym',
    $ciphertext => $regpg, 'de';

unlink 'secret.asc', 'secret', 'secout';

done_testing;
exit;
