#!/bin/bash

# ============================================
# dwm (Dynamic Window Manager) 安装脚本（chezmoi run_once_）
# 仅支持 Linux
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
        if [[ "$OS" != "Linux" ]]; then
            echo "[ERROR] dwm 仅支持 Linux"
            exit 1
        fi
        if command -v pacman &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        elif command -v apt-get &> /dev/null; then
            PACKAGE_MANAGER="apt"
        fi
    }
    function install_package() {
        local pkg="$1"
        if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            sudo pacman -S --noconfirm "$pkg"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            sudo apt-get update && sudo apt-get install -y "$pkg"
        fi
    }
    function install_dependencies() {
        for dep in "$@"; do
            install_package "$dep"
        done
    }
fi

# 设置代理
setup_proxy "${PROXY:-http://127.0.0.1:7890}"

# 检测操作系统和包管理器
detect_os_and_package_manager || exit 1

# 检查 dwm 是否已安装
if command -v dwm &> /dev/null; then
    echo "[INFO] dwm 已安装: $(dwm -v 2>&1 | head -n 1)"
    exit 0
fi

echo "[INFO] 开始安装 dwm..."

# 安装编译依赖
install_dependencies "base-devel" "git" "libx11" "libxft" "libxinerama"

# dwm 需要从源码编译
DWM_DIR="$HOME/.local/src/dwm"
mkdir -p "$(dirname "$DWM_DIR")"

if [ ! -d "$DWM_DIR" ]; then
    echo "[INFO] 克隆 dwm 源码..."
    git clone https://git.suckless.org/dwm "$DWM_DIR"
fi

cd "$DWM_DIR"

# 如果有自定义配置，应用它
if [ -f "$HOME/.config/dwm/config.h" ]; then
    echo "[INFO] 应用自定义配置..."
    cp "$HOME/.config/dwm/config.h" "$DWM_DIR/config.h"
fi

# 编译并安装
echo "[INFO] 编译 dwm..."
make clean
make
sudo make install

if command -v dwm &> /dev/null; then
    echo "[SUCCESS] dwm 安装成功"
else
    echo "[ERROR] dwm 安装失败"
    exit 1
fi
