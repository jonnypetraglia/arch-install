source ./environment.sh

ROOT_FS = 'releng/airootfs'

###### Inside Live CD ######


# Timezone
ln -sf /usr/share/zoneinfo/US/$MY_TIMEZONE /etc/localtime

# Localization
echo 'en_US.UTF-8 UTF-8' >> $ROOT_FS/etc/locale.gen # TODO: Is this needed?
echo 'LANG=en_US.UTF-8' >> $ROOT_FS/etc/locale.conf

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


# Packages

for pkgFile in $(cat machines/$MY_HOSTNAME)
do
    if [[ $pkgfile = *pacman ]]
    then
        cat "packages/$pkgfile" | pacstrap $ROOT_FS
    fi
done


# AUR
pacman -Sy arch-install-scripts git base-devel go
echo yay | ./yay-pacstrap.sh

for pkgFile in $(cat machines/$MY_HOSTNAME)
do
    if [[ $pkgfile = *aur ]]
    then
        cat "packages/$pkgfile" | ./yay-pacstrap.sh
    fi
done
pacstrap -U $ROOT_FS *.pkg.tar.zst



# dotfiles?
# ~/.config/fish/config.fish
# ~/.config/syncthing/config.xml



# TODO: greeter-session inside /etc/lightdm/lightdm.conf
