#!/bin/bash

set -x 

# Install fish shell
pacman -S --noconfirm fish

# Set fish as you archlinux  default shell
# Note: Other OS may install fish to different path
chsh -s /usr/bin/fish

# Install oh-my-fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# Install powerline fonts
	# clone
git clone https://github.com/powerline/fonts.git --depth=1
	# install
cd fonts
./install.sh
	# clean-up a bit
cd ..
rm -rf fonts

# Instlal and apply new fish theme
omf install agnoster

