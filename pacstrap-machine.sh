#!/bin/env bash

SUFFIX="$1"
SOURCE_FILE="$2"
ROOT_FS="$3"


for pkgfile in $(cat $SOURCE_FILE)
do
    if [[ $pkgfile == *aur ]]
    then
        
    fi
    cat "packages/$pkgfile" | pacstrap $ROOT_FS
done