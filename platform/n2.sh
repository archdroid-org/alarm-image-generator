#!/bin/bash

platform_variables() {
    echo "WAYLAND: set to 1 to install wayland GL libraries instead of fbdev."
}

platform_pre_chroot() {
    echo "Platform pre-chroot..."
    alarm_build_package dkms-mali-bifrost

    if [ "${WAYLAND}x" = "x" ]; then
        alarm_build_package odroid-n2-libgl-fb
        alarm_build_package odroid-gl4es
    else
        alarm_build_package odroid-n2-libgl-wl
    fi
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

    if [ "${WAYLAND}x" = "x" ]; then
        alarm_install_package odroid-n2-libgl-fb
        alarm_install_package odroid-n2-gl4es
    else
        alarm_install_package odroid-n2-libgl-wl
    fi

    # Customizations
    echo "Copy boot.ini adapted for mainline kernel..."
    cp /mods/boot/boot.n2.mainline.ini /boot/boot.ini
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of=${LOOP} conv=fsync,notrunc bs=512 seek=1
    sync
}