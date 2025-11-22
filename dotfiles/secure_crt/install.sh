#!/bin/bash

# SecureCRT 配置安装脚本
# 仅支持 Windows 系统（通过 Git Bash/MSYS2 运行）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "SecureCRT 配置安装脚本"
echo "=========================================="

# 检查操作系统
if [[ "$OS" != MINGW* ]] && [[ "$OS" != MSYS* ]] && [[ "$OS" != CYGWIN* ]]; then
    echo "警告: SecureCRT 主要支持 Windows 系统"
    echo "当前系统: $OS"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# SecureCRT 配置目录（Windows）
if [[ "$OS" == MINGW* ]] || [[ "$OS" == MSYS* ]] || [[ "$OS" == CYGWIN* ]]; then
    # Windows 路径
    SECURECRT_CONFIG_DIR="$APPDATA/VanDyke/Config"
    if [ -z "$APPDATA" ]; then
        SECURECRT_CONFIG_DIR="$HOME/AppData/Roaming/VanDyke/Config"
    fi
else
    echo "错误: 无法确定 SecureCRT 配置目录"
    exit 1
fi

echo "SecureCRT 配置目录: $SECURECRT_CONFIG_DIR"

# 创建配置目录
mkdir -p "$SECURECRT_CONFIG_DIR"

# 复制配置文件
echo ""
echo "正在复制配置文件..."

if [ -f "$SCRIPT_DIR/SecureCRTV8_VM_Login_TOP.vbs" ]; then
    cp "$SCRIPT_DIR/SecureCRTV8_VM_Login_TOP.vbs" "$SECURECRT_CONFIG_DIR/"
    echo "已复制 VBScript: SecureCRTV8_VM_Login_TOP.vbs"
fi

if [ -f "$SCRIPT_DIR/windows7_securecrt_config.xml" ]; then
    cp "$SCRIPT_DIR/windows7_securecrt_config.xml" "$SECURECRT_CONFIG_DIR/"
    echo "已复制配置文件: windows7_securecrt_config.xml"
fi

if [ -f "$SCRIPT_DIR/windows7_securecrt_config.log" ]; then
    cp "$SCRIPT_DIR/windows7_securecrt_config.log" "$SECURECRT_CONFIG_DIR/"
    echo "已复制日志文件: windows7_securecrt_config.log"
fi

echo ""
echo "=========================================="
echo "SecureCRT 配置安装完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $SECURECRT_CONFIG_DIR"
echo ""
echo "注意:"
echo "1. 需要在 SecureCRT 中手动导入配置"
echo "2. VBScript 文件可以在 SecureCRT 的脚本菜单中使用"

