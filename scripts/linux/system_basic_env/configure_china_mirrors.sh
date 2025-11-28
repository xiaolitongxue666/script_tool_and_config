#!/bin/bash

set -x

# 镜像列表
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

cat >/etc/pacman.d/mirrorlist <<EOL
## Aliyun (HTTPS, primary)
Server = https://mirrors.aliyun.com/archlinux/\$repo/os/\$arch
## USTC (HTTPS, secondary)
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
## Tencent Cloud (HTTPS, tertiary)
Server = https://mirrors.cloud.tencent.com/archlinux/\$repo/os/\$arch
## Huawei Cloud (HTTPS)
Server = https://mirrors.huaweicloud.com/repository/archlinux/\$repo/os/\$arch
## Nanjing University (HTTPS)
Server = https://mirrors.nju.edu.cn/archlinux/\$repo/os/\$arch
## Chongqing University (HTTPS)
Server = https://mirrors.cqu.edu.cn/archlinux/\$repo/os/\$arch
## Neusoft (HTTPS)
Server = https://mirrors.neusoft.edu.cn/archlinux/\$repo/os/\$arch
## Lanzhou University (HTTPS)
Server = https://mirror.lzu.edu.cn/archlinux/\$repo/os/\$arch
## Southern University of Science and Technology (HTTPS)
Server = https://mirrors.sustech.edu.cn/archlinux/\$repo/os/\$arch

EOL

# pacman 配置文件
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

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.aliyun.com/archlinuxcn/\$arch
Server = https://mirrors.cloud.tencent.com/archlinuxcn/\$arch
Server = https://mirrors.huaweicloud.com/repository/archlinuxcn/\$arch
Server = https://mirrors.nju.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.cqu.edu.cn/archlinuxcn/\$arch
Server = https://mirror.lzu.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.sustech.edu.cn/archlinuxcn/\$arch
EOL

# 显示配置
cat /etc/pacman.d/mirrorlist

cat /etc/pacman.conf

# 更新 pacman 源
pacman -Syy
