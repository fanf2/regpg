#!/bin/sh

case $# in
(1)	N=$1
	V=regpg-$N
	;;
(*)	echo 1>&2 'usage: util/reversion.sh <number>'
	exit 1
	;;
esac

perl -pi -e 's{regpg-\d+(\.\d+)+}{'$V'}' \
	README.md regpg

git commit -a -m $V
git tag -s -m $V $V
