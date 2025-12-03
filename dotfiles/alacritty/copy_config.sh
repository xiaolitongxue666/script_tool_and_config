#!/bin/bash
# Alacritty 配置文件复制脚本
# 功能：将配置文件复制到部署位置，并处理主题文件的下载
# 用途：仅复制配置，不安装 Alacritty 本身
# 注意：如果 Alacritty 未安装，请先运行 install.sh

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="$SCRIPT_DIR/alacritty.toml"

if [ ! -f "$SOURCE_CONFIG" ]; then
    echo "错误: 未找到源配置文件: $SOURCE_CONFIG"
    exit 1
fi

# 检测操作系统
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
else
    PLATFORM="linux"
fi

# 确定目标配置文件目录
if [ "$PLATFORM" == "windows" ]; then
    # Windows: 使用 %APPDATA%\alacritty
    if [ -z "$APPDATA" ]; then
        # 在 Git Bash 中，APPDATA 可能未设置，尝试从 Windows 环境变量获取
        if command -v cmd.exe &> /dev/null; then
            APPDATA=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' | sed 's|\\|/|g')
        fi
    fi

    if [ -n "$APPDATA" ] && [ "$APPDATA" != "%APPDATA%" ]; then
        CONFIG_DIR="$APPDATA/alacritty"
    else
        # 如果无法获取 APPDATA，使用默认路径
        CONFIG_DIR="$HOME/AppData/Roaming/alacritty"
    fi
else
    # macOS/Linux: 使用 ~/.config/alacritty
    CONFIG_DIR="$HOME/.config/alacritty"
fi

CONFIG_FILE="$CONFIG_DIR/alacritty.toml"
THEMES_DIR="$CONFIG_DIR/themes"

# 创建目标目录
mkdir -p "$CONFIG_DIR"
mkdir -p "$THEMES_DIR"

# 复制配置文件
echo "复制配置文件..."
echo "  源文件: $SOURCE_CONFIG"
echo "  目标文件: $CONFIG_FILE"

if cp "$SOURCE_CONFIG" "$CONFIG_FILE"; then
    echo "✓ 配置文件已成功复制到: $CONFIG_FILE"

    # macOS: 自动检测并修复 shell 路径
    if [ "$PLATFORM" == "macos" ]; then
        echo ""
        echo "检测并修复 shell 路径..."
        ZSH_PATH=""

        # 优先使用 Homebrew 安装的 zsh（Apple Silicon）
        if [ -f "/opt/homebrew/bin/zsh" ]; then
            ZSH_PATH="/opt/homebrew/bin/zsh"
            echo "  检测到 Homebrew 安装的 zsh: $ZSH_PATH"
        # 其次使用系统默认的 zsh
        elif [ -f "/bin/zsh" ]; then
            ZSH_PATH="/bin/zsh"
            echo "  使用系统默认的 zsh: $ZSH_PATH"
        fi

        if [ -n "$ZSH_PATH" ]; then
            # 检查配置文件中当前的 shell 路径是否存在
            CURRENT_SHELL=$(grep -E "^\s*program\s*=" "$CONFIG_FILE" 2>/dev/null | head -1 | sed -E 's|.*program\s*=\s*"([^"]+)".*|\1|')

            if [ -n "$CURRENT_SHELL" ] && [ ! -f "$CURRENT_SHELL" ]; then
                echo "  警告: 配置的 shell 路径不存在: $CURRENT_SHELL"
                echo "  自动修复为: $ZSH_PATH"
            fi

            # 自动修复 shell 路径（无论是否存在，都更新为检测到的正确路径）
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS 使用 BSD sed
                sed -i '' "s|program = \"/opt/homebrew/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null || \
                sed -i '' "s|program = \"/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null
            else
                # Linux 使用 GNU sed
                sed -i "s|program = \"/opt/homebrew/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null || \
                sed -i "s|program = \"/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null
            fi

            # 验证修复结果
            FINAL_SHELL=$(grep -E "^\s*program\s*=" "$CONFIG_FILE" 2>/dev/null | head -1 | sed -E 's|.*program\s*=\s*"([^"]+)".*|\1|')
            if [ "$FINAL_SHELL" = "$ZSH_PATH" ] && [ -f "$FINAL_SHELL" ]; then
                echo "✓ Shell 路径已修复为: $ZSH_PATH"
            else
                echo "✓ Shell 路径已配置为: $ZSH_PATH"
            fi
        else
            echo "  警告: 未找到 zsh，请检查配置"
        fi
    fi
else
    echo "✗ 复制失败"
    exit 1
fi

# 检查配置文件中引用的主题文件
echo ""
echo "检查主题文件..."

# 从配置文件中提取主题文件名
THEME_NAME=$(grep -E "themes/.*\.toml" "$CONFIG_FILE" | sed -E "s|.*themes/([^/]+)\.toml.*|\1|" | head -1)

if [ -n "$THEME_NAME" ]; then
    THEME_FILE="$THEMES_DIR/${THEME_NAME}.toml"
    echo "  检测到主题: $THEME_NAME"

    if [ -f "$THEME_FILE" ]; then
        echo "✓ 主题文件已存在: $THEME_FILE"
    else
        echo "⚠ 主题文件不存在: $THEME_FILE"
        read -p "是否从 GitHub 下载主题文件？(y/n，默认 y) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            THEME_URL="https://raw.githubusercontent.com/alacritty/alacritty-theme/master/themes/${THEME_NAME}.toml"
            echo "  正在下载: $THEME_URL"

            if command -v curl &> /dev/null; then
                if curl -L -f -o "$THEME_FILE" "$THEME_URL" 2>/dev/null; then
                    echo "✓ 主题文件下载成功: $THEME_FILE"
                else
                    echo "✗ 主题文件下载失败"
                    echo "  请手动下载: $THEME_URL"
                    echo "  保存到: $THEME_FILE"
                fi
            elif command -v wget &> /dev/null; then
                if wget -q -O "$THEME_FILE" "$THEME_URL" 2>/dev/null; then
                    echo "✓ 主题文件下载成功: $THEME_FILE"
                else
                    echo "✗ 主题文件下载失败"
                    echo "  请手动下载: $THEME_URL"
                    echo "  保存到: $THEME_FILE"
                fi
            else
                echo "✗ 未找到 curl 或 wget，无法自动下载"
                echo "  请手动下载: $THEME_URL"
                echo "  保存到: $THEME_FILE"
            fi
        else
            echo "  跳过主题文件下载"
            echo "  提示: 可以从以下地址手动下载:"
            echo "    https://raw.githubusercontent.com/alacritty/alacritty-theme/master/themes/${THEME_NAME}.toml"
        fi
    fi
else
    echo "  未检测到主题文件引用"
fi

echo ""
echo "=========================================="
echo "配置复制完成"
echo "=========================================="
echo ""
echo "配置文件位置: $CONFIG_FILE"
if [ "$PLATFORM" == "windows" ]; then
    WIN_PATH=$(echo "$CONFIG_FILE" | sed 's|/|\\|g')
    echo "Windows 路径格式: $WIN_PATH"
fi
if [ -n "$THEME_NAME" ]; then
    echo "主题文件位置: $THEMES_DIR/${THEME_NAME}.toml"
fi
echo ""
echo "注意: 配置文件是跨平台通用的，会自动适配不同系统"

