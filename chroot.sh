#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi
cd /arch-install/

###### Chrooting ######


source ./environment.sh

./copyme.sh
arch-chroot $ROOT_FS /arch-install/chrooted.sh
