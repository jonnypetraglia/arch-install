#!/bin/env bash
set -e
set -o pipefail

# source ./environment.sh

THIS_DIR="${BASH_SOURCE[0]%/*}"
MY_HOSTNAME="$1" # pass in as '*' to do all files with a TARGET_DIR
TARGET_DIR="$2"


if [ -z "$MY_HOSTNAME" ]
then
    pkgfiles=$(ls $THIS_DIR/packages/*.aur)
else
    echo "Aurstrapping for $MY_HOSTNAME"
    pkgfiles=$(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".aur$")
fi

for pkgfile in ${pkgfiles[@]}
do
    echo "Aurstrapping $pkgfile"
    $THIS_DIR/build-aurs.sh $THIS_DIR/packages/$pkgfile $TARGET_DIR
done