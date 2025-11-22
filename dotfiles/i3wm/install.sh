#!/bin/bash

# i3 窗口管理器安装脚本
# 仅支持 Linux 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "i3 窗口管理器安装脚本"
echo "=========================================="

# 检查操作系统
if [[ "$OS" != "Linux" ]]; then
    echo "错误: i3 窗口管理器仅支持 Linux 系统"
    exit 1
fi

# 检测 Linux 发行版
if command -v pacman &> /dev/null; then
    INSTALL_CMD="sudo pacman -S --noconfirm i3-wm i3status i3lock"
    PACKAGE_MANAGER="pacman"
elif command -v apt-get &> /dev/null; then
    INSTALL_CMD="sudo apt-get install -y i3 i3status i3lock"
    PACKAGE_MANAGER="apt"
elif command -v yum &> /dev/null; then
    INSTALL_CMD="sudo yum install -y i3 i3status i3lock"
    PACKAGE_MANAGER="yum"
else
    echo "错误: 未检测到支持的包管理器"
    exit 1
fi

# 检查是否已安装 i3
if command -v i3 &> /dev/null; then
    echo "i3 已安装: $(which i3)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 i3
if [ "$SKIP_INSTALL" != "true" ]; then
    echo "正在安装 i3 窗口管理器..."
    eval "$INSTALL_CMD"
fi

# 复制配置文件
echo ""
echo "正在复制配置文件..."
I3_CONFIG_DIR="$HOME/.config/i3"
mkdir -p "$I3_CONFIG_DIR"

if [ -f "$SCRIPT_DIR/config" ]; then
    cp "$SCRIPT_DIR/config" "$I3_CONFIG_DIR/"
    echo "已复制配置文件到 $I3_CONFIG_DIR/config"
else
    echo "警告: 未找到配置文件"
fi

# 复制 i3status 配置（如果存在）
if [ -f "$SCRIPT_DIR/i3status.conf" ]; then
    I3STATUS_CONFIG_DIR="$HOME/.config/i3status"
    mkdir -p "$I3STATUS_CONFIG_DIR"
    cp "$SCRIPT_DIR/i3status.conf" "$I3STATUS_CONFIG_DIR/"
    echo "已复制 i3status 配置"
fi

echo ""
echo "=========================================="
echo "i3 窗口管理器安装和配置完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $I3_CONFIG_DIR/config"
echo "重新加载配置: 在 i3 中按 Mod+Shift+R (默认 Mod 为 Super/Windows 键)"
echo ""
echo "注意: 需要重新登录或重启窗口管理器以应用配置"

