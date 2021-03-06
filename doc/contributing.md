contributing to regpg
=====================

If you have any comments, suggestions, or bug reports, please email
them to me at <fanf2@cam.ac.uk> or <dot@dotat.at>, or submit them via
GitHub.

If you would like to contribute code, tests, or documentation,
please state explicitly whether your work is CC0 or GPLv3, and
include a Signed-off-by: line to certify that you wrote it or
otherwise have the right to pass it on as a open-source patch,
according to the Developer's Certificate of Origin 1.1
<https://developercertificate.org>

----------------------------------------------------------------

building `regpg`
----------------

The source archives (see "Downloads" in the `README`) are distributed
ready-built, so you should only need to build `regpg` if you are
installing from `git` (see "Repositories" in the `README`).

The following `make` targets are supported:

* `install` - install the script and man page
* `uninstall` - remove installed files

* `all` - build the main script and documentation
* `test` - run the test suite
* `clean` - remove build artefacts and test droppings

----------------------------------------------------------------

release process
---------------

        ./util/version.sh 1.2

The `util/version.sh` makes a signed tag for the new version, builds
and sign release tarballs in `./dist/`, uploads the release, and marks
`regpg.pl` with an unknown patch level post release.

When you `make upload` the current patchlevel script is published at
<https://dotat.at/prog/regpg/regpg>.

You can `make release` any time to get patchlevel tarballs in `./dust/`

----------------------------------------------------------------

overall licence - GPLv3
-----------------------

The overall licence for regpg is the GPLv3, same as GnuPG and Ansible.
There is a copy of the GPL distributed with regpg in the file `COPYING`.

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

The GPL applies to:

  * `regpg.pl` itself

  * the documentation in the `doc` directory and the `README.md` file

  * the `logo` directory; `GnuPG.svg` is based on the GnuPG logo

  * `ansible/action.py` which is based on Ansible's `template.py` action plugin

  * the tests in the `t` directory

----------------------------------------------------------------

licence - CC0 pieces
--------------------

Several `regpg` support files are public domain (CC0)
<https://creativecommons.org/publicdomain/zero/1.0/>:

  * the `Makefile` and the build scripts in the `util` directory

  * the hook scripts in the `ansible` directory other than `action.py`

These CC0 files are likely to be incorporated into other projects,
so they are released under the least restrictive terms possible.

----------------------------------------------------------------

licence - talks
---------------

The `talks` directory in the `regpg` git repository is not
included in the `regpg` release tarballs.

Most of the images are released under various Creative Commons
licences. Each image should have a link to its source.

The non-image files (TeX source and `Makefile`) are public domain (CC0).

----------------------------------------------------------------

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
