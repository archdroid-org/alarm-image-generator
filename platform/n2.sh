#!/bin/bash

NAME="ArchLinuxARM-odroid-n2-latest"
IMAGE="ArchLinuxARM-odroid-n2"

platform_variables() {
    echo "WAYLAND: set to 1 to install wayland GL libraries instead of fbdev."
    echo "MAINLINE_KERNEL: set to 1 to use mainline kernel."
}

platform_pre_chroot() {
    echo "Platform pre-chroot..."

    if [ "${MAINLINE_KERNEL}" != "1" ]; then
        alarm_build_package linux-odroid-n2plus
    else
        alarm_build_package linux-odroid-n2-mainline
        alarm_build_package dkms-mali-bifrost
    fi

    if [ "${WAYLAND}" != "1" ]; then
        alarm_build_package odroid-n2-libgl-fb
        alarm_build_package odroid-gl4es
    else
        alarm_build_package odroid-n2-libgl-wl
    fi

    alarm_build_package odroid-alsa
    alarm_build_package uboot-odroid-n2plus
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    # Kernel
    yes | pacman -R uboot-odroid-n2

    if [ "${MAINLINE_KERNEL}" = "1" ]; then
        alarm_install_package linux-odroid-n2-mainline-5
        alarm_install_package linux-odroid-n2-mainline-headers

        yes | pacman -S --noconfirm dkms

        # Wireless
        yes | pacman -S --noconfirm dkms-8812au

        # GPU kernel driver
        alarm_install_package dkms-mali-bifrost
    else
        alarm_install_package linux-odroid-n2plus-4.9
        alarm_install_package linux-odroid-n2plus-headers
    fi

    # Audio support
    alarm_install_package odroid-alsa

    # Updated uboot
    alarm_install_package uboot-odroid-n2plus

    if [ "${WAYLAND}" != "1" ]; then
        alarm_install_package odroid-n2-libgl-fb
        alarm_install_package odroid-gl4es
    fi

    # Customizations
    if [ "${MAINLINE_KERNEL}" = "1" ]; then
        echo "Copy boot.ini adapted for mainline kernel..."
        cp /mods/boot/boot.n2plus.mainline.ini /boot/boot.ini
    else
        echo "Copy boot.ini adapted for n2+..."
        cp /mods/boot/boot.n2plus.hardkernel.ini /boot/boot.ini

        echo "Enable startup modules..."
        cp /mods/etc/modules-load.d/modules.n2.conf /etc/modules-load.d/modules.conf
    fi
}

platform_chroot_setup_exit() {
    echo "Platform chroot-setup-exit..."
    # Install at last since this causes issues
    if [ "${WAYLAND}" = "1" ]; then
        alarm_install_package odroid-n2-libgl-wl
    fi
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of=${LOOP} conv=fsync,notrunc bs=512 seek=1
    sync
}
