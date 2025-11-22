#!/bin/bash

# dwm (Dynamic Window Manager) 安装脚本
# 支持 Linux 系统（Arch Linux、Ubuntu/Debian、Fedora/CentOS）
# 参考: https://dwm.suckless.org/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "dwm (Dynamic Window Manager) 安装脚本"
echo "=========================================="
echo "检测到操作系统: $OS"
echo ""

# 检查操作系统
if [[ "$OS" != "Linux" ]]; then
    echo "错误: dwm 仅支持 Linux 系统"
    exit 1
fi

# 检测 Linux 发行版并安装依赖
echo "正在检测 Linux 发行版..."
if command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    DEVEL_PACKAGES="libx11 libxt libxft libxext libxp libxtst libxinerama"
    echo "检测到: Arch Linux"
elif command -v apt-get &> /dev/null; then
    PACKAGE_MANAGER="apt"
    INSTALL_CMD="sudo apt-get install -y"
    DEVEL_PACKAGES="libx11-dev libxt-dev libxft-dev libxext-dev libxp-dev libxtst-dev libxinerama-dev"
    echo "检测到: Ubuntu/Debian"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    DEVEL_PACKAGES="libX11-devel libXt-devel libXft-devel libXext-devel libXp-devel libXtst-devel libXinerama-devel"
    echo "检测到: Fedora/CentOS/RHEL"
elif command -v yum &> /dev/null; then
    PACKAGE_MANAGER="yum"
    INSTALL_CMD="sudo yum install -y"
    DEVEL_PACKAGES="libX11-devel libXt-devel libXft-devel libXext-devel libXp-devel libXtst-devel libXinerama-devel"
    echo "检测到: CentOS/RHEL (yum)"
else
    echo "错误: 未检测到支持的包管理器"
    echo "请手动安装 Xlib 开发库："
    echo "  - libX11-devel (或 libx11-dev)"
    echo "  - libXt-devel (或 libxt-dev)"
    echo "  - libXft-devel (或 libxft-dev)"
    echo "  - libXext-devel (或 libxext-dev)"
    echo "  - libXinerama-devel (或 libxinerama-dev)"
    exit 1
fi

# 安装依赖
echo ""
echo "正在安装依赖包..."
$INSTALL_CMD $DEVEL_PACKAGES git make gcc

# 检查是否已安装 dwm
if command -v dwm &> /dev/null; then
    echo ""
    echo "dwm 已安装: $(which dwm)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 dwm
if [ "$SKIP_INSTALL" != "true" ]; then
    echo ""
    echo "正在编译并安装 dwm..."
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 克隆 dwm 源码
    echo "正在克隆 dwm 源码..."
    git clone https://git.suckless.org/dwm
    cd dwm
    
    # 如果有自定义配置文件，复制它
    if [ -f "$SCRIPT_DIR/config.h" ]; then
        echo "正在使用自定义配置文件..."
        cp "$SCRIPT_DIR/config.h" .
    elif [ -f "$SCRIPT_DIR/config.def.h" ]; then
        echo "正在使用默认配置文件模板..."
        cp "$SCRIPT_DIR/config.def.h" config.h
    else
        echo "使用默认配置（可通过编辑 config.h 自定义）"
        # 如果没有配置文件，使用默认的 config.def.h
        if [ ! -f config.h ]; then
            cp config.def.h config.h
        fi
    fi
    
    # 编译并安装
    echo "正在编译 dwm..."
    make clean
    sudo make install
    
    # 清理临时文件
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_DIR"
    
    echo "✅ dwm 安装完成"
fi

# 可选：安装 st (Simple Terminal)
echo ""
read -p "是否安装 st (Simple Terminal)？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在安装 st..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 下载 st
    ST_VERSION="0.9"
    wget -q "https://dl.suckless.org/st/st-${ST_VERSION}.tar.gz" || {
        echo "警告: 无法下载 st，尝试备用版本..."
        ST_VERSION="0.8.5"
        wget -q "https://dl.suckless.org/st/st-${ST_VERSION}.tar.gz" || {
            echo "错误: 无法下载 st"
            cd "$SCRIPT_DIR"
            rm -rf "$TEMP_DIR"
            exit 1
        }
    }
    
    tar -zxf "st-${ST_VERSION}.tar.gz"
    cd "st-${ST_VERSION}"
    
    # 编译并安装
    make clean
    sudo make install
    
    # 安装 terminfo
    sudo tic -sx st.info
    
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_DIR"
    echo "✅ st 安装完成"
fi

# 创建 XSession 桌面文件（用于登录管理器）
echo ""
echo "正在创建 XSession 桌面文件..."
XSESSION_DIR="/usr/share/xsessions"
if [ ! -d "$XSESSION_DIR" ]; then
    sudo mkdir -p "$XSESSION_DIR"
fi

sudo tee "$XSESSION_DIR/dwm.desktop" > /dev/null <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF

echo "✅ XSession 文件已创建: $XSESSION_DIR/dwm.desktop"

echo ""
echo "=========================================="
echo "dwm 安装和配置完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 在登录管理器中选择 'dwm' 会话"
echo "2. 或者将以下内容添加到 ~/.xinitrc:"
echo "   exec dwm"
echo ""
echo "配置文件位置:"
echo "  - dwm 配置: 编辑源码中的 config.h 并重新编译"
echo "  - 自定义配置: $SCRIPT_DIR/config.h"
echo ""
echo "参考链接:"
echo "  - https://dwm.suckless.org/"
echo "  - https://dwm.suckless.org/customisation/"

