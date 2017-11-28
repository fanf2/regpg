#!/bin/sh

set -eux

git push --tags github master
git push --tags dotat master
git push --tags uis master

gpg --detach-sign --armor regpg

rsync -ilrt regpg regpg.asc regpg.html index.html \
	dist doc logo talks \
	chiark:public-html/prog/regpg/
