#!/bin/sh

set -x

# Install Xlib and include headers
dnf install libX11-devel libXt-devel libXft-devel libXext-devel libXp-devel libXtst-devel libXinerama-devel

# Build and install
git clone https://git.suckless.org/dwm

cd dwm

make clean install
