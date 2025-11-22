#!/bin/bash

# Zsh 安装脚本
# 支持 macOS、Linux 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Zsh 安装脚本"
echo "=========================================="
echo "检测到操作系统: $OS"
echo ""

# 检测操作系统
if [[ "$OS" == "Darwin" ]]; then
    if command -v brew &> /dev/null; then
        INSTALL_CMD="brew install zsh"
    else
        echo "注意: macOS 通常已预装 Zsh"
        INSTALL_CMD=""
    fi
    ZSH_PATH="/bin/zsh"
elif [[ "$OS" == "Linux" ]]; then
    if command -v pacman &> /dev/null; then
        INSTALL_CMD="sudo pacman -S --noconfirm zsh"
    elif command -v apt-get &> /dev/null; then
        INSTALL_CMD="sudo apt-get install -y zsh"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="sudo yum install -y zsh"
    else
        echo "错误: 未检测到支持的包管理器"
        exit 1
    fi
    ZSH_PATH="/usr/bin/zsh"
else
    echo "错误: 不支持的操作系统: $OS"
    exit 1
fi

# 检查是否已安装 Zsh
if command -v zsh &> /dev/null; then
    echo "Zsh 已安装: $(which zsh)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 Zsh
if [ "$SKIP_INSTALL" != "true" ] && [ -n "$INSTALL_CMD" ]; then
    echo "正在安装 Zsh..."
    eval "$INSTALL_CMD"
fi

# 安装 Oh My Zsh
echo ""
read -p "是否安装 Oh My Zsh (OMZ)？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在安装 Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh 已存在，跳过安装"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
fi

# 复制配置文件
echo ""
echo "正在复制配置文件..."
ZSH_CONFIG_FILE="$HOME/.zshrc"

# 备份现有配置（如果存在）
if [ -f "$ZSH_CONFIG_FILE" ]; then
    BACKUP_FILE="${ZSH_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ZSH_CONFIG_FILE" "$BACKUP_FILE"
    echo "已备份现有配置到: $BACKUP_FILE"
fi

# 复制统一配置文件
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
    cp "$SCRIPT_DIR/.zshrc" "$ZSH_CONFIG_FILE"
    echo "已复制配置文件到 $ZSH_CONFIG_FILE"
else
    echo "警告: 未找到统一配置文件: $SCRIPT_DIR/.zshrc"
    echo "将使用 Oh My Zsh 默认配置"
fi

# 设置 Zsh 为默认 Shell
echo ""
read -p "是否将 Zsh 设置为默认 Shell？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$ZSH_PATH" ]; then
        chsh -s "$ZSH_PATH"
        echo "已将 Zsh 设置为默认 Shell"
    else
        ZSH_ACTUAL_PATH=$(which zsh)
        if [ -n "$ZSH_ACTUAL_PATH" ]; then
            chsh -s "$ZSH_ACTUAL_PATH"
            echo "已将 Zsh 设置为默认 Shell: $ZSH_ACTUAL_PATH"
        else
            echo "警告: 未找到 Zsh 可执行文件"
        fi
    fi
fi

echo ""
echo "=========================================="
echo "Zsh 安装和配置完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $ZSH_CONFIG_FILE"
echo "重新加载配置: source $ZSH_CONFIG_FILE"
echo "或重新打开终端"

