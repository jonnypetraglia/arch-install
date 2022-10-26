# jny installer for Arch Linux

Entirely bash. Ugh.

# Components

  - **Packages** are grouped together into logical units inside the `packages` directory. They end with differing extensions based on their package type.
    - pacman = officially supported Pacman package
    - aur = Arch User Repository package
    - cargo = Rust package
  - **Machines** are files that contain what package groups to install to a target machine. The filename should match what will be put inside `environment.sh` as `$MY_USERNAME`.




# Installing

## 0. environment.sh

Edit before running. MY_HOSTNAME _must_ have a corresponding file in the machines directory.

## 1. disksetup.sh

This will:

  - Create a new partition table (currently: GPT)
  - Create required partitions (currently: Root & Swap)
  - Make & label filesystems (current: ext4 and btrfs)
  - Mount new filesystems & generate fstab from them

## 2. prechroot.sh

Before chrooting into the new system, set some config for the new system.

  - Timezone
  - Localization
  - Network Configuration
  - Users (root and MY_USERNAME inside environment.sh)
  - Pacstraps all packages for machine - both Pacman & AUR

## 3. chroot.sh

To be run while inside the chroot (i.e. `arch-chroot $ROOT_FS chroot.sh`).

