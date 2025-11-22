#!/bin/bash

# 运行此脚本前，建议添加中国源镜像

# 导入 GPG 密钥
yes | pacman -S archlinuxcn-keyring

# 更新 core extra community archlinuxcn
pacman -Syy

# 为 neovim 安装 vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 安装 sudo
#yes | pacman -S sudo

# 安装 git
yes | pacman -S git 
yes | pacman -S lazygit

# 为 neovim 插件 ncm2 安装 python 工具
yes | pacman -S python3
yes | pacman -S python-pip
yes | pacman -S python2-pip

# 安装 neovim
yes | pacman -S neovim

# 更新 glibc libidn
yes | pacman -Sy glibc libidn

# 为 neovim 安装 python 工具
python3 -m pip install pynvim
pip3 install requests
pip3 install pynvim 
pip3 install neovim

# 安装 cmake
yes | pacman -S cmake

# 安装 make
yes | pacman -S make

# 安装 gcc
yes | pacman -S gcc

# 安装 net-tools
yes | pacman -S net-tools

# 安装 iputils (ping 命令)
yes | pacman -S iputils

# 安装 dos2unix
#yes | pacman -S dos2unix

# 安装 zsh
#yes | pacman -S zsh

# 安装 ssh
yes | pacman -S openssh

# 安装 awk
yes | pacman -S awk

# 安装 screenfetch
yes | pacman -S screenfetch

# 安装 file 命令
yes | pacman -S file

# 安装 ctags
yes | pacman -S ctags
