#!/bin/bash

set -x 

# Install vim plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 

# Install neovim
pacman -S --noconfirm neovim

# Clone neovim configs
mkdir -p ~/.config/nvim/
cd ~/.config
git clone git@github.com:xiaolitongxue666/nvim.git

#Install plugs
nvim +'PlugInstall --sync' +qa