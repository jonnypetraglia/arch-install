#!/bin/env bash
#
# This script calls aurstrap-file.sh with the
# files in the packages directory for the machine
# specified in MY_HOSTNAME
#
set -e
set -o pipefail

source ./environment.sh

THIS_DIR="${BASH_SOURCE[0]%/*}"
TARGET_DIR="$2"


if [ -z "$MY_HOSTNAME" ]
then
    echo "Specify hostname file (from machines directory)."
    exit 1
# elif [ "$MY_HOSTNAME" = '*' ]
# then
#     pkgfiles=$(ls $THIS_DIR/packages/*.aur |xargs -0 -n 1 basename)
else
    echo "Aurstrapping for $MY_HOSTNAME"
    pkgfiles=$(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".aur$")
fi

pacman -S --needed $(cat packages/aur.pacman)
sudo -u $MY_USERNAME $THIS_DIR/aurstrap-file.sh $THIS_DIR/packages/aur.aur $TARGET_DIR

for pkgfile in ${pkgfiles[@]}
do
    if [[ "$pkgfile" != aur.* ]]
    then
        echo "Aurstrapping $pkgfile"
        sudo -u $MY_USERNAME $THIS_DIR/aurstrap-file.sh $THIS_DIR/packages/$pkgfile $TARGET_DIR
    fi
done
