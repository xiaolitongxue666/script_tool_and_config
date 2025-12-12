#!/bin/bash

# ============================================
# Zsh 和 Oh My Zsh 安装脚本（chezmoi run_once_）
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
        if [[ "$OS" == "Darwin" ]]; then
            PLATFORM="macos"
            PACKAGE_MANAGER="brew"
        elif [[ "$OS" == "Linux" ]]; then
            PLATFORM="linux"
            if command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
            elif command -v apt-get &> /dev/null; then
                PACKAGE_MANAGER="apt"
            fi
        fi
    }
    function install_package() {
        local pkg="$1"
        if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
            brew install "$pkg"
        elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            sudo pacman -S --noconfirm "$pkg"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            sudo apt-get update && sudo apt-get install -y "$pkg"
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
else
    echo "[INFO] 开始安装 Zsh..."

    case "$PLATFORM" in
        macos)
            if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
                install_package "zsh"
            else
                echo "[INFO] macOS 通常已预装 Zsh"
            fi
            ;;
        linux)
            install_package "zsh"
            ;;
        *)
            echo "[ERROR] 不支持的操作系统"
            exit 1
            ;;
    esac
fi

# 安装 Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[INFO] 安装 Oh My Zsh..."
    export RUNZSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "[INFO] Oh My Zsh 已安装"
fi

echo "[SUCCESS] Zsh 和 Oh My Zsh 安装完成"
