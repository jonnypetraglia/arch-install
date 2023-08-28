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
BOOTLOADER='systemd-boot'
source ./environment.sh

function setup_user {
    mkdir -p /home/$MY_USERNAME
    chown $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME
}

function init_system {
    # Timezone
    hwclock --systohc
    # Localization
    locale-gen
    # Initramfs
    mkinitcpio -P
}

# Bootloader
function install_systemd {
    echo "Installing $BOOTLOADER"
    bootctl install
    (
        echo "title Arch Linux"
        echo 'linux /vmlinuz-linux'
        echo 'initrd /initramfs-linux.img'
        echo "options root=UUID=$(get_root_uuid)"
    ) > /boot/loader/entries/$MY_HOSTNAME.conf
    bootctl install
    (
        echo "title Arch Linux fallback"
        echo 'linux /vmlinuz-linux'
        echo 'initrd /initramfs-linux-fallback.img'
        echo "options root=UUID=$(get_root_uuid)"
    ) > /boot/loader/entries/${MY_HOSTNAME}_fallback.conf
}
function get_root_uuid {
    root_disk=$(mount | grep 'on / ' | cut -d' ' -f1)
    blkid | grep "^$root_disk" | grep -oP ' UUID="\K[^"]+'
}
function install_grub {
    pacman -S grub os-prober --needed
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-install $(mount | grep ' on /boot ' | cut -d' ' -f1)
}
function install_bootloader {
    case "$BOOTLOADER" in
        'systemd-boot')
            install_systemd
            ;;
        'grub')
            install_grub
            ;;
    esac
    echo "Installed $BOOTLOADER"
}

# Pacstrap packages
function install_pacman {
    for pkgfile in $(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".pacman$")
    do
        pkgfile_pkgs=$(cut -d' ' -f1 packages/$pkgfile)
        echo "Installing:" $pkgfile_pkgs
        # read -p 'Press any key to continue...'
        pacman -S $pkgfile_pkgs --needed --noconfirm
    done
}

# AUR
function install_aur {
    ./aurstrap-machine.sh
}

# Language Packages
function ifexists {
    command -v $1 >/dev/null 2>&1
}
function haspackages {
    ls ./packages/*.$1 >/dev/null 2>&1
}
function get_file_contents {
    cut -d' ' -f1 $1  | uniq
}
function install_other_packages {
    ifexists fish   && haspackages fish     && cat ./packages/*fisher | su $MY_USERNAME "fish install"
    ifexists npm    && haspackages npm      && npm install --global $( get_file_contents './packages/*.npm' )
    ifexists gem    && haspackages gem      && gem install $( get_file_contents './packages/*.gem')
    ifexists pip    && haspackages pip      && pip install $( get_file_contents './packages/*.pip' )
    ifexists cargo  && haspackages cargo    && sudo -u $MY_USERNAME cargo install $( get_file_contents './packages/*.cargo' )
    ifexists go     && haspackages go       && sudo -u $MY_USERNAME go install  $( get_file_contents './packages/*.go' )
}


# Services
function enable_services {
    SYSTEMD_SERVICES=$(cut -d' ' -f1 machines/$MY_HOSTNAME | grep ".service$")
    for serv in ${SYSTEMD_SERVICES[@]}
    do
        if [ $(systemctl list-unit-files "${serv}*" | wc -l) -gt 3 ]
        then
            echo "Enabling $serv"
            systemctl enable $serv
        fi
    done
}

setup_user
# init_system
# install_bootloader
# pacman -Sy
# install_pacman
for pkgfile in $(cut -d' ' -f1 machines/$MY_HOSTNAME | grep "$aur\.")
do
    install_aur
    break
done
install_other_packages
enable_services


# Wrapping up
pacman -Q > /installed_packages.txt

echo "Finished! Enjoy using $MY_HOSTNAME!"



# Cache files are stored within /var/cache/pacman and its subdirectories, although this can be changed with the CacheDir directive in /etc/pacman.conf.
