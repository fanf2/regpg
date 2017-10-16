#!/bin/sh
git push --tags github master
git push --tags dotat master
git push --tags uis master
ln -sf README.html index.html
rsync -ilrt regpg *.html dist doc \
	chiark:public-html/prog/regpg/
rm -f index.html
