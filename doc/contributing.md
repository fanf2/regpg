contributing to regpg
=====================

All the files in this distribution have the CC0 licence:

> Written by Tony Finch <fanf2@cam.ac.uk> <dot@dotat.at>  
> at Cambridge University Information Services.  
> You may do anything with this. It has no warranty.  
> <https://creativecommons.org/publicdomain/zero/1.0/>

The logo is licenced according to the GPLv2 or later, since it is
based on the GnuPG logo. It is maintained in this git repository but
is not included in the distribution files.

If you have any comments, suggestions, or bug reports, please email
them to me at either address above.

If you would like to contribute code or documentation, please state
explicitly that your work is also CC0, or include a Signed-off-by:
line to certify that you wrote it or otherwise have the right to pass
it on as a open-source patch, according to the Developer's Certificate
of Origin 1.1 <https://developercertificate.org>


release process
---------------

* make a signed tag for the new version

        ./util/version 1.2

* build and sign release tarballs in `./dist/`

        make release

* set an unknown patch level post release

        ./util/version 1.2.X

* publish

        make upload

You can `make release` any time to get patchlevel tarballs in `./dust/`
