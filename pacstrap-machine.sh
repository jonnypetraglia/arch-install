#!/bin/env bash
set -e
set -o pipefail

cd /arch-install # TODO Get around this...

MY_HOSTNAME="$1"


if [ ! -f "machines/$MY_HOSTNAME" ]
then
    echo "No machine configuration found for $MY_HOSTNAME"
    exit 404
fi

echo "Pacstrapping for $MY_HOSTNAME"
for pkgfile in $(cut -d' ' -f1 machines/$MY_HOSTNAME)
do
    echo "Pacstrapping $pkgfile"
    ./pacinstall.sh ./packages/$pkgfile
done