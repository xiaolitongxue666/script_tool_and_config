#!/bin/bash

set -x 

# 安装常用软件
pacman -S --noconfirm htop bmon tree net-tools which git gcc make wget

# 安装 VirtualBox 客户机工具
pacman -Sy --noconfirm virtualbox-guest-utils

reboot
