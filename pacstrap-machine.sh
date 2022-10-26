#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

cd /arch-install # TODO Get around this...
source ./environment.sh

if [ ! -f "machines/$MY_HOSTNAME" ]
then
    echo "No machine configuration found for $MY_HOSTNAME"
    exit 404
fi


SOURCE_FILE="$1"

echo "Pacstrapping from $SOURCE_FILE"
for ext in pacman aur
do
    echo "lol $ext"
    for pkgfile in $(cut -d' ' -f1 $SOURCE_FILE)
    do
        echo "Pacstrapping $pkgfile"
        ./pacinstall.sh ./packages/$pkgfile
    done
done
