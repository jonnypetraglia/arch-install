#!/bin/env bash
TARGET_FILE="$1"
RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=nobody
fi


targets=$(cut -d' ' -f1 $TARGET_FILE)

mkdir -p tmp
rm -rf tmp
mkdir -p tmp
chown $RUN_AS:$RUN_AS tmp
cd tmp

for pkg in ${targets[@]}
do
    if ls ../aurstrap/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        echo "Skipping $pkg"
        continue
    fi
    echo "Building $pkg"
    yay -Sw --noconfirm $pkg --builddir .
    if ls $pkg/$pkg*.tar.zst 1> /dev/null 2>&1
    then
        mv $pkg/$pkg*.tar.zst ../aurstrap
    fi
    rm -rf *
done
cd ../
rm -rf tmp
