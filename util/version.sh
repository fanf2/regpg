#!/bin/sh
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

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
(*.X)	files="regpg.pl"
	skip=:
	;;
(*)	files="regpg.pl README.md"
	skip=
	;;
esac

perl -pi -e 's{regpg-\d+(\.\d+)+(\.X)?}{'$V'}' $files

$skip make clean all test

git commit -a -m $V
$skip git tag -s -m $V $V
