#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

echo hi
pwd

source /arch-install/environment.sh


SOURCE_FILE="$1"

echo "Pacstrapping from $SOURCE_FILE"
for ext in pacman aur
    for pkgfile in $(cut -d' ' -f1 $SOURCE_FILE | grep ".$ext$")
    do
        echo "Pacstrapping $pkgFile"
        ./pacinstall.sh ./packages/$pkgFile
    done
done
