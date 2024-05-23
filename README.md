regpg - safely store server secrets
===================================

The `regpg` program is a thin wrapper around `gpg` for looking after
secrets that need to be stored encrypted in a version control system
(so you don't have to trust the VCS server) and decrypted when your
configuration management system deploys them to servers.


Overview
--------

 *  discreet and discrete

    `regpg` is designed to store each secret in its own
    ASCII-armored PGP-encryped file, separate from non-secret
    code and configuration. The only other file `regpg` needs
    is a public keyring.

 *  simplified key management

    `regpg` manages a keyring containing the public keys of
    whoever is allowed to decrypt the secrets.

    There is no need to curate your personal public keyring, or
    get involved in the web of trust, or use PGP keyservers.
    You exchange public keys with your colleagues via the `regpg`
    `pubring.gpg` file in your version control system.

 *  keeping consistent

    After you have added or removed a key it is easy to re-encrypt
    secrets. `regpg` can check that all secrets are properly
    encrypted to the keys in its `pubring.gpg` file.

 *  handy helpers

    `regpg` has subcommands for generating and encrypting TLS and
    SSH private keys in one step, and for wrangling X.509
    certificates.

    There are also some quick `init` commands to get `regpg` hooked up
    with `ansible` and `git`, and some `conv` commands to help you
    migrate to `regpg` from other tools.

 *  conventional project layout

    At the root of your project you have a `pubring.gpg` file which
    lists the set of people who can decrypt the secrets. This is your
    current working directory when using `regpg`. Elsewhere in your
    project directory and its subdirectories you have encrypted
    `secret.asc` files. The F<.asc> extension is short for
    ASCII-armored PGP message.

 *  when not to use `regpg`

    It's usually better to use [HashiCorp Vault](https://www.vaultproject.io/)
    or your cloud provider's native secret management, if you can.


Downloads
---------

Download the single-file `regpg` perl script:
<https://dotat.at/prog/regpg/regpg>
and its [GPG signature](https://dotat.at/prog/regpg/regpg.asc).

Download the full source archives and GPG signatures:

* <https://dotat.at/prog/regpg/dist/regpg-1.12.tar.xz>
  ([sig](https://dotat.at/prog/regpg/dist/regpg-1.12.tar.xz.asc))
* <https://dotat.at/prog/regpg/dist/regpg-1.12.tar.gz>
  ([sig](https://dotat.at/prog/regpg/dist/regpg-1.12.tar.gz.asc))
* <https://dotat.at/prog/regpg/dist/regpg-1.12.zip>
  ([sig](https://dotat.at/prog/regpg/dist/regpg-1.12.zip.asc))


Documentation
-------------

 *  Homepage: <https://dotat.at/prog/regpg/>

 *  `regpg help` displays the reference manual, or you can read it at
    <https://dotat.at/prog/regpg/regpg.html>

 *  [doc/tutorial.md](https://dotat.at/prog/regpg/doc/tutorial.html) -
    an introduction and overview of `regpg`.

 *  [doc/rationale.md](https://dotat.at/prog/regpg/doc/rationale.html) -
    why `regpg` exists.

 *  [doc/secrets.md](https://dotat.at/prog/regpg/doc/secrets.html) -
    `regpg`'s approach to handling secrets.

 *  [doc/threat-model.md](https://dotat.at/prog/regpg/doc/threat-model.html) -
    `regpg`'s threat model.

 *  talks/2017-11-uis-staff/
    [script](https://dotat.at/prog/regpg/talks/2017-11-uis-staff/notes.pdf) and
    [slides](https://dotat.at/prog/regpg/talks/2017-11-uis-staff/slides.pdf) -
    a presentation I gave to my colleagues which reprises some of the
    above in a different form

 *  [doc/relnotes.md](https://dotat.at/prog/regpg/doc/relnotes.html) -
    `regpg` release notes and change summary.

If you use `regpg`, let me know! Send me mail at <dot@dotat.at>.

If you would like to submit a bug report or a patch,
or if you would like more information about `regpg`'s licence, see
[doc/contributing.md](https://dotat.at/prog/regpg/doc/contributing.html)


Installing
----------

For a simple one-file install you can copy the `regpg` script to a
directory on your `$PATH`. If you have `regpg.pl` but not bare
`regpg` then you need to run `make`.

You can run `make install` to install the script and man page to the
standard places in your home directory, and `make uninstall` to remove
them. See the start of the `Makefile` for variables you can set on the
command line to adjust the install location. See
[doc/contributing.md](https://dotat.at/prog/regpg/doc/contributing.html)
for more details about building from `git`.


Dependencies
------------

To use `regpg` you need the following programs. I've listed the
versions that I have tested.

* `perl` - 5.16 - 5.20 - 5.22 - 5.26
* `gnupg` - 1.4.18 - 1.4.21 - 2.0.22 - 2.0.26 - 2.1.11 - 2.1.18 - 2.2.10
* `gnupg-agent` - 2.0.22 - 2.0.26 - 2.1.11 - 2.2.1
* `pinentry-gtk2` 0.8.3 (or) `pinentry-tty` 0.9.7 (or) `pinentry-curses` 0.8.1

You only need the following programs if you use `regpg`'s helper
subcommands.

* `git` - 2.7 - 2.10 - 2.15 - 2.19
* Ansible - 2.0 ... 2.6
* BIND - 9.14
* OpenSSH - 6.7 - 7.2 - 7.6
* OpenSSL - 1.0.1 - 1.0.2 - 1.1.0 - 1.1.1
* PuTTY - 0.68 - 0.70
* `xclip` - 0.12

You only need the following to build from `git`.

* `make` - any version should do
* `Markdown.pl` or `Text::Markdown` -
    aka `markdown` or `libtext-markdown-perl` on Debian-like systems
* `perlcritic` - aka `libperl-critic-perl` on Debian-like systems


Repositories
------------

You can clone or browse the repository from:

* <https://dotat.at/cgi/git/regpg.git>
* <https://github.com/fanf2/regpg.git>

Acknowledgments
---------------

Thanks to Jon Warbrick who gave me the idea for `regpg`'s key
management; and David Carter, Ben Harris, Paul Haughton, Ian Lewis,
David McBride, [`mchubby`](https://github.com/mchubby), and Matthew
Vernon for helpful bug reports and discussions.


---------------------------------------------------------------------------

> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
>
> `regpg` is free software: you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.
>
> `regpg` is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
> GNU General Public License for more details.
>
> You should have received a copy of the GNU General Public License
> along with `regpg`.  If not, see <http://www.gnu.org/licenses/>.
