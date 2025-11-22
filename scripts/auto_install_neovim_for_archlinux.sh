#!/bin/bash

set -x 

# 安装 vim plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 

# 安装 neovim
pacman -S --noconfirm neovim

# 克隆 neovim 配置
mkdir -p ~/.config/nvim/
cd ~/.config
git clone git@github.com:xiaolitongxue666/nvim.git

# 安装插件
nvim +'PlugInstall --sync' +qa