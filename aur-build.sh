#!/bin/env bash
set -e
set -o pipefail
##
# This script builds a package in the AUR
# ....but it skips it if the latest version is already installed???
##

RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=$MY_USERNAME
fi

mkdir -p ./build
chown $RUN_AS:$RUN_AS build
cd build
echo "Building $1"
curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1" -o PKGBUILD

latest_version="$(cat ./PKGBUILD | grep "^pkgver" | cut -d'=' -f2)"
installed_version="$(pacman -Qi yay | grep '^Version ')" # | cut -d':' -f2 | cut -d' ' -f1 | cut -d'-' -f1)"

if [[ "$installed_version" == *"$latest_version"* ]]
then
    echo "$1 $latest_version already installed"
else
    sudo -u $RUN_AS makepkg -f
    if [[ $? -eq 0 ]]
    then
        mv *.tar.zst ../
    else
        echo "$1" >> .failed
    fi
fi
rm -rf *
cd ..
rm -rf build
