#!/bin/env bash
set -e
set -o pipefail

SUFFIX="$1"
SOURCE_FILE="$2"
ROOT_FS="$3"



echo $SOURCE_FILE
for pkgfile in $(cut -d' ' -f1 $SOURCE_FILE)
do
    if [[ $pkgfile == *aur ]]
    then
	mkdir -p ./tmp_build
	rm -rf ./tmp_build
	mkdir -p ./tmp_build
	cd ./tmp_build
	chown nobody:nobody ./tmp_build
	echo "AUR $pkgfile"
	cut -d' ' -f1 ../packages/$pkgfile | while read $pkg
	do
	   echo "Building $pkg"
           sudo -u nobody curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$pkg" -o PKGBUILD
           sudo -u nobody makepkg
	done
	sudo pacstrap -G -M -U *.tar.* $ROOT_FS
	cd ../
	rm -rf tmp_build
    else
	    echo "Pacman $pkgfile"
	    sudo pacstrap $ROOT_FS $(cut -d' ' -f1 packages/$pkgfile)
    fi
done
