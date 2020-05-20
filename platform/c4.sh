#!/bin/bash

platform_pre_chroot() {
    echo "Platform pre-chroot..."
    alarm_build_package linux-odroid-c4
    alarm_build_package uboot-odroid-c4
    alarm_build_package odroid-c4-libgl-fb
    alarm_build_package odroid-gl4es
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    # Kernel
    yes | pacman -Rcs linux-odroid-n2
    yes | pacman -Rcs uboot-odroid-n2

    # Additional packages
    alarm_install_package linux-odroid-c4
    alarm_install_package uboot-odroid-c4
    alarm_install_package odroid-c4-libgl-fb
    alarm_install_package odroid-gl4es
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of=${LOOP} conv=fsync,notrunc bs=512 seek=1
    sync
}