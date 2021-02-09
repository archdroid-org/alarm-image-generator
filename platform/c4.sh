#!/bin/bash

NAME="ArchLinuxARM-odroid-n2-latest"
IMAGE="ArchLinuxARM-odroid-c4"

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
        alarm_build_package linux-odroid-panfrost
        alarm_build_package rtl88xxau-aircrack-dkms-git
        alarm_build_package mesa-arm-git
    else
        alarm_build_package linux-odroid-g12
    fi

    if [ "${DISABLE_MALIGL}" != "1" ]; then
        if [ "${WAYLAND}" != "1" ]; then
            alarm_build_package odroid-c4-libgl
            alarm_build_package odroid-gl4es
        else
            alarm_build_package odroid-c4-libgl
        fi
    fi

    alarm_build_package uboot-odroid-c4
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
        alarm_install_package linux-odroid-panfrost-5
        alarm_install_package linux-odroid-panfrost-headers

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

    # U-Boot
    alarm_install_package uboot-odroid-c4

    # Audio support
    alarm_install_package odroid-alsa

    if [ "${DISABLE_MALIGL}" != "1" ]; then
        if [ "${WAYLAND}" != "1" ]; then
            alarm_install_package odroid-c4-libgl-fb
            alarm_install_package odroid-gl4es
        fi
    fi

    # Customizations
    cp /mods/boot/boot-logo.alarm.bmp.gz /boot/boot-logo.bmp.gz

    if [ "${MAINLINE_KERNEL}" = "1" ]; then
        echo "Copy boot.ini adapted for mainline kernel..."
        cp /mods/boot/boot.c4.mainline.ini /boot/boot.ini
    elif [ "${PANFROST_KERNEL}" = "1" ]; then
        echo "Copy boot.ini adapted for mainline kernel..."
        cp /mods/boot/boot.c4.mainline.ini /boot/boot.ini

        echo "Enable panfrost-performance service..."
        cp /mods/etc/systemd/system/panfrost-performance.service /etc/systemd/system/
        systemctl enable panfrost-performance
    else
        echo "Copy boot.ini adapted for c4..."
        cp /mods/boot/boot.c4.hardkernel.ini /boot/boot.ini
    fi
}

platform_chroot_setup_exit() {
    echo "Platform chroot-setup-exit..."
    # Install at last since this causes issues
    if [ "${DISABLE_MALIGL}" != "1" ]; then
        if [ "${WAYLAND}" = "1" ]; then
            alarm_install_package odroid-c4-libgl-wl
        fi
    fi

    cp /mods/etc/default/cpupower.c4 /etc/default/cpupower
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
