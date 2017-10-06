#!/bin/sh

git init
git fetch ucs@git.csx.cam.ac.uk:git/gitcam
git checkout -b master FETCH_HEAD
git filter-branch --force --prune-empty \
    --tree-filter $(pwd)/filter-tree.sh \
    --msg-filter "sed 's/Notes on gitolite setup/start/'" \
    -- --all
git add filter-branch.sh filter-tree.sh
git commit -F - <<EOF
regpg divorced from gitcam repository

This is to prepare for a proper release.

The filter-branch.sh and filter-tree.sh scripts record how
this new repository was cerated.
EOF
git rm -r ansible
git rm filter-branch.sh filter-tree.sh
git commit -F - <<EOF
regpg: clean up divorce scripts and ansible remnants
EOF
