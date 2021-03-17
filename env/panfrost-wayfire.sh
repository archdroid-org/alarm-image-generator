#!/bin/bash

# Set environment name
ENV_NAME="Wayfire Panfrost"

env_variables() {
    echo "PIPEWIRE: set to 1 to install pipewire instead of pulseaudio."
}

# Called before entering the disk image chroot
env_pre_chroot() {
    echo "Env pre-chroot..."
}

# Called inside the chroot
env_chroot_setup() {
    echo "Env chroot-setup..."

    # Graphics
    alarm_pacman mesa-devel-git mesa-demos wayland \
        xorg-server xorg-xwayland sdl sdl2 sdl2_image

    # Desktop environment
    alarm_pacman wlroots sway swaybg swayidle swaylock \
        wf-recorder mako wl-clipboard bemenu bemenu-wlroots kanshi \
        grim slurp wofi waybar-git wf-config wayfire wayfire-plugins-extra \
        wf-shell wcm

    alarm_pacman thunar tumbler thunar-volman \
        thunar-archive-plugin thunar-media-tags-plugin \
        xdg-user-dirs xdg-user-dirs-gtk xdg-utils xfce4-terminal \
        qt5-wayland gnome-keyring xdg-desktop-portal xdg-desktop-portal-wlr \
        polkit-gnome xorg-xrdb osmo lightdm lightdm-gtk-greeter \
        lightdm-gtk-greeter-settings

    # Audio
    if [ "$PIPEWIRE" = "1" ]; then
        alarm_pacman alsa-utils \
            pipewire pipewire-alsa pipewire-jack pipewire-pulse \
            pavucontrol gst-plugin-pipewire audacious audacious-plugins
    else
        alarm_pacman alsa-utils \
            pulseaudio pavucontrol pulseaudio-alsa pulseaudio-bluetooth \
            audacious audacious-plugins
    fi

    # Video
    alarm_pacman ffmpeg ffmpegthumbnailer mpv vlc

    # Network
    alarm_pacman networkmanager nm-connection-editor network-manager-applet

    # Bluetooth
    alarm_pacman blueman

    # Theming
    alarm_pacman arc-gtk-theme papirus-icon-theme \
        adwaita-icon-theme gtk-engine-murrine

    # Fonts
    alarm_pacman ttf-croscore ttf-dejavu ttf-hack ttf-liberation \
        ttf-nerd-fonts-symbols cantarell-fonts \
        adobe-source-code-pro-fonts ttf-opensans

    # System
    alarm_pacman gparted

    # Other applications
    alarm_pacman eog \
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

    # Required for wayland-logout
    alarm_pacman lsof

    # Enable Services
    systemctl enable lightdm
    systemctl enable NetworkManager

    # Add initial setup
    cp /mods/usr/bin/archdroid-setup /usr/bin/
    chmod 0755 /usr/bin/archdroid-setup

    # Customizations
    echo "QT_STYLE_OVERRIDE=kvantum" >> /etc/environment
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
    echo "MOZ_ENABLE_WAYLAND=1" >> /etc/environment

    cp /mods/etc/lightdm/* /etc/lightdm/

    mkdir -p /var/lib/AccountsService/users
    cp /mods/var/lib/AccountsService/users/alarm.wayfire \
        /var/lib/AccountsService/users/alarm

    mkdir -p /usr/share/backgrounds
    cp /mods/usr/share/backgrounds/space.jpg /usr/share/backgrounds/

    mkdir /home/alarm/.config
    cp -a /mods/home/alarm/.config/mako /home/alarm/.config/
    cp -a /mods/home/alarm/.config/waybar /home/alarm/.config/
    cp -a /mods/home/alarm/.config/wlogout /home/alarm/.config/
    cp -a /mods/home/alarm/.config/wofi /home/alarm/.config/
    cp -a /mods/home/alarm/.config/xfce4 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/gtk-3.0 /home/alarm/.config/
    cp -a /mods/home/alarm/.config/Kvantum /home/alarm/.config/
    cp -a /mods/home/alarm/.config/qt5ct /home/alarm/.config/
    cp -a /mods/home/alarm/.config/geany /home/alarm/.config/
    mkdir /home/alarm/.config/dconf
    cp /mods/home/alarm/.config/dconf/user.lite /home/alarm/.config/dconf/user
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

    # Additional packages
    alarm_yay_install pamac-aur
    alarm_yay_install wl-color-picker

    # Finish desktop environment installation from AUR
    alarm_yay_install wlogout wdisplays

    alarm_yay_install mugshot

    if [ "$PIPEWIRE" = "1" ]; then
        alarm_yay_install pipewire-jack-dropin
    fi
}
