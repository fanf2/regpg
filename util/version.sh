#!/bin/sh

set -eux

case $# in
(1)	N=$1
	V=regpg-$N
	;;
(*)	echo 1>&2 'usage: util/reversion.sh <number>'
	exit 1
	;;
esac

case $N in
(*.X)	files="regpg"
	skip=:
	;;
(*)	files="regpg README.md"
	skip=
	;;
esac

make clean all test

perl -pi -e 's{regpg-\d+(\.\d+)+(\.X)?}{'$V'}' $files

git commit -a -m $V
$skip git tag -s -m $V $V
