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
	echo "AUR $pkgfile"
	cut -d' ' -f1 ../packages/$pkgfile | while read $pkg
	do
	   echo "Building $pkg"
           sudo -u nobody curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o PKGBUILD
           sudo -u nobody makepkg -i
	done
	cd ../
	rm -rf tmp_build
    else
	    echo "Pacman $pkgfile"
	    pacman -S $ROOT_FS $(cut -d' ' -f1 packages/$pkgfile) --needed --noconfirm
    fi
