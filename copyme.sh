source ./environment.sh

# Copies these scripts inside the newly installed machine so that they are available inside the chroot

rm -rf $ROOT_FS/arch-install
mkdir -p $ROOT_FS/arch-install
cp -r * $ROOT_FS/arch-install

chmod 777 -R $ROOT_FS/arch-install

