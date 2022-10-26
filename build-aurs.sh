#!/bin/env bash
set -e
set -o pipefail

TARGET_FILE="$1"
RUN_AS=$(whoami)
if [ $(id -u) -eq 0 ]
then
    RUN_AS=nobody
fi


echo "Pacinstalling AUR targets inside $TARGET_FILE"
targets=$(cut -d' ' -f1 $TARGET_FILE)
echo "Targets: $targets"


mkdir -p tmp
echo dir made
rm -rf tmp
echo dir destroyed
mkdir -p tmp
echo dir made
chown $RUN_AS:$RUN_AS tmp
echo chowned
cd tmp
echo "In $(pwd)"


for pkg in ${targets[@]}
do
    echo "Building $pkg"
    curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o PKGBUILD
    sudo -u $RUN_AS makepkg
    echo "Installing $pkg"
    # pacman -U *.tar.*
    mv *.tar.zst ../
    rm -rf *
done
cd ../
rm -rf tmp
ls -1