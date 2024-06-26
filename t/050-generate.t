#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

my $cert = <<'CERT';
-----BEGIN CERTIFICATE-----
MIIGATCCBOmgAwIBAgISA2uP+lWKbsxZ6Fxg6vf9HcSgMA0GCSqGSIb3DQEBCwUA
MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD
ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xNzExMDIxOTU5MDFaFw0x
ODAxMzExOTU5MDFaMBMxETAPBgNVBAMTCGRvdGF0LmF0MIICIjANBgkqhkiG9w0B
AQEFAAOCAg8AMIICCgKCAgEAqtjNHyTBWTQ3eIFdtIPAk79vnJgkEE4JJq0HLI1N
Alm533WY68Av4hmdK4pz2/Sjpvyx9nnPFI8fgWbRJBN3q9TAmVgOIXciDBRTMkK4
Lb44viGzrYAr6MSE6mBmO6ouyLgv0jt0hvnzkz0LJF08xuZROMstHIJeZcS+AFFa
J3LjwLRZOtE0qFiIesycJTyUlHuJH2ChmRXfYLFDlcJ1bltlRgZxUwahJPhes628
OhGhTzzuHrwiDzFP3+HfFqdPcuEnh9gwTAhYNlTBQ9RC7W/Y3Pl3GXtZkGKzmdCW
pYOw/IIxooPqYe8/p23huScfMgNCbyJIS5+HOVSqHN6YogwDsfkJOON9pKCMoSGy
0wlD08Xpb8Qq9ESYDPSZmfbFGEvNCq58Tzr1oFQBDGLCRLll/NdCdX6sJ5C/Knye
o0G/EWd8ZeuCwtV5dT+XW/NLRdNB9FqbvzOA9DoMQYn+AQvHO59uVgozRO4RiEgQ
OqG5GcOHKOWKlV7tb69VhKC1NgMl8QDwJE0K4KSxFRkEyr+97/3YPPZ7ggwnyPCN
aoOPjoQcw+QUprGYleqrCRAhnBUR0cbBchp1Jib6icSDpE0UQBGWGCCMEog1EwI5
0rvgvoodaFVrR3dH9zN2sKAEMgBiOHwZcvkdQtrVcv06CAZKMhRBMNR4k7lw4O4+
AmMCAwEAAaOCAhYwggISMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEF
BQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUhAC4PpGv1ESS
uB6qyuk8DN5n2+UwHwYDVR0jBBgwFoAUqEpqYwR93brm0Tm3pkVl7/Oo7KEwbwYI
KwYBBQUHAQEEYzBhMC4GCCsGAQUFBzABhiJodHRwOi8vb2NzcC5pbnQteDMubGV0
c2VuY3J5cHQub3JnMC8GCCsGAQUFBzAChiNodHRwOi8vY2VydC5pbnQteDMubGV0
c2VuY3J5cHQub3JnLzAhBgNVHREEGjAYgghkb3RhdC5hdIIMd3d3LmRvdGF0LmF0
MIH+BgNVHSAEgfYwgfMwCAYGZ4EMAQIBMIHmBgsrBgEEAYLfEwEBATCB1jAmBggr
BgEFBQcCARYaaHR0cDovL2Nwcy5sZXRzZW5jcnlwdC5vcmcwgasGCCsGAQUFBwIC
MIGeDIGbVGhpcyBDZXJ0aWZpY2F0ZSBtYXkgb25seSBiZSByZWxpZWQgdXBvbiBi
eSBSZWx5aW5nIFBhcnRpZXMgYW5kIG9ubHkgaW4gYWNjb3JkYW5jZSB3aXRoIHRo
ZSBDZXJ0aWZpY2F0ZSBQb2xpY3kgZm91bmQgYXQgaHR0cHM6Ly9sZXRzZW5jcnlw
dC5vcmcvcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQELBQADggEBAGlGM8eWBIcTJe0i
X7TUsYUfaF+R3JNj+R64wDc5G1hY3v7AohbAtcVIEBgG9BViBCJnMDRslXJyaRMP
AYw2yi86vOjOgjAginYRlNcoj+Df7+YFUmXiI9X0eG8HBf242QhnUGDG40StmYig
hwCpLbHm7FA02qFwfRsvZUvu0d1vEibGD77vtmIv3c4GV8lZC/AHEffr5NbYmeM5
o3dD8sE8ndaF2NsJ/uUsh8geMVLk1ajZfXclbRRBEo1u5r73xYyZHWHHx06xqvEl
dD5Wnm/fbK7UzG+mGWYVf0nQKE2o9hgH7yY7OhcQlOHYi8jpMATBmtkjaJ/2txGY
57Vd274=
-----END CERTIFICATE-----
CERT

works 'gencsrcnf pipe',
    $cert => qw(regpg gencsrcnf);
like $stdout, qr{commonName\s+=\s+dotat[.]at}, 'tls.cnf contains CN';
like $stdout, qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'tls.cnf contains SAN';
is $stderr, '', 'regpg stderr quiet';

works 'gencsrconf compat alias',
    $cert => qw(regpg gencsrconf);
like $stdout, qr{commonName\s+=\s+dotat[.]at}, 'tls.cnf contains CN';
like $stdout, qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'tls.cnf contains SAN';
is $stderr, '', 'regpg stderr quiet';

spew 'cert', $cert;

works 'gencsrcnf from file',
    '' => qw(regpg gencsrcnf cert);
like $stdout, qr{commonName\s+=\s+dotat[.]at}, 'tls.cnf contains CN';
like $stdout, qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'tls.cnf contains SAN';
is $stderr, '', 'regpg stderr quiet';

works 'gencsrcnf to file',
    '' => qw(regpg gencsrcnf cert tls.cnf);
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
like slurp('tls.cnf'),
    qr{commonName\s+=\s+dotat[.]at}, 'tls.cnf contains CN';
like slurp('tls.cnf'),
    qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'tls.cnf contains SAN';

fails 'gencsrcnf three args',
    '' => qw(regpg gencsrcnf one two three);
like $stderr, qr{usage:}, 'usage';

works 'genkey rsa',
    '' => qw(regpg genkey rsa tls.pem.asc);
is $stdout, '', 'regpg stdout quiet';
ok -f 'tls.pem.asc', 'genkey rsa wrote file';
like slurp('tls.pem.asc'), $pgpmsg, 'genkey rsa wrote encrypted file';

works 'decrypt rsa key', '' => qw(regpg decrypt tls.pem.asc);
like $stdout, qr{-----BEGIN( RSA)? PRIVATE KEY-----}, 'genkey made a private key';

works 'genkey rsa ssh',
    '' => qw(regpg genkey rsa ssh.asc ssh.pub);
is $stdout, '', 'regpg stdout quiet';
ok -f 'ssh.asc', 'genkey rsa wrote ssh private key';
ok -f 'ssh.pub', 'genkey rsa wrote ssh public key';
like slurp('ssh.asc'), $pgpmsg, 'genkey rsa wrote encrypted ssh key';
like slurp('ssh.pub'), qr{ssh-rsa}, 'genkey rsa ssh public key OK';

works 'decrypt ssh key', '' => qw(regpg decrypt ssh.asc);
like $stdout, qr{-----BEGIN( RSA)? PRIVATE KEY-----}, 'genkey made a private key';

works 'genkey ecdsa',
    '' => qw(regpg genkey ecdsa ec.asc);
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
ok -f 'ec.asc', 'genkey ecdsa wrote private key';
my $ecdsa = slurp('ec.asc');
like $ecdsa, $pgpmsg, 'genkey ecdsa wrote encrypted key';

works 'genkey ecdsa make pub key',
    '' => qw(regpg genkey ecdsa ec.asc ec.pub);
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
ok -f 'ec.pub', 'genkey ecdsa wrote ssh public key';
is slurp('ec.asc'), $ecdsa, 'genkey ecdsa priv key unchanged';
like slurp('ec.pub'), qr{ecdsa-sha2-nistp256}, 'genkey ecdsa ssh public key OK';

if (canexec 'puttygen') {
	works 'genkey ed25519 ssh',
	    '' => qw(regpg genkey ed25519 ed.asc ed.pub);
	is $stdout, '', 'regpg stdout quiet';
	is $stderr, '', 'regpg stderr quiet';
	ok -f 'ed.asc', 'genkey ed25519 wrote ssh private key';
	ok -f 'ed.pub', 'genkey ed25519 wrote ssh public key';
	like slurp('ed.asc'), $pgpmsg, 'genkey ed25519 wrote encrypted ssh key';
	like slurp('ed.pub'), qr{ssh-ed25519}, 'genkey ed25519 ssh public key OK';
}

fails 'genkey one arg',
    '' => qw(regpg genkey one);
like $stderr, qr{usage:}, 'usage';

fails 'genkey four args',
    '' => qw(regpg genkey one two three four);
like $stderr, qr{usage:}, 'usage';

my $csr = qr{\A-----BEGIN CERTIFICATE REQUEST-----};

works 'gencsr pipe',
    '' => qw(regpg gencsr tls.pem.asc tls.cnf);
like $stdout, $csr, 'regpg stdout is cert request';
is $stderr, '', 'regpg stderr quiet';

works 'gencsr file',
    '' => qw(regpg gencsr tls.pem.asc tls.cnf tls.csr);
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
ok -f 'tls.csr', 'gencsr wrote file';
like slurp('tls.csr'), $csr, 'gencsr file is cert request';

works 'openssl likes csr',
    '' => qw(openssl req -in tls.csr -text);
like $stdout, qr{CN ?= ?dotat[.]at}, 'openssl found CN';
like $stdout, qr{DNS:www[.]dotat[.]at}, 'openssl found SAN';
is $stderr, '', 'openssl stderr quiet';

works 'gencsr verbose pipe',
    '' => qw(regpg gencsr -v tls.pem.asc tls.cnf);
like $stdout, $csr, 'verbose stdout cert';
like $stderr, qr{pipe to openssl req}, 'regpg stderr noisy';

works 'gencsr verbose file',
    '' => qw(regpg gencsr -v tls.pem.asc tls.cnf tls.csr);
like $stdout, qr{CN ?= ?dotat[.]at}, 'verbose found CN';
like $stdout, qr{DNS:www[.]dotat[.]at}, 'verbose found SAN';
like $stderr, qr{running openssl req}, 'regpg stderr noisy';

fails 'gencsr one arg',
    '' => qw(regpg gencsr one);
like $stderr, qr{usage:}, 'usage';

fails 'gencsr four args',
    '' => qw(regpg gencsr one two three four);
like $stderr, qr{usage:}, 'usage';

works 'genpwd pipe',
    '' => qw(regpg genpwd -q);
like $stdout, $pgpmsg, 'genpwd -q output encrypted';
is $stderr, '', 'regpg stderr quiet';

unlink 'pwd.asc';
run '' => qw(regpg genpwd pwd.asc);
if ($stderr =~ m{crypt.3. does not support SHA256}) {
	isnt $status, 0, 'regpg genpwd';
	is $stdout, '', 'regpg stdout quiet';

	ok -f 'pwd.asc', 'genpwd wrote file';
	like slurp('pwd.asc'), $pgpmsg, 'genpwd file encrypted';
} else {
	is $status, 0, 'regpg genpwd';
	is $stderr, '', 'regpg stderr quiet';
	like $stdout, qr{^\$5\$}, 'regpg stdout hashed pwd';
	my $hash = $stdout;

	ok -f 'pwd.asc', 'genpwd wrote file';
	like slurp('pwd.asc'), $pgpmsg, 'genpwd file encrypted';

	works 'decrypt pwd',
	    '' => qw(regpg decrypt pwd.asc);
	my $pwd = $stdout;
	chomp $pwd;
	sub ck {
		return sprintf "%s\n", crypt $pwd, shift;
	}
	is $hash, (ck $hash), "crypt works first time";

	works 'genpwd file again',
	    '' => qw(regpg genpwd pwd.asc);
	like $stdout, qr{^\$5\$}, 'regpg stdout hashed pwd';
	is $stdout, (ck $stdout), "crypt works second time";
}

done_testing;
exit;
