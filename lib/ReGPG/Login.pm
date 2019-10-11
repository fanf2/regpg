package ReGPG::Login;

use strict;
use warnings;

use Carp;
use Exporter qw(import);
use File::Basename;
use File::Slurp;
use IPC::System::Simple qw(capturex);
use MIME::Base64;
use YAML;

our $regpg-1.10;

our @EXPORT = qw(
	read_login
);

our @gpg_d = qw(gpg --use-agent --batch --quiet --decrypt);

sub read_login {
	my $yml = shift;
	my $dir = dirname $yml;
	my $login = YAML::LoadFile $yml;
	my $gpg_d = $login->{gpg_d};
	for my $k (keys %$gpg_d) {
		my $asc = $dir.'/'.$gpg_d->{$k};
		my $clear = $asc =~ s{\.asc$}{}r;
		if (-f $clear) {
			$login->{$k} = read_file $clear;
		} else {
			$login->{$k} = capturex @gpg_d, $asc;
		}
		chomp $login->{$k};
	}
	my $check = sub {
		for (@_) {
			croak "$yml: missing key $_\n"
			    unless defined $login->{$_};
		}
	};
	if (ref $_[-1]) {
		my $opt = pop @_;
		if (my $basic = $opt->{basic}) {
			$check->(@$basic);
			my $auth = join ':', @$login{@$basic};
			$login->{authorization} =
			    'Basic ' . encode_base64 $auth, '';
		}
	}
	$check->(@_);
	return $login;
}

1;

__END__

=head1 NAME

ReGPG::Login - load partially-encrypted login credentials

=head1 SYNOPSIS

	use ReGPG::Login;

	my $login = read_login "login.yml",
		qw(username password url);

=head1 DESCRIPTION

To avoid unnecessarily decrypting secrets, B<regpg> encourages you to
store nothing but a bare secret in each encrypted file. Information
about what is in the file is kept elsewhere in cleartext.

ReGPG::Login defines a conventional storage layout for login
credentials. Each login has a L<YAML> file containing metadata such as
username and login URL, alongside encrypted files containing the
password or other secrets.

=head2 YAML metadata format

The YAML file contains a top-level object with keys for the non-secret
credentials whose values appear verbatim in the file.

There is a C<gpg_d> sub-object which contains the keys for secret
credentials. Each key's value is the name of an encrypted file
(relative to the YAML file) which contains just the bare secret.

There is one secret per file, so if a login needs multiple secrets
(e.g. for Oauth) then there will be multiple encryped files.
For example,

	# commentary explaining the purpose of this login
	---
	username: alice
	url: https://example.com/login
	gpg_d:
	  consumer_key: consumer_key.asc
	  consumer_secret: consumer_secret.asc
	  secret: secret.asc
	  token: token.asc

=head2 Reading a login

The C<read_login> subroutine loads the YAML file and the associated
secrets.

Each key in the C<gpg_d> sub-object has a filename as its value,
conventionally ending in C<.asc> to indicate a gpg ASCII-armored
encrypted file.

For each filename, C<read_login> will load a decrypted version without
a C<.asc> extension if that is present. Otherwise it decrypts the file
using C<gpg --use-agent --batch --quiet --decrypt>. In either case any
trailing newline is removed.

The key and decrypted contents are added to the top-level object.

=head2 Checking a login

Any trailing arguments to C<read_login> are a list of keys that muct
be present in the top-level object after adding the decrypted files.
If any are missing, C<read_login> will croak.

=head2 Login post-processing options

The last argument to C<read_login> can be a hash ref containing options.

=head3 basic

The only option defined so far is C<basic>. The value of the option is
an array ref containing username and password login field names. These
field names are included in the check list. The corresponding login
field values are used to create an HTTP Basic C<Authorization> header
value.

For example,

	my $login = read_login "login.yml", qw(url),
	    { basic => [qw[username password]] };
	my $r = LWP::UserAgent->new()->post($login->{url},
	    Authorization => $login->{authorization},
	    ...
	);

=head1 VERSION

  This is regpg-1.10 <https://dotat.at/prog/regpg/>

  Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>
  at Cambridge University Information Services
  You may do anything with this. It has no warranty.
  <https://creativecommons.org/publicdomain/zero/1.0/>

=head1 BUGS

This module is not installed properly

=head1 SEE ALSO

regpg(1), gpg(1), gpg-agent(1), YAML(3pm)

=cut
