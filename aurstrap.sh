#!/bin/env bash
set -e
set -o pipefail

source ./environment.sh

THIS_DIR="${BASH_SOURCE[0]%/*}"

echo "Aurstrapping for $MY_HOSTNAME"
for pkgfile in $(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".aur$")
do
    echo "Aurstrapping $pkgfile"
    $THIS_DIR/build-aurs.sh $THIS_DIR/packages/$pkgfile
done