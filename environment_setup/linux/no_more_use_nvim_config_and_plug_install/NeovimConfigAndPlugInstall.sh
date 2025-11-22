#!/bin/sh

#Install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#Download neovim config file
git clone https://github.com/xiaolitongxue666/NeovimConfigFile.git ~/config/nvim

#Install plugs
nvim +'PlugInstall --sync' +qa
