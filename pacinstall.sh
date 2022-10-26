#!/bin/env bash
set -e
set -o pipefail

TARGET_FILE="$1"

whoami
exit 0

if [[ $TARGET_FILE == *aur ]]
then
    echo "Pacinstalling AUR targets inside $TARGET_FILE"
    targets=$(cut -d' ' -f1 $TARGET_FILE)
    echo "Targets: $targets"
    mkdir -p /tmp/install
    echo dir made
    rm -rf /tmp/install
    echo dir destroyed
    mkdir -p /tmp/install
    echo dir made
    chown nobody:nobody /tmp/install
    echo chowned
    cd /tmp/install
    echo "In $(pwd)"
    for pkg in "${targets[@]}"
    do
        echo "Building $pkg"
        curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o PKGBUILD
        echo "Build $pkg"
        sudo -u nobody makepkg
        echo "Installing $pkg"
        sudo pacman -U *.tar.*
        rm -rf *
    done
    cd ../
    rm -rf /tmp/install
else
    echo "Pacinstalling Pacman packages inside $TARGET_FILE"
    sudo pacman -S $(cut -d' ' -f1 $TARGET_FILE) --needed --noconfirm
fi
