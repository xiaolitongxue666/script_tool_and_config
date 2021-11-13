#!/bin/bash

set -x 

# mirrorlist
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

cat >/etc/pacman.d/mirrorlist <<EOL
# 清华大学
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
## 163
Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch
## aliyun
Server = http://mirrors.aliyun.com/archlinux/\$repo/os/\$arch

EOL

# pacman.conf
cp /etc/pacman.conf /etc/pacman.conf.backup

cat >/etc/pacman.conf <<EOL
[options]
Architecture = auto
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOL

# show config
cat /etc/pacman.d/mirrorlist

cat /etc/pacman.conf

