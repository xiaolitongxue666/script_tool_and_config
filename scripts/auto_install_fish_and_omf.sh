#!/bin/bash

set -x 

# 安装 fish shell
pacman -S --noconfirm fish

# 将 fish 设置为 archlinux 的默认 shell
# 注意：其他操作系统可能将 fish 安装到不同路径
chsh -s /usr/bin/fish

# 安装 oh-my-fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# 安装 powerline 字体
	# 克隆
git clone https://github.com/powerline/fonts.git --depth=1
	# 安装
cd fonts
./install.sh
	# 清理
cd ..
rm -rf fonts

# 安装并应用新的 fish 主题
omf install agnoster

# 安装 bass 以运行 bash 脚本
omf install bass
