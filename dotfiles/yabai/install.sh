#!/bin/bash

# Yabai 窗口管理器安装脚本
# 仅支持 macOS 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Yabai 窗口管理器安装脚本"
echo "=========================================="

# 检查操作系统
if [[ "$OS" != "Darwin" ]]; then
    echo "错误: Yabai 窗口管理器仅支持 macOS 系统"
    exit 1
fi

# 检查是否已安装 Homebrew
if ! command -v brew &> /dev/null; then
    echo "错误: 需要 Homebrew 来安装 Yabai"
    echo "请先安装 Homebrew: https://brew.sh"
    exit 1
fi

# 检查是否已安装 Yabai
if command -v yabai &> /dev/null; then
    echo "Yabai 已安装: $(which yabai)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 Yabai
if [ "$SKIP_INSTALL" != "true" ]; then
    echo "正在安装 Yabai..."
    brew install koekeishiya/formulae/yabai
fi

# 复制配置文件
echo ""
echo "正在复制配置文件..."
YABAI_CONFIG_DIR="$HOME/.config/yabai"
mkdir -p "$YABAI_CONFIG_DIR"

if [ -f "$SCRIPT_DIR/yabairc" ]; then
    cp "$SCRIPT_DIR/yabairc" "$YABAI_CONFIG_DIR/"
    echo "已复制配置文件到 $YABAI_CONFIG_DIR/yabairc"
else
    echo "警告: 未找到配置文件"
fi

# 设置权限（Yabai 需要辅助功能权限）
echo ""
echo "=========================================="
echo "Yabai 安装完成！"
echo "=========================================="
echo ""
echo "重要提示："
echo "1. 需要在系统设置中授予 Yabai 辅助功能权限"
echo "2. 配置文件位置: $YABAI_CONFIG_DIR/yabairc"
echo "3. 重新加载配置: yabai --restart-service"
echo ""
echo "启动 Yabai:"
echo "  brew services start yabai"
echo ""
echo "停止 Yabai:"
echo "  brew services stop yabai"

