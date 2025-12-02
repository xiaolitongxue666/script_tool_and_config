#!/bin/bash
# 测试 Alacritty shell 配置

CONFIG_FILE="$APPDATA/alacritty/alacritty.toml"
if [ -z "$APPDATA" ]; then
    CONFIG_FILE="$HOME/AppData/Roaming/alacritty/alacritty.toml"
fi

echo "配置文件位置: $CONFIG_FILE"
echo ""
echo "当前 shell 配置:"
sed -n '/^\[shell\]/,+3p' "$CONFIG_FILE"
echo ""
echo "验证路径是否存在:"
BASH_PATH=$(sed -n '/^\[shell\]/,+3p' "$CONFIG_FILE" | grep "program" | sed 's/.*= *"\(.*\)".*/\1/' | sed 's|\\\\|\\|g')
echo "路径: $BASH_PATH"
if [ -f "$BASH_PATH" ]; then
    echo "✓ 路径存在"
    "$BASH_PATH" --version 2>&1 | head -1
else
    echo "✗ 路径不存在"
fi

