source ./environment.sh

###### Post-arch-chroot ######

# Timezone
hwclock --systohc

# Localization
locale-gen

# Initramfs
mkinitcpio -P

# Bootloader
bootctl install # systemd-boot

# Services
systemctl enable lightdm.service
systemctl enable sshd.service
systemctl enable bluetooth.service
systemctl enable reflector.service
systemctl enable dhcpcd.service





# Misc Packages
## fish shell
cat ./packages/*fish.txt | fish install
## Node.js
npm install --global $(cat ./packages/*npm.txt)
## Ruby
gem install $(cat ./packages/*gem.txt)
## Python
pip install $(cat ./packages/*pip.txt)
## TODO: Cargo
## TODO: VS Code
## TODO: Go?


