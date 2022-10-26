#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

###### Post-arch-chroot ######

cd /arch-install
source ./environment.sh

BOOTLOADER='systemd-boot'



# # Timezone
hwclock --systohc

# # Localization
locale-gen

# # Initramfs
mkinitcpio -P

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



# AUR Packages
./aurstrap.sh $MY_HOSTNAME
# Or if they were generated ahead of time (WIP) this:
# pacman -U ./aurstrap

# Services
for serv in dhcpcd lightdm reflector sshd syncthing
do
    if [ $(systemctl list-unit-files "${1}.service*" | wc -l) -gt 3 ]
    then
        systemctl enable $1.service
    fi
done

# Language Packages
function ifexists {
    command -v $1 >/dev/null 2>&1
}
ifexists fish && cat ./packages/*fisher | fish install
ifexists npm && npm install --global $(cat ./packages/*npm)
ifexists gem && gem install $(cat ./packages/*gem)
ifexists pip && pip install $(cat ./packages/*pip)
ifexists cargo && cargo install $(cat ./packages/*cargo)
ifexists go && go install $(cat ./packages/*go)


# Wrapping up
pacman -Q > /installed_packages.txt

echo "Finished! Enjoy using $MY_HOSTNAME!"
