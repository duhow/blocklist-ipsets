#!/bin/bash

set -eu

FILE_SOURCE=source
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
ENTRIES=`grep -ve '^#' -ve '^$' $FILE_SOURCE | wc -l`

export DATE COMMIT ENTRIES

envsubst < template > $TARGET

grep -ve '^#' -ve '^$' $FILE_SOURCE >> $TARGET
