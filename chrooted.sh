#!/bin/env bash
if [ $(id -u) -ne 0 ]
then
    echo'Script must be run as root'
    exit 403
fi

###### Post-arch-chroot ######

source ./environment.sh


# Timezone
hwclock --systohc

# Localization
locale-gen

# Initramfs
mkinitcpio -P

# Bootloader
bootctl install # systemd-boot

# Services
systemctl enable bluetooth.service
systemctl enable dhcpcd.service
systemctl enable lightdm.service
systemctl enable reflector.service
systemctl enable sshd.service
systemctl enable syncthing.service

# Language Packages
cat ./packages/*fisher | fish install
npm install --global $(cat ./packages/*npm)
gem install $(cat ./packages/*gem)
pip install $(cat ./packages/*pip)
cargo install $(cat ./packages/*cargo)
go install $(cat ./packages/*go)


# Wrapping up
pacman -Q > /installed_packages.txt

echo "Finished! Enjoy using $MY_HOSTNAME!"
