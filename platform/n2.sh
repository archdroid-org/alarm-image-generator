#!/bin/bash

NAME="ArchLinuxARM-odroid-n2-latest"
IMAGE="ArchLinuxARM-odroid-n2"

platform_variables() {
    echo "WAYLAND: set to 1 to install wayland GL libraries instead of fbdev."
    echo "DISABLE_MALIGL: set to 1 to disable installation of mali libraries."
    echo "MAINLINE_KERNEL: set to 1 to use mainline kernel."
    echo "PANFROST_KERNEL: set to 1 to use panfrost enabled kernel."
}

platform_pre_chroot() {
    echo "Platform pre-chroot..."

    if [ "${MAINLINE_KERNEL}" = "1" ]; then
        alarm_build_package linux-amlogic-58
        alarm_build_package dkms-mali-bifrost-next
        alarm_build_package rtl88xxau-aircrack-dkms-git
    elif [ "${PANFROST_KERNEL}" = "1" ]; then
        alarm_build_package linux-amlogic-panfrost-510
        alarm_build_package rtl88xxau-aircrack-dkms-git
        alarm_build_package mesa-arm-git
    else
        alarm_build_package linux-odroid-g12
    fi

    if [ "${DISABLE_MALIGL}" != "1" ]; then
        if [ "${WAYLAND}" != "1" ]; then
            alarm_build_package odroid-n2-libgl
            alarm_build_package odroid-gl4es
        else
            alarm_build_package odroid-n2-libgl
        fi
    fi

    alarm_build_package uboot-odroid-n2plus
    alarm_build_package odroid-alsa
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    # Kernel
    yes | pacman -Rcs linux-odroid-n2
    yes | pacman -Rcs uboot-odroid-n2

    if [ "${MAINLINE_KERNEL}" = "1" ]; then
        alarm_install_package linux-amlogic-58-5
        alarm_install_package linux-amlogic-58-headers

        alarm_pacman dkms

        # Wireless
        alarm_install_package rtl88xxau-aircrack-dkms-git

        # GPU kernel driver
        alarm_install_package dkms-mali-bifrost-next
    elif [ "${PANFROST_KERNEL}" = "1" ]; then
        alarm_install_package linux-amlogic-panfrost-510-5
        alarm_install_package linux-amlogic-panfrost-510-headers

        alarm_pacman dkms

        # Wireless
        alarm_install_package rtl88xxau-aircrack-dkms-git

        # mesa git for panfrost
        alarm_install_package mesa-arm-git

        # Enable firefox X11 egl support
        echo "MOZ_X11_EGL=1" >> /etc/environment
    else
        alarm_install_package linux-odroid-g12-4.9
        alarm_install_package linux-odroid-g12-headers
    fi

    # Updated uboot
    alarm_install_package uboot-odroid-n2plus

    # Audio support
    alarm_install_package odroid-alsa

    if [ "${DISABLE_MALIGL}" != "1" ]; then
        if [ "${WAYLAND}" != "1" ]; then
            alarm_install_package odroid-n2-libgl-fb
            alarm_install_package odroid-gl4es
        fi
    fi

    # Customizations
    cp /mods/boot/boot-logo.alarm.bmp.gz /boot/boot-logo.bmp.gz
    cp /mods/etc/udev/rules.d/99-n2-fan-trip-temp.rules /etc/udev/rules.d/

    if [ "${MAINLINE_KERNEL}" = "1" ]; then
        echo "Copy boot.ini adapted for mainline kernel..."
        cp /mods/boot/boot.n2plus.mainline.ini /boot/boot.ini
    elif [ "${PANFROST_KERNEL}" = "1" ]; then
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
    if [ "${DISABLE_MALIGL}" != "1" ]; then
        if [ "${WAYLAND}" = "1" ]; then
            alarm_install_package odroid-n2-libgl-wl
        fi
    fi
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Setting boot.ini UUID"
    local loopname=$(echo "${LOOP}" | sed "s/\/dev\///g")

    local uuidboot=$(lsblk -o uuid,name | grep ${loopname}p1 | awk "{print \$1}")
    local uuidroot=$(lsblk -o uuid,name | grep ${loopname}p2 | awk "{print \$1}")

    sudo sed -i "s/root=\/dev\/mmcblk\${devno}p2/root=UUID=${uuidroot}/g" \
        root/boot/boot.ini

    sudo sed -i "s/setenv bootlabel \"ArchLinux\"/setenv bootlabel \"ArchLinux ${ENV_NAME}\"/g" \
        root/boot/boot.ini

    sudo echo "UUID=${uuidboot}  /boot  vfat  defaults,noatime,discard  0  0" \
        | sudo tee --append root/etc/fstab

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of=${LOOP} conv=fsync,notrunc bs=512 seek=1
    sync
}
