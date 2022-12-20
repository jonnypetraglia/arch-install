#!/bin/env bash

TARGET_FILE="$1"
TARGET_DIR="$2"
if [[ -z "$TARGET_DIR" ]]
then
    TARGET_DIR='.'
fi

function build_with_yay {
    echo "Building $1"
    yay -Sw --noconfirm $1 --builddir .
    if ls $pkg/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        pacman -U $pkg/$pkg*.tar.zst
        rm -f $pkg/$pkg*.tar.zst
        # mv $pkg/$pkg*.tar.zst $TARGET_DIR
    fi
}

function aurstrap {
    if [ $(id -u) -eq 0 ]
    then
        echo 'ERROR: Cannot run austrap-file.sh as root'
        exit 1
    else
        echo "Installing $1"
        yay -S --noconfirm $1 --needed
    fi
    if [[ $? -ne 0 ]]
    then
        echo "$1" >> $TARGET_DIR/.failed
    fi
}

targets=$(cut -d' ' -f1 $TARGET_FILE)

rm -f ./.failed

mkdir -p tmp
rm -rf tmp
mkdir -p tmp
cd tmp

for pkg in ${targets[@]}
do
    latest_version="$(curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" | grep "^pkgver" | cut -d'=' -f2)"
    installed_version="$(pacman -Qi $pkg | grep '^Version ')" # | cut -d':' -f2 | cut -d' ' -f1 | cut -d'-' -f1)"
    echo "Latest version of $pkg is $latest_version"
    echo $installed_version
    if [[ "$installed_version" == *"$latest_version"* ]]
    then
        echo "$pkg $latest_version already installed"
        continue
    fi
    if ls $ABSOLUTE_TARGET_DIR/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        echo "Skipping $pkg"
        continue
    fi
    aurstrap $pkg || echo "$pkg" >> ./.failed
    rm -rf *
done
cd ../
rm -rf tmp
