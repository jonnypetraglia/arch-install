#!/bin/env bash
set -e
set -o pipefail

./disksetup.sh
./copyme.sh
./prechroot.sh
arch-chroot $ROOT_FS /arch-install/chrooted.sh
