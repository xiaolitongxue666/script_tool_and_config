#!/bin/bash
# 将 alacritty.toml 复制到部署位置的脚本

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

# 创建目标目录
mkdir -p "$CONFIG_DIR"

# 复制配置文件
echo "复制配置文件..."
echo "  源文件: $SOURCE_CONFIG"
echo "  目标文件: $CONFIG_FILE"

if cp "$SOURCE_CONFIG" "$CONFIG_FILE"; then
    echo "✓ 配置文件已成功复制到: $CONFIG_FILE"
    echo ""
    echo "注意: 配置文件是跨平台通用的，会自动适配不同系统"
    if [ "$PLATFORM" == "windows" ]; then
        WIN_PATH=$(echo "$CONFIG_FILE" | sed 's|/|\\|g')
        echo "Windows 路径格式: $WIN_PATH"
    fi
else
    echo "✗ 复制失败"
    exit 1
fi

