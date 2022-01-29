#!/bin/bash

set -x 

# Install X windoes system
pacman -S --noconfirm xorg xorg-server

# Instll GNOME
pacman -S --noconfirm gnome

# Start and enable gdm.service
systemctl start gdm.serever
systemctl enable gdm.service

# Reboot system
reboot