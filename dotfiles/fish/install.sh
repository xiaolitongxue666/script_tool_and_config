#!/bin/bash

# Fish Shell 安装脚本
# 支持 macOS、Linux 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Fish Shell 安装脚本"
echo "=========================================="
echo "检测到操作系统: $OS"
echo ""

# 检测操作系统
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
    FISH_PATH="/usr/local/bin/fish"
    INSTALL_CMD="brew install fish"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
    FISH_PATH="/usr/bin/fish"
    # 检测 Linux 发行版
    if command -v pacman &> /dev/null; then
        INSTALL_CMD="sudo pacman -S --noconfirm fish"
    elif command -v apt-get &> /dev/null; then
        INSTALL_CMD="sudo apt-get install -y fish"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="sudo yum install -y fish"
    else
        echo "错误: 未检测到支持的包管理器"
        exit 1
    fi
else
    echo "错误: 不支持的操作系统: $OS"
    exit 1
fi

# 检查是否已安装 Fish
if command -v fish &> /dev/null; then
    echo "Fish Shell 已安装: $(which fish)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 Fish Shell
if [ "$SKIP_INSTALL" != "true" ]; then
    echo "正在安装 Fish Shell..."
    if [[ "$OS" == "Darwin" ]]; then
        if command -v brew &> /dev/null; then
            brew install fish
        else
            echo "错误: 需要 Homebrew 来安装 Fish Shell"
            echo "请先安装 Homebrew: https://brew.sh"
            exit 1
        fi
    else
        eval "$INSTALL_CMD"
    fi
fi

# 设置 Fish 为默认 Shell
echo ""
read -p "是否将 Fish 设置为默认 Shell？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$FISH_PATH" ]; then
        chsh -s "$FISH_PATH"
        echo "已将 Fish 设置为默认 Shell"
    else
        echo "警告: 未找到 Fish 可执行文件: $FISH_PATH"
        echo "请手动设置: chsh -s $(which fish)"
    fi
fi

# 安装 Oh My Fish
echo ""
read -p "是否安装 Oh My Fish (OMF)？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在安装 Oh My Fish..."
    curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
    
    # 安装常用插件
    if command -v omf &> /dev/null; then
        echo "正在安装 Fish 主题和插件..."
        omf install agnoster
        omf install bass
    fi
fi

# 安装 Powerline 字体（可选）
echo ""
read -p "是否安装 Powerline 字体？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    ./install.sh
    cd /
    rm -rf "$TEMP_DIR"
    echo "Powerline 字体安装完成"
fi

# 复制配置文件
echo ""
echo "正在复制配置文件..."
FISH_CONFIG_DIR="$HOME/.config/fish"
mkdir -p "$FISH_CONFIG_DIR"

# 复制统一配置文件
if [ -f "$SCRIPT_DIR/config.fish" ]; then
    cp "$SCRIPT_DIR/config.fish" "$FISH_CONFIG_DIR/"
    echo "已复制统一配置文件: config.fish"
fi

# 复制 conf.d 目录（如果存在）
if [ -d "$SCRIPT_DIR/conf.d" ]; then
    mkdir -p "$FISH_CONFIG_DIR/conf.d"
    cp -r "$SCRIPT_DIR/conf.d/"* "$FISH_CONFIG_DIR/conf.d/" 2>/dev/null || true
    echo "已复制 conf.d 目录"
fi

# 复制 completions 目录（如果存在）
if [ -d "$SCRIPT_DIR/completions" ]; then
    mkdir -p "$FISH_CONFIG_DIR/completions"
    cp -r "$SCRIPT_DIR/completions/"* "$FISH_CONFIG_DIR/completions/" 2>/dev/null || true
    echo "已复制 completions 目录"
fi

echo ""
echo "=========================================="
echo "Fish Shell 安装和配置完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $FISH_CONFIG_DIR"
echo "如需重新加载配置，请运行: source $FISH_CONFIG_DIR/config.fish"
echo "或重新打开终端"

