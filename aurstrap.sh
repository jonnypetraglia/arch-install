#!/bin/env bash
set -e
set -o pipefail

# source ./environment.sh

THIS_DIR="${BASH_SOURCE[0]%/*}"
MY_HOSTNAME="$1" # pass in as '*' to do all files with a TARGET_DIR
TARGET_DIR="$2"


if [ -z "$MY_HOSTNAME" ]
then
    echo "Specify hostname file (from machines directory). Pass '*' to include ALL AUR packages."
    exit 1
elif [ "$MY_HOSTNAME" = '*' ]
then
    pkgfiles=$(ls $THIS_DIR/packages/*.aur |xargs -0 -n 1 basename)
else
    echo "Aurstrapping for $MY_HOSTNAME"
    pkgfiles=$(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".aur$")
fi

for pkgfile in ${pkgfiles[@]}
do
    echo "Aurstrapping $pkgfile"
    $THIS_DIR/aurstrap-file.sh $THIS_DIR/packages/$pkgfile $TARGET_DIR
done