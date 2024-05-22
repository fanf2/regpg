regpg release notes and change summary
======================================


2024-05-22 - regpg-1.12
-----------------------

* A `regpg gendnskey` subcommand that generates DNSSEC keys with
  sensible parameters.

* Fix `check`, `recrypt`, `shred` subcommands when filenames contain
  spaces.

* Compatibility fixes for more recent versions of Ansible, OpenSSL,
  and GnuPG.

* Accommodate lack of SHA256 support in Mac OS X `crypt(3)`


2019-12-19 - regpg-1.11
-----------------------

* ReGPG::Login supports object-oriented style as well as script style.

* ReGPG::Login has a HTTP Basic authorization convenience helper.

* A `regpg dnssec` subcommand that provides wrappers for the BIND
  `dnssec-keygen` and `dnssec-settime` programs, to make it more
  convenient to work with encrypted DNSSEC private keys.


2019-09-27 - regpg-1.10
-----------------------

* Introduce ReGPG::Login, a Perl module to load partially-encrypted
  login credentials. It uses the storage layout that I have set up
  for the DNS systems at Cambridge.

  Bugs: I have not yet fixed the Makefile to install it properly,
  nor written any tests.


2019-06-07 - regpg-1.9
----------------------

* Explicitly tell OpenSSL to use SHA-256.

  I have not managed to find a version of OpenSSL that does not use
  SHA-256 (I checked 1.0.1 and 1.1.0 and 1.1.1) so this is effectively
  a no-op, but it might be useful for people stuck on ante-diluvian
  versions.

* Minor test suite fixes for RHEL 7.


2019-02-13 - regpg-1.8
----------------------

* Attempt to work around `gpg2` reliability problems. The Ansible
  plugins will run `gpg1` if it is available (since it is more
  reliable than `gpg2`) and re-run `gpg2` if it looks like there was a
  spurious failure.

* Python 3 compatibility for the Ansible plugins.

* Compatibility with `gpg2` format key IDs. When listing key IDs,
  `gpg` adds a prefix indicating the algorithm and key size, separated
  from the ID by a slash. However, `gpg` does not accept key IDs in
  this format, so `regpg` strips off the prefix to make it work.
  Previously `regpg` only recognized `gpg1` prefixes like `4096R/`,
  but now it also strips off `gpg2` prefixes like `rsa4096/`.


2019-02-13 - regpg-1.7
----------------------

* Declare `regpg` to be stable.

* Reduce length of passwords, so it is feasible to copy-type them into
  a console.

* Other minor `genpwd` improvements.


2018-09-12 - regpg-0.106
------------------------

* Compatibility with Ansible 2.5 and 2.6. Thanks to David Carter
  for reporting that there were problems.

* Minor test portability and robustness improvements found when
  running on Debian sid / unstable.

* genspkifp generates SPKI fingerprints for HTTPS public key pinning (HPKP)


2018-02-02 - regpg-0.103
------------------------

* quiet mode


2018-02-01 - regpg-0.102
------------------------

* fix `regpg init ansible` when there are existing plugin settings

* check the relnotes are updated before release


2018-01-24 - regpg-0.100
------------------------

* Ed25519 ssh keys (using `puttygen`)

* fix ssh key generation on BSDish systems

* Support for both Markdown.pl and Text::Markdown in doc build

* Avoid locale interference in tests

* Use `~/.regpg` to avoid interference from user's `gpg.conf`

* `depipe` subcommand, for writing to a temporary fifo

* `gencrt` and `gencsa` now auto-generate private keys as necessary


2017-12-18 - regpg-0.99
-----------------------

* `gencrt` subcommand for self-signed X.509 certificates

* `gencrt` also has super simple X.509 CA support


2017-12-13 - regpg-0.98
-----------------------

* port to Ansible 2.0, 2.1.0, 2.1.1, and devel

* crypt(3) hash output from`genpwd`


2017-11-30 - regpg-0.95
-----------------------

* GPLv3

* Ansible portability fixes

* Ansible gpg_d module, to support binary secrets

* Force message authentication digests on encrypted files


2017-11-23 - regpg-0.94
-----------------------

* `squeegee` subcommand

* `lskeys` can list decryption keys of encrypted files


2017-11-22 - regpg-0.93
-----------------------

* Portability fixes to different versions of Ansible, GnuPG, OpenSSL

* Improvements to test suite


2017-11-21 - regpg-0.92
-----------------------

* Presentation to colleagues

* Logo


Earlier history
---------------

Before this point, `regpg` had very few users. Please see the `git`
logs for changes to older versions.


---------------------------------------------------------------------------

> Part of `regpg` <https://dotat.at/prog/regpg/>  
> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  

<!--
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This file is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with regpg.  If not, see <http://www.gnu.org/licenses/>.
-->
