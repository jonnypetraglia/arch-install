#!/bin/env bash

TARGET_FILE="$1"
TARGET_DIR="$2"

RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=nobody
fi

function aurstrap {
    if [ -z $TARGET_DIR ]
    then
        sudo -u $RUN_AS yay -S --noconfirm $1
    else
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
    if ls $TARGET_DIR/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        echo "Skipping $pkg"
        continue
    fi
    echo "Building $pkg"
    aurstrap $pkg
    if ls $pkg/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        mv $pkg/$pkg*.tar.zst $TARGET_DIR
    fi
    rm -rf *
done
cd ../
rm -rf tmp
