#!/bin/sh

set -eux

V=$(git describe --tags --dirty=.X | perl -pe 's{-(\d+)-g}{.$1.}')
for f in $(git ls-files | egrep -v '^logo/|^talks/|^\.git') "$@"
do	mkdir -p $V/$(dirname $f)
	cp $f $V/$f
done

zip -qr $V.zip $V
tar cf $V.tar $V
xz -k9 $V.tar
gzip -9 $V.tar
rm -R $V

gpg --detach-sign --armor $V.tar.gz
gpg --detach-sign --armor $V.tar.xz
gpg --detach-sign --armor $V.zip

if git rev-parse --verify --quiet $V
then	dist=dist
else	dist=dust
fi

mkdir -p $dist
mv $V.* $dist
