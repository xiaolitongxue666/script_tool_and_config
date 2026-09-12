#!/usr/bin/env bash
# 将 btop4win 路径添加到 Git Bash 配置文件
# 使用方法：在 Git Bash 中运行此脚本

BASH_PROFILE="$HOME/.bash_profile"
BTOP_PATH="/c/Program Files/btop4win"
BTOP_EXE="$BTOP_PATH/btop4win.exe"

echo "========================================"
echo "Adding btop4win to Git Bash PATH"
echo "========================================"
echo ""

# 检查 btop4win 是否存在
if [ ! -f "$BTOP_EXE" ]; then
    echo "[ERROR] btop4win.exe not found at: $BTOP_EXE"
    echo "Please install btop4win first."
    exit 1
fi

echo "[OK] btop4win.exe found at: $BTOP_EXE"
echo ""

# 检查 .bash_profile 是否存在
if [ ! -f "$BASH_PROFILE" ]; then
    echo "[INFO] Creating .bash_profile..."
    touch "$BASH_PROFILE"
    echo "# Git Bash 配置文件" >> "$BASH_PROFILE"
    echo "" >> "$BASH_PROFILE"
fi

# 检查是否已经添加了 btop4win 路径
if grep -q "btop4win" "$BASH_PROFILE"; then
    echo "[INFO] btop4win path already exists in .bash_profile"
    echo "Removing old configuration..."

    # 创建一个临时文件，移除所有 btop4win 相关行
    grep -v "btop4win" "$BASH_PROFILE" > "$BASH_PROFILE.tmp" 2>/dev/null || true
    mv "$BASH_PROFILE.tmp" "$BASH_PROFILE" 2>/dev/null || true
fi

# 添加到文件末尾（简单可靠的方法）
echo "" >> "$BASH_PROFILE"
echo "# btop4win 配置（系统监控工具）" >> "$BASH_PROFILE"
echo "# 如果 btop4win 已安装，添加到 PATH" >> "$BASH_PROFILE"
echo "if [ -d \"$BTOP_PATH\" ]; then" >> "$BASH_PROFILE"
echo "    export PATH=\"$BTOP_PATH:\$PATH\"" >> "$BASH_PROFILE"
echo "fi" >> "$BASH_PROFILE"

echo "[OK] btop4win path added to .bash_profile"
echo ""
echo "========================================"
echo "Verification"
echo "========================================"
echo ""

# 重新加载配置
source "$BASH_PROFILE"

# 验证
if command -v btop4win >/dev/null 2>&1; then
    echo "[SUCCESS] btop4win is now available!"
    echo ""
    echo "Version:"
    btop4win --version
    echo ""
    echo "The configuration has been saved to: $BASH_PROFILE"
    echo "It will be automatically loaded in all new Git Bash sessions."
else
    echo "[WARNING] btop4win not found in current session"
    echo "Please restart Git Bash or run: source $BASH_PROFILE"
fi

echo ""

