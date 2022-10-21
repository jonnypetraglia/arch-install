#!/bin/env bash
set -e
set -o pipefail

SUFFIX="$1"
SOURCE_FILE="$2"
ROOT_FS="$3"


for pkgfile in $(cut -d' ' -f1 $SOURCE_FILE)
do
    if [[ $pkgfile == *aur ]]
    then
        
    fi
    cat "packages/$pkgfile" | pacstrap -G -M $ROOT_FS
done