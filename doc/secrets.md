regpg's approach to handling secrets
====================================

regpg is designed to manage secrets that have to be stored in the
clear on disk on the servers that need access to them - private keys
for TLS, SSH, DNS, APIs, etc. - but these secrets should be kept
encrypted everywhere else. We don't want to expose them on non-server
disks, in editors, or terminal windows, or clipboards.

From our high-level perspective, secrets are basically blobs of random
data: we can't usefully look at them or edit them by hand. So there is
very little reason to expose them, provided we have tools (such as
`regpg`) that make it easy to avoid doing so.


One file per secret
-------------------

Although `regpg` isn't very dogmatic, it works best when we put each
secret in its own file. This allows us to use the filename as the name
of the secret, which is available without decrypting anything, and
often all the metadata we need.

Rather than embedding secrets in non-secret files, we prefer:

* in code, load secrets as needed from disk

* in configuration, `include` secrets

* for configuration formats without an `include` directive,
  use a template to combine the non-secret and secret parts

This discipline is also required for properly separated production /
test / development environments that do not share secrets.


Lifecycle of secrets
--------------------

What we're aiming for is to keep it simple:

* a secret is generated and immediately encrypted, so it can be
  distributd and backed up

* the secret is decrypted for deployment on the servers that need it

* eventually, it is deleted because it has been replaced or become
  redundant

We would also like to avoid decrypting secrets when we don't have to.
Keeping secrets separate from non-secret files allows us to do most
deployments without having to decrypt anything.

Unfortunately there are situations where we can't keep things as
simple as we would like, when we need to decrypt a key for reasons
other than deployment. We might need to generate a new X.509 CSR, or
adjust the timing metadata in a BIND-format DNSSEC private key.


Helper subcommands
------------------

In those cases where our secrets need to live more complicated lives,
we still want to keep the secrets off disk and off screen. It's often
possible to construct pipelines that follow our secrecy rules, e.g.

        openssl genrsa 2048 | regpg encrypt mykey.asc

But this is often difficult to get right. The `regpg` helper
subcommands wrap up some of these pipelines in a handy package.

There are cases where the existing tools make it very difficult to
implement helpers that follow our rules, typically because they insist
on working with files not pipes. Examples include `ssh-keygen -t
ed25519` and `dnssec-settime`. In these cases you have to decrypt to
disk, and there is no `regpg` helper, so you know what is happening.


Just a gpg helper
-----------------

The essence of `regpg` is to be a helper for `gpg`. You can just use
raw `gpg --decrypt` on your secrets.

The important part of `regpg` is how it helps you manage a shared
keyring, and uses that to encrypt your secrets. The rest is
convenience utilities.


---------------------------------------------------------------------------

> Part of `regpg` <https://dotat.at/prog/regpg/>
>
> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
> You may do anything with this. It has no warranty.  
> <https://creativecommons.org/publicdomain/zero/1.0/>
