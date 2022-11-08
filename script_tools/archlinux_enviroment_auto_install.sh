#!/bin/bash

#Before run this script , recommand to add china source packet

#Import GPG key
yes | pacman -S archlinuxcn-keyring

#Update core extra community archlinuxcn
pacman -Syy

#Install vim-plug for neovim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#Install sudo
#yes | pacman -S sudo

#Install git
yes | pacman -S git 
yes | pacman -S lazygit

#Install python tools for neovim plig ncm2
yes | pacman -S python3
yes | pacman -S python-pip
yes | pacman -S python2-pip

#Install neovim
yes | pacman -S neovim

#Update glibc libidn
yes | pacman -Sy glibc libidn

#Install python tools for neovim
python3 -m pip install pynvim
pip3 install requests
pip3 install pynvim 
pip3 install neovim

#Install cmke 
yes | pacman -S cmake

#Install make
yes | pacman -S make

#Install gcc
yes | pacman -S gcc

#Install net-tools
yes | pacman -S net-tools

#Install iputils (ping command)
yes | pacman -S iputils

#Install dos2unix
#yes | pacman -S dos2unix

#Install zsh
#yes | pacman -S zsh

#Install ssh
yes | pacman -S openssh

#Install awk
yes | pacman -S awk

#Install screenfetch
yes | pacman -S screenfetch

#Install file command
yes | pacman -S file

#Install ctags
yes | pacman -S ctags
