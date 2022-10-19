source ./environment.sh

ROOT_FS = 'releng/airootfs'

###### Inside Live CD ######


# Timezone
ln -sf /usr/share/zoneinfo/US/$MY_TIMEZONE /etc/localtime

# Localization
cp /etc/locale.gen $ROOT_FS/etc/locale.gen # TODO: Is this needed?
sed -i "s/^#$MY_LOCALE.UTF-8/$MY_LOCALE.UTF-8/" /etc/locale.gen

# Network Configuration
echo $MY_HOSTNAME > $ROOT_FS/etc/hostname
echo "127.0.0.1     localhost" > $ROOT_FS/etc/hosts
echo "::1           localhost" >> $ROOT_FS/etc/hosts
echo "127.0.0.1     $MY_HOSTNAME.localhost      localhost" >> $ROOT_FS/etc/hosts

# Users
echo "$MY_USERNAME:x:1000:1000::/home/$MY_USERNAME:/usr/bin/fish" >> eleng/airootfs/etc/passwd
echo "$MY_USERNAME:x:1000:" >> $ROOT_FS/etc/group

echo "root:$ROOT_PASSWORD_ENC:19085::::::" > $ROOT_FS/etc/shadow
echo "$MY_USERNAME:$MY_PASSWORD_ENC:19245:0:99999:7:::" > $ROOT_FS/etc/shadow
echo "$MY_USERNAME:!::" > $ROOT_FS/etc/gshadow
echo "sambashare:!::$MY_USERNAME" > $ROOT_FS/etc/gshadow

echo "root  ALL=(ALL:ALL)   ALL" > /etc/sudoers
echo "$MY_USERNAME  ALL=(ALL:ALL)   ALL" >> /etc/sudoers


# 9. AUR
## Yay
pacman -S git base-devel go
mkdir yay
curl -o ./yay/PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay
cd yay
makepkg
mkdir -p $ROOT_FS/post-install
cp "yay/yay-*.pkg.tar.zst" $ROOT_FS/post-install/
pacman -U "yay/yay-*.pkg.tar.zst"



# dotfiles?
# ~/.config/fish/config.fish
# ~/.config/syncthing/config.xml



# TODO: greeter-session inside /etc/lightdm/lightdm.conf
