#!/bin/sh

set -eux

git push --tags github master
git push --tags dotat master
git push --tags uis master

V=$(git describe | perl -pe 's{-(\d+)-\w+}{.$1}')
perl -pi -e 's{regpg-\d+(\.\d+)+(\.X)?}{'$V'}' regpg
gpg --detach-sign --armor regpg

rsync -ilrt regpg regpg.asc regpg.html index.html \
	dist doc logo talks \
	chiark:public-html/prog/regpg/

git checkout regpg
rm -f regpg.asc
