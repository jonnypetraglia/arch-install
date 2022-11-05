#!/bin/env bash

TARGET_FILE="$1"
TARGET_DIR="$2"
ABSOLUTE_TARGET_DIR="$pwd/$TARGET_DIR"
RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=$MY_USERNAME
fi

function aurstrap {
    if [ $(id -u) -eq 0 ]
    then
        echo "Building $1"
        sudo -u $RUN_AS yay -Sw --noconfirm $1 --builddir .
    else
        echo "Installing $1"
        yay -S --noconfirm $1 --needed
    fi
    if [[ $? -ne 0 ]]
    then
        echo "$1" > "$ABSOLUTE_TARGET_DIR/.failed"
    fi
}

targets=$(cut -d' ' -f1 $TARGET_FILE)

mkdir -p tmp
rm -rf tmp
mkdir -p tmp
cd tmp

for pkg in ${targets[@]}
do
    latest_version="$(curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" || echo "!" | grep "^pkgver" | cut -d'=' -f2)"
    installed_version="$(pacman -Qi $pkg | grep '^Version ')" # | cut -d':' -f2 | cut -d' ' -f1 | cut -d'-' -f1)"
    if [[ "$installed_version" == *"$latest_version"* ]]
    then
        echo "$1 $latest_version already installed"
        continue
    fi
    if ls $ABSOLUTE_TARGET_DIR/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        echo "Skipping $pkg"
        continue
    fi
    aurstrap $pkg || echo "$1" > "$pkg/.failed"
    if ls $pkg/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        mv $pkg/$pkg*.tar.zst $ABSOLUTE_TARGET_DIR
    fi
    rm -rf *
done
cd ../
rm -rf tmp
