#!/bin/env bash
set -e
set -o pipefail

SOURCE_FILE="$2"

source ./environment.sh

echo "Pacstrapping from $SOURCE_FILE"
for ext in pacman aur
    for pkgfile in $(cut -d' ' -f1 $SOURCE_FILE | grep ".$ext$")
    do
        echo "Pacstrapping $pkgFile"
        ./pacinstall.sh ./packages/$pkgFile
    done
done
