#!/bin/env bash
set -e
set -o pipefail

SUFFIX="$1"
SOURCE_FILE="$2"

source ./environment.sh

echo $SOURCE_FILE
for pkgfile in $(cut -d' ' -f1 $SOURCE_FILE)
do
    ./pacinstall.sh $pkgFile
done
