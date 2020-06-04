#!/bin/bash

# Called before entering the disk image chroot
env_pre_chroot() {
    echo "Env pre-chroot..."

    alarm_build_package wlroots-git
    alarm_build_package swaybg-git
    alarm_build_package sway-git
    alarm_build_package swayidle-git
    alarm_build_package swaylock-git
    alarm_build_package wf-config-git
    alarm_build_package wayfire-git
    alarm_build_package wf-shell-git
    alarm_build_package wcm-git
    alarm_build_package wf-recorder-git
    alarm_build_package wlogout-git
    alarm_build_package greetd-git
    alarm_build_package greetd-gtkgreet-git
    alarm_build_package pamac-aur
    alarm_build_package mugshot
}

# Called inside the chroot
env_chroot_setup() {
    echo "Env chroot-setup..."

    # Graphics
    pacman -S --noconfirm mesa mesa-demos wayland weston \
        xorg-server-xwayland sdl sdl2 sdl2_image

    # Desktop environment
    pacman -S --noconfirm thunar tumbler thunar-volman \
        thunar-archive-plugin thunar-media-tags-plugin \
        xdg-user-dirs xdg-utils lxterminal guake grim slurp \
        wl-clipboard qt5-wayland bemenu bemenu-wlroots kanshi \
        gnome-shell gnome-tweaks xdg-desktop-portal \
        polkit-gnome mako xorg-xrdb lxappearance-gtk3


    # Audio
    pacman -S --noconfirm alsa-utils \
        pulseaudio pavucontrol pulseaudio-alsa pulseaudio-bluetooth \
        audacious audacious-plugins

    # Video
    pacman -S --noconfirm ffmpeg ffmpegthumbnailer mpv vlc

    # Network
    pacman -S --noconfirm connman cmst

    # Bluetooth
    pacman -S --noconfirm blueman

    # Theming
    pacman -S --noconfirm arc-gtk-theme papirus-icon-theme \
        adwaita-icon-theme gtk-engine-murrine

    # Fonts
    pacman -S --noconfirm ttf-croscore ttf-dejavu ttf-hack ttf-liberation \
        ttf-nerd-fonts-symbols cantarell-fonts \
        adobe-source-code-pro-fonts ttf-opensans

    # System
    pacman -S --noconfirm gparted

    # Shell
    pacman -S --noconfirm zsh zsh-autosuggestions zsh-completions \
        zsh-syntax-highlighting

    # Other applications
    pacman -S --noconfirm eog \
        qt5ct \
        kvantum-qt5 \
        evince \
        file-roller p7zip unrar unzip zip \
        firefox \
        nano neovim \
        geany geany-plugins \
        krita inkscape \
        gnome-calculator \
        gvfs gvfs-afc gvfs-google gvfs-gphoto2 \
        gvfs-mtp gvfs-nfs gvfs-smb

    # Additional packages
    alarm_install_package wlroots-git
    alarm_install_package swaybg-git
    alarm_install_package sway-git
    alarm_install_package swayidle-git
    alarm_install_package swaylock-git
    alarm_install_package wf-config-git
    alarm_install_package wayfire-git
    alarm_install_package wf-shell-git
    alarm_install_package wcm-git
    alarm_install_package wf-recorder-git
    alarm_install_package wlogout
    alarm_install_package greetd-git
    alarm_install_package greetd-gtkgreet-git
    alarm_install_package pamac-aur
    alarm_install_package mugshot

    # Enable Services
    systemctl enable greetd
    systemctl enable connman

    # Customizations
    cp /mods/etc/greetd/* /etc/greetd/
    cp /mods/etc/profile.d/wayland.sh /etc/profile.d/
    mkdir -p /usr/share/backgrounds
    cp /mods/usr/share/backgrounds/space.jpg /usr/share/backgrounds/

    mkdir /home/alarm/.config
    cp -a /mods/home/alarm/.config/mpv /home/alarm/.config/
    cp -a /mods/home/alarm/.config/xfce4 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/gtk-3.0 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/Kvantum /home/alarm/.config/
    cp -a /mods/home/alarm/.config/qt5ct /home/alarm/.config/
    cp -a /mods/home/alarm/.config/geany /home/alarm/.config/
    cp -a /mods/home/alarm/.config/dconf /home/alarm/.config/
    cp -a /mods/home/alarm/.config/lxterminal /home/alarm/.config/
    cp /mods/home/alarm/.config/wayfire.ini /home/alarm/.config/
    cp /mods/home/alarm/.config/weston.ini /home/alarm/.config/
    cp /mods/home/alarm/.config/wf-shell.ini /home/alarm/.config/
    cp /mods/home/alarm/.gtkrc-2.0 /home/alarm/
    cp /mods/home/alarm/.Xresources /home/alarm/
    cp /mods/home/alarm/.Xdefaults /home/alarm/

    # Set permissions to alarm
    chown -R alarm:alarm /home/alarm
}

# Called after exiting the disk image chroot
env_post_chroot() {
    echo "Env post-chroot..."
    return
}
