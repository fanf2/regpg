#!/bin/sh

set -eux

git push --tags github master
git push --tags dotat master
git push --tags uis master

V=$(git describe | perl -pe 's{-(\d+)-\w+}{.$1}')
perl -pi -e 's{regpg-\d+(\.\d+)+(\.X)?}{'$V'}' regpg
gpg --detach-sign --armor regpg
ln -sf README.html index.html

rsync -ilrt regpg regpg.asc *.html dist doc \
	chiark:public-html/prog/regpg/

git checkout regpg
rm -f index.html regpg.asc
