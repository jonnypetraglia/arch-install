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

DEFAULT_PACSTRAP="base linux linux-firmware sudo"

function generate_fstab {
    echo "Generating $ROOT_FS/etc/fstab"
    mkdir -p $ROOT_FS/etc
    genfstab -U $ROOT_FS > $ROOT_FS/etc/fstab
}
function pacstrap_system {
    pacman -Sy
    pacman -S archlinux-keyring --needed --noconfirm
    pacman -S arch-install-scripts --needed --noconfirm
    pacstrap $ROOT_FS $DEFAULT_PACSTRAP
    arch-chroot $ROOT_FS pacman-key --init
    arch-chroot $ROOT_FS pacman-key --populate
}
function set_timezone_and_locale {
    ln -sf /usr/share/zoneinfo/US/$MY_TIMEZONE $ROOT_FS/etc/localtime
    echo 'en_US.UTF-8 UTF-8' > $ROOT_FS/etc/locale.gen # TODO: Is this needed?
    echo 'LANG=en_US.UTF-8' > $ROOT_FS/etc/locale.conf
}
function write_network_configuration {
    echo $MY_HOSTNAME > $ROOT_FS/etc/hostname
    echo "127.0.0.1     localhost" > $ROOT_FS/etc/hosts
    echo "::1           localhost" >> $ROOT_FS/etc/hosts
    echo "127.0.0.1     $MY_HOSTNAME.localhost      localhost" >> $ROOT_FS/etc/hosts
    echo 'domain Home' > $ROOT_FS/resolv.conf
    echo "nameserver $MY_ROUTER_IP" >> $ROOT_FS/resolv.conf
    echo 'nameserver 8.8.8.8' >> $ROOT_FS/resolv.conf
}
function configure_users {
    # Set root password
    echo "root:$ROOT_PASSWORD_ENC:19085::::::" > $ROOT_FS/etc/shadow
    # Creating user
    echo "$MY_USERNAME:x:1000:1000::/home/$MY_USERNAME:/usr/bin/fish" >> $ROOT_FS/etc/passwd
    echo "$MY_USERNAME:x:1000:" >> $ROOT_FS/etc/group
    # Shadow files
    echo "$MY_USERNAME:$MY_PASSWORD_ENC:19245:0:99999:7:::" >> $ROOT_FS/etc/shadow
    echo "$MY_USERNAME:!::" >> $ROOT_FS/etc/gshadow
    echo "sambashare:!::$MY_USERNAME" >> $ROOT_FS/etc/gshadow
    # Sudoers
    echo "root  ALL=(ALL:ALL)   ALL" > $ROOT_FS/etc/sudoers
    echo "$MY_USERNAME  ALL=(ALL:ALL)   ALL" >> $ROOT_FS/etc/sudoers
}
function misc_configuration {
    echo "fs.inotify.max_user_watches=1000000" >> $ROOT_FS/etc/sysctl.d/90-override.conf
}


./copyme.sh     # Copy install scripts into new system
generate_fstab
pacstrap_system
set_timezone_and_locale
write_network_configuration
configure_users
misc_configuration

# TODO dotfiles here?


echo "Live CD portion complete. Run chroot.sh"
