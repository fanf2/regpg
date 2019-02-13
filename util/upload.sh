#!/bin/sh
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

set -eux

git push --tags dotat master
git push --tags gitlab master
git push --tags github master

rm -f regpg.asc
gpg --detach-sign --armor regpg

rsync -ilrt regpg regpg.asc regpg.html index.html \
	dist doc logo talks \
	chiark:public-html/prog/regpg/
