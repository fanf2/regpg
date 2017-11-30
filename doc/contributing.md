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

Several `regpg` support files are public domain (CC0)
<https://creativecommons.org/publicdomain/zero/1.0/>:

  * the `Makefile` and the build scripts in the `util` directory

  * the hook scripts in the `ansible` directory other than `action.py`

These CC0 files are likely to be incorporated into other projects,
so they are released under the least restrictive terms possible.

----------------------------------------------------------------

### release process

* make a signed tag for the new version

        ./util/version 1.2

* build and sign release tarballs in `./dist/`

        make release

* set an unknown patch level post release

        ./util/version 1.2.X

* publish

        make upload

You can `make release` any time to get patchlevel tarballs in `./dust/`

----------------------------------------------------------------
