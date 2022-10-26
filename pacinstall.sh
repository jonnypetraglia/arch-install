#!/bin/env bash
set -e
set -o pipefail

TARGET_FILE="$1"
source /arch-install/environment.sh


if [[ $TARGET_FILE == *aur ]]
then
    targets=$(cut -d' ' -f1 $TARGET_FILE)
    mkdir -p ./tmp_build
    rm -rf ./tmp_build
    mkdir -p ./tmp_build
    cd ./tmp_build
    chown nobody:nobody ./
    echo "Pacinstalling AUR targets inside $TARGET_FILE"
    echo targets | while read $pkg
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
    pacman -S $(cut -d' ' -f1 $TARGET_FILE) --needed --noconfirm
fi
