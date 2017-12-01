#!/bin/sh
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

set -eux

case $# in
(1)	V=regpg-$1
	;;
(*)	echo 1>&2 'usage: util/version.sh <number>'
	exit 1
	;;
esac

seddery() {
	local version="$1"
	shift
	perl -pi -e 's{regpg-\d+(\.\d+|\.X)+}{'$version'}' "$@"
	git commit -a -m $version
}

make clean all test

seddery $V regpg.pl README.md
git tag -s -m $V $V

make release upload

seddery $V.X regpg.pl
