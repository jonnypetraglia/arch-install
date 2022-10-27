#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

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
echo "Installed $BOOTLOADER"

# Language Packages

function ifexists {
    command -v $1 >/dev/null 2>&1
}
function hasfiles {
    ls ./packages/*.$1 >/dev/null 2>&1 &&
}
ifexists fish   && hasfiles fish    && cat ./packages/*fisher | sudo -u $MY_USERNAME fish install
ifexists npm    && hasfiles npm     && npm install --global $(cat ./packages/*.npm | uniq)
ifexists gem    && hasfiles gem     && gem install $(cat ./packages/.*gem | uniq)
ifexists pip    && hasfiles pip     && pip install $(cat ./packages/*.pip | uniq)
ifexists cargo  && hasfiles cargo   && sudo -u $MY_USERNAME cargo install $(cat ./packages/*.cargo | uniq)
ifexists go     && hasfiles go      && sudo -u $MY_USERNAME go install $(cat ./packages/*.go | uniq)



# # AUR Package manager
sudo -u $MY_USERNAME ./aur-build.sh yay
pacman -U ./yay-*.tar.zst --noconfirm
rm yay-*.tar.zst


# # AUR Packages
./aurstrap.sh

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
