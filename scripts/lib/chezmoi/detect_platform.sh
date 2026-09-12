#!/usr/bin/env bash

# ============================================
# 平台 / 包管理器检测（SSOT）
# 被 common_install.sh、chezmoi_core.sh、deploy.sh 共用
# 禁止在入口脚本内再写一套 OS 分支
# ============================================

# 仅检测操作系统平台（不检测包管理器）
# 设置: OS, PLATFORM (darwin|linux|windows), PLATFORM_NAME
detect_platform() {
    OS="$(uname -s)"
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="darwin"
        PLATFORM_NAME="macOS"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        PLATFORM_NAME="Linux"
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        PLATFORM_NAME="Windows"
    else
        echo "[ERROR] Unsupported OS: $OS" >&2
        return 1
    fi
    echo "[INFO] Platform: $PLATFORM_NAME ($OS)" >&2
}

# 检测操作系统和包管理器
# 设置: OS, PLATFORM, PACKAGE_MANAGER
detect_os_and_package_manager() {
    OS="$(uname -s)"

    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="darwin"
        if command -v brew &> /dev/null; then
            PACKAGE_MANAGER="brew"
        else
            echo "[ERROR] Homebrew is required on macOS" >&2
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
            echo "[ERROR] No supported package manager detected" >&2
            return 1
        fi
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        if command -v winget &> /dev/null; then
            PACKAGE_MANAGER="winget"
        elif command -v pacman.exe &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        else
            echo "[ERROR] winget or MSYS2 is required on Windows" >&2
            return 1
        fi
    else
        echo "[ERROR] Unsupported OS: $OS" >&2
        return 1
    fi

    echo "[INFO] Platform: $PLATFORM, package manager: $PACKAGE_MANAGER" >&2
}

# chezmoi_core 兼容别名（同一实现）
chezmoi_detect_platform() {
    detect_platform
}

# 检测是否为 WSL（仅 Linux 为真）
chezmoi_is_wsl() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        return 1
    fi
    grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSLENV:-}" ]]
}

# 兼容旧名
is_wsl() {
    chezmoi_is_wsl
}

# 是否为 Arch Linux（含 archarm；不含 Ubuntu/Debian/WSL-Ubuntu）
is_arch_linux() {
    [[ "$(uname -s 2>/dev/null || true)" == "Linux" ]] || return 1
    [[ -f /etc/os-release ]] || return 1
    local id id_like
    # shellcheck disable=SC1091
    id="$(. /etc/os-release 2>/dev/null; echo "${ID:-}")"
    # shellcheck disable=SC1091
    id_like="$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-}")"
    [[ "$id" == "arch" || "$id" == "archarm" || "$id_like" == *arch* ]]
}
