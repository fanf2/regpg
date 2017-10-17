regpg's threat model
====================


decryption keys
---------------

Each person whose private key is listed in `regpg`'s `pubring.gpg` is
responsible for keeping their secret key safe.

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
`pubring.gpg`.


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

* `gpg-agent` is required (see above)

* helper subcommands avoid writing secrets to disk


revocation
----------

This is one of the weak points of `regpg`'s setup. If you have access
to the private part of a key previously included in `pubring.gpg`, and
access to the repository, you can still decrypt secrets stored in old
revisions.

Revoking access to `regpg` secrets requires destroying the private
part of the key that was removed from `pubring.gpg`.


auditing
--------

Another weak point. `regpg` supports distributed access to secrets.
The only point of audit is access to revision control, but that does
not tell anyone when secrets are decrypted.



---------------------------------------------------------------------------

> Part of `regpg` <https://dotat.at/prog/regpg/>
>
> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
> You may do anything with this. It has no warranty.  
> <https://creativecommons.org/publicdomain/zero/1.0/>
