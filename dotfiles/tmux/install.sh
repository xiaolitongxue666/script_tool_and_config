#!/bin/bash

# Tmux 安装脚本
# 支持 macOS、Linux 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Tmux 安装脚本"
echo "=========================================="
echo "检测到操作系统: $OS"
echo ""

# 检测操作系统
if [[ "$OS" == "Darwin" ]]; then
    if command -v brew &> /dev/null; then
        INSTALL_CMD="brew install tmux"
    else
        echo "错误: 需要 Homebrew 来安装 Tmux"
        exit 1
    fi
elif [[ "$OS" == "Linux" ]]; then
    if command -v pacman &> /dev/null; then
        INSTALL_CMD="sudo pacman -S --noconfirm tmux"
    elif command -v apt-get &> /dev/null; then
        INSTALL_CMD="sudo apt-get install -y tmux"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="sudo yum install -y tmux"
    else
        echo "错误: 未检测到支持的包管理器"
        exit 1
    fi
else
    echo "错误: 不支持的操作系统: $OS"
    exit 1
fi

# 检查是否已安装 Tmux
if command -v tmux &> /dev/null; then
    echo "Tmux 已安装: $(which tmux)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 Tmux
if [ "$SKIP_INSTALL" != "true" ]; then
    echo "正在安装 Tmux..."
    eval "$INSTALL_CMD"
fi

# 复制配置文件
echo ""
echo "正在复制配置文件..."
TMUX_CONFIG_DIR="$HOME/.config/tmux"
mkdir -p "$TMUX_CONFIG_DIR"

if [ -f "$SCRIPT_DIR/tmux.conf" ]; then
    cp "$SCRIPT_DIR/tmux.conf" "$TMUX_CONFIG_DIR/"
    echo "已复制配置文件到 $TMUX_CONFIG_DIR/tmux.conf"
elif [ -f "$SCRIPT_DIR/config" ]; then
    cp "$SCRIPT_DIR/config" "$TMUX_CONFIG_DIR/tmux.conf"
    echo "已复制配置文件到 $TMUX_CONFIG_DIR/tmux.conf"
else
    echo "警告: 未找到配置文件"
fi

# 创建符号链接（如果使用 ~/.tmux.conf）
if [ ! -f "$HOME/.tmux.conf" ]; then
    ln -s "$TMUX_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf" 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "Tmux 安装和配置完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $TMUX_CONFIG_DIR/tmux.conf 或 ~/.tmux.conf"
echo "重新加载配置: tmux source-file ~/.tmux.conf"

