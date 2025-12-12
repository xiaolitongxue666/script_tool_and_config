#!/bin/bash

# ============================================
# Starship 提示符安装脚本（chezmoi run_once_）
# ============================================

# 获取 common_install.sh 路径
# chezmoi 会将脚本复制到 ~/.local/share/chezmoi/scripts/ 或使用项目路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd 2>/dev/null || echo "$HOME")"
COMMON_INSTALL="${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

# 如果找不到项目路径，尝试使用 chezmoi 脚本路径
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
            PACKAGE_MANAGER="pacman"
        else
            echo "[ERROR] 不支持的操作系统"
            exit 1
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

# 设置代理（默认 127.0.0.1:7890）
setup_proxy "${PROXY:-http://127.0.0.1:7890}"

# 检测操作系统和包管理器
detect_os_and_package_manager || exit 1

# 检查 Starship 是否已安装
if command -v starship &> /dev/null; then
    echo "[INFO] Starship 已安装: $(starship --version | head -n 1)"
    exit 0
fi

echo "[INFO] 开始安装 Starship..."

# 根据平台安装 Starship
case "$PLATFORM" in
    macos)
        if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
            install_package "starship"
        else
            echo "[INFO] 使用官方安装脚本..."
            curl -sS https://starship.rs/install.sh | sh
        fi
        ;;
    linux)
        if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            install_package "starship"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            install_package "starship"
        else
            echo "[INFO] 使用官方安装脚本..."
            curl -sS https://starship.rs/install.sh | sh
        fi
        ;;
    *)
        echo "[INFO] 使用官方安装脚本..."
        curl -sS https://starship.rs/install.sh | sh
        ;;
esac

if command -v starship &> /dev/null; then
    echo "[SUCCESS] Starship 安装成功: $(starship --version | head -n 1)"
else
    echo "[ERROR] Starship 安装失败"
    exit 1
fi
