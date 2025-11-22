#!/bin/sh

# 参考链接:
# https://askubuntu.com/questions/25251/how-do-i-select-dwm-or-fluxbox-to-start-on-login
# https://unix.stackexchange.com/questions/594636/the-default-keybinding-for-opening-a-terminal-in-dwm-does-not-work

set -x

# 安装 Xlib 和头文件
dnf install libX11-devel libXt-devel libXft-devel libXext-devel libXp-devel libXtst-devel libXinerama-devel

# 编译并安装
git clone https://git.suckless.org/dwm
cd dwm
make clean install

# 安装 st（简单终端）
cd ..
wget https://dl.suckless.org/st/st-0.8.5.tar.gz
tar -zxvf st-0.8.5.tar.gz
cd st-0.8.5
make clean install
tic -sx st.info

# 在登录屏幕添加 dwm 选项
cat << EOF > /usr/share/xsessions/dwm.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
