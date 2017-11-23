A tutorial overview of regpg
============================

These notes show you how to:

 * generate a key
 * get the gpg-agent working
 * install regpg
 * start your project
 * enrol another admin
 * hook into git
 * manipulate secrets
 * change keys and secrets
 * hook into ansible


generate a key
--------------

The first thing we need to do is generate a GPG key for use with `regpg`.

Even if you already have a `gpg` key, it's a good idea to generate one
specifically for use with `regpg`. This makes it easier to revoke your
access to secrets protected by `regpg`: you destroy your secret key.

So, run:

        $ gpg --gen-key

and answer the questions. The transcript below is long, but there are
only a few questions and you can take the defaults for most of them.
I chose:

 * RSA and RSA keys
 * keysize 4096 bits
 * key does not expire

The full process looks like this:

        gpg (GnuPG) 1.4.18; Copyright (C) 2014 Free Software Foundation, Inc.
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.

        gpg: directory `/home/fanf9/.gnupg' created
        gpg: new configuration file `/home/fanf9/.gnupg/gpg.conf' created
        gpg: WARNING: options in `/home/fanf9/.gnupg/gpg.conf' are not yet active during this run
        gpg: keyring `/home/fanf9/.gnupg/secring.gpg' created
        gpg: keyring `/home/fanf9/.gnupg/pubring.gpg' created
        Please select what kind of key you want:
           (1) RSA and RSA (default)
           (2) DSA and Elgamal
           (3) DSA (sign only)
           (4) RSA (sign only)
        Your selection? 1
        RSA keys may be between 1024 and 4096 bits long.
        What keysize do you want? (2048) 4096
        Requested keysize is 4096 bits
        Please specify how long the key should be valid.
                 0 = key does not expire
              <n>  = key expires in n days
              <n>w = key expires in n weeks
              <n>m = key expires in n months
              <n>y = key expires in n years
        Key is valid for? (0)
        Key does not expire at all
        Is this correct? (y/N) y

        You need a user ID to identify your key; the software constructs the user ID
        from the Real Name, Comment and Email Address in this form:
            "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"

        Real name: Tony Finch
        Email address: fanf9@uis.cam.ac.uk
        Comment: regpg
        You selected this USER-ID:
            "Tony Finch (regpg) <fanf9@uis.cam.ac.uk>"

        Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
        You need a Passphrase to protect your secret key.

        Enter passphrase: s00per-s33krit
        Repeat passphrase: s00per-s33krit

        We need to generate a lot of random bytes. It is a good idea to perform
        some other action (type on the keyboard, move the mouse, utilize the
        disks) during the prime generation; this gives the random number
        generator a better chance to gain enough entropy.
        .........+++++
        ...................+++++
        We need to generate a lot of random bytes. It is a good idea to perform
        some other action (type on the keyboard, move the mouse, utilize the
        disks) during the prime generation; this gives the random number
        generator a better chance to gain enough entropy.
        ....+++++
        ..............+++++
        gpg: /home/fanf9/.gnupg/trustdb.gpg: trustdb created
        gpg: key 3E4D80EF marked as ultimately trusted
        public and secret key created and signed.

        gpg: checking the trustdb
        gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
        gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
        pub   4096R/3E4D80EF 2017-10-17
              Key fingerprint = C292 2AB4 1114 30F3 B3B2  483E 1124 9B85 3E4D 80EF
        uid                  Tony Finch (regpg) <fanf9@uis.cam.ac.uk>
        sub   4096R/53E8369C 2017-10-17


get the gpg-agent working
-------------------------

On my Debian workstation, `gpg-agent` is started automatically if it
is installed. (The package name is `gnupg-agent`.)

        $ sudo apt install gnupg-agent
        Reading package lists... Done
        Building dependency tree
        Reading state information... Done
        gnupg-agent is already the newest version.
        gnupg-agent set to manually installed.
        0 upgraded, 0 newly installed, 0 to remove and 127 not upgraded.

I can check it is running by looking for its environment variable:

        $ echo $GPG_AGENT_INFO
        /tmp/gpg-r0ccbX/S.gpg-agent:1320:1

If it isn't running, you can start it with:

        $ eval $(gpg-agent --daemon)
        gpg-agent[22691]: directory `/home/fanf9/.gnupg/private-keys-v1.d' created
        gpg-agent[22692]: gpg-agent (GnuPG) 2.0.26 started


install regpg
-------------

This is the quick and dirty way!

        $ mkdir -p ~/bin
        $ curl https://dotat.at/prog/regpg/regpg >~/bin/regpg
        $ chmod +x ~/bin/regpg
        $ export PATH=~/bin:$PATH


start your project
------------------

We're going to keep our project in `git`, so

        $ git init demo
        Initialized empty Git repository in /home/fanf9/demo/.git/
        $ cd demo

Now we can get the project set up with `regpg init`. Unlike most
`regpg` subcommands, `init` likes to tell you what it is doing.

        $ regpg init
        pipe from gpg --list-secret-keys --with-colons fanf9
        pipe from gpg --export --armor --export-options export-minimal F8A1BC7553E8369C
        pipe to gpg --no-default-keyring --keyring ./pubring.gpg --import
        gpg: keyring `./pubring.gpg' created
        gpg: key 3E4D80EF: public key "Tony Finch (regpg) <fanf9@uis.cam.ac.uk>" imported
        gpg: Total number processed: 1
        gpg:               imported: 1  (RSA: 1)
        $ ls -A
        .git  pubring.gpg  pubring.gpg~

The basic `init` subcommand just creates a `pubring.gpg` file and
imports your public key. Note that 3E4D80EF matches the ID of the key
we generated earlier.

The `pubring.gpg` file lives at the root of your project. It lists the
set of people who can decrypt the secrets. Your encrypted secrets will
live elsewhere in this directory and its subdirectories.

Let's commit what we have so far:

        $ git add pubring.gpg
        $ git commit -m 'Start'


enrol another admin
-------------------

You can list `pubring.gpg` like this:

        $ regpg lskeys
        ./pubring.gpg
        -------------
        pub   4096R/3E4D80EF 2017-10-17
              Key fingerprint = C292 2AB4 1114 30F3 B3B2  483E 1124 9B85 3E4D 80EF
        uid                  Tony Finch (regpg) <fanf9@uis.cam.ac.uk>
        sub   4096R/53E8369C 2017-10-17

Let's add a key. In many cases, each person will enrol their own keys,
but since you are probably following this tutorial by yourself, let's
enrol my key instead.

We'll fetch it into our gpg public key ring in `~/.gnupg`, then copy
it to `regpg`'s `pubring.gpg` using the key ID we were told when we
fetched it:

        $ gpg --fetch-keys https://dotat.at/fanf.gpg
        gpg: key 78D9305F: public key "Tony Finch <dot@dotat.at>" imported
        gpg: Total number processed: 1
        gpg:               imported: 1  (RSA: 1)
        gpg: no ultimately trusted keys found
        $ regpg add 78D9305F
        gpg: key 78D9305F: public key "Tony Finch <dot@dotat.at>" imported
        gpg: Total number processed: 1
        gpg:               imported: 1  (RSA: 1)

Now we have two keys in the keyring:

        $ regpg lskeys
        ./pubring.gpg
        -------------
        pub   4096R/3E4D80EF 2017-10-17
              Key fingerprint = C292 2AB4 1114 30F3 B3B2  483E 1124 9B85 3E4D 80EF
        uid                  Tony Finch (regpg) <fanf9@uis.cam.ac.uk>
        sub   4096R/53E8369C 2017-10-17

        pub   4096R/78D9305F 2017-04-04
              Key fingerprint = D9B6 599A 03AA 1D93 8DC5  A820 72F3 EE0B 78D9 305F
        uid                  Tony Finch <dot@dotat.at>
        uid                  Tony Finch <fanf@FreeBSD.org>
        uid                  Tony Finch <fanf@apache.org>
        uid                  Tony Finch <fanf2@cam.ac.uk>
        uid                  Tony Finch <fanf@exim.org>
        sub   4096R/55317719 2017-04-04

Commit it:

        $ git commit -m 'Enrol Tony Finch' pubring.gpg


hook into git
-------------

For the most part, `regpg` does not get involved in matters of version
control. The exception is that it has a hook for `git diff`. For example,

        $ git show HEAD
        commit 1b9a91eb5b9c4de89eb84a55210c4f90c8d5a309
        Author: Tony Finch <fanf9@uis.cam.ac.uk>
        Date:   Tue Oct 17 20:38:26 2017 +0100

            Enrol Tony Finch

        diff --git a/pubring.gpg b/pubring.gpg
        index 2131596..60d6f1c 100644
        Binary files a/pubring.gpg and b/pubring.gpg differ

This is not a useful diff. You can make it much nicer by installing
`regpg`'s git hook:

        $ regpg init git
        done init -k ./pubring.gpg
        pipe from git check-attr diff ./pubring.gpg
        append to ./.gitattributes
        pipe from git check-attr diff ./*.asc
        append to ./.gitattributes
        running git config diff.gpgkeys.textconv regpg ls -k
        running git config diff.gpgrcpt.textconv regpg ls -k ~/demo/pubring.gpg

`regpg init` is safe to re-run - you can see it observe that
`pubring.gpg` is already initialized, and that the `git diff` hook is
not yet installed.

Now we get a much more useful diff:

        $ git show HEAD
        commit 1b9a91eb5b9c4de89eb84a55210c4f90c8d5a309
        Author: Tony Finch <fanf9@uis.cam.ac.uk>
        Date:   Tue Oct 17 20:38:26 2017 +0100

            Enrol Tony Finch

        diff --git a/pubring.gpg b/pubring.gpg
        index 2131596..60d6f1c 100644
        --- a/pubring.gpg
        +++ b/pubring.gpg
        @@ -1,7 +1,16 @@
        -/tmp/WiBcbL_pubring.gpg
        +/tmp/YvFpSP_pubring.gpg
         -----------------------
         pub   4096R/3E4D80EF 2017-10-17
               Key fingerprint = C292 2AB4 1114 30F3 B3B2  483E 1124 9B85 3E4D 80EF
         uid                  Tony Finch (regpg) <fanf9@uis.cam.ac.uk>
         sub   4096R/53E8369C 2017-10-17

        +pub   4096R/78D9305F 2017-04-04
        +      Key fingerprint = D9B6 599A 03AA 1D93 8DC5  A820 72F3 EE0B 78D9 305F
        +uid                  Tony Finch <dot@dotat.at>
        +uid                  Tony Finch <fanf@FreeBSD.org>
        +uid                  Tony Finch <fanf@apache.org>
        +uid                  Tony Finch <fanf2@cam.ac.uk>
        +uid                  Tony Finch <fanf@exim.org>
        +sub   4096R/55317719 2017-04-04
        +

We need to commit the new file created by `regpg`:

        $ git add .gitattributes
        $ git commit -m 'regpg init git'
        [master 10340c6] regpg init git
         1 file changed, 1 insertion(+)
         create mode 100644 .gitattributes

A couple of things worth noting:

 * You will need to re-run `regpg init git` whenever you create a
   fresh clone of a repository, since `git` does not push or fetch
   the `.git/config` part of the setup. (It would be a remote code
   execution vulnerability!)

 * The git hook does not diff decrypted secrets, because they should
   be kept secret, not displayed. Instead it diffs the keys that are
   able to decrypt the secret. This is intended to help you audit
   changes to the list of people that can access the secrets.


manipulate secrets
------------------

Let's prepare a private key and certificate signing request for a web
server.

First we need a key:

        $ regpg genkey rsa dotat.at.pem.asc
        Generating RSA private key, 2048 bit long modulus
        ......................+++
        ............................+++
        e is 65537 (0x10001)
        $ head -1 dotat.at.pem.asc
        -----BEGIN PGP MESSAGE-----

You can see that it has been generated and encrypted.

We need a CSR configuration file. `regpg` has a handy helper for
making one from an existing certificate (from a file or `https`
server):

        $ regpg csrconf dotat.at dotat.at.csr.conf
        $ cat dotat.at.csr.conf
        [ req ]
        prompt = no
        distinguished_name = distinguished_name
        req_extensions = req_extensions

        [ req_extensions ]
        subjectAltName = @subjectAltName

        [ distinguished_name ]
        commonName                = dotat.at

        [ subjectAltName ]
        DNS.0 = dotat.at
        DNS.1 = www.dotat.at

We can use this to make a CSR. (Normally I would edit it to fit some
new website I am setting up.) The CSR has to be signed by the private
key we generated earlier, so regpg will decrypt it for us:

        $ regpg gencsr dotat.at.pem.asc dotat.at.csr.conf dotat.at.csr

We can then decode the CSR with `openssl req`, pass it to our
certificate authority, etc.

Let's save our work so far:

        $ git add dotat.at.pem.asc dotat.at.csr.conf dotat.at.csr
        $ git commit -m 'TLS key and CSR for dotat.at'
        [master 483f97f] TLS key and CSR for dotat.at
         3 files changed, 87 insertions(+)
         create mode 100644 dotat.at.csr
         create mode 100644 dotat.at.csr.conf
         create mode 100644 dotat.at.pem.asc


change keys and secrets
-----------------------

I don't want my alter ego to have access to this new key. Let's get
rid of the second entry in `pubring.gpg`:

        $ regpg delkey 78D9305F
        gpg (GnuPG) 1.4.18; Copyright (C) 2014 Free Software Foundation, Inc.
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.

        pub  4096R/78D9305F 2017-04-04 Tony Finch <dot@dotat.at>

        Delete this key from the keyring? (y/N) y
        $ regpg lskeys
        ./pubring.gpg
        -------------
        pub   4096R/3E4D80EF 2017-10-17
              Key fingerprint = C292 2AB4 1114 30F3 B3B2  483E 1124 9B85 3E4D 80EF
        uid                  Tony Finch (regpg) <fanf9@uis.cam.ac.uk>
        sub   4096R/53E8369C 2017-10-17

What has happened to our encrypted secret key? Well, nothing! It is
still encrypted to both keys. There are a couple of ways to see this.
I can get a list of all the keys that can decrypt a secret:

        $ regpg lskeys foo.asc
        pub   4096R/3E4D80EF 2017-10-17
              Key fingerprint = C292 2AB4 1114 30F3 B3B2  483E 1124 9B85 3E4D 80EF
        uid                  Tony Finch (regpg) <fanf9@uis.cam.ac.uk>
        sub   4096R/53E8369C 2017-10-17

        pub   4096R/78D9305F 2017-04-04
              Key fingerprint = D9B6 599A 03AA 1D93 8DC5  A820 72F3 EE0B 78D9 305F
        uid                  Tony Finch <dot@dotat.at>
        uid                  Tony Finch <fanf@FreeBSD.org>
        uid                  Tony Finch <fanf@apache.org>
        uid                  Tony Finch <fanf2@cam.ac.uk>
        uid                  Tony Finch <fanf@exim.org>
        sub   4096R/55317719 2017-04-04

Or I can get a diff between the keys in `pubring.gpg` and the keys
that can decrypt the secret:

        $ regpg check
         checking: ./dotat.at.pem.asc
        gpg: error reading key: public key not found
        -pub   4096R/78D9305F 2017-04-04
        -      Key fingerprint = D9B6 599A 03AA 1D93 8DC5  A820 72F3 EE0B 78D9 305F
        -uid                  Tony Finch <dot@dotat.at>
        -uid                  Tony Finch <fanf@FreeBSD.org>
        -uid                  Tony Finch <fanf@apache.org>
        -uid                  Tony Finch <fanf2@cam.ac.uk>
        -uid                  Tony Finch <fanf@exim.org>
        -sub   4096R/55317719 2017-04-04
        -

The red diff deletion output tells us that there is a key with access
to the secret which is not in `pubring.gpg`. We can fix this by running:

        $ regpg recrypt -r

And now the check is clean:

        $ regpg check
         checking: ./dotat.at.pem.asc

Commit this change:

        $ git commit -am 'Shun Tony Finch'
        [master d0e76e5] Shun Tony Finch
         2 files changed, 45 insertions(+), 56 deletions(-)
         rewrite dotat.at.pem.asc (96%)
         rewrite pubring.gpg (67%)


hook into ansible
-----------------

This is a bit more elaborate!

First we need a minimal Ansible setup.

        $ cat >inventory
        localhost ansible_connection=local
        ^D
        $ cat >ansible.cfg
        [defaults]
        inventory = inventory
        ^D
        $ git add inventory ansible.cfg
        $ git commit -m 'Start Ansible'
        [master abc6d5f] Start Ansible
         2 files changed, 4 insertions(+)
         create mode 100644 ansible.cfg
         create mode 100644 inventory

Let's run the command first and then we'll have a look at what it did:

        $ regpg init ansible
        done init -k ./pubring.gpg
        pipe from gpg --no-default-keyring --keyring ./pubring.gpg --list-keys --with-colons
        will pipe out to ./gpg-preload.asc
        pipe to gpg --no-default-keyring --keyring ./pubring.gpg --trust-model=always --armor --encrypt --recipient F8A1BC7553E8369C
        write to ./gpg-preload.yml
        write to ./plugins/filter/gpg_d.py
        running ansible localhost -c local -m ini_file -a section=defaults option=filter_plugins value=plugins/filter dest=./ansible.cfg
        localhost | SUCCESS => {
            "changed": true,
            "dest": "./ansible.cfg",
            "gid": 97061,
            "group": "fanf9",
            "mode": "0644",
            "msg": "section and option added",
            "owner": "fanf9",
            "size": 43,
            "state": "file",
            "uid": 97061
        }
        $ ls -A
        .git            ansible.cfg      gpg-preload.yml  plugins      pubring.gpg~
        .gitattributes  gpg-preload.asc  inventory        pubring.gpg

OK, this has added several files. We already know about `.git*` and
`pubring.gpg`. Let's look at the others.

        $ cat ansible.cfg
        [defaults]
        inventory = inventory
        filter_plugins = plugins/filter

`regpg` has added a filter plugin to Ansible's configuration. (You can
run `regpg init ansible` in an existing Ansible project and `regpg`
will safely modify your configuration - in fact `regpg` uses Ansible
to reconfigure Ansible!)

        $ ls plugins/filter
        gpg_d.py

The actual plugin is called `gpg_d`. It is a short Python module which
wraps `gpg --decrypt` in the same way as `regpg decrypt`. You don't
need `regpg` to use this plugin!

The remaining `gpg-preload` files are so you can ensure that
`gpg-agent` is ready at the start of your playbooks. If you are
running Ansible against lots of servers, it can try to decrypt
multiple files concurrently, and `gpg-agent` will ask you for your
passphrase lots of times. (This is probably a bug in `gpg-agent`...)

You can look inside `gpg-preload.asc`:

        $ regpg decrypt gpg-preload.asc
        True$

It just contains "True" which is used by the playbook to prove it has
been decrypted successfully.

You can run the playbook:

        $ ansible-playbook gpg-preload.yml

        PLAY [all] *********************************************************************
        TASK [setup] *******************************************************************
        ok: [localhost]

        TASK [ensure gpg agent is ready] ***********************************************
        ok: [localhost -> localhost] => {
            "changed": false,
            "msg": "All assertions passed"
        }

        PLAY RECAP *********************************************************************
        localhost                  : ok=3    changed=0    unreachable=0    failed=0

Finally, let's commit the results:

        $ git add ansible.cfg gpg-preload.asc gpg-preload.yml plugins/filter/gpg_d.py
        $ git commit -m 'regpg init ansible'
        [master 79d05b3] regpg init ansible
         4 files changed, 61 insertions(+)
         create mode 100644 gpg-preload.asc
         create mode 100644 gpg-preload.yml
         create mode 100644 plugins/filter/gpg_d.py


---------------------------------------------------------------------------

> Part of `regpg` <https://dotat.at/prog/regpg/>
>
> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
> You may do anything with this. It has no warranty.  
> <https://creativecommons.org/publicdomain/zero/1.0/>
