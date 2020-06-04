#!/bin/bash

platform_variables() {
    echo "WAYLAND: set to 1 to install wayland GL libraries instead of fbdev."
}

platform_pre_chroot() {
    echo "Platform pre-chroot..."
    alarm_build_package uboot-odroid-c4

    if [ "${WAYLAND}x" = "x" ]; then
        alarm_build_package linux-odroid-c4
        alarm_build_package odroid-c4-libgl-fb
        alarm_build_package odroid-gl4es
    else
        alarm_build_package dkms-mali-bifrost
        alarm_build_package odroid-c4-libgl-wl
        alarm_build_package odroid-c4-dtb
    fi
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    # Kernel
    yes | pacman -Rcs linux-odroid-n2
    yes | pacman -Rcs uboot-odroid-n2

    # Additional packages/configurations
    alarm_install_package uboot-odroid-c4

    if [ "${WAYLAND}x" = "x" ]; then
        alarm_install_package linux-odroid-c4
        alarm_install_package odroid-c4-libgl-fb
        alarm_install_package odroid-gl4es
    else
        yes | pacman -S --noconfirm linux-aarch64-rc linux-aarch64-rc-headers
        yes | pacman -S --noconfirm dkms dkms-8812au
        alarm_install_package dkms-mali-bifrost
        alarm_install_package odroid-c4-dtb

        cp /boot/boot.ini /boot/boot.hardkernel.ini
        cp /mods/boot/boot.c4.mainline.ini /boot/boot.ini
    fi
}

platform_chroot_setup_exit() {
    echo "Platform chroot-setup-exit..."
    # Install at last since this causes issues
    if [ "${WAYLAND}x" != "x" ]; then
        alarm_install_package odroid-c4-libgl-wl
    fi

    cp /mods/etc/default/cpupower.c4 /etc/default/cpupower
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of=${LOOP} conv=fsync,notrunc bs=512 seek=1
    sync
}
