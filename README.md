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

    There are also some quick `init` commands to get `regpg`
    hooked up with `ansible` and `git`.


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

If you use `regpg`, let me know! Send me mail at <dot@dotat.at>.

If you would like to submit a bug report or a patch, see
[doc/contributing.md](https://dotat.at/prog/regpg/doc/contributing.html)


Installing
----------

For a simple one-file install you can copy the `regpg` script to a
directory on your `$PATH`.

You can run `make install` to install the script and man page to
the standard places in your home directory. See the start of the
`Makefile` for variables you can set on the command line to adjust
the install location.


Dependencies
------------

To use `regpg` you need the following programs. I've listed the
versions that I have tested.

* `perl` 5.20
* `gpg` 1.4.18
* `gpg-agent` 2.0.26
* `pinentry-gtk2` 0.8.3 (or) `pinentry-tty` 0.9.7

You only need the following programs if you use `regpg`'s helper
subcommands.

* `git` 2.10
* Ansible 2.2
* OpenSSH 6.7
* OpenSSL 1.0.1
* `xclip` 0.12


Downloads
---------

Download the single-file `regpg` perl script:
<https://dotat.at/prog/regpg/regpg>

Download the full source archives and GPG signatures:

* <https://dotat.at/prog/regpg/regpg-0.79.tar.xz>
  ([sig](https://dotat.at/prog/regpg/regpg-0.79.tar.xz.asc))
* <https://dotat.at/prog/regpg/regpg-0.79.tar.gz>
  ([sig](https://dotat.at/prog/regpg/regpg-0.79.tar.gz.asc))
* <https://dotat.at/prog/regpg/regpg-0.79.zip>
  ([sig](https://dotat.at/prog/regpg/regpg-0.79.zip.asc))


Repositories
------------

You can clone or browse the repository from:

* <https://dotat.at/cgi/git/regpg.git>
* <https://github.com/fanf2/regpg.git>
* <https://git.uis.cam.ac.uk/x/uis/git/regpg.git>


Acknowledgments
---------------

Thanks to Jon Warbrick who gave me the idea for `regpg`'s key
management, and David McBride for helpful discussions.

---------------------------------------------------------------------------

> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
> You may do anything with this. It has no warranty.  
> <https://creativecommons.org/publicdomain/zero/1.0/>
