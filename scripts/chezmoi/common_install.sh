#!/bin/bash

# ============================================
# 通用安装函数库
# 用于 chezmoi run_once_ 脚本
# 提供代理配置、包管理器、依赖安装等功能
# ============================================

# ============================================
# 代理配置函数
# ============================================

# 设置代理环境变量
# 参数: proxy_url (可选，默认 http://127.0.0.1:7890)
setup_proxy() {
    local proxy_url="${1:-http://127.0.0.1:7890}"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    echo "[INFO] 代理已设置: $proxy_url"
}

# 检查代理是否可用
check_proxy() {
    local proxy_url="${1:-${http_proxy:-http://127.0.0.1:7890}}"
    if curl -s --proxy "$proxy_url" --max-time 5 https://www.google.com > /dev/null 2>&1; then
        echo "[INFO] 代理可用: $proxy_url"
        return 0
    else
        echo "[WARNING] 代理不可用: $proxy_url"
        return 1
    fi
}

# ============================================
# 操作系统和包管理器检测
# ============================================

# 检测操作系统和包管理器
detect_os_and_package_manager() {
    OS="$(uname -s)"

    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="macos"
        if command -v brew &> /dev/null; then
            PACKAGE_MANAGER="brew"
        else
            echo "[ERROR] macOS 需要安装 Homebrew"
            return 1
        fi
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        if command -v pacman &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        elif command -v apt-get &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        else
            echo "[ERROR] 未检测到支持的包管理器"
            return 1
        fi
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        if command -v winget &> /dev/null; then
            PACKAGE_MANAGER="winget"
        elif command -v pacman.exe &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        else
            echo "[ERROR] Windows 需要安装 winget 或 MSYS2"
            return 1
        fi
    else
        echo "[ERROR] 不支持的操作系统: $OS"
        return 1
    fi

    echo "[INFO] 平台: $PLATFORM, 包管理器: $PACKAGE_MANAGER"
}

# ============================================
# 包安装函数
# ============================================

# 跨平台包安装函数
# 参数: package_name
install_package() {
    local package_name="$1"
    if [ -z "$package_name" ]; then
        echo "[ERROR] 包名不能为空"
        return 1
    fi

    # 确保已检测操作系统
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_os_and_package_manager || return 1
    fi

    echo "[INFO] 安装包: $package_name"

    case "$PACKAGE_MANAGER" in
        brew)
            brew install "$package_name" || return 1
            ;;
        pacman)
            if [[ "$PLATFORM" == "windows" ]]; then
                # Windows MSYS2
                pacman.exe -S --noconfirm "$package_name" || return 1
            else
                # Linux Arch
                sudo pacman -S --noconfirm "$package_name" || return 1
            fi
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y "$package_name" || return 1
            ;;
        dnf)
            sudo dnf install -y "$package_name" || return 1
            ;;
        yum)
            sudo yum install -y "$package_name" || return 1
            ;;
        winget)
            winget install --id="$package_name" -e --accept-source-agreements --accept-package-agreements || return 1
            ;;
        *)
            echo "[ERROR] 不支持的包管理器: $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    echo "[SUCCESS] 包安装成功: $package_name"
}

# ============================================
# 依赖安装函数
# ============================================

# 安装前置依赖
# 参数: 依赖包列表（空格分隔）
install_dependencies() {
    if [ $# -eq 0 ]; then
        echo "[WARNING] 未提供依赖列表"
        return 0
    fi

    echo "[INFO] 检查并安装前置依赖..."

    # 确保已检测操作系统
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_os_and_package_manager || return 1
    fi

    for dep in "$@"; do
        # 检查是否已安装
        if command -v "$dep" &> /dev/null; then
            echo "[INFO] 依赖已安装: $dep"
            continue
        fi

        # 尝试安装
        install_package "$dep" || echo "[WARNING] 依赖安装失败: $dep"
    done

    echo "[SUCCESS] 依赖检查完成"
}

# ============================================
# 命令检查函数
# ============================================

# 检查命令是否存在，不存在则安装
# 参数: command_name [package_name]
check_command_or_install() {
    local command_name="$1"
    local package_name="${2:-$command_name}"

    if command -v "$command_name" &> /dev/null; then
        echo "[INFO] 命令已存在: $command_name"
        return 0
    fi

    echo "[INFO] 命令不存在，尝试安装: $package_name"
    install_package "$package_name"
}

# ============================================
# 日志函数（如果 common.sh 不可用）
# ============================================

if ! type log_info &> /dev/null; then
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi
