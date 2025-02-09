#!/bin/bash

alarm_pacman() {
    yes | pacman -S --needed --noconfirm $@
}

alarm_install_yay() {
    if ! which yay > /dev/null ; then
        cd packages
        if [ ! -e "yay-bin" ]; then
            wget "https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz"
            tar -xvzf yay-bin.tar.gz
            rm yay-bin.tar.gz
        fi
        chown -R alarm:alarm yay-bin
        cd yay-bin
        rm yay-bin*.pkg.tar.*
        sudo -u alarm makepkg -CAs --skippgpcheck --noconfirm
        package=$(ls yay-bin*.pkg.tar.* | sort | tail -n1)
        yes | pacman -U "$package"
        cd ../../
    fi
}

alarm_build_package() {
    cd packages

    if [ ! -e "$1" ]; then
        yay -G "$1"
    fi

    chown -R alarm:alarm "$1"
    cd "$1"

    package=$(ls *.pkg.tar.* | sort | tail -n1)
    if [ "$package" = "" ]; then
        echo "Building $1..."
        sudo -u alarm makepkg -CAs --skippgpcheck --noconfirm
    fi

    cd ../../
}

alarm_install_package() {
    if ! ls /packages/$1/$1*.pkg.tar.* > /dev/null ; then
        alarm_build_package $1
    fi
    package=$(ls /packages/$1/$1*.pkg.tar.* | sort | tail -n1)
    yes | pacman -U "$package"
}

# Include environment hooks
if [ -e /env.sh ]; then
    source /env.sh
fi

if [ -e /platform.sh ]; then
    source /platform.sh
fi

#
# Try to set locale before installing packages.
#
sed -i 's/#en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
localectl set-locale en_US.UTF-8

#
# PACMAN SETUP
#
pacman-key --init
pacman-key --populate archlinuxarm

#
# Update packages list and keyrings
#
while ! pacman -Sy ; do
    echo "Command failed. Retrying in 5 seconds..."
    sleep 5
done
alarm_pacman archlinux-keyring archlinuxarm-keyring

#
# Update all packages
#
yes | pacman -Su --noconfirm

# Devel
alarm_pacman base-devel sudo wget cmake git arch-install-scripts

# Bluetooth
alarm_pacman bluez bluez-utils

# Network
alarm_pacman iw inetutils \
    wireless_tools wireless-regdb net-tools networkmanager whois openssh \
    samba smbclient cifs-utils links wpa_supplicant

# System
alarm_pacman pciutils cpupower usbutils ntfs-3g \
    neofetch lsb-release nano dialog terminus-font

# Shell
alarm_pacman zsh zsh-autosuggestions zsh-completions \
    zsh-syntax-highlighting

# Realtime priviliges for audio recording
alarm_pacman realtime-privileges


#
# Initial alarm user account setup
#
usermod -G audio,tty,video,input,wheel,network,realtime -a alarm
cp /mods/etc/sudoers.d/wheel /etc/sudoers.d/
cp /mods/home/alarm/.makepkg.conf /home/alarm/
chown -R alarm:alarm /home/alarm

#
# Enable more build cores on makepkg.conf for faster AUR builds
#
cp /etc/makepkg.conf /home/alarm/.makepkg.conf
sed -i 's|#MAKEFLAGS="-j2"|MAKEFLAGS="-j'"$(nproc)"'"|g' makepkg.conf
chown alarm:alarm /home/alarm/.makepkg.conf

#
# Install yay AUR helper
#
alarm_install_yay

#
# Add custom repo for some extra packages
#
alarm_install_package archlinuxdroid-repo
while ! pacman -Sy ; do
    echo "Command failed. Retrying in 5 seconds..."
    sleep 5
done


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

# Fix domain resolution issue
cp /mods/etc/systemd/resolved.conf /etc/systemd/

# Add initial setup script
cp /mods/etc/systemd/system/initial-setup.service /etc/systemd/system/
cp /mods/usr/bin/initial-img-setup /usr/bin/


#
# CUSTOMIZATIONS
#
cp /mods/etc/fstab /etc/
chsh -s /usr/bin/zsh alarm
cp /mods/etc/sysctl.d/general.conf /etc/sysctl.d/general.conf
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

chown -R alarm:alarm /home/alarm


#
# SYSTEM SERVICES
#
systemctl enable sshd
systemctl enable bluetooth
systemctl enable cpupower
systemctl disable systemd-networkd
systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd
systemctl enable initial-setup


#
# Exit HOOKS
#
if type "platform_chroot_setup_exit" 1>/dev/null ; then
    echo "Executing platform chroot setup exit hook..."
    platform_chroot_setup_exit
fi

#
# Remove customized makepkg.conf
#
rm /home/alarm/.makepkg.conf

exit
