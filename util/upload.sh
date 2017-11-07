#!/bin/sh
git push --tags github master
git push --tags dotat master
git push --tags uis master

V=$(git describe | sed 's/-g.*//;s/-/./g;s/\./-/')
perl -pi -e 's{regpg-\d+(\.\d+)+}{'$V'}' regpg
ln -sf README.html index.html

rsync -ilrt regpg *.html dist doc \
	chiark:public-html/prog/regpg/

git checkout regpg
rm -f index.html
