#!/bin/bash

set -x 

# Install NetworkManager
pacman -S wpa_supplicant wireless_tools networkmanager

# Install UI
pacman -S nm-connection-editor network-manager-applet

# Enable NetworkManager at every boot
systemctl enable NetworkManager.service

# Setting GMONE | Chromium | Forefox proxy setting
gsettings set org.gnome.system.proxy mode 'manual' 
gsettings set org.gnome.system.proxy.http host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.http port 8080
gsettings set org.gnome.system.proxy.ftp host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.ftp port 8080
gsettings set org.gnome.system.proxy.https host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.https port 8080
gsettings set org.gnome.system.proxy.socks host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.socks port 8080