#!/bin/bash

# Fish Shell 配置同步脚本
# 将统一配置文件同步到用户配置目录

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FISH_CONFIG_DIR="$HOME/.config/fish"

echo "=========================================="
echo "Fish Shell 配置同步"
echo "=========================================="

# 创建配置目录
mkdir -p "$FISH_CONFIG_DIR"

# 复制统一配置文件
if [ -f "$SCRIPT_DIR/config.fish" ]; then
    cp "$SCRIPT_DIR/config.fish" "$FISH_CONFIG_DIR/"
    echo "✅ 已同步配置文件: config.fish"
else
    echo "❌ 警告: 未找到配置文件: $SCRIPT_DIR/config.fish"
    exit 1
fi

# 复制 conf.d 目录（如果存在）
if [ -d "$SCRIPT_DIR/conf.d" ]; then
    mkdir -p "$FISH_CONFIG_DIR/conf.d"
    cp -r "$SCRIPT_DIR/conf.d/"* "$FISH_CONFIG_DIR/conf.d/" 2>/dev/null || true
    echo "✅ 已同步 conf.d 目录"
fi

# 复制 completions 目录（如果存在）
if [ -d "$SCRIPT_DIR/completions" ]; then
    mkdir -p "$FISH_CONFIG_DIR/completions"
    cp -r "$SCRIPT_DIR/completions/"* "$FISH_CONFIG_DIR/completions/" 2>/dev/null || true
    echo "✅ 已同步 completions 目录"
fi

echo ""
echo "=========================================="
echo "配置同步完成！"
echo "=========================================="
echo "配置文件位置: $FISH_CONFIG_DIR"
echo "重新加载配置: source $FISH_CONFIG_DIR/config.fish"
echo "或重新打开终端"
