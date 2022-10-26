#!/bin/env bash
set -e
set -o pipefail

TARGET_FILE="$1"
source ./environment.sh


if [[ $TARGET_FILE == *aur ]]
then
    mkdir -p ./tmp_build
    rm -rf ./tmp_build
    mkdir -p ./tmp_build
    cd ./tmp_build
    chown nobody:nobody ./
    echo "Pacinstalling AUR targets inside $TARGET_FILE"
    cut -d' ' -f1 $TARGET_FILE | while read $pkg
    do
        echo "Building $pkg"
        sudo -u nobody curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o PKGBUILD
        sudo -u nobody makepkg -i
        echo "Build $pkg"
    done
    cd ../
    rm -rf tmp_build
else
    echo "Pacinstalling Pacman packages inside $TARGET_FILE"
    pacman -S $ROOT_FS $(cut -d' ' -f1 $TARGET_FILE) --needed --noconfirm
fi
