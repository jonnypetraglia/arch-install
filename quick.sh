#!/bin/env bash
set -e
set -o pipefail

./disksetup.sh
echo 'Disk setup complete!'


read -pr 'Press any key to run pre-chroot setup...'
clear
./prechroot.sh
echo 'Pre-chroot setup complete!'


read -pr 'Press any key to run the chrooted setup...'
clear
./chroot.sh
