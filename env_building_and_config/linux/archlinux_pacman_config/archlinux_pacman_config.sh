#!/bin/bash

#Update core extra community
sudo pacman -Sy

#Add china packet source to pacman config file
echo -e "" >> /etc/pacman.conf
echo -e "[archlinuxcn]" >> /etc/pacman.conf
echo -e "SigLevel = Optional TrustedOnly" >> /etc/pacman.conf
echo -e "Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
