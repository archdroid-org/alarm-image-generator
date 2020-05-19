#!/bin/bash

platform_pre_chroot() {
    echo "Platform pre-chroot..."
    alarm_build_package dkms-mali-bifrost
    alarm_build_package mali-bifrost-fbdev-driver
    alarm_build_package odroid-n2-gl4es
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    # Kernel
    yes | pacman -Rcs linux-odroid-n2
    yes | pacman -S --noconfirm linux-aarch64-rc linux-aarch64-rc-headers

    # Wireless
    yes | pacman -S --noconfirm dkms dkms-8812au

    # Additional packages
    alarm_install_package dkms-mali-bifrost
    alarm_install_package mali-bifrost-fbdev-driver
    alarm_install_package odroid-n2-gl4es

    # Customizations
    echo "Copy boot.ini adapted for mainline kernel..."
    cp /mods/boot/boot.n2.mainline.ini /boot/boot.ini
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of=${LOOP} conv=fsync,notrunc bs=512 seek=1
}