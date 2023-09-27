#!/bin/bash

set -eu

TARGET=public/blocklist.ipset
mkdir -p public

# if no changes pending, everything is commited
if [ -z "`git status -s`" ]; then
  DATE=`git show -s --format=%ci`
  COMMIT=`git show -s --format=%h`
else
  DATE=`date`
  COMMIT="latest"
fi

export DATE COMMIT

envsubst < template > $TARGET
grep -ve '^#' -ve '^$' source >> $TARGET
