#!/bin/bash

# ============================================
# Zsh 安装脚本（chezmoi run_once_）
# Windows 特定（通过 MSYS2）
# ============================================

# 获取 common_install.sh 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd 2>/dev/null || echo "$HOME")"
COMMON_INSTALL="${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

if [ ! -f "$COMMON_INSTALL" ]; then
    COMMON_INSTALL="$HOME/.local/share/chezmoi/scripts/chezmoi/common_install.sh"
fi

# 加载通用函数库
if [ -f "$COMMON_INSTALL" ]; then
    source "$COMMON_INSTALL"
else
    echo "[WARNING] 未找到 common_install.sh，使用基本函数"
    function setup_proxy() { :; }
    function detect_os_and_package_manager() {
        OS="$(uname -s)"
        if [[ ! "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
            echo "[ERROR] 此脚本仅支持 Windows"
            exit 1
        fi
        if command -v pacman.exe &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        elif command -v winget &> /dev/null; then
            PACKAGE_MANAGER="winget"
        else
            echo "[ERROR] 需要 MSYS2 或 winget"
            exit 1
        fi
    }
    function install_package() {
        local pkg="$1"
        if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            pacman.exe -S --noconfirm "$pkg"
        elif [[ "$PACKAGE_MANAGER" == "winget" ]]; then
            winget install --id="$pkg" -e --accept-source-agreements --accept-package-agreements
        fi
    }
fi

# 设置代理
setup_proxy "${PROXY:-http://127.0.0.1:7890}"

# 检测操作系统和包管理器
detect_os_and_package_manager || exit 1

# 检查 Zsh 是否已安装
if command -v zsh &> /dev/null; then
    echo "[INFO] Zsh 已安装: $(zsh --version)"
    exit 0
fi

echo "[INFO] 开始安装 Zsh..."

# 检查 MSYS2
if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
    install_package "zsh"
elif [[ "$PACKAGE_MANAGER" == "winget" ]]; then
    # 通过 winget 安装 MSYS2，然后安装 zsh
    if ! command -v pacman.exe &> /dev/null; then
        echo "[INFO] 安装 MSYS2..."
        winget install --id=MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements
        echo "[INFO] 请重启终端后再次运行此脚本"
        exit 0
    fi
    install_package "zsh"
fi

if command -v zsh &> /dev/null; then
    echo "[SUCCESS] Zsh 安装成功: $(zsh --version)"
else
    echo "[ERROR] Zsh 安装失败"
    exit 1
fi
