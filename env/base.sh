#!/bin/bash

alarm_install_package() {
    yes | pacman -U /mods/packages/$1*.pkg.tar.*
}

# Include environment hooks
if [ -e /env.sh ]; then
    source /env.sh
fi

if [ -e /platform.sh ]; then
    source /platform.sh
fi

#
# PACMAN SETUP
#
pacman-key --init
pacman-key --populate archlinuxarm

pacman -Suy --noconfirm

# Devel
pacman -S --noconfirm base-devel cmake git arch-install-scripts

# Bluetooth
pacman -S --noconfirm bluez bluez-utils

# Network
pacman -S --noconfirm iw inetutils \
    wireless_tools wireless-regdb net-tools netctl whois wget openssh \
    samba smbclient cifs-utils links

# System
pacman -S --noconfirm pciutils sudo cpupower usbutils neofetch \
    nano dialog terminus-font

# Shell
pacman -S --noconfirm zsh zsh-autosuggestions zsh-completions \
    zsh-syntax-highlighting


#
# INSTALL CUSTOM PACKAGES
#
alarm_install_package yay-bin


#
# SETUP HOOKS
#
if type "platform_chroot_setup" 1>/dev/null ; then
    echo "Executing platform chroot setup hook..."
    platform_chroot_setup
fi

if type "env_chroot_setup" 1>/dev/null ; then
    echo "Executing environment chroot setup hook..."
    env_chroot_setup
fi


#
# TWEAKS
#
sed -i 's/#en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
localectl set-locale en_US.UTF-8
locale-gen

# Fix domain resolution issue
cp /mods/etc/systemd/resolved.conf /etc/systemd/


#
# CUSTOMIZATIONS
#
usermod -G audio,tty,video,wheel -a alarm
chsh -s /usr/bin/zsh alarm
cp /mods/etc/sudoers.d/wheel /etc/sudoers.d/
cp /mods/etc/default/cpupower /etc/default/
cp /mods/etc/vconsole.conf /etc/
if [ ! -e "/mods/packages/.oh-my-zsh" ]; then
    git clone -c core.eol=lf -c core.autocrlf=false \
        -c fsck.zeroPaddedFilemode=ignore \
        -c fetch.fsck.zeroPaddedFilemode=ignore \
        -c receive.fsck.zeroPaddedFilemode=ignore \
        --depth=1 --branch "master" \
        "https://github.com/ohmyzsh/ohmyzsh" \
        /mods/packages/.oh-my-zsh
fi
cp -a /mods/packages/.oh-my-zsh /home/alarm/
cp /home/alarm/.oh-my-zsh/templates/zshrc.zsh-template /home/alarm/.zshrc
cp /mods/home/alarm/.makepkg.conf /home/alarm/

chown -R alarm:alarm /home/alarm


#
# SYSTEM SERVICES
#
systemctl enable sshd
systemctl enable bluetooth
systemctl enable cpupower
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd


#
# Exit HOOKS
#
if type "platform_chroot_setup_exit" 1>/dev/null ; then
    echo "Executing platform chroot setup exit hook..."
    platform_chroot_setup_exit
fi

exit