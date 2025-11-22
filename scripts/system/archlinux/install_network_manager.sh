#!/bin/bash

set -x 

# 安装 NetworkManager
pacman -S wpa_supplicant wireless_tools networkmanager

# 安装用户界面
pacman -S nm-connection-editor network-manager-applet

# 在每次启动时启用 NetworkManager
systemctl enable NetworkManager.service

# 设置 GNOME | Chromium | Firefox 代理设置
gsettings set org.gnome.system.proxy mode 'manual' 
gsettings set org.gnome.system.proxy.http host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.http port 8080
gsettings set org.gnome.system.proxy.ftp host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.ftp port 8080
gsettings set org.gnome.system.proxy.https host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.https port 8080
gsettings set org.gnome.system.proxy.socks host 'proxy.localdomain.com'
gsettings set org.gnome.system.proxy.socks port 8080