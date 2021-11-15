#!/bin/bash

set -x 

# Install common software 
pacman -S --noconfirm htop bmon tree net-tools which git

# Install virtualbox-guest-utils
pacman -Sy --noconfirm virtualbox-guest-utils

reboot
