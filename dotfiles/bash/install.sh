#!/bin/bash

# Bash 安装和配置脚本
# 支持 macOS、Linux、Windows 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Bash 配置安装脚本"
echo "=========================================="
echo "检测到操作系统: $OS"
echo ""

# 检测操作系统
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
    CONFIG_FILE=".bash_profile"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
    CONFIG_FILE=".bashrc"
elif [[ "$OS" == MINGW* ]] || [[ "$OS" == MSYS* ]] || [[ "$OS" == CYGWIN* ]]; then
    PLATFORM="windows"
    CONFIG_FILE=".bash_profile"
else
    echo "错误: 不支持的操作系统: $OS"
    exit 1
fi

# 复制统一配置文件
echo "正在复制统一配置文件..."
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    # 检查是否已存在配置标记
    if ! grep -q "# Loaded from dotfiles/bash" "$HOME/$CONFIG_FILE" 2>/dev/null; then
        echo "" >> "$HOME/$CONFIG_FILE"
        echo "# Loaded from dotfiles/bash" >> "$HOME/$CONFIG_FILE"
        echo "source $SCRIPT_DIR/config.sh" >> "$HOME/$CONFIG_FILE"
        echo "配置已添加到 $HOME/$CONFIG_FILE"
    else
        echo "配置已存在于 $HOME/$CONFIG_FILE，跳过"
    fi
else
    echo "警告: 未找到统一配置文件: $SCRIPT_DIR/config.sh"
fi

echo ""
echo "=========================================="
echo "Bash 配置安装完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $HOME/$CONFIG_FILE"
echo "请运行以下命令重新加载配置:"
echo "  source $HOME/$CONFIG_FILE"

