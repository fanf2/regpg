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

sub check {
	my $self = shift;
	my $yml = $self->{filename};
	for (@_) {
		croak "$yml: missing field $_\n"
		    unless defined $self->{$_};
	}
	return $self;
}

sub auth_basic {
	my $self = shift;
	return $self->{authorization}
	    if $self->{authorization};
	$self->check(@_);
	my $auth = join ':', @$self{@_};
	return $self->{authorization} =
	    'Basic ' . encode_base64 $auth, '';
}

sub new {
	my $class = shift;
	my %opt = @_;
	my $yml = $opt{filename};
	my $dir = dirname $yml;
	my $self = YAML::LoadFile $yml;
	$self->{filename} = $yml;
	my $gpg_d = $self->{gpg_d} // {};
	for my $k (keys %$gpg_d) {
		my $asc = $dir.'/'.$gpg_d->{$k};
		my $clear = $asc =~ s{\.asc$}{}r;
		if (-f $clear) {
			$self->{$k} = read_file $clear;
		} else {
			$self->{$k} = capturex @gpg_d, $asc;
		}
		chomp $self->{$k};
	}
	bless $self, $class;
	for my $option (qw(auth_basic check)) {
		if (my $args = $opt{$option}) {
			$self->$option(@$args);
		}
	}
	return $self;
}

sub read_login {
	my $yml = shift;
	return ReGPG::Login->new(
		filename => $yml,
		check => [@_],
	    );
}

1;

__END__

=head1 NAME

ReGPG::Login - load partially-encrypted login credentials

=head1 SYNOPSIS

	use ReGPG::Login;

	# simple style
	my $login = read_login "login.yml",
		qw(username password url);

	# object-oriented style
	my $login = ReGPG::Login->new(
		filename => "login.yml",
		check => [qw(username password url)],
	);

=head1 DESCRIPTION

To avoid unnecessarily decrypting secrets, B<regpg> encourages you to
store nothing but a bare secret in each encrypted file. Information
about what is in the file is kept elsewhere in cleartext.

ReGPG::Login defines a conventional storage layout for login
credentials. Each login has a L<YAML> file containing metadata such as
username and login URL, alongside encrypted files containing the
password or other secrets.

=head2 YAML metadata format

The YAML file contains a top-level object with fields for the non-secret
credentials whose values appear verbatim in the file.

There is a C<gpg_d> sub-object which contains the fields for secret
credentials. Each fields's value is the name of an encrypted file
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

The C<ReGPG::Login> constructors load a YAML file and the associated
secrets.

Each field in the C<gpg_d> sub-object has a filename as its value,
conventionally ending in C<.asc> to indicate a gpg ASCII-armored
encrypted file.

For each filename, the constructor will load a decrypted version without
a C<.asc> extension if that is present. Otherwise it decrypts the file
using C<gpg --use-agent --batch --quiet --decrypt>. In either case any
trailing newline is removed.

The field with decrypted contents is added to the top-level login
object.

The YAML filename is also saved in a C<filename> field in the login
object.

=head1 METHODS

=over

=item ReGPG::Login->new(%opt)

Object-oriented constructor. The options in C<%opt> are:

=over

=item filename => "login.yml"

The YAML file to load. (required)

=item check => [@fields]

Shortcut for calling C<$login-E<gt>check(@fields)>

=item auth_basic => [@fields]

Shortcut for calling C<$login-E<gt>auth_basic(@fields)>

=back

=item $login->check(@fields)

Ensure the fields are present in the login. Croaks if any are missing.

=item $login->auth_basic(@fields)

The arguments are username and password login field names. The method
checks that the fields are present, then uses the corresponding login
field values to create an HTTP Basic C<Authorization> header value.
This is stored in the C<authorization> field of the login object, and
returned.

For example,

	my $login = ReGPG::Login->new(
		filename => "login.yml",
		check => [qw[ url ]],
		auth_basic => [qw[ username password ]],
	);
	my $r = LWP::UserAgent->new()->post($login->{url},
	    Authorization => $login->{authorization},
	    ...
	);

=back

=head1 SUBROUTINES

ReGPG::Login exports one subroutine.

=over

=item read_login $filename, @check

A simplified constructor. The @check list is optional optional.
This is equivalent to

	ReGPG::Login->new(
		filename => $filename,
		check => [@check],
	);

=back

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
