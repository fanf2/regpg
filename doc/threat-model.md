regpg's threat model
====================


decryption keys
---------------

Each person whose private key is listed in `regpg`'s `pubring.gpg` is
responsible for keeping their secret key safe from prying eyes, and
safely backed up. It is a good idea to generate a new key specifically
for use with `regpg` - see "revocation" below.

`regpg` requires the use of `gpg-agent`, which reduces the need to
retype passphrases, which makes it more reasonable to have long random
passphrases.


authority to decrypt
--------------------

The contents of `regpg`'s `pubring.gpg` determine who has access to
secrets.

`regpg` is designed to be used with version control, so that changes
to `pubring.gpg` are recorded and audited like any other code or
configuration change.

With `regpg`, change reviews are important to protect against
elevation of privilege by an attacker who gains write access to
`pubring.gpg`. To make this easier, `regpg init git` installs a
`git diff` hook for `pubring.gpg`.


existence of secrets
--------------------

`regpg` does not try to hide secrets; we assume their existence is
equally sensitive as any unencrypted code or configuration that shares
the same repository.


backups
-------

We assume that `gpg` encryption is strong enough that we can
promiscuously distribute encrypted secrets via version control and
backups, to keep them safe from accidental lossage.

If all the private decryption keys are lost then access to the secrets
is lost. It is therefore vital to keep `gpg` private keys safe.


avoiding accidental exposure
----------------------------

We try to help `regpg` users maintain situational awareness of their
secrets:

* Encryption and decryption are explicit.

* There are conventional filenames for encrypted secrets.

* There are configuration management idioms for deploying decrypted
  secrets.

* The `check` subcommand lets you verify your mental model matches
  reality.


workstation compromise
----------------------

`regpg` takes a couple of measures to reduce the consequences of a
compromised workstation.

* `gpg-agent` is required (see "decryption keys" above)

* helper subcommands avoid writing secrets to disk


revocation
----------

This is one of the weak points of `regpg`'s setup. If you have access
to the private part of a key previously included in `pubring.gpg`, and
access to the repository, you can still decrypt secrets stored in old
revisions.

Revoking access to `regpg` secrets requires destroying the private
part of the key that was removed from `pubring.gpg`. Hence it is a
good idea to use a `regpg`-specific key.

If you can't be sure that someone no longer has access to their
private key after you revoked their access, you will have to replace
all the secrets.


auditing
--------

Another weak point. `regpg` supports distributed access to secrets.
The only point of audit is access to revision control, but that does
not tell anyone when secrets are decrypted.



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
