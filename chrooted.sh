#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

###### Post-arch-chroot ######

source ./environment.sh

BOOTLOADER='systemd-boot'



# # Packages
# /arch-install/pacstrap-machine.sh "/arch-install/machines/$MY_HOSTNAME"

# # Timezone
# hwclock --systohc

# # Localization
# locale-gen

# # Initramfs
# mkinitcpio -P

# Bootloader
case "$BOOTLOADER" in
    'systemd-boot')
        bootctl install
        ;;
    'grub')
        pacman -S grub os-prober
        grub-mkconfig -o /boot/grub/grub.cfg
        grub-install $(mount | grep ' on / ' | cut -d' ' -f1) # TODO: On root
        e2label "${selected_disk_name}1" $MY_HOSTNAME
        ;;
esac

# Services
for serv in dhcpcd lightdm reflector sshd syncthing
    if [ $(systemctl list-unit-files "${1}.service*" | wc -l) -gt 3 ]
        systemctl enable $1.service
    then
    fi
done

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
