#!/bin/bash

NAME="ArchLinuxARM-odroid-n2-latest"
IMAGE="ArchLinuxARM-odroid-c4"

platform_variables() {
    echo "WAYLAND: set to 1 to install wayland GL libraries instead of fbdev."
    echo "MAINLINE_KERNEL: set to 1 to use mainline kernel."
}

platform_pre_chroot() {
    echo "Platform pre-chroot..."

    if [ "${MAINLINE_KERNEL}" != "1" ]; then
        alarm_build_package linux-odroid-c4
    else
        alarm_build_package dkms-8812au
        alarm_build_package dkms-mali-bifrost-next
        alarm_build_package odroid-c4-dtb
    fi

    if [ "${WAYLAND}" != "1" ]; then
        alarm_build_package odroid-c4-libgl-fb
        alarm_build_package odroid-gl4es
    else
        alarm_build_package odroid-c4-libgl-wl
    fi

    alarm_build_package uboot-odroid-c4
    alarm_build_package odroid-alsa
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    # Kernel
    yes | pacman -Rcs linux-odroid-n2
    yes | pacman -Rcs uboot-odroid-n2

    # Additional packages/configurations
    alarm_install_package uboot-odroid-c4

    if [ "${MAINLINE_KERNEL}" != "1" ]; then
        alarm_install_package linux-odroid-c4-4.9
        alarm_install_package linux-odroid-c4-headers
    else
        yes | pacman -S --noconfirm linux-aarch64 linux-aarch64-headers
        yes | pacman -S --noconfirm dkms

        alarm_install_package dkms-8812au
        alarm_install_package dkms-mali-bifrost-next
        alarm_install_package odroid-c4-dtb

        cp /boot/boot.ini /boot/boot.hardkernel.ini
        cp /mods/boot/boot.c4.mainline.ini /boot/boot.ini
    fi

    # Audio support
    alarm_install_package odroid-alsa

    if [ "${WAYLAND}" != "1" ]; then
        alarm_install_package odroid-c4-libgl-fb
        alarm_install_package odroid-gl4es
    fi
}

platform_chroot_setup_exit() {
    echo "Platform chroot-setup-exit..."
    # Install at last since this causes issues
    if [ "${WAYLAND}" = "1" ]; then
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
