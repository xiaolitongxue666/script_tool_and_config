#!/bin/bash

set -x 

cat >/etc/pacman.conf/ <<EOL

[archlinuxcn]
SigLevel = Optional TrustedOnly
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
EOL

cat /etc/pacman.conf
