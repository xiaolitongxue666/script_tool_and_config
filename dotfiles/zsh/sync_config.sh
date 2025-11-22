#!/bin/bash

# Zsh 配置同步脚本
# 将统一配置文件同步到用户配置目录

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_CONFIG_FILE="$HOME/.zshrc"

echo "=========================================="
echo "Zsh 配置同步"
echo "=========================================="

# 检查统一配置文件是否存在
if [ ! -f "$SCRIPT_DIR/.zshrc" ]; then
    echo "❌ 错误: 未找到配置文件: $SCRIPT_DIR/.zshrc"
    exit 1
fi

# 备份现有配置（如果存在）
if [ -f "$ZSH_CONFIG_FILE" ]; then
    BACKUP_FILE="${ZSH_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ZSH_CONFIG_FILE" "$BACKUP_FILE"
    echo "✅ 已备份现有配置到: $BACKUP_FILE"
fi

# 复制统一配置文件
cp "$SCRIPT_DIR/.zshrc" "$ZSH_CONFIG_FILE"
echo "✅ 已同步配置文件到: $ZSH_CONFIG_FILE"

echo ""
echo "=========================================="
echo "配置同步完成！"
echo "=========================================="
echo "配置文件位置: $ZSH_CONFIG_FILE"
echo "重新加载配置: source $ZSH_CONFIG_FILE"
echo "或重新打开终端"

