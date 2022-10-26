#!/bin/env bash
set -e
set -o pipefail

# source ./environment.sh

MY_HOSTNAME="$1"

THIS_DIR="${BASH_SOURCE[0]%/*}"

if [ -z "$MY_HOSTNAME"]
then
    pkgfiles=$(ls -d $THIS_DIR/packages/*.aur)
else
    echo "Aurstrapping for $MY_HOSTNAME"
    pkgfiles=$(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".aur$")
fi

for pkgfile in ${pkgfiles[@]}
do
    echo "Aurstrapping $pkgfile"
    $THIS_DIR/build-aurs.sh $pkgfile
done