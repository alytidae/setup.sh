#!/bin/bash
set -e

echo "CRYPTSETUP!"

cryptsetup luksFormat --type luks1 $SETUP_PART_ROOT

cryptsetup luksOpen $SETUP_PART_ROOT voidvm

vgcreate voidvm /dev/mapper/voidvm

lvcreate --name swap -L 4G voidvm
lvcreate --name root -l 100%FREE voidvm

mkfs.ext4 -L root /dev/voidvm/root
mkswap /dev/voidvm/swap

mount /dev/voidvm/root /mnt

mkfs.vfat $SETUP_PART_EFI
mkdir -p /mnt/boot/efi
mount $SETUP_PART_EFI /mnt/boot/efi

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

xbps-install -Sy -R https://repo-default.voidlinux.org/current -r /mnt base-system cryptsetup grub-x86_64-efi lvm2
xbps-install -Sy -R https://repo-default.voidlinux.org/current xtools
xgenfstab /mnt > /mnt/etc/fstab

