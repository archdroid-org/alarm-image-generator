#!/bin/bash

NAME="ArchLinuxARM-odroid-n2-latest"
IMAGE="ArchLinuxARM-odroid-n2"

platform_variables() {
    echo "TOBETTER_KERNEL: set to 1 to use tobetter kernel branch."
}

platform_pre_chroot() {
    echo "Platform pre-chroot..."
}

platform_chroot_setup() {
    echo "Platform chroot-setup..."

    yes | pacman -Rcs linux-odroid-n2
    yes | pacman -Rcs uboot-odroid-n2

    if [ "${TOBETTER_KERNEL}" = "1" ]; then
        yes | pacman -Rcs linux-aarch64
        alarm_pacman linux-odroid-600
    else
        alarm_pacman linux-aarch64
    fi

    # Updated uboot
    alarm_pacman uboot-tools
    alarm_install_package uboot-odroid-n2plus

    # Customizations
    cp /mods/boot/boot-logo.alarm.bmp.gz /boot/boot-logo.bmp.gz
    cp /mods/etc/udev/rules.d/99-n2-fan-trip-temp.rules /etc/udev/rules.d/

    echo "Enable panfrost-performance service..."
    cp /mods/etc/systemd/system/panfrost-performance.service /etc/systemd/system/
    systemctl enable panfrost-performance
}

platform_chroot_setup_exit() {
    echo "Platform chroot-setup-exit..."
}

platform_post_chroot() {
    echo "Platform post-chroot..."

    echo "Setting boot.ini UUID"
    local loopname
    loopname=$(echo "${LOOP}" | sed "s/\/dev\///g")

    local uuidboot
    uuidboot=$(lsblk -o uuid,name | grep "${loopname}p1" | awk "{print \$1}")
    local uuidroot
    uuidroot=$(lsblk -o uuid,name | grep "${loopname}p2" | awk "{print \$1}")

    sudo sed -i "s/root=\/dev\/mmcblk\${devno}p2/root=UUID=${uuidroot}/g" \
        root/boot/boot.ini

    sudo sed -i "s/setenv bootlabel \"ArchLinux\"/setenv bootlabel \"ArchLinux ${ENV_NAME}\"/g" \
        root/boot/boot.ini

    sudo echo "UUID=${uuidboot}  /boot  vfat  defaults,noatime,discard  0  0" \
        | sudo tee --append root/etc/fstab

    echo "Flashing U-Boot..."
    sudo dd if=root/boot/u-boot.bin of="${LOOP}" conv=fsync,notrunc bs=512 seek=1
    sync
}
