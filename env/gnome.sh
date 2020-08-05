#!/bin/bash

# Overwrite platform image size since we need more space.
IMAGE_SIZE=6

# Called before entering the disk image chroot
env_pre_chroot() {
    echo "Env pre-chroot..."

    alarm_build_package pamac-aur
    alarm_build_package gnome-shell-extension-dash-to-dock
}

# Called inside the chroot
env_chroot_setup() {
    echo "Env chroot-setup..."

    # Desktop environment
    pacman -S --noconfirm gnome gnome-tweaks gdm

    # Audio
    pacman -S --noconfirm \
        pulseaudio pavucontrol pulseaudio-alsa pulseaudio-bluetooth

    # Video
    pacman -S --noconfirm mpv

    # Network
    pacman -S --noconfirm networkmanager nm-connection-editor

    # Theming
    pacman -S --noconfirm arc-gtk-theme papirus-icon-theme

    # Fonts
    pacman -S --noconfirm ttf-croscore ttf-dejavu ttf-hack \
        ttf-liberation ttf-nerd-fonts-symbols cantarell-fonts \
        adobe-source-code-pro-fonts ttf-opensans

    # System
    pacman -S --noconfirm gparted

    # Other applications
    pacman -S --noconfirm \
        gcolor3 \
        kvantum-qt5 \
        file-roller p7zip unrar unzip zip \
        firefox \
        nano neovim \
        gimp inkscape \
        gvfs gvfs-afc gvfs-google gvfs-gphoto2 \
        gvfs-mtp gvfs-nfs gvfs-smb

    # Additional packages
    alarm_install_package pamac-aur
    alarm_install_package gnome-shell-extension-dash-to-dock

    # Enable Services
    systemctl enable gdm
    systemctl enable NetworkManager

    # Customizations
    cp /mods/etc/profile.d/qt.sh /etc/profile.d/
    cp /mods/etc/profile.d/firefox_wayland.sh /etc/profile.d/
    cp /mods/etc/modprobe.d/blacklist.gnome.conf /etc/modprobe.d/blacklist_gnome.conf
    mkdir -p /usr/share/backgrounds
    cp /mods/usr/share/backgrounds/space.jpg /usr/share/backgrounds/

    mkdir /home/alarm/.config
    cp -a /mods/home/alarm/.config/gtk-3.0 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/Kvantum /home/alarm/.config/
    cp -a /mods/home/alarm/.config/qt5ct /home/alarm/.config/
    cp -a /mods/home/alarm/.config/geany /home/alarm/.config/
    cp -a /mods/home/alarm/.config/dconf /home/alarm/.config/
    cp /mods/home/alarm/.config/weston.ini /home/alarm/.config/
    cp /mods/home/alarm/.gtkrc-2.0 /home/alarm/

    chown -R alarm:alarm /home/alarm
}

# Called after exiting the disk image chroot
env_post_chroot() {
    echo "Env post-chroot..."
    return
}
