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

# 同步配置文件
echo ""
echo "=========================================="
echo "同步配置文件"
echo "=========================================="

HOME_CONFIG_FILE="$HOME/$CONFIG_FILE"

# 检查统一配置文件是否存在
if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
    echo "❌ 警告: 未找到统一配置文件: $SCRIPT_DIR/config.sh"
    echo "将跳过配置文件同步"
else
    # 备份现有配置文件（如果存在）
    if [ -f "$HOME_CONFIG_FILE" ]; then
        BACKUP_FILE="${HOME_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME_CONFIG_FILE" "$BACKUP_FILE"
        echo "✅ 已备份现有配置到: $BACKUP_FILE"
    fi

    # 检查是否已存在配置标记
    if grep -q "# Loaded from dotfiles/bash" "$HOME_CONFIG_FILE" 2>/dev/null; then
        echo "⚠️  配置已存在于 $HOME_CONFIG_FILE"
        read -p "是否更新配置？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 移除旧的配置标记和 source 行（跨平台兼容）
            if [[ "$OS" == "Darwin" ]]; then
                # macOS 需要扩展名参数
                sed -i.bak '/# Loaded from dotfiles\/bash/,+1d' "$HOME_CONFIG_FILE" 2>/dev/null || true
                rm -f "${HOME_CONFIG_FILE}.bak" 2>/dev/null || true
            else
                # Linux/Windows 不需要扩展名
                sed -i '/# Loaded from dotfiles\/bash/,+1d' "$HOME_CONFIG_FILE" 2>/dev/null || true
            fi
            # 添加新的配置
            echo "" >> "$HOME_CONFIG_FILE"
            echo "# Loaded from dotfiles/bash" >> "$HOME_CONFIG_FILE"
            echo "source $SCRIPT_DIR/config.sh" >> "$HOME_CONFIG_FILE"
            echo "✅ 已更新配置到 $HOME_CONFIG_FILE"
        else
            echo "跳过配置更新"
        fi
    else
        # 添加配置
        echo "" >> "$HOME_CONFIG_FILE"
        echo "# Loaded from dotfiles/bash" >> "$HOME_CONFIG_FILE"
        echo "source $SCRIPT_DIR/config.sh" >> "$HOME_CONFIG_FILE"
        echo "✅ 已添加配置到 $HOME_CONFIG_FILE"
    fi
fi

echo ""
echo "=========================================="
echo "Bash 配置安装完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $HOME/$CONFIG_FILE"
echo "请运行以下命令重新加载配置:"
echo "  source $HOME/$CONFIG_FILE"

