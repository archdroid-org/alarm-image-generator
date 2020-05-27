#!/bin/bash

gnome_scheme=org.gnome.desktop.interface

gsettings set $gnome_scheme gtk-theme 'Arc-Dark'
gsettings set $gnome_scheme icon-theme 'Papirus-Dark'
gsettings set $gnome_scheme cursor-theme 'Adwaita'
gsettings set $gnome_scheme cursor-size '48'
gsettings set $gnome_scheme font-name 'Sans 16'