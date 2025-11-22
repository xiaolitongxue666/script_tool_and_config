#!/bin/bash

# Bash 配置同步脚本
# 将统一配置文件添加到用户的 .bashrc 或 .bash_profile

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Bash 配置同步"
echo "=========================================="

# 检测操作系统并确定配置文件
if [[ "$OS" == "Darwin" ]]; then
    CONFIG_FILE=".bash_profile"
elif [[ "$OS" == "Linux" ]]; then
    CONFIG_FILE=".bashrc"
elif [[ "$OS" == MINGW* ]] || [[ "$OS" == MSYS* ]] || [[ "$OS" == CYGWIN* ]]; then
    CONFIG_FILE=".bash_profile"
else
    CONFIG_FILE=".bashrc"
fi

HOME_CONFIG_FILE="$HOME/$CONFIG_FILE"

# 检查统一配置文件是否存在
if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
    echo "❌ 错误: 未找到配置文件: $SCRIPT_DIR/config.sh"
    exit 1
fi

# 检查是否已存在配置标记
if grep -q "# Loaded from dotfiles/bash" "$HOME_CONFIG_FILE" 2>/dev/null; then
    echo "⚠️  配置已存在于 $HOME_CONFIG_FILE，跳过"
    echo "如需更新，请手动编辑 $HOME_CONFIG_FILE"
else
    echo "" >> "$HOME_CONFIG_FILE"
    echo "# Loaded from dotfiles/bash" >> "$HOME_CONFIG_FILE"
    echo "source $SCRIPT_DIR/config.sh" >> "$HOME_CONFIG_FILE"
    echo "✅ 已添加配置到 $HOME_CONFIG_FILE"
fi

echo ""
echo "=========================================="
echo "配置同步完成！"
echo "=========================================="
echo "配置文件位置: $HOME_CONFIG_FILE"
echo "重新加载配置: source $HOME_CONFIG_FILE"

