#!/bin/env bash
set -e
set -o pipefail

if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

###### Inside Live CD ######

source ./environment.sh

if [ ! -f "machines/$MY_HOSTNAME" ]
then
    echo "No machine configuration found for $MY_HOSTNAME"
    exit 404
fi

# Pacstrap basic system
pacman --needed -Sy archlinux-keyring --noconfirm
pacman --needed -S arch-install-scripts --noconfirm
pacstrap -K $ROOT_FS base linux linux-firmware

# Timezone
ln -sf /usr/share/zoneinfo/US/$MY_TIMEZONE $ROOT_FS/etc/localtime

# Localization
echo 'en_US.UTF-8 UTF-8' > $ROOT_FS/etc/locale.gen # TODO: Is this needed?
echo 'LANG=en_US.UTF-8' > $ROOT_FS/etc/locale.conf

# Network Configuration
echo $MY_HOSTNAME > $ROOT_FS/etc/hostname
echo "127.0.0.1     localhost" > $ROOT_FS/etc/hosts
echo "::1           localhost" >> $ROOT_FS/etc/hosts
echo "127.0.0.1     $MY_HOSTNAME.localhost      localhost" >> $ROOT_FS/etc/hosts
echo 'domain Home' > $ROOT_FS/resolv.conf
echo "nameserver $MY_ROUTER_IP" >> $ROOT_FS/resolv.conf
echo 'nameserver 8.8.8.8' >> $ROOT_FS/resolv.conf

# Users
echo "$MY_USERNAME:x:1000:1000::/home/$MY_USERNAME:/usr/bin/fish" >> $ROOT_FS/etc/passwd
echo "$MY_USERNAME:x:1000:" >> $ROOT_FS/etc/group

echo "root:$ROOT_PASSWORD_ENC:19085::::::" > $ROOT_FS/etc/shadow
echo "$MY_USERNAME:$MY_PASSWORD_ENC:19245:0:99999:7:::" > $ROOT_FS/etc/shadow
echo "$MY_USERNAME:!::" > $ROOT_FS/etc/gshadow
echo "sambashare:!::$MY_USERNAME" > $ROOT_FS/etc/gshadow

echo "root  ALL=(ALL:ALL)   ALL" > $ROOT_FS/etc/sudoers
echo "$MY_USERNAME  ALL=(ALL:ALL)   ALL" >> $ROOT_FS/etc/sudoers


# Misc System
echo "fs.inotify.max_user_watches=1000000" >> $ROOT_FS/etc/sysctl.d/90-override.conf


# TODO dotfiles here?

# Packages
arch-chroot $ROOT_FS ./pacstrap-machine.sh $ext  "machines/$MY_HOSTNAME"     $ROOT_FS

echo "Live CD portion complete. Running chroot portion."
arch-chroot $ROOT_FS ./chrooted.sh

