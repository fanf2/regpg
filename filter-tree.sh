#!/bin/sh

git ls-files |
egrep -v 'regpg|gpg_d|gpg-preload.yml' |
xargs git rm -f
if	[ -f bin/regpg ]
then	git mv -f bin/regpg regpg
fi
