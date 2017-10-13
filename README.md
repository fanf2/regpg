regpg - safely store server secrets
===================================

The `regpg` program is a thin wrapper around `gpg` to help with
managing secrets that need to be stored encrypted in revision control
for a configuration management system.

Dependencies
------------

To use `regpg` you need the following programs. I've listed the
versions that I have tested.

* `perl` 5.20
* `gpg` 1.4.18
* `gpg-agent` 2.0.26
* `pinentry-gtk2` 0.8.3 / `pinentry-tty` 0.9.7

You only need the following programs if you use `regpg`'s helper
subcommands.

* `git` 2.10
* Ansible 2.2
* OpenSSH 6.7
* OpenSSL 1.0.1

Downloads
---------

### Documentation

The `regpg` homepage is <http://dotat.at/prog/regpg/>

Read the `regpg` reference manual:
<http://dotat.at/prog/regpg/regpg.html>

### Code

Download the single-file `regpg` perl script:
<https://dotat.at/prog/regpg/regpg>

Download the full source archives:

* <http://dotat.at/prog/regpg/regpg-0.42.tar.xz>
* <http://dotat.at/prog/regpg/regpg-0.42.tar.gz>
* <http://dotat.at/prog/regpg/regpg-0.42.zip>

### Source repositories

You can clone or browse the repository from:

* <https://dotat.at/cgi/git/regpg.git>
* <https://github.com/fanf2/regpg.git>
* <https://git.uis.cam.ac.uk/x/uis/git/regpg.git>


Acknowledgments
---------------

Thanks to Ben Harris and Jon Warbrick who gave me the idea for
`regpg`'s key management.

---------------------------------------------------------------------------

> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
> You may do anything with this. It has no warranty.  
> <https://creativecommons.org/publicdomain/zero/1.0/>
