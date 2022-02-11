#!/bin/sh

# https://askubuntu.com/questions/25251/how-do-i-select-dwm-or-fluxbox-to-start-on-login
# https://unix.stackexchange.com/questions/594636/the-default-keybinding-for-opening-a-terminal-in-dwm-does-not-work

set -x

# Install Xlib and include headers
dnf install libX11-devel libXt-devel libXft-devel libXext-devel libXp-devel libXtst-devel libXinerama-devel

# Build and install
git clone https://git.suckless.org/dwm
cd dwm
make clean install

# Install st
cd ..
wget https://dl.suckless.org/st/st-0.8.5.tar.gz
tar -zxvf st-0.8.5.tar.gz
cd st-0.8.5
make clean isntall
tic -sx st.info
