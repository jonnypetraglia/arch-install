#!/bin/env bash

TARGET_FILE="$1"
TARGET_DIR="$2"
ABSOLUTE_TARGET_DIR="$pwd/$TARGET_DIR"

RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=nobody
fi

function aurstrap {
    touch .
    if [ -z "$TARGET_DIR" ]
    then
        echo "Installing $1"
        sudo -u $RUN_AS yay -S --noconfirm $1 --needed
    else
        echo "Building $1"
        sudo -u $RUN_AS yay -Sw --noconfirm $1 --builddir .
    fi
}


targets=$(cut -d' ' -f1 $TARGET_FILE)

mkdir -p tmp
rm -rf tmp
mkdir -p tmp
chown $RUN_AS:$RUN_AS tmp
cd tmp

for pkg in ${targets[@]}
do
    if ls $ABSOLUTE_TARGET_DIR/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        echo "Skipping $pkg"
        continue
    fi
    aurstrap $pkg
    if ls $pkg/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        mv $pkg/$pkg*.tar.zst $ABSOLUTE_TARGET_DIR
    fi
    rm -rf *
done
cd ../
rm -rf tmp