#!/bin/bash

# Set environment name
ENV_NAME="XFCE"

# Called before entering the disk image chroot
env_pre_chroot() {
    echo "Env pre-chroot..."
}

# Called inside the chroot
env_chroot_setup() {
    echo "Env chroot-setup..."

    # Graphics
    alarm_pacman mesa-demos \
        xorg-server xorg-xinit xorg-xrefresh \
        xf86-input-libinput sdl sdl2 sdl2_image

    if ! pacman -Qi mesa-devel-git > /dev/null 2>&1 ; then
        alarm_pacman xf86-video-fbdev
    fi

    # Desktop environment
    alarm_pacman xfce4 xfce4-goodies \
        tumbler thunar-volman thunar-archive-plugin \
        thunar-media-tags-plugin xdg-user-dirs xdg-utils \
        lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

    # Audio
    alarm_pacman \
        pulseaudio pavucontrol pulseaudio-alsa pulseaudio-bluetooth \
        audacious audacious-plugins

    # Video
    alarm_pacman \
        gst-libav gst-plugin-gtk gst-plugins-bad gst-plugins-bad-libs \
        gst-plugins-base gst-plugins-base-libs gst-plugins-good \
        gst-plugins-ugly gstreamer vlc ffmpeg ffmpegthumbnailer

    alarm_pacman mpv-sdl

    # Network
    alarm_pacman \
        network-manager-applet networkmanager nm-connection-editor

    # Bluetooth
    alarm_pacman blueman

    # Theming
    alarm_pacman arc-gtk-theme papirus-icon-theme \
        gtk-engine-murrine

    # Fonts
    alarm_pacman ttf-croscore ttf-dejavu ttf-hack ttf-liberation \
        ttf-nerd-fonts-symbols cantarell-fonts \
        adobe-source-code-pro-fonts ttf-opensans

    # System
    alarm_pacman gparted

    # Other applications
    alarm_pacman eog \
        gcolor2 \
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

    pacman -R --noconfirm mousepad parole xfburn ristretto

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

    mkdir -p /home/alarm/.local/share/applications
    cp /mods/home/alarm/.local/share/applications/gcolor2.desktop \
        /home/alarm/.local/share/applications

    chown -R alarm:alarm /home/alarm
}

# Called after exiting the disk image chroot
env_post_chroot() {
    echo "Env post-chroot..."

    # Additional packages from aur
    alarm_yay_install pamac-aur
    alarm_yay_install xfce4-places-plugin
    alarm_yay_install xfce4-docklike-plugin-git
    alarm_yay_install mugshot
}
