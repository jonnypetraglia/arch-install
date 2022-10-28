#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi
cd /arch-install

###### Post-arch-chroot ######

# cd /arch-install
source ./environment.sh

BOOTLOADER='systemd-boot'


# Timezone
hwclock --systohc

# Localization
locale-gen

# Initramfs
mkinitcpio -P

# Bootloader
echo "Installing $BOOTLOADER"
function install_systemd {
    bootctl install
    (
        echo "title Arch Linux"
        echo 'linux /vmlinuz-linux'
        echo 'initrd /initramfs-linux.img'
        echo "root=PARTUUID=$(get_root_uuid)"
    ) > /boot/loader/entries/$MY_HOSTNAME.conf
    bootctl install
    (
        echo "title Arch Linux fallback"
        echo 'linux /vmlinuz-linux'
        echo 'initrd /initramfs-linux-fallback.img'
        echo "root=PARTUUID=$(get_root_uuid)"
    ) > /boot/loader/entries/$MY_HOSTNAME_fallback.conf
}
function get_root_uuid {
    root_disk=$(mount | grep 'on / ' | cut -d' ' -f1)
    blkid | grep "^$root_disk" | grep -oP 'PARTUUID="\K[^"]+'
}
function install_grub {
    pacman -S grub os-prober --needed
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-install $(mount | grep ' on /boot ' | cut -d' ' -f1)
}
case "$BOOTLOADER" in
    'systemd-boot')
        install_systemd
        ;;
    'grub')
        install_grub
        ;;
esac
echo "Installed $BOOTLOADER"

# Pacstrap machine-specific system
pacman-key --init
pacman-key --populate
for pkgfile in $(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".pacman$")
do
    pkgfile_pkgs=$(cut -d' ' -f1 packages/$pkgfile)
    echo "Pacstrapping:" $pkgfile_pkgs
    read -p 'Press any key to continue...'
    pacman -S $pkgfile_pkgs --needed --noconfirm
done

# AUR Package manager
pacman -S sudo --needed
if [ ! -z "$(command -v yay)" ]
then
    echo "Installing Yay"
    sudo -u $MY_USERNAME ./aur-build.sh yay
    pacman -U ./yay-*.tar.zst --noconfirm
    rm yay-*.tar.zst
fi

# AUR Packages
./aurstrap.sh

# Language Packages
function ifexists {
    command -v $1 >/dev/null 2>&1
}
function haspackages {
    ls ./packages/*.$1 >/dev/null 2>&1
}
ifexists fish   && haspackages fish     && cat ./packages/*fisher | sudo -u $MY_USERNAME fish install
ifexists npm    && haspackages npm      && npm install --global $(cat ./packages/*.npm | uniq)
ifexists gem    && haspackages gem      && gem install $(cat ./packages/.*gem | uniq)
ifexists pip    && haspackages pip      && pip install $(cat ./packages/*.pip | uniq)
ifexists cargo  && haspackages cargo    && sudo -u $MY_USERNAME cargo install $(cat ./packages/*.cargo | uniq)
ifexists go     && haspackages go       && sudo -u $MY_USERNAME go install $(cat ./packages/*.go | uniq)


# Services
SYSTEMD_SERVICES=$(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".service$")
for serv in ${SYSTEMD_SERVICES[@]}
do
    if [ $(systemctl list-unit-files "${1}.service*" | wc -l) -gt 3 ]
    then
        systemctl enable $1.service
    fi
done



# Wrapping up
pacman -Q > /installed_packages.txt

echo "Finished! Enjoy using $MY_HOSTNAME!"
