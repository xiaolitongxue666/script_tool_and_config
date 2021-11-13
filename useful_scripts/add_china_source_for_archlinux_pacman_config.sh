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
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist

[extra]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist

[community]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist

[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOL

# Show config
cat /etc/pacman.d/mirrorlist

cat /etc/pacman.conf

# Update pacman source
pacman -Syy
