#!/bin/env bash
set -e
set -o pipefail

source ./environment.sh

DEST_DIR="$1"

echo "Aurstrapping for $MY_HOSTNAME into $DEST_DIR"
mkdir -p $DEST_DIR
for pkgfile in $(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".aur$")
do
    echo "Aurstrapping $pkgfile"
    ./build-aurs.sh ./packages/$pkgfile $DEST_DIR
done