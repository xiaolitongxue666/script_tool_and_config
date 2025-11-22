#!/bin/bash

# skhd (Simple Hotkey Daemon) 安装脚本
# 仅支持 macOS 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "skhd 快捷键守护进程安装脚本"
echo "=========================================="

# 检查操作系统
if [[ "$OS" != "Darwin" ]]; then
    echo "错误: skhd 仅支持 macOS 系统"
    exit 1
fi

# 检查是否已安装 Homebrew
if ! command -v brew &> /dev/null; then
    echo "错误: 需要 Homebrew 来安装 skhd"
    echo "请先安装 Homebrew: https://brew.sh"
    exit 1
fi

# 检查是否已安装 skhd
if command -v skhd &> /dev/null; then
    echo "skhd 已安装: $(which skhd)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 skhd
if [ "$SKIP_INSTALL" != "true" ]; then
    echo "正在安装 skhd..."
    brew install koekeishiya/formulae/skhd
fi

# 复制配置文件
echo ""
echo "正在复制配置文件..."
SKHD_CONFIG_DIR="$HOME/.config/skhd"
mkdir -p "$SKHD_CONFIG_DIR"

if [ -f "$SCRIPT_DIR/skhdrc" ]; then
    cp "$SCRIPT_DIR/skhdrc" "$SKHD_CONFIG_DIR/"
    echo "已复制配置文件到 $SKHD_CONFIG_DIR/skhdrc"
else
    echo "警告: 未找到配置文件"
fi

# 设置权限（skhd 需要辅助功能权限）
echo ""
echo "=========================================="
echo "skhd 安装完成！"
echo "=========================================="
echo ""
echo "重要提示："
echo "1. 需要在系统设置中授予 skhd 辅助功能权限"
echo "2. 配置文件位置: $SKHD_CONFIG_DIR/skhdrc"
echo "3. 重新加载配置: skhd --reload"
echo ""
echo "启动 skhd:"
echo "  brew services start skhd"
echo ""
echo "停止 skhd:"
echo "  brew services stop skhd"

