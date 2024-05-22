#!/usr/bin/perl
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename;
use File::Path;
use File::Temp qw(mktemp tempfile);
use Getopt::Std;
use MIME::Base64;
use POSIX;
use Term::ANSIColor;

sub usage {
	print STDERR <<'EOF';
regpg - safely store server secrets
usage:
	regpg help
	regpg check [options] <cryptfile.asc>...
keys:
	regpg lskeys [options] [cryptfile.asc]
	regpg addself [options]
	regpg addkey [options] <keyname>...
	regpg delkey [options] <keyname>...
	regpg exportkey [options] [keyname]...
	regpg importkey [options] [keyfile]...
secrets:
	regpg encrypt [options] [[clearfile] cryptfile.asc]
	regpg decrypt [options] [cryptfile.asc [clearfile]]
	regpg recrypt [options] <cryptfile.asc>...
helpers:
	regpg depipe [options] <cryptfile.asc> <fifo>
	regpg edit [options] <cryptfile.asc>
	regpg pbcopy [options] [cryptfile.asc]
	regpg pbpaste [options] [cryptfile.asc]
	regpg shred [options] <clearfile>...
generators:
	regpg dnssec [opts] <action> [flags] <dnskey>
	regpg gencrt [opts] <days> [<cakey> <cacrt>] <priv> <cnf> <crt>
	regpg gencsrcnf [options] [<certfile>|<hostname> [csr.cnf]]
	regpg gencsr [options] <private.asc> <csr.cnf> [csr]
	regpg gendnskey [options] <zone>
	regpg genkey [options] <algorithm> <private.asc> [ssh.pub]
	regpg genpwd [options] [cryptfile.asc]
	regpg genspkifp [options] [priv|crt|csr|host]
setup:
	regpg init [options] [hook]...
	regpg conv <command> [options] <args>...
options:
	-k <pubring.gpg>	recipient keyring
	-n			no changes (implies -v)
	-q			quiet mode
	-r			recrypt all files after keyring changes
	-v			verbose mode
Either or both file arguments to `encrypt` and `decrypt`
can be '-' meaning stdin or stdout. Omitted clearfile
arguments are equivalent to '-'.
EOF
	exit 1;
}

sub help {
	exec "perldoc -M Pod::Text::Overstrike -F $0";
}

my %opt;
my @gpg;
my @gpg_de;
my @gpg_en;
my $keydir;
my $keybase;

sub getargs {
	my %arg = @_;
	usage unless getopts '-hk:nqrv', \%opt;
	help if $opt{h};
	$opt{k} //= './pubring.gpg';
	$opt{v} = 1 if $opt{n};
	usage if @ARGV < $arg{min};
	usage if defined $arg{max} and @ARGV > $arg{max};
	die "regpg: $opt{k} not found\n"
	    unless -f $opt{k} or $arg{keymaker};
	$opt{k} = "./$opt{k}" unless $opt{k} =~ m{/};
	($keybase,$keydir) = fileparse $opt{k};
	my $regpghome = $ENV{REGPGHOME} ? $ENV{REGPGHOME} :
			$ENV{HOME} ? "$ENV{HOME}/.regpg" :
			die "regpg: \$HOME and \$REGPGHOME are unset\n";
	# let gpg report any problems
	mkdir $regpghome; chmod 0700, $regpghome;
	@gpg = (qw(gpg --no-greeting --keyid-format=long --trust-model=always
		   --homedir), $regpghome,
		qw(--no-default-keyring --keyring), $opt{k});
	@gpg_de = (qw(gpg --decrypt --quiet --batch --use-agent));
	@gpg_en = (@gpg, qw(--armor --force-mdc --encrypt));
	return;
}

sub stdio {
	my $stdio = (not defined $_[-1] or $_[-1] eq '-');
	return !wantarray ? $stdio : $stdio ? () : @_;
}

sub getout {
	return @ARGV == 0 ? ()
	     : @ARGV == 1 ? ('--output', @ARGV)
	     : die 'Internal error';
}

########################################################################
#
#  utilities
#

# save stdout/stderr once
open my $stdout, '>&STDOUT' or die "dup: $!\n";
open my $stderr, '>&STDERR' or die "dup: $!\n";

sub verbose {
	print STDERR "@_\n" if $opt{v};
	return;
}

sub vsystem {
	verbose "running @_";
	return 0 if $opt{n};
	return 0 if 0 == system @_;
	die "failed: @_\n";
}

sub vsystem_warn {
	eval { vsystem @_};
	return $? >> 8;
}

sub canexec {
	return scalar grep { -x "$_/@_" } split /:/, $ENV{PATH};
}

sub firstdir {
	return (grep { defined $_ and -d $_ } @_)[0];
}

sub pipeslurp {
	verbose "pipe from @_";
	return if $opt{n};
	open my $pipe, '-|', @_
	    or die "open pipe from $_[0]: $!\n";
	my @out = <$pipe>;
	unless (close $pipe) {
		die "read pipe from $_[0]: $!\n" if $!;
		die "pipe from $_[0] failed\n";
	}
	return @out if wantarray;
	return join '', @out;
}

sub safeslurp {
	delete local $opt{n};
	return pipeslurp @_;
}

sub pipeslurp_quiet {
	return pipeslurp @_ if $opt{v} or $opt{n};
	open STDERR, '>', '/dev/null' or die "open /dev/null: $!\n";
	my @out = pipeslurp @_;
	open STDERR, '>&', $stderr or die "dup: $!\n";
	return @out if wantarray;
	return join '', @out;
}

sub pipespew {
	my $data = shift;
	verbose "pipe to @_";
	return if $opt{n};
	open my $pipe, '|-', @_
	    or die "open pipe to $_[0]: $!\n";
	print $pipe $data;
	unless (close $pipe) {
		die "write pipe to $_[0]: $!\n" if $!;
		die "pipe to $_[0] failed\n";
	}
	return 0;
}

sub tempclose {
	my ($th,$tn,$fn) = @_;
	close $th
	    or die "write $tn: $!\n";
	chmod 0666 & ~umask, $tn
	    or die "chmod $tn: $!\n";
	rename $tn => $fn
	    or die "rename $tn => $fn: $!\n";
	return;
}

sub pipespewto {
	my $fn = shift;
	my $data = shift;
	verbose "will pipe out to $fn";
	return verbose "pipe to", @_
	    if $opt{n};
	mkpath dirname $fn;
	my ($th,$tn) = tempfile "$fn.XXXXXXXX";
	open STDOUT, '>&', $th or die "dup: $!\n";
	pipespew $data, @_;
	open STDOUT, '>&', $stdout or die "dup: $!\n";
	return tempclose $th, $tn, $fn;
}

sub spewto {
	my $fn = shift;
	verbose "write to $fn";
	return if $opt{n};
	mkpath dirname $fn;
	my ($th,$tn) = tempfile "$fn.XXXXXXXX";
	print $th @_;
	return tempclose $th, $tn, $fn;
}

sub spewtofifo {
	my $fifo = shift;
	verbose "mkfifo $fifo";
	if ($opt{n}) {
		verbose "write to $fifo";
		verbose "unlink $fifo";
		return;
	}
	unlink $fifo;
	mkfifo $fifo, 0600
	    or die "mkfifo $fifo: $!\n";
	my $pid = fork;
	die "regpg: fork: $!\n" unless defined $pid;
	return $pid if $pid > 0;
	open my $fh, '>', $fifo
	    or die "open $fifo: $!\n";
	verbose "write to $fifo";
	print $fh @_;
	close $fh or die "write $fifo: $!\n";
	verbose "unlink $fifo";
	unlink $fifo;
	verbose "regpg pid $$ done";
	exit 0;
}

sub copyfile {
	my $srcN = shift;
	my $dstN = shift;
	verbose "copy $srcN => $dstN";
	sysopen my $srcH, $srcN, O_RDONLY
	    or die "open < $srcN: $!\n";
	sysopen my $dstH, $dstN, O_WRONLY|O_CREAT|O_EXCL
	    or die "open > $dstN: $!\n";
	local $/ = undef;
	syswrite $dstH, <$srcH>;
	close $dstH or die "write $dstN: $!\n";
	return;
}

sub peekfile {
	my $fn = shift;
	return if not -f $fn;
	open my $fh, '<', $fn
	    or die "open $fn: $!\n";
	return scalar <$fh>;
}

sub random_bytes {
	my $len = shift;
	open my $fh, '<', '/dev/urandom'
	    or die "open /dev/urandom: $!\n";
	$len == sysread $fh, my $bytes, $len
	    or die "read /dev/urandom: $!\n";
	return $bytes;
}

sub random_password {
	return encode_base64 random_bytes 12;
}

sub random_serial {
	return -set_serial => "0x".unpack "H*", random_bytes 16;
}

########################################################################
#
#  gpg wrappers
#

# When initializing a public keyring, gpg-2.1 will create a "keybox"
# file which is incompatible with older versions of gpg. However, if
# it is working with an existing old-style keyring it will maintain
# compatibility. So, we use the following key to start the keyring,
# then remove it after adding the keys we wanted. This is a revoked
# expired signing-only key so I can't use it to subvert your secrets.
my $dummy_key = <<'DUMMY';
mQENBDpPyJsBCAC1kKuLLuRySgw2nx9lPPX9lHd2liYpqqxhS5uscubyP7qp11H+gms2Dr2zpcizpVp
vIlF8l44xMwVbO7+rVpG1wnrCf6WklbmLR6vscJOwmSVh2uNA7wiKpU6W9aZAIX9cVF6tMa0KDij8pW
H4GAS5GvZcjaf1qAH1+B4M3iqviX0oyypn/8WU59hnnnMdD9CIUBUOrGqFeN+ZwQUYFs6R9+lkzjDfC
F4xbBSM/+kd4WDfHE+0PXKfXdMh3JTONy9oz5FfIhDTzjFks5SuM/eXZmLbmORwYYN+LIHy3j12ErSO
nnnMtdWPheP1Z8BGuaaeSpEG6wAw8+1v+e/qTxsBABEBAAGJASgEIAECABIFAjpPyMgLHQBkdW1teSB
rZXkACgkQo/luLGExUxvY0wgAqUlFaqmMBXBcSSkEaM5UkcPOjcvy8anAub6Hj5zfzQc6Cfj8e9hR8Y
4S61RQ0GCfgeRJcIFCZpqQpk54J5OldcHMTmAGB9rYMoLxJtBfhUo8IYViRQlJduhz8m7YK7pkp666u
YD45q3NmRazIh30WMewAfw5FaakJXPoXglc8Q23m0YpiBOY4MVMDlqBV8JdjCXKYHWzIX5WXwJtDhiw
uRcOUi6QoCOQC/C2ysdS2MizrYRwY0KPRLtBVH/pm1XfcdW08kX/R0dqHX9rWz7qr6AmWLRbadOUwfV
FxROpMD4qMUXahRlaJdUcjM8IfJO/O84yfA20smkinl+3oWbZfLACAAO0JUR1bW15IEtleSA8ZHVtbX
lAdGhpcy1rZXktaXMuaW52YWxpZD6JAT4EEwECACgFAjpPyJsCGwMFCQABUYAGCwkIBwMCBhUIAgkKC
wQWAgMBAh4BAheAAAoJEKP5bixhMVMbMYgIAJFC/5SDw6l9QTUvHGDhgswq5q+SkjlXrpWJ9kVYQxx7
Bx9QFtCrfGtpHxDND+cJideX8CN4A+EdxYO8R+pQI4Q4nsOIjTBsNYYcmh7YMHTfS3F+/UTpbGWLcIm
SvIhiKHhwVFoFxrgW9IlaiEsW+NngB1dXQeR7xyeUV/MDQrxlBKcNw2hhSf8tPfIn/5djX/Z57cNRDz
Z9qAuajkk7ZZ/gE9ZCrBy0X5T5W0xdV15fGmsvCAWDR1oQyfvZEHIKhIAOHtlCrXAAamm0vyE5cWT8/
W1rVvJ5/AcDJkWHZOw/LaDrT98PXFnyhvY3JPI/XCUWAISA0xB6wjvImRZzOK+wAgAD
DUMMY
sub dummy_init {
	return 1 if -f $opt{k} and -s $opt{k};
	return spewto $opt{k}, decode_base64 $dummy_key;
}
sub dummy_fini {
	return vsystem @gpg, qw(--delete-key --batch --yes 0xA3F96E2C6131531B);
}

sub ring_keys {
	my @out = @_ ? (safeslurp @_)
	    : (safeslurp @gpg, qw(--list-keys --with-colons));
	# get the key ID of each encryption-capable key or subkey
	return map { m{^(?:[^:]*:){4}([^:]*):} }
	    grep { m{^(pub|sub|sec|ssb)(:[^:]*){10}:\w*e\w*:} } @out;
}

sub recipients {
	return map { ('--recipient' => $_) } ring_keys;
}

sub self_keys {
	return ring_keys
	    qw(gpg --list-secret-keys --with-colons), $ENV{USER};
}

sub clean_ids {
	return map { s{^\w+/}{}r } @_;
}

sub add_keys {
	# Export from the user's normal gpg setup (except when subverted by
	# init_ansible_gpg). We prefer to use gpg2 here, instead of the
	# default gpg, so that we can downgrade from keybox files to more
	# compatible old-style pubring files. export-minimal removes
	# extraneous signatures from the key, which avoids complaints about
	# unavailable public keys when it is imported.
	my $gpg = (canexec 'gpg2') ? 'gpg2' : 'gpg';
	my $keys = pipeslurp $gpg, qw(--export --armor
			--export-options export-minimal), @_;
	# Import to this local keyring
	my $skip = dummy_init;
	pipespew $keys, @gpg, '--import';
	dummy_fini unless $skip;
	return 0;
}

sub fingerprint {
	# search in both the regpg keyring and the user's keyring
	my @r;
	eval { @r = pipeslurp_quiet @gpg, '--fingerprint', @_; };
	return @r if @r;
	eval { @r = pipeslurp_quiet 'gpg', '--fingerprint', @_; };
	return @r if @r;
	return "no fingerprint for @_\n", "\n";
}

sub find_all {
	my @all = sort map { m{^([^\n]+)\n*$} }
	    safeslurp q(find . -type f |
		xargs grep -l '^-----BEGIN PGP MESSAGE-----$' || true);
	return @all;
}

sub recrypt_one {
	my $fn = shift;
	my @recipients = @_;
	my $cleartext = pipeslurp @gpg_de, $fn;
	return pipespewto $fn, $cleartext, @gpg_en, @recipients;
}

sub recrypt_some {
	my @recipients = recipients;
	recrypt_one $_, @recipients for @_;
	return 0;
}

sub maybe_recrypt_all {
	recrypt_some find_all if $opt{r};
	return 0;
}

# actually an openssl wrapper

sub certslurp {
	my $src = shift;
	my ($host,$port) = $src =~ m{^(.*):(\d+)$}
	    ? ($1,$2) : ($src,443);
	return safeslurp "openssl s_client ".
	    "-servername $host -connect $host:$port ".
	    "</dev/null 2>/dev/null | @_";
}

########################################################################
#
#  check
#

sub check_clear {
	my ($file,$dir,$ext) = fileparse @_;
	return () if @_ > 1 and not $ext;
	return grep { -f $_ }
	    "$dir$file", "$dir$file~", "$dir#$file#", glob "$dir.$file.sw?";
}

sub check_quiet {
	my $fn = shift;
	my @ring = @_;
	my $re = qr{^\S+\s+ENC_TO\s+(\S+)\s+.*\n};
	my @file = map { s{$re}{$1}r } grep { m{$re} }
	    pipeslurp @gpg, qw(--list-only --quiet --status-fd 1), $fn;
	# diff key lists
	my %ring; @ring{@ring} = (); delete @ring{@file};
	my %file; @file{@file} = (); delete @file{@ring};
	@ring = keys %ring;
	@file = keys %file;
	my @clear = check_clear $fn, qw(.asc .gpg);
	return ( ring => [ @ring ],
		 file => [ @file ],
		 diff => (!!@ring || !!@file),
		 clear => [ @clear ],
		 unsafe => (!!@clear) );
}

sub diff_del {
	return map { colored("-$_", "red") } @_;
}
sub diff_add {
	return map { colored("+$_", "green") } @_;
}
sub holy_crap {
	return colored " CLEARTEXT @_", "bright_white on_bright_red";
}

sub check_one {
	my $fn = shift;
	my %ck = check_quiet $fn, @_;
	return 0 if $opt{n};
	return 0 if $opt{q} and not ($ck{unsafe} || $ck{diff});
	print $fn,
	    $ck{unsafe} ? "\t" . holy_crap(@{ $ck{clear} }) : "",
	    $ck{diff} ? "\t" : "",
	    diff_del(@{ $ck{file} }),
	    diff_add(@{ $ck{ring} }),
	    "\n";
	return $ck{unsafe} || $ck{diff};
}

sub check_long {
	my $fn = shift;
	my %ck = check_quiet $fn, @_;
	return 0 if $opt{n};
	return 0 if $opt{q} and not ($ck{unsafe} || $ck{diff});
	print " checking: $fn\n";
	printf "%s\n", holy_crap $_ for @{ $ck{clear} };
	print diff_del fingerprint $_ for @{ $ck{file} };
	print diff_add fingerprint $_ for @{ $ck{ring} };
	return $ck{unsafe} || $ck{diff};
}

sub check_some {
	my @ring_keys = ring_keys;
	return check_long @_, @ring_keys if @_ == 1;
	my $r = 0;
	$r |= check_one $_, @ring_keys for @_;
	return $r;
}

sub shred_files {
	if (canexec 'shred') {
		vsystem 'shred', '-u', $_ for check_clear @_;
	} else {
		vsystem 'rm', '-f', check_clear @_;
	}
	return 0;
}

sub shred_some {
	$opt{v} = 1 unless $opt{q};
	if (@ARGV) {
		shred_files $_ for @ARGV;
	} else {
		shred_files $_, qw(.asc .gpg) for @_;
	}
	return 0;
}

########################################################################
#
#  dnssec wrappers
#

sub dnssec_key {
	return $_[-1] =~ s{(\.[0-9a-z.]*)?\s*$}{}r;
}

sub dnssec_encrypt {
	my $key = shift;
	my $oldhash = peekfile "$key.private.sha256";
	my $newhash = safeslurp qw(openssl dgst -sha256), "$key.private";
	$newhash =~ s{^.* }{};
	return 0 if $oldhash and $oldhash eq $newhash;
	# overwrite without prompting
	spewto "$key.private.asc", scalar pipeslurp
	    @gpg_en, recipients, qw(--output -), "$key.private";
	spewto "$key.private.sha256", $newhash;
	return 0;
}

sub dnssec_shred {
	dnssec_encrypt my $key = shift;
	return shred_files "$key.private.asc", '.asc';
}

sub dnssec_keygen {
	print my $key = pipeslurp_quiet 'dnssec-keygen', @ARGV;
	return dnssec_shred dnssec_key $key;
}

sub dnssec_recrypt {
	return dnssec_encrypt dnssec_key @ARGV;
}

sub dnssec_settime {
	my $key = dnssec_key @ARGV;
	my $inclear = -f "$key.private";
	my $umask = umask 0077;
	spewto "$key.private", pipeslurp @gpg_de, "$key.private.asc"
	    unless $inclear;
	umask $umask;
	my $status = vsystem_warn 'dnssec-settime', @ARGV;
	$inclear ? dnssec_encrypt $key : dnssec_shred $key;
	return $status;
}

########################################################################
#
#  init
#

my $ansible_action = INSERT_HERE 'ansible/action.py';
my $ansible_filter = INSERT_HERE 'ansible/filter.py';
my $gpg_preload    = INSERT_HERE 'ansible/gpg-preload.yml';
my $vault_script   = INSERT_HERE 'ansible/vault-open.sh';

sub ansible_cfg {
	my ($sect,$opt,$val) = @_;
	my ($fn,$fh,$c) = ("${keydir}ansible.cfg");
	local $/ = undef;
	$val = "$1:$val" if open $fh, '<', $fn and
	    $c = <$fh> and $c =~ m{^\s*$opt\s*=\s*(.*)$}m;
	return vsystem qw(ansible localhost -c local -m ini_file -a),
	    "section=$sect option=$opt value=$val ".
	    "dest=${keydir}ansible.cfg";
}

sub init_preload {
	my $asc = "${keydir}gpg-preload.asc";
	my $yml = "${keydir}gpg-preload.yml";
	pipespewto $asc, 'True', @gpg_en, recipients
	    unless -f $asc;
	return spewto $yml, $gpg_preload;
}

sub init_plugin {
	my ($type,$file) = @_;
	spewto "${keydir}plugins/$type/gpg_d.py", $file;
	return ansible_cfg 'defaults', "${type}_plugins", "plugins/${type}";
}

sub init_ansible {
	init_preload;
	# dummy module to make the action plugin work
	spewto "${keydir}library/gpg_d.py", '';
	init_plugin 'action', $ansible_action;
	init_plugin 'filter', $ansible_filter;
	return;
}

sub init_ansible_vault {
	my $vault_pass = "${keydir}vault.pwd.asc";
	my $vault_open = "${keydir}vault.open";
	pipespewto $vault_pass, random_password, @gpg_en, recipients
	    unless -f $vault_pass;
	spewto $vault_open, $vault_script;
	chmod 0777 & ~umask, $vault_open;
	return ansible_cfg qw(defaults vault_password_file vault.open);
}

sub git_diff_attr {
	my ($file,$mode) = @_;
	my $a = safeslurp qw(git check-attr diff), "$keydir$file";
	if ($a eq "$keydir$file: diff: unspecified\n") {
		my $gitattr = "$keydir.gitattributes";
		verbose "append to $gitattr";
		unless ($opt{n}) {
			open my $fh, '>>', $gitattr
			    or die "open $gitattr: $!\n";
			print $fh "$file diff=$mode\n";
			close $fh
			    or die "write $gitattr: $!\n";
		}
	}
	return;
}

sub init_git {
	git_diff_attr $keybase, 'gpgkeys';
	git_diff_attr '*.asc', 'gpgrcpt';
	vsystem qw(git config diff.gpgkeys.textconv), 'regpg ls -k';
	vsystem qw(git config diff.gpgrcpt.textconv),
	    sprintf "regpg ls -k %s", abs_path $opt{k};
	return;
}

sub init_keys {
	return verbose "done init -k $opt{k}" if -f $opt{k};
	return add_keys self_keys;
}

########################################################################
#
#  conversion
#

sub conv_ansible_gpg {
	$opt{v} = 1 unless $opt{q};
	getargs keymaker => 1, min => 0, max => 0;
	my $old_scripts = "${keydir}ansible-gpg";
	return verbose "$old_scripts not found" unless -d $old_scripts;
	my $old_dir = "${keydir}.ansible-gpg";
	# subvert add_keys to get keys from a file rather than a list of IDs
	add_keys qw(--no-default-keyring --keyring), "$old_dir/pubring.gpg";
	copyfile "$old_dir/vault_passphrase.gpg" => "${keydir}vault.pwd.asc";
	init_ansible_vault;
	rmtree $old_scripts, $opt{v}, 1;
	rmtree $old_dir, $opt{v}, 1;
	return 0;
}

sub conv_ansible_vault {
	getargs min => 0, max => 2;
	if (@ARGV == 0) {
		print "regpg conv ansible-vault candidate files:\n";
		print safeslurp q(find . -type f |
			xargs grep -l '[$]ANSIBLE_VAULT;' | sort);
		return 0;
	}
	my $version = pipeslurp qw(ansible-vault --version);
	my $cleartext;
	if ($version =~ m{ansible-vault 2\.4\.0\.}) {
		# this is likely to crash due to a bug in ansible 2.4.0
		$cleartext = pipeslurp
		    qw(ansible-vault decrypt --output /dev/stdout), shift @ARGV;
	} else {
		# `ansible-vault decrypt --output -` is noisy on stderr
		$cleartext = pipeslurp_quiet
		    qw(ansible-vault decrypt --output -), shift @ARGV;
	}
	return pipespew $cleartext, @gpg_en, recipients, getout;
}

sub conv_stgza {
	getargs min => 0, max => 2;
	# like @gpg_de but passphrase on stdin instead of via agent
	my @gpg_dp = qw(gpg --decrypt --quiet --batch --passphrase-fd 0);
	# surprisingly this is better as a long shell pipeline
	my $decrypt = "@gpg_de secrets.pwd.asc | @gpg_dp secrets.tar.gz.asc";
	if (@ARGV) {
		my @tar = (qw(tar Oxzf -), shift @ARGV);
		my @encrypt = (@gpg_en, recipients, getout);
		return vsystem "$decrypt | @tar | @encrypt";
	} else {
		my @tar = $opt{v} ? qw(tar tvzf -) : qw(tar tzf -);
		return vsystem "$decrypt | @tar | sort";
	}
}

########################################################################
#
#  subcommands
#

sub addkey {
	getargs keymaker => 1, min => 1;
	add_keys clean_ids @ARGV;
	return maybe_recrypt_all;
}

sub addself {
	getargs keymaker => 1, min => 0, max => 0;
	return add_keys self_keys;
}

sub delkey {
	getargs keymaker => 1, min => 1;
	# --expert persuades gpg to delete the key even if the secret
	# key is available, when deleting one of the user's own keys
	vsystem @gpg, '--expert', '--delete-key', clean_ids @ARGV;
	return maybe_recrypt_all;
}

sub exportkey {
	getargs min => 0;
	return vsystem @gpg, qw(--export --armor), clean_ids @ARGV;
}

sub importkey {
	getargs keymaker => 1, min => 0;
	my $skip = dummy_init;
	my $status = vsystem_warn @gpg, '--import', @ARGV;
	dummy_fini unless $skip;
	return $status if $status;
	return maybe_recrypt_all;
}

sub lskeys {
	getargs min => 0, max => 1;
	return vsystem @gpg, '--fingerprint'
	    if @ARGV == 0;
	my $out = pipeslurp @gpg,
	    qw(--quiet --batch --list-packets --list-only), @ARGV;
	print fingerprint $_ for $out =~ m{\s+keyid\s+(\S+)\s+}g;
	return 0;
}

#----------------------------------------------------------------------#

sub for_files {
	my ($zap,$sub) = @_;
	getargs min => 0;
	if (@ARGV and $opt{r}) {
		die "regpg: either -r or arguments, not both\n";
	} elsif (@ARGV) {
		return $sub->(@ARGV);
	} elsif ($opt{r} or $zap eq 'zap') {
		return $sub->(find_all);
	} else {
		die "regpg: use -r to really $zap all files\n";
	}
}

sub check {
	return for_files zap => \&check_some;
}

sub shred {
	return for_files shred => \&shred_some;
}

sub squeegee {
	$opt{r} = 1;
	return shred;
}

sub recrypt {
	return for_files recrypt => \&recrypt_some;
}

sub encrypt {
	getargs min => 0, max => 2;
	my @in = (@ARGV > 1) ? (shift @ARGV) : ();
	return vsystem @gpg_en, recipients, getout, @in;
}

sub decrypt {
	getargs min => 0, max => 2;
	my @in = (@ARGV > 0) ? (shift @ARGV) : ();
	if (stdio @ARGV) {
		return vsystem @gpg_de, @in;
	} else {
		umask 0077;
		spewto @ARGV, pipeslurp @gpg_de, @in;
		return 0;
	}
}

#----------------------------------------------------------------------#

sub depipe {
	getargs min => 2, max => 2;
	my ($secret,$fifo) = @ARGV;
	my $cleartext = pipeslurp @gpg_de, $secret;
	my $pid = spewtofifo $fifo, $cleartext;
	print "regpg pid $pid waiting on $fifo\n" if $pid;
	return 0;
}

my @pbcopy = qw(pbcopy);
my @pbpaste = qw(pbpaste);

sub xclip {
	if (canexec 'xclip') {
		@pbcopy = qw(xclip -i);
		@pbpaste = qw(xclip -o);
	}
	return getargs min => 0, max => 1;
}

sub pbcopy {
	xclip;
	my $cleartext = pipeslurp @gpg_de, stdio @ARGV;
	pipespew $cleartext, @pbcopy;
	unless ($opt{n}) {
		print STDERR "Press ^C when you have used the secret...";
		do { local $SIG{INT} = sub {}; pause; };
		print STDERR "\n";
	}
	return pipespew '', @pbcopy;
}

sub pbpaste {
	xclip;
	my $cleartext = pipeslurp @pbpaste;
	die 'regpg: clipboard is empty' if $cleartext eq '';
	pipespew $cleartext, @gpg_en, recipients, getout;
	return pipespew '', @pbcopy;
}

sub edit {
	getargs min => 1, max => 1;
	my ($template,$dir) = fileparse "@ARGV.XXXXXXXX";
	$dir = firstdir "/run/user/$<", "/dev/shm", $ENV{TMPDIR}, $dir, ".";
	my $tmp = mktemp "$dir/$template";
	vsystem @gpg_de, '--output', $tmp, @ARGV if -f "@ARGV";
	my $status = (vsystem_warn $ENV{EDITOR}, $tmp) ||
	    (vsystem_warn @gpg_en, recipients, '--output', @ARGV, $tmp);
	shred_files $tmp;
	return $status;
}

#----------------------------------------------------------------------#

sub dnssec {
	getargs min => 2;
	my $action = shift @ARGV;
	my @action = qw(keygen recrypt settime);
	if (grep { $action eq $_ } @action) {
		return $::{"dnssec_$action"}();
	} else {
		die "regpg dnssec action must be one of: @action\n";
	}
}

sub gendnskey {
	getargs min => 1, max => 1;
	print my @found = map s{\.key$}{\n}r, glob "K@ARGV.+013+*.key";
	return 0 if @found;
	unshift @ARGV, qw(-L 86400 -a 13);
	my $exit = dnssec_keygen;
	unshift @ARGV, qw(-f KSK -Psync now);
	return $exit || dnssec_keygen;
}

sub gencsrcnf {
	# not really a keymaker - we just don't use the keyring
	getargs keymaker => 1, min => 0, max => 2;
	my ($src,$cnf,$crt) = @ARGV;
	my @openssl_x509 = qw(openssl x509 -noout -text -nameopt multiline);
	if (stdio $src or -f $src) {
		$crt = safeslurp @openssl_x509, stdio -in => $src;
	} else {
		$crt = certslurp $src, @openssl_x509;
	}
	my $dns = qr{DNS:([A-Za-z0-9*.-]+)[,\s]+};
	$crt =~ m{\n(\ +)Subject:\n((?:\1\ +.*\n)+)\1[^ ](?:.*\n)+
		  [ ]+X509v3[ ]Subject[ ]Alternative[ ]Name:\s+($dns+)}x
	    or die "regpg: could not find certificate subject\n";
	my $subject = $2;
	my @san = $3 =~ m{$dns}g;
	$subject =~ s{^\s+}{}mg;
	my $san = join '', map { "DNS.$_ = $san[$_]\n" } keys @san;
	my $out = <<"CONF";
[ req ]
prompt = no
distinguished_name = distinguished_name
req_extensions = extensions
x509_extensions = extensions

[ extensions ]
subjectAltName = \@subjectAltName

[ distinguished_name ]
$subject
[ subjectAltName ]
$san
CONF
	if (stdio $cnf) {
		print $out;
	} else {
		spewto $cnf, $out;
	}
	return 0;
}

sub getkey {
	my $priv = shift;
	if (-f $priv) {
		return pipeslurp @gpg_de, $priv;
	} else {
		my $key = pipeslurp qw(openssl genrsa 2048);
		pipespewto $priv, $key, @gpg_en, recipients;
		return $key;
	}
}

sub gencrt {
	getargs min => 4, max => 6;
	my ($days,$cakey,$cacrt,$priv,$cnf,$self,$signed);
	if (@ARGV == 6) {
		($days,$cakey,$cacrt,$priv,$cnf,$signed) = @ARGV;
		$self = mktemp "$signed.XXXXXXXX";
		$cakey = pipeslurp @gpg_de, $cakey;
		$priv = getkey $priv;
	} else {
		($days,$priv,$cnf,$self) = @ARGV;
		$priv = getkey $priv;
	}
	# Generate a self-signed certificate, then re-sign if necessary.
	# If we generate a CSR then `openssl x509 -req` drops the
	# extensions when making a signed certificate. `openssl ca`
	# requires too much faff with config files for our purposes.
	pipespew $priv, qw(openssl req -new -x509 -sha256 -key /dev/stdin),
	    random_serial, -days => $days, -config => $cnf, -out => $self;
	if (@ARGV == 6) {
		# The authorityKeyIdentifier will get the wrong value if
		# it is added the first time round. See x509v3_config(5ssl)
		my $ext = mktemp "$cnf.XXXXXXXX";
		spewto $ext,
		     "subjectKeyIdentifier = hash\n",
		     "authorityKeyIdentifier = keyid:always, issuer:always\n";
		pipespew $cakey, qw(openssl x509 -sha256 -CAkey /dev/stdin),
		    random_serial, -days => $days, -CA => $cacrt,
		    -extfile => $ext, -in => $self, -out => $signed;
		unlink $self, $ext;
	}
	vsystem qw(openssl x509 -text -in), $ARGV[-1] if $opt{v};
	return 0;
}

sub gencsr {
	getargs min => 2, max => 3;
	my ($priv,$cnf,$req) = @ARGV;
	my $key = getkey $priv;
	my @opt = (-config => $cnf);
	push @opt, stdio -out => $req;
	pipespew $key, qw(openssl req -new -sha256 -key /dev/stdin), @opt;
	vsystem qw(openssl req -text -in), $req
	    if $opt{v} and $opt[-2] eq '-out';
	return 0;
}

sub genssh {
	my ($pub,$key) = @_;
	# Ideally we want to use a pipe, but ssh-keygen does not like
	# the loose permission on /dev/stdin on BSDish systems, and
	# puttygen seems to stop reading from a pipe before EOF; the
	# disadvantage of the fifo is the risk of losing an open race.
	my @stat = POSIX::fstat((POSIX::pipe)[0]);
	if ($stat[2] & 0077 && $stat[4] == $<) {
		my $fifo = mktemp "$pub.XXXXXXXX";
		spewtofifo $fifo, $key;
		open STDOUT, '>', $pub
		    or die "regpg: open $pub: $!\n";
		exec qw(ssh-keygen -y -f), $fifo;
	} else {
		pipespewto $pub, $key, qw(ssh-keygen -y -f /dev/stdin);
		return 0;
	}
}

sub genkey {
	getargs min => 2, max => 3;
	my ($algo,$priv,$pub) = @ARGV;
	my %genkey = (
	    dsa   => [qw(openssl dsaparam -genkey -noout 1024)],
	    ecdsa => [qw(openssl ecparam  -genkey -noout -name prime256v1)],
	    ec256 => [qw(openssl ecparam  -genkey -noout -name prime256v1)],
	    ec384 => [qw(openssl ecparam  -genkey -noout -name secp384r1)],
	    ec521 => [qw(openssl ecparam  -genkey -noout -name secp521r1)],
	    rsa   => [qw(openssl genrsa 2048)],
	    ed25519 => [qw(puttygen -O private-openssh -t ed25519
   --random-device /dev/urandom --new-passphrase /dev/null -o /dev/stdout)]
	);
	my @genkey = sort keys %genkey;
	die "regpg genkey: algorithm $algo is not in @genkey\n",
	    unless exists $genkey{$algo};
	return genssh $pub, scalar pipeslurp @gpg_de, $priv
	    if -f $priv and defined $pub;
	my $key = pipeslurp @{ $genkey{$algo} };
	pipespewto $priv, $key, @gpg_en, recipients;
	genssh $pub, $key if $pub;
	return 0;
}

sub cryptpwd {
	my $pwd = shift; chomp $pwd;
	my $salt = random_password;
	my $crypt = crypt $pwd, '$5$'.$salt.'$';
	die "crypt(3) does not support SHA256\n"
	    unless $crypt =~ m{^\$5\$};
	return printf "%s\n", $crypt
}

sub genpwd {
	getargs min => 0, max => 1;
	if ($ARGV[0] and -f $ARGV[0]) {
		cryptpwd pipeslurp @gpg_de, @ARGV;
	} else {
		my $pwd = random_password;
		pipespew $pwd, @gpg_en, recipients, getout;
		cryptpwd $pwd unless $opt{q};
	}
	return 0;
}

sub genspkifp {
	# not really a keymaker - we just don't use the keyring
	getargs keymaker => 1, min => 1, max => 1;
	my ($fn) = @ARGV;
	my $fl = peekfile $fn;
	my $pub;
	if (not defined $fl) {
		print STDERR certslurp $fn, qw(openssl x509 -subject -noout)
		    unless $opt{q};
		$pub = certslurp $fn, qw(openssl x509 -pubkey -noout);
	} elsif ($fl eq "-----BEGIN PGP MESSAGE-----\n") {
		$pub = safeslurp "@gpg_de $fn | openssl pkey -pubout";
	} elsif ($fl eq "-----BEGIN RSA PRIVATE KEY-----\n") {
		$pub = safeslurp qw(openssl pkey -pubout -in), $fn;
	} elsif ($fl =~ m{^-----BEGIN CERTIFICATE( REQUEST)?-----\s*$}) {
		my @cmd = ('openssl', defined($1) ? 'req' : 'x509');
		print STDERR pipeslurp @cmd, qw(-subject -noout -in), $fn
		    unless $opt{q};
		$pub = safeslurp @cmd, qw(-pubkey -noout -in), $fn;
	} else {
		die "unknown file format: $fn\n";
	}
	return pipespew $pub, 'openssl pkey -pubin -outform der |
	openssl dgst -sha256 -binary |
	openssl base64';
}

#----------------------------------------------------------------------#

sub init {
	getargs keymaker => 1, min => 0;
	$opt{v} = 1 unless $opt{q};
	# Note: 'keys' is described but not named in the manual
	# because it is automatically added to the hook list
	my %init = (
		'keys' => \&init_keys,
		'git' => \&init_git,
		'ansible' => \&init_ansible,
		'ansible-vault' => \&init_ansible_vault,
	    );
	my @init = sort keys %init;
	for my $init ('keys', @ARGV) {
		die "regpg init: hook $init is not in @init\n",
		    unless exists $init{$init};
		$init{$init}->();
	}
	return 0;
}

sub conv {
	getargs keymaker => 1, min => 0;
	my %conv = (
		'ansible-gpg' => \&conv_ansible_gpg,
		'ansible-vault' => \&conv_ansible_vault,
		'stgza' => \&conv_stgza,
	    );
	my @conv = sort keys %conv;
	my $conv = shift @ARGV;
	die "regpg conv: choose one of @conv\n",
	    unless defined $conv
	    and exists $conv{$conv};
	return $conv{$conv}->();
}

$::{'--help'} = $::{help};
$::{ck}       = $::{check};
$::{ls}       = $::{lskeys};
$::{add}      = $::{addkey};
$::{del}      = $::{delkey};
$::{export}   = $::{exportkey};
$::{import}   = $::{importkey};
$::{en}       = $::{encrypt};
$::{re}       = $::{recrypt};
$::{gencsrconf} = $::{gencsrcnf};

usage unless @ARGV;
my $subcommand = shift;
if (grep { $subcommand eq $_ }
	qw(add addkey addself check ck conv
	   decrypt depipe del delkey dnssec
	   edit en encrypt export exportkey
	   gencrt gencsrcnf gencsrconf gencsr
	   gendnskey genkey genpwd genspkifp
	   --help help import importkey init ls lskeys
	   pbcopy pbpaste re recrypt shred squeegee)) {
	exit $::{$subcommand}();
} else {
	usage;
}

__END__

=head1 NAME

regpg - safely store server secrets

=head1 SYNOPSIS

B<regpg> B<help>

B<regpg> B<check> [I<options>] <I<cryptfile.asc>>...

- keys:

B<regpg> B<lskeys> [I<options>] [I<cryptfile.asc>]

B<regpg> B<addself> [I<options>]

B<regpg> B<addkey> [I<options>] <I<keyname>>...

B<regpg> B<delkey> [I<options>] <I<keyname>>...

B<regpg> B<exportkey> [I<options>] [I<keyname>]...

B<regpg> B<importkey> [I<options>] [I<keyfile>]...

- secrets:

B<regpg> B<encrypt> [I<options>] [[I<clearfile>] I<cryptfile.asc>]

B<regpg> B<decrypt> [I<options>] [I<cryptfile.asc> [I<clearfile>]]

B<regpg> B<recrypt> [I<options>] <I<cryptfile.asc>>...

- helpers:

B<regpg> B<depipe> I<cryptfile.asc> I<fifo>

B<regpg> B<edit> [I<options>] <I<cryptfile.asc>>

B<regpg> B<pbcopy> [I<options>] [I<cryptfile.asc>]

B<regpg> B<pbpaste> [I<options>] [I<cryptfile.asc>]

B<regpg> B<shred> [I<options>] <I<clearfile>>...

- generators:

B<regpg> B<dnssec> [I<opts>] <I<action>> [I<flags>] <I<dnskey>>

B<regpg> B<gencrt> [I<opts>] <I<days>> [<I<cakey>> <I<cacrt>>] <I<priv>> <I<cnf>> <I<crt>>

B<regpg> B<gencsrcnf> [I<options>] [<I<certfile>>|<I<hostname>> [I<csr.cnf>]]

B<regpg> B<gencsr> [I<options>] <I<private.asc>> <I<csr.cnf>> [I<csr>]

B<regpg> B<genkey> [I<options>] <I<algorithm>> <I<private.asc>> [I<ssh.pub>]

B<regpg> B<genpwd> [I<options>] [I<cryptfile.asc>]

B<regpg> B<genspkifp> [I<options>] [I<priv>|I<crt>|I<csr>|I<host>]

- setup:

B<regpg> B<init> [I<options>] [I<hook>]...

B<regpg> B<conv> <I<command>> [I<options>] <I<args>>...

=head1 DESCRIPTION

The B<regpg> program is a thin wrapper around B<gpg> for looking after
secrets that need to be stored encrypted in a version control system
and deployed to servers with a configuration management system.

At the root of your project you have a F<pubring.gpg> file which lists
the set of people who can decrypt the secrets. Elsewhere in that
directory and its subdirectories you have encrypted F<secret.asc>
files. (The F<.asc> extension is short for ASCII-armored PGP message.)
You can use a different layout, by B<regpg> works best if you follow
the usual conventions.

You use the B<regpg> B<*keys> subcommands to maintain F<pubring.gpg>.
By default, B<regpg> expects to find F<pubring.gpg> in the current
working directory.

You use the B<regpg> B<*crypt> subcommands to manage encrypted files.
The "recipients" who can decrypt the files are all the keys in the
public key ring. Decryption is non-interactive, using B<gpg-agent>.

You use the B<regpg> B<gen*> subcommands to create encrypted secrets
to be used by other software.

The B<regpg> B<check> subcommand verifies that the encrypted files and
public keyring are consistent with each other.

The B<regpg> B<init> subcommand helps you to hook up B<regpg> with
Ansible and B<git>.

=head1 OPTIONS

The B<regpg> subcommands all take the same options.

=over

=item B<-k> I<pubring.gpg>

Specify the name of the public key ring file,
to override the default F<./pubring.gpg>.

=item B<-n>

Do nothing, but show what would have been done.

=item B<-q>

Quiet mode.
This affects the B<check>, B<conv>, B<genpwd>, B<genspkifp>, B<init>,
and B<shred> subcommands.

=item B<-r>

For the B<addkey>, B<delkey>, B<import>, and B<recrypt> subcommands,
recrypt all files found by the B<check> subcommand. For the B<shred>
subcommand, destroy all cleartext files found by the B<check> subcommand.

=item B<-v>

Verbose mode. This mainly prints the B<gpg> commands.

=back

=head1 SUBCOMMANDS

Several subcommands have abbreviated synonyms.

=over

=item B<regpg> B<help>

Display this documentation.

=item B<regpg> B<check> <I<cryptfile.asc>>...

=item B<regpg> B<ck> <I<cryptfile.asc>>...

Check I<cryptfile>s for consistency.

If no arguments are given, B<check>
recursively finds and lists all encrypted files.
These are the files that are recryped by the B<-r> option.

With the B<-q> option, files are only listed if
B<regpg> B<check> finds a problem with them.

If a I<cryptfile> has a C<.asc> or a C<.gpg> extension,
and an adjacent file exists without the extension,
it is called out as a potential cleartext file.
You can use C<regpg shred> to destroy cleartext files.

Keys that can decrypt a I<cryptfile>
but are not present in the B<-k> I<pubring.gpg>
are listed in red with C<-> markers.

Keys are present in the B<-k> I<pubring.gpg>
but cannot decrypt a I<cryptfile>
are listed in green with C<+> markers.

If one argument is given then key fingerprints are printed in full,
otherwise the diffs just list bare key IDs.

These differences can be resolved by the B<recrypt> subcommand.

=back

=head2 Key management

The following subcommands manage the contents of the publig key ring
file, by default F<pubring.gpg>.

=over

=item B<regpg> B<lskeys> [I<cryptfile.asc>]

=item B<regpg> B<ls> [I<cryptfile.asc>]

With no argument, list the keys in the B<regpg> keyring.

With a I<cryptfile.asc> argument, list the keys that are able to
decrypt the file.

=item B<regpg> B<addself>

Add your own key(s) to the B<regpg> keyring.

A key is "yours" if you have its secret key and it has an
identity matching your login name.

It is a good idea to generate a new B<gpg> key specifically for use
with B<regpg>. If you have multiple keys, B<addself> will add them
all. You can then use B<delkey> to remove the unwanted ones.

If none of your keys were previously on the B<regpg> keyring then you
will not be able to B<recrypt> the secrets. You will need to get one
of the existing keyholders to do that for you.

=item B<regpg> B<addkey> <I<keyname>>...

=item B<regpg> B<add> <I<keyname>>...

Export keys from your default B<gpg> public keyring,
and import them into the B<regpg> keyring.

A I<keyname> can be a key fingerprint or ID
or a person's email address.

If the B<-r> option is given,
all files are recrypted after the key(s) are added.

=item B<regpg> B<delkey> <I<keyname>>...

=item B<regpg> B<del> <I<keyname>>...

Delete keys from the B<regpg> keyring.

A I<keyname> can be a key fingerprint or ID
or a person's email address.

If the B<-r> option is given,
all files are recrypted after the key(s) are deleted.

=item B<regpg> B<exportkey> [I<keyname>]...

=item B<regpg> B<export> [I<keyname>]...

Export keys from the B<regpg> keyring.

If no I<keyname>s are given then all keys are exported.

=item B<regpg> B<importkey> [I<keyfile>]...

=item B<regpg> B<import> [I<keyfile>]...

Import keys into the B<regpg> keyring that have previously been
exported by B<gpg>.

If no I<keyfile>s are given then keys are read from stdin.

If the B<-r> option is given,
all files are recrypted after the key(s) are added.

=back

=head2 Secret management

The following are the core secret encryption and decryption
subcommands.

=over

=item B<regpg> B<encrypt> [[I<clearfile>] I<cryptfile.asc>]

=item B<regpg> B<en> [[I<clearfile>] [I<cryptfile.asc>]

Encrypt I<clearfile> to produce I<cryptfile.asc>.
The encryption recipients are all the keys in the public key ring.

If I<clearfile> is C<-> or there is one argument then the cleartext is
read from stdin.

If I<cryptfile> is C<-> or there are no arguments then the ciphertext
is written to stdout.

Note: conventionally the I<cryptfile> has a F<.asc> extention, short
for ASCII-armored PGP message.

=item B<regpg> B<decrypt> [I<cryptfile.asc> [I<clearfile>]]

Decrypt I<cryptfile.asc> to produce I<clearfile>.
The output file is created with mode 0600,
i.e. the permissions deny access to group and other users.
You must be running B<gpg-agent> which will be used
to gain access to your private key for decryption.

If I<cryptfile> is C<-> or there are no arguments then the ciphertext
is read from stdin.

If I<clearfile> is C<-> or there is one argument then the cleartext
is written to stdout.

Note: You can also just use C<gpg --decrypt>. The C<regpg decrypt>
subcommand requires the GPG agent so it has consistent behaviour in
bulk operations such as C<regpg recrypt -r>.

=item B<regpg> B<recrypt> <I<cryptfile.asc>>...

=item B<regpg> B<re> <I<cryptfile.asc>>...

Decrypt and re-encrypt I<cryptfile>s.
If the B<-r> option is given,
all files are re-encrypted.

You should use this after using B<addkey> or B<delkey>,
if you did not pass the B<-r> option.

=back

=head2 Higher-level helpers

The following subcommands provide more convenient access to secrets,
at the cost of some safety.

=over

=item B<regpg> B<depipe> I<cryptfile.asc> I<fifo>

Create a temporary named pipe called I<fifo>. The I<cryptfile> is
decrypted and written to the I<fifo> in the background. In the
foreground you can start a program which reads the cleartext from the
I<fifo>. When it has finished, the I<fifo> is removed.

This subcommand is for use with programs that can't read from stdin
but can read from a named pipe.

=item B<regpg> B<edit> <I<cryptfile.asc>>

Decrypt I<cryptfile.asc> (if it exists) and run C<$EDITOR> on the
cleartext file. The cleartext is placed on a C<tmpfs> in RAM when
possible. When you have finished editing, the file is re-encrypted and
the cleartext is shredded.

=item B<regpg> B<pbcopy> [I<cryptfile.asc>]

Decrypt I<cryptfile.asc> and copy the cleartext to the clipboard. When
you have used the secret, press ^C and B<regpg> will clear the clipboard.

This uses B<pbcopy> on macOS or B<xclip> on X11.

If I<cryptfile> is missing or C<-> then it is read from stdin.

=item B<regpg> B<pbpaste> [I<cryptfile.asc>]

Encrypt the contents of the clipboard and paste the ciphertext into
I<cryptfile.asc>. The clipboard is cleared afterwards.

This uses B<pbpaste> on macOS or B<xclip> on X11.

If I<cryptfile> is missing or C<-> then it is written to stdout.

=item B<regpg> B<shred> <I<clearfile>>...

Destroy cleartext files and any related editor backup files.
If C<shred(1)> is not available, the files are just deleted.

If the B<-r> option is given,
all cleartext files found by C<regpg check> are shredded.

Note: You might want to test B<shred> with the B<-n> option first!

=item B<regpg> B<squeegee>

An alias for C<regpg shred -r>, an effective cleaner that is
particularly handy for users of glass TTYs.

=back

=head2 Secret generators

The following subcommands combine the core B<regpg> B<encrypt> /
B<decrypt> subcommands with secret handling tools from BIND,
OpenSSL, OpenSSH, etc.

=over

=item B<regpg> B<dnssec> [I<opts>] B<keygen> [I<flags>] <I<name>>

Create a DNSSEC key using BIND's B<dnssec-keygen> utility, encrypt
private key as per B<regpg> B<dnssec> B<recrypt>, then shred it.

The I<opts> are B<regpg> options. The I<flags> and I<name> are passed
to B<dnssec-keygen>.

Use the B<regpg> B<gendnskey> wrapper to generate keys for a zone with
the recommended setup.

=item B<regpg> B<dnssec> [I<opts>] B<recrypt> <I<dnskey>>

Re-encrypt a DNSSEC private key if necessary. The I<dnskey> can name
any of the four files that this subcommand works with:

=over

=item C<K*.key> - the public key

=item C<K*.private> - the private key cleartext, possibly modified

=item C<K*.private.asc> - the encrypted private key

=item C<K*.private.sha256> - fingerprint of decrypted key

=back

If the C<K*.private.sha256> file is missing or does not match the
contents of the C<K*.private> file, then the C<K*.private> is
encrypted and the C<K*.private.asc> file is overwritten.

=item B<regpg> B<dnssec> [I<opts>] B<settime> [I<flags>] <I<dnskey>>

Update the timing parameters on a DNSSEC key using BIND's
B<dnssec-settime> utility.

The private key is decrypted if necessary before running
B<dnssec-settime>, then re-encrypted. The private key is shredded
unless it was present un-encrypted before.

The I<opts> are B<regpg> options. The I<flags> and I<dnskey> are
passed to B<dnssec-settime>. The I<dnskey> can name any of the key
files listed under B<regpg> B<dnssec> B<recrypt>.

=item B<regpg> B<gencrt> <I<days>> [<I<cakey>> <I<cacrt>>] <I<priv>> <I<cnf>> <I<crt>>

Create an X.509 certificate with a validity period given by I<days>,
and write it to I<crt>. If you provide I<cakey> and I<cacrt>, the
certificate will be signed by them, otherwise it will be self-signed.

The certificate's encrypted private key is read from I<priv>, and the
certificate parameters (distinguished name, subjectAltName, etc) are
given in the OpenSSL configuration file I<cnf>. (See the C<req(1ssl)>
man page for details.) If I<priv> does not exist, it is created as if by
C<regpg genkey rsa> I<priv>.

In the self-signed case the OpenSSL configuration file I<cnf> should
contain all the X.508v3 extension attributes you require. (See the
C<x509v3_config(5ssl)> man page for details.) In the CA-signed case,
B<regpg> will add the C<subjectKeyIdentifier> and
C<authorityKeyIdentifier>, so you should omit them.

See the L</EXAMPLES> below for how to use this for a private internal
certificate authority.

=item B<regpg> B<gencsrcnf> [<I<certfile>>|<I<hostname>> [I<csr.cnf>]]

Convert an X.509 certificate into an B<openssl> B<req> configuration file
which can be used with B<regpg> B<gencsr>.

You can use B<gencsrcnf> with an existing certificate file I<certfile>
to help with renewals, or you can fetch a web server's certificate
from I<hostname> to create an example configuration to adapt for a new
certificate request. See the L</EXAMPLES> below.

If I<certfile> is C<-> or there are no arguments then it is read from
stdin.

If I<csr.cnf> is C<-> or there is one argument then it is written to
stdout.

=item B<regpg> B<gencsr> <I<private.asc>> <I<csr.cnf>> [I<csr>]

Generate an X.509 certificate signing request for an encrypted private
key.

The CSR parameters (distinguished name, subjectAltName, etc)
are given in the OpenSSL configuration file I<csr.cnf>.
(See the C<req(1ssl)> man page for details.)

The private key I<private.asc> should have been generated
with B<regpg> B<genkey> B<rsa>. If it does not exist,
it is created for you.

If I<csr> is C<-> or is omitted then it is written to stdout.

As well as being written to I<csr>, the CSR is printed in text form
if you give the B<-v> option.

=item B<regpg> B<gendnskey> [I<options>] <I<zone>>

Create recommended DNSSEC keys for the I<zone> if they do not already
exist, with a 24 hour TTL, using algorithm 13 (ECDSA P256 SHA-256),
with separate ZSK and KSK, and with CDS and CDNSKEY records. This is a
shortcut for:

    $ regpg dnssec keygen -L 86400 -a 13 $zone
    $ regpg dnssec keygen -L 86400 -a 13 -f KSK -Psync now $zone

=item B<regpg> B<genkey> <I<algorithm>> <I<private.asc>> [I<ssh.pub>]

Generate a cryptographic key pair, for use with OpenSSL or OpenSSH.
The PEM private key is encrypted and written to the file
I<private.asc>.

If an I<ssh.pub> filename is given, an B<ssh> public key is written
there. If I<private.asc> already exists, B<genkey> will convert it to
an B<ssh> public key rather than generating a new key.

The algorithm can be one of:

=over

=item dsa - 1024 bit DSA

=item ec256 - 256 bit ECDSA (prime256v1)

=item ec384 - 384 bit ECDSA (secp384r1)

=item ec521 - 521 bit ECDSA (secp521r1)

=item ecdsa - same as ec256

=item rsa - 2048 bit RSA

=item ed25519 - 256 bit Edwards elliptic curve

=back

Unlike the other algorithms, C<ed25519> is ssh-only, and requires
B<puttygen>.

=item B<regpg> B<genpwd> [I<cryptfile.asc>]

If I<cryptfile.asc> already exists, decrypt it and print a SHA256
(type C<$5$>) C<crypt(3)> hash of the password.

Otherwise, generate a 16 character password, encrypt it, store it in
I<cryptfile.asc>, and (unless the B<-q> option is given) print a
C<crypt(3)> hash of the password.

If I<cryptfile.asc> is C<-> or is omitted then the encrypted password
is written to stdout.

The C<ReGPG::Login(3pm)> module helps you to associate metadata such as
username and login URL with an encrypted password. It uses a YAML file
conventionally named like I<cryptfile.yml> alonside I<cryptfile.asc>.

The B<regpg> B<genpwd> subcommand will create I<cryptfile.asc>, then
report an error instead of printing the password hash when C<crypt(3)>
lacks support for SHA256, such as on Mac OS X.

=item B<regpg> B<genspkifp> [I<options>] [I<priv>|I<crt>|I<csr>|I<host>]

Generate an X.509 subject public key information SHA-256 fingerprint,
suitable for use with HTTPS public key pinning (HPKP). The public key
can be obtained from a gpg-encrypted private key, a certificate file,
a certificate signing request, or by fetching a server's certificate.
In the latter three cases, the subject's distinguished name is printed
to C<stderr> unless the B<-q> option was given.

=back

=head2 Initial setup

=over

=item B<regpg> B<init> [I<hook>]...

Easy initialization of B<regpg> and its hooks for other utilities.
It is safe to re-run B<regpg> B<init> since it is idempotent.

Every B<init> run ensures the B<regpg> public keyring exists. If it
doesn't, the keyring is created using B<regpg> B<addself>.

The hooks can be zero or more of:

=over

=item git

=item ansible

=item ansible-vault

Z<>

=back

=over

=item B<regpg> B<init> B<git>

Configure B<git> to provide human-readable diffs of the B<regpg>
public keyring, and keys that can decrypt each secret.

Note: You must have run B<git> B<init> first. The B<git> B<diff>
configuration is not propagated with the contents of the repository,
so you need to re-run B<regpg> B<init> B<git> in each fresh clone.

Note: this does not provide human-readable diffs of the cleartext
contents of encrypted files, because that would expose secrets
dangerously. Instead it diffs the keys that are able to decrypt each
secret. This is intended to help you audit changes to the list of
people that can access the secrets.

=item B<regpg> B<init> B<ansible>

Configure Ansible for use with B<regpg>.
An F<ansible.cfg> file is created if necessary.

This installs three things:

The F<gpg_d> module works like the F<copy> module, except that the
C<src:> file is decrypted before being transferred to the remote
target. The decrypted contents can be binary.

The F<gpg_d> Jinja2 filter inserts decrypted files into templates.
The decrypted contents must be plain text.

To ensure that B<gpg-agent> is not confused by concurrent passphrase
requests, you can include F<gpg-preload.yml> at the start of your
playbook.

See the L</EXAMPLES> below for how to use this setup.

Note: these Ansible hooks only use B<gpg>, so you don't need B<regpg>
to run your playbooks. You only need B<regpg> for altering the public
keyring and encrypted files.

Note: The F<plugins/action/gpg_d.py> file is distributed under the
terms of the GNU General Public License version 3 or later. The other
hook files are public domain (CC0).

=item B<regpg> B<init> B<ansible-vault>

Configure Ansible Vault for use with B<regpg>.
An F<ansible.cfg> file is created if necessary.

This creates an encrypted vault password F<vault.pwd.asc> and a
wrapper script F<vault.open> to decrypt the password using B<gpg>.

You can then use B<ansible-vault> as usual, and when it needs the
vault password it will be automatically decrypted.

Note: the decryption script only uses B<gpg>, so you don't need
B<regpg> to run B<ansible-playbook> nor B<ansible-vault>. You only
need B<regpg> for altering the public keyring.

=back

=back

=head2 Converting to regpg

The B<conv> subcommand has a number of sub-sub-commands which help you
convert from other setups to B<regpg>.

=over

=item B<regpg> B<conv> B<ansible-gpg>

Convert an C<ansible-gpg> setup for use with B<regpg>,
as if you had used C<regpg init ansible-vault>.

This copies the keys from F<.ansible-gpg/pubring.gpg> into the
B<regpg> keyring, renames F<.ansible-gpg/vault_passphrase.gpg> to
F<vault.pwd.gpg>, reconfigures Ansible, and finally removes the
remaining F<ansible-gpg> files.

=item B<regpg> B<conv> B<ansible-vault> [<I<vaultfile>> [I<cryptfile.asc>]]

Decrypt I<vaultfile> using B<ansible-vault> and re-encrypt the
cleartext using B<regpg>.

If I<cryptfile> is C<-> or omitted then the ciphertext
is written to stdout.

If both arguments are omitted then B<regpg> searches for
B<ansible-vault> files that may need conversion.

=item B<regpg> B<conv> B<stgza> [<I<member>> [I<cryptfile.asc>]]

Convert from a symmetrically-encrypted F<secrets.tar.gz.asc> using its
B<regpg>-encrypted passphrase from F<secrets.pwd.asc>. (These filenames
are hard-coded to match old tooling.)

The I<member> is the name of a file inside F<secrets.tar.gz.asc> to
extract and re-encrypt with B<regpg>.

If I<cryptfile> is C<-> or omitted then the ciphertext is written
to stdout.

With no argument, B<regpg> lists the contents of
F<secrets.tar.gz.asc>.

=back

=head1 ENVIRONMENT

=over

=item GPG_AGENT_INFO

When decrypting, B<regpg> tells B<gpg> to use B<gpg-agent> which (in
older versions of B<gpg>) is located using C<$GPG_AGENT_INFO>.

=item REGPGHOME

By default B<regpg> sets B<gpg>'s home directory to F<~/.regpg>.
You can set C<$REGPGHOME> to override this.

=back

=head1 FILES

=over

=item ./pubring.gpg

The default B<regpg> public keyring.

=item ~/.regpg/

Dummy C<$GNUPGHOME> directory to isolate B<regpg> from problematic
F<gpg.conf> settings. You can set the C<$REGPGHOME> environment
variable to change this. When starting, B<regpg> automatically ensures
this directory exists.

=back

=head1 EXAMPLES

=head2 TLS preparation

Get a template OpenSSL CSR configuration file based on a certificate
similar to the one you want. This example gets the request details
from the certificate for C<dotat.at>, which it downloads from the web
server:

    $ regpg gencsrcnf dotat.at tls.cnf

Edit F<tls.cnf> to the correct details for your server, then you
can generate a key and CSR:

    $ regpg gencsr tls.pem.asc tls.cnf tls.csr

=head2 Private internal certificate authority

To create the root certificate, you'll need an OpenSSL configuration
file similar to this, but with a more suitable distinguished name:

        [ req ]
        prompt = no
        distinguished_name = distinguished_name
        req_extensions = extensions
        x509_extensions = extensions

        [ extensions ]
        keyUsage = critical, keyCertSign, cRLSign
        basicConstraints = critical, CA:TRUE
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always, issuer:always

        [ distinguished_name ]
        commonName = "Honest Achmed's Used Cars and Certificates"

Then make your CA root private key and certificate:

    $ regpg gencrt 3650 root.pem.asc root.cnf root.crt

Then to make a certificate, generate a configuration file using
B<gencsrcnf> as in the previous example. You may want to add the
following to the C<[extensions]> section:

        keyUsage = digitalSignature, keyEncipherment
        extendedKeyUsage = serverAuth, clientAuth

Then run the following command:

    $ regpg gencrt 365 root.pem.asc root.crt tls.pem.asc tls.cnf tls.crt

Note: For simple self-signed certificates, it's easiest to omit
the key usage restrictions.

=head2 Ansible without Vault

After running B<regpg> B<init> B<ansible>, here are a couple of ways
you can use B<gpg> in your Ansible playbooks.

This Ansible task installs B<ssh> host private keys that have been
encrypted with B<regpg>. The C<when:> condition on the last line
allows you to avoid decrypting secrets except when necessary.

    - name: install ssh host keys
      gpg_d:
        src="{{item}}.asc"
        dest="/etc/ssh/{{item}}"
        mode=0600
      with_items:
        - ssh_host_dsa_key
        - ssh_host_ecdsa_key
        - ssh_host_rsa_key
      when: secrets | default(all) | default()

There can be a problem when Ansible invokes F<gpg_d> multiple times
concurrently, that you may be asked to enter your passphrase more than
once. You can avoid this by forcing Ansible to preload B<gpg-agent>
immediately at startup. Do this by including F<gpg-preload.yml> at the
start of your main playbook:

    ---
    - include: gpg-preload.yml
      when: secrets | default(all) | default()
    # etc...

The F<gpg-preload.yml> playbook uses the F<gpg_d> filter like this:

    assert:
      that: "{{ 'gpg-preload.asc' | gpg_d }}"

=head1 VERSION

  This is regpg-1.11.X <https://dotat.at/prog/regpg/>

  Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>
  at Cambridge University Information Services
  and distributed under the terms of the GNU General Public License
  version 3 or later. <https://www.gnu.org/licenses/gpl.html>

=head1 ACKNOWLEDGMENTS

Thanks to Jon Warbrick who gave me the idea for B<regpg>'s key
management; and David Carter, Ben Harris, Ian Lewis, David McBride,
C<mchubby>, and Matthew Vernon for helpful bug reports and
discussions.

=head1 SEE ALSO

gpg(1), gpg-agent(1), ansible(1), git(1), openssl(1),
ReGPG::Login(3pm), puttygen(1) shred(1), ssh-keygen(1)

=cut
