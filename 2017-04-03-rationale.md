2017-04-03 - why not Ansible Vault
==================================

> This is a lightly-edited copy of a message I sent to my colleagues
> to announce `regpg` and explain why it exists. At the time this was
> written, Jon Warbrick and Ben Harris were using `ansible-gpg` which
> they had written to encrypt `ansible-vault` passphrases using `gpg`.
> Key management in `regpg` was copied from `ansible-gpg`.

I've done some more investigation and fiddling around, and I have made a
thing which I am a bit more happy with than `ansible-vault`.

It's currently called `regpg`, which isn't a very good name. I might
rename it `revaulting` but that's a bit long and silly.

It's very much inspired by
[`ansible-gpg`](https://git.uis.cam.ac.uk/x/uis/u/jw35/ansible-gpg.git)
and also by
[StackExchange's BlackBox](https://github.com/StackExchange/blackbox).

The basic `regpg` subcommands and the `gpg` invocations come from
`ansible-gpg`, but instead of managing a single Ansible Vault password
file, you can use `regpg` to manage lots of secret files.

BlackBox does a similar job, but it gets involved with VCS integration,
which isn't really a problem I need solving. (The BlackBox README lists
several other similar tools which do things like transparent decryption
for `git diff` etc. which does not seem safe to me.)

BlackBox keeps explicit lists of `gpg` recipients and encrypted files. I
copied the way `ansible-gpg` gets the recipients from `pubring.gpg`, and I
use `find | xargs grep` to locate encrypted files.

## Why not `ansible-vault`

The main thing `ansible-vault` offers is easy decryption of secrets when
running a playbook, but this can be done with a small `gpg_d` filter
plugin to wrap `gpg --decrypt`.

### Visibility

Ansible Vault decryption is mostly transparent, so when you are
reading a playbook it isn't immediately clear which things ought to be
encrypted.

If something isn't encrypted when it should be, there is no error to tell
you about the mistake.

The `gpg_d` plugin does not have these problems.

There isn't a standard `ansible-vault` subcommand to find secrets, but you
can do so with a recursive `grep` for ANSIBLE_VAULT.

### Editing

Text editors have lots of features for storing backup files and cut/paste
history, which you really don't want when managing secrets. (It isn't wise
to use `ansible-vault` if your `$EDITOR` is emacsclient!)

The alternative promoted by `ansible-vault` is to encrypt/decrypt
files in place on disk (swapping the same file between cleartext and
ciphertext), which makes it easy to accidentally commit a cleartext
secret. The lack of 'expected ciphertext, found cleartext' errors in
this situation does not help you to find out when you have made this
mistake.

### Variables

Working out where variables come from in Ansible can be tricky. Encrypting
variable files makes this much harder. There is
[an unpleasant official workaround](http://docs.ansible.com/ansible/playbooks_best_practices.html#best-practices-for-variables-and-vaults)
based on duplicating the vault's structure in cleartext variables.

[I haven't found a use for encrypted variables (as opposed to encrypted
files), so this isn't a practical moan.]

### Rekeying

To rekey everything you need to script up something based on a recursive
grep for ANSIBLE_VAULT - there isn't a standard tool to do it. It's extra
tricky with script-provided passphrases - rekey support doesn't seem to be
part of the common `ansible-vault` + `gpg-agent` recipes.

Rekeying `gpg` files is comparatively easy.

## Robots

One of the more knotty problems I have been sitting on is automated
DNSSEC key rollovers. The difficulty is how to manage backups of the
private keys so that they can be recovered when the master server is
rebuilt. At the moment they are wired in to my fairly inconvenient old
setup for deploying encrypted secrets with Ansible.

By using `gpg` for secret storage, the key rollover process can encrypt
replacement DNSKEYs using only the public keyring - without being given
access to any other secrets.

The key rollover robot can even commit and push the change reasonably
safely, by using `gitolite` `VREF` access controls to restrict changes
made by the robot to a few particular paths within the repository.

At the moment this idea is very speculative.


---------------------------------------------------------------------------

Written by Tony Finch <dot@dotat.at> <fanf2@cam.ac.uk>
at Cambridge University Information Services.
You may do anything with this. It has no warranty.
<https://creativecommons.org/publicdomain/zero/1.0/>
