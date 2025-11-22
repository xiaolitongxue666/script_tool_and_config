#!/bin/bash

set -x 

# 安装 X 窗口系统
pacman -S --noconfirm xorg xorg-server

# 安装 GNOME
pacman -S --noconfirm gnome

# 启动并启用 gdm.service
systemctl start gdm.service
systemctl enable gdm.service

# 重启系统
reboot