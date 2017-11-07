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

works 'gencsrconf pipe',
    $cert => $regpg, 'gencsrconf';
like $stdout, qr{commonName\s+=\s+dotat[.]at}, 'csrconf contains CN';
like $stdout, qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'csrconf contains SAN';
is $stderr, '', 'regpg stderr quiet';

spew 'cert', $cert;

works 'gencsrconf from file',
    '' => $regpg, 'gencsrconf', 'cert';
like $stdout, qr{commonName\s+=\s+dotat[.]at}, 'csrconf contains CN';
like $stdout, qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'csrconf contains SAN';
is $stderr, '', 'regpg stderr quiet';

works 'gencsrconf to file',
    '' => $regpg, 'gencsrconf', 'cert', 'tls.csr.conf';
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
like slurp('tls.csr.conf'),
    qr{commonName\s+=\s+dotat[.]at}, 'csrconf contains CN';
like slurp('tls.csr.conf'),
    qr{DNS.\d+\s+=\s+www[.]dotat[.]at}, 'csrconf contains SAN';

fails 'gencsrconf three args',
    '' => $regpg, qw(gencsrconf one two three);
like $stderr, qr{usage:}, 'usage';

works 'genkey rsa',
    '' => $regpg, qw(genkey rsa tls.pem.asc);
is $stdout, '', 'regpg stdout quiet';
like $stderr, qr{Generating}, 'regpg stderr noisy';
ok -f 'tls.pem.asc', 'genkey rsa wrote file';
like slurp('tls.pem.asc'), $pgpmsg, 'genkey rsa wrote encrypted file';

works 'genkey rsa ssh',
    '' => $regpg, qw(genkey rsa ssh.asc ssh.pub);
is $stdout, '', 'regpg stdout quiet';
like $stderr, qr{Generating}, 'regpg stderr noisy';
ok -f 'ssh.asc', 'genkey rsa wrote ssh private key';
ok -f 'ssh.pub', 'genkey rsa wrote ssh public key';
like slurp('ssh.asc'), $pgpmsg, 'genkey rsa wrote encrypted ssh key';
like slurp('ssh.pub'), qr{ssh-rsa}, 'genkey rsa ssh public key OK';

fails 'genkey one arg',
    '' => $regpg, qw(genkey one);
like $stderr, qr{usage:}, 'usage';

fails 'genkey four args',
    '' => $regpg, qw(genkey one two three four);
like $stderr, qr{usage:}, 'usage';

my $csr = qr{\A-----BEGIN CERTIFICATE REQUEST-----};

works 'gencsr pipe',
    '' => $regpg, 'gencsr', 'tls.pem.asc', 'tls.csr.conf';
like $stdout, $csr, 'regpg stdout is cert request';
is $stderr, '', 'regpg stderr quiet';

works 'gencsr file',
    '' => $regpg, 'gencsr', 'tls.pem.asc', 'tls.csr.conf', 'tls.csr';
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
ok -f 'tls.csr', 'gencsr wrote file';
like slurp('tls.csr'), $csr, 'gencsr file is cert request';

works 'openssl likes csr',
    '' => qw(openssl req -in tls.csr -text);
like $stdout, qr{CN=dotat[.]at}, 'openssl found CN';
like $stdout, qr{DNS:www[.]dotat[.]at}, 'openssl found SAN';
is $stderr, '', 'openssl stderr quiet';

fails 'gencsr one arg',
    '' => $regpg, qw(gencsr one);
like $stderr, qr{usage:}, 'usage';

fails 'gencsr four args',
    '' => $regpg, qw(gencsr one two three four);
like $stderr, qr{usage:}, 'usage';

works 'genpwd pipe',
    '' => $regpg, qw(genpwd);
like $stdout, $pgpmsg, 'genpwd output encrypted';
is $stderr, '', 'regpg stderr quiet';

works 'genpwd file',
    '' => $regpg, qw(genpwd pwd.asc);
is $stdout, '', 'regpg stdout quiet';
is $stderr, '', 'regpg stderr quiet';
ok -f 'pwd.asc', 'genpwd wrote file';
like slurp('pwd.asc'), $pgpmsg, 'genpwd file encrypted';

done_testing;
exit;
