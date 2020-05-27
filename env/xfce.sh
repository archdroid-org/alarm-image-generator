#!/bin/bash

# Called before entering the disk image chroot
env_pre_chroot() {
    echo "Env pre-chroot..."

    alarm_build_package pamac-aur
    alarm_build_package xfce4-places-plugin
    alarm_build_package xfce4-docklike-plugin-git
    alarm_build_package mugshot
}

# Called inside the chroot
env_chroot_setup() {
    echo "Env chroot-setup..."

    # Graphics
    pacman -S --noconfirm mesa mesa-demos \
        xorg-server xorg-xinit xorg-xrefresh \
        xf86-input-libinput xf86-video-fbdev \
        sdl sdl2 sdl2_image

    # Desktop environment
    pacman -S --noconfirm xfce4 xfce4-goodies \
        tumbler thunar-volman thunar-archive-plugin \
        thunar-media-tags-plugin xdg-user-dirs xdg-utils \
        lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

    # Audio
    pacman -S --noconfirm \
        pulseaudio pavucontrol pulseaudio-alsa pulseaudio-bluetooth \
        audacious audacious-plugins

    # Video
    pacman -S --noconfirm \
        gst-libav gst-plugin-gtk gst-plugins-bad gst-plugins-bad-libs \
        gst-plugins-base gst-plugins-base-libs gst-plugins-good \
        gst-plugins-ugly gstreamer vlc ffmpeg ffmpegthumbnailer

    # Network
    pacman -S --noconfirm \
        network-manager-applet networkmanager nm-connection-editor

    # Bluetooth
    pacman -S --noconfirm blueman

    # Theming
    pacman -S --noconfirm arc-gtk-theme papirus-icon-theme

    # Fonts
    pacman -S --noconfirm ttf-croscore ttf-dejavu ttf-hack ttf-liberation \
        ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono \
        cantarell-fonts adobe-source-code-pro-fonts ttf-opensans

    # System
    pacman -S --noconfirm gparted

    # Shell
    pacman -S --noconfirm zsh zsh-autosuggestions zsh-completions \
        zsh-syntax-highlighting

    # Other applications
    pacman -S --noconfirm eog \
        gcolor3 \
        qt5ct \
        kvantum-qt5 \
        evince \
        file-roller p7zip unrar unzip zip \
        firefox \
        nano neovim \
        geany geany-plugins \
        gimp inkscape \
        gnome-calculator \
        gvfs gvfs-afc gvfs-google gvfs-gphoto2 \
        gvfs-mtp gvfs-nfs gvfs-smb

    pacman -R --noconfirm mousepad parole xfburn ristretto orage

    # Additional packages
    alarm_install_package pamac-aur
    alarm_install_package xfce4-places-plugin
    alarm_install_package xfce4-docklike-plugin-git
    alarm_install_package mugshot

    # Enable Services
    systemctl enable lightdm
    systemctl enable NetworkManager

    # Customizations
    cp /mods/etc/lightdm/* /etc/lightdm/
    cp /mods/etc/profile.d/qt.sh /etc/profile.d/
    cp /mods/usr/share/backgrounds/space.jpg /usr/share/backgrounds/

    mkdir /home/alarm/.config
    cp -a /mods/home/alarm/.config/xfce4 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/gtk-3.0 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/qt5ct /home/alarm/.config/
    cp -a /mods/home/alarm/.config/Kvantum /home/alarm/.config/
    cp -a /mods/home/alarm/.config/geany /home/alarm/.config/
    cp /mods/home/alarm/.gtkrc-2.0 /home/alarm/

    chown -R alarm:alarm /home/alarm
}

# Called after exiting the disk image chroot
env_post_chroot() {
    echo "Env post-chroot..."
    return
}