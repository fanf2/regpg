#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use T;

unlink glob '*';
works 'add', '' => qw(regpg add testing.example);

my $crt = qr{\A-----BEGIN CERTIFICATE-----};

my $xx = qr{[0-9a-fA-F]{2}};

spew 'ca.cnf', <<'END';
[ req ]
prompt = no
distinguished_name = distinguished_name
req_extensions = extensions
x509_extensions = extensions

[ extensions ]
keyUsage = critical, keyCertSign, cRLSign
basicConstraints = critical, CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = issuer:always, keyid:always

[ distinguished_name ]
commonName = "Honest Achmed's Used Cars and Certificates"
END

works 'genkey rsa',
    '' => qw(regpg genkey rsa ca.pem.asc);
ok -f 'ca.pem.asc', 'genkey rsa wrote file';

works 'gencrt ca',
    '' => qw(regpg gencrt 365 ca.pem.asc ca.cnf ca.crt);
ok -f 'ca.crt', 'gencrt wrote file';
like slurp('ca.crt'), $crt, 'gencrt file is cert';

works 'openssl likes ca.crt',
    '' => qw(openssl x509 -in ca.crt -text);
like $stdout, qr{CN ?= ?Honest Achmed}, 'openssl found CN';
is $stderr, '', 'openssl stderr quiet';

my ($ca_sn) = $stdout =~ m{\s+Serial Number:\s+(\S+)\n};
my ($ca_id) = $stdout =~ qr{\s+X509v3 Subject Key Identifier:\s+(\S+)\s+};
$ca_sn = uc $ca_sn; # good grief, OpenSSL, can't you be consistent?

like $ca_sn, qr{^($xx:){14,}$xx$}, 'serial number is 16 bytes';
like $ca_id, qr{^($xx:){15,}$xx$}, 'key id is 16 or more bytes';
like $stdout, qr{\s+X509v3\s+Authority\s+Key\s+Identifier:
		 \s+keyid:$ca_id
		 \s+DirName:[^\n]+
		 \s+serial:$ca_sn}x,
    'authority key id/sn same as subject key id/sn';

like $stdout, qr{Signature Algorithm: sha256WithRSAEncryption},
    'ca certificate uses SHA256';

spew 'web.cnf', <<'END';
[ req ]
prompt = no
distinguished_name = distinguished_name
req_extensions = extensions
x509_extensions = extensions

[ extensions ]
subjectAltName = @subjectAltName
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[ distinguished_name ]
commonName = dotat.at

[ subjectAltName ]
DNS.0 = dotat.at
DNS.1 = www.dotat.at
END

works 'genkey rsa',
    '' => qw(regpg genkey rsa web.pem.asc);
ok -f 'web.pem.asc', 'genkey rsa wrote file';

works 'gencrt web (self)',
    '' => qw(regpg gencrt 365 web.pem.asc web.cnf web.crt);
ok -f 'web.crt', 'gencrt wrote file';
like slurp('web.crt'), $crt, 'gencrt file is cert';

works 'openssl likes web.crt (self)',
    '' => qw(openssl x509 -in web.crt -text);
like $stdout, qr{CN ?= ?dotat[.]at}, 'openssl found CN';
like $stdout, qr{DNS:www[.]dotat[.]at}, 'openssl found SAN';
is $stderr, '', 'openssl stderr quiet';

my ($web_sn) = $stdout =~ m{\s+Serial Number:\s+(\S+)\n};
my ($web_id) = $stdout =~ qr{\s+X509v3 Subject Key Identifier:\s+(\S+)\s+};
$web_sn = uc $web_sn; # sigh

unlink 'web.crt';

works 'gencrt web (signed)',
    '' => qw(regpg gencrt 365 ca.pem.asc ca.crt web.pem.asc web.cnf web.crt);
ok -f 'web.crt', 'gencrt wrote file';
like slurp('web.crt'), $crt, 'gencrt file is cert';

works 'openssl likes web.crt (self)',
    '' => qw(openssl x509 -in web.crt -text);
like $stdout, qr{CN ?= ?dotat[.]at}, 'openssl found CN';
like $stdout, qr{DNS:www[.]dotat[.]at}, 'openssl found SAN';
is $stderr, '', 'openssl stderr quiet';

like $stdout, qr{Signature Algorithm: sha256WithRSAEncryption},
    'certificate uses SHA256';

like $stdout, qr{\s+X509v3\s+Authority\s+Key\s+Identifier:
		 \s+keyid:$ca_id
		 \s+DirName:[^\n]+
		 \s+serial:$ca_sn}x,
    'authority key id/sn refer to certificate authority';

works 'openssl can verify cert',
    '' => qw(openssl verify -CAfile ca.crt web.crt);
is $stdout, "web.crt: OK\n", 'verified OK';

works 'decrypt key',
    '' => qw{regpg decrypt web.pem.asc web.pem};
works 'genspkifp web.pem',
    '' => qw{regpg genspkifp web.pem};
my $fp = $stdout;
is length $fp, int((256/8+2)*4/3), 'plausible SHA256 fingerprint';
works 'genspkifp web.pem.asc',
    '' => qw{regpg genspkifp -v web.pem.asc};
is $stdout, $fp, 'web.pem fp matches web.pem.asc';
works 'genspkifp web.crt',
    '' => qw{regpg genspkifp web.crt};
is $stdout, $fp, 'web.pem fp matches web.crt';
like $stderr, qr{CN ?= ?dotat[.]at}, 'printed DN of crt';

works 'generate csr',
    '' => qw{regpg gencsr web.pem.asc web.cnf web.csr};
works 'openssl likes web.csr',
    '' => qw(openssl req -in web.csr -text);
like $stdout, qr{Signature Algorithm: sha256WithRSAEncryption},
    'csr uses SHA256';
works 'genspkifp web.csr',
    '' => qw{regpg genspkifp web.crt};
is $stdout, $fp, 'web.pem fp matches web.csr';
like $stderr, qr{CN ?= ?dotat[.]at}, 'printed DN of csr';
works 'genspkifp quietly',
    '' => qw{regpg genspkifp -q web.crt};
is $stdout, $fp, 'web.pem fp matches web.csr';
is $stderr, '', 'quiet mode';

done_testing;
exit;
