regpg release notes
===================


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
