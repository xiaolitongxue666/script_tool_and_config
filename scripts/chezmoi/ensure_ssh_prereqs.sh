#!/usr/bin/env bash
# ============================================
# apply 前确保 SSH ProxyCommand 依赖就绪
# Linux: connect-proxy/connect；macOS: connect；Windows: connect.exe（随 Git for Windows）
# 供 install.sh 在 chezmoi apply 前调用，避免首次 apply 时模板依赖缺失
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
COMMON_INSTALL_SH="${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

if [[ -f "${COMMON_SH}" ]]; then
    # shellcheck source=../common.sh
    source "${COMMON_SH}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

if [[ -f "${COMMON_INSTALL_SH}" ]]; then
    # shellcheck source=common_install.sh
    source "${COMMON_INSTALL_SH}"
else
    log_warning "未找到 common_install.sh，将使用最小安装逻辑"
    detect_os_and_package_manager() {
        local os
        os="$(uname -s)"
        if [[ "$os" == "Darwin" ]]; then
            PLATFORM="macos"
            PACKAGE_MANAGER="brew"
        elif [[ "$os" == "Linux" ]]; then
            PLATFORM="linux"
            command -v pacman &>/dev/null && PACKAGE_MANAGER="pacman"
            command -v apt-get &>/dev/null && PACKAGE_MANAGER="apt"
            command -v dnf &>/dev/null && PACKAGE_MANAGER="dnf"
            command -v yum &>/dev/null && PACKAGE_MANAGER="yum"
        elif [[ "$os" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
            PLATFORM="windows"
            PACKAGE_MANAGER=""
        fi
    }
    install_package() {
        if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
            brew install "$1"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            sudo apt-get install -y "$1"
        elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            sudo pacman -S --noconfirm "$1"
        fi
    }
fi

# 检测当前平台（与 install.sh 一致）
detect_os_and_package_manager 2>/dev/null || true
if [[ -z "${PLATFORM:-}" ]]; then
    OS="$(uname -s)"
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        command -v pacman &>/dev/null && PACKAGE_MANAGER="pacman"
        command -v apt-get &>/dev/null && PACKAGE_MANAGER="apt"
        command -v dnf &>/dev/null && PACKAGE_MANAGER="dnf"
        command -v yum &>/dev/null && PACKAGE_MANAGER="yum"
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        PACKAGE_MANAGER=""
    else
        PLATFORM="unknown"
    fi
fi

has_connect_linux_macos() {
    command -v connect &>/dev/null && return 0
    [[ -x /opt/homebrew/bin/connect ]] && return 0
    [[ -x /usr/local/bin/connect ]] && return 0
    return 1
}

ensure_linux() {
    if has_connect_linux_macos; then
        log_info "connect 已存在: $(command -v connect 2>/dev/null || echo '/opt/homebrew/bin/connect 或 /usr/local/bin/connect')"
        return 0
    fi
    if [[ "${PACKAGE_MANAGER:-}" == "apt" ]]; then
        log_info "安装 connect-proxy（SSH 经代理连接 GitHub:443）..."
        if sudo apt-get install -y connect-proxy 2>/dev/null; then
            log_success "connect-proxy 安装完成"
        else
            log_warning "connect-proxy 安装失败，WSL 下可手动执行: sudo apt install connect-proxy"
        fi
    elif [[ "${PACKAGE_MANAGER:-}" == "pacman" ]]; then
        log_info "安装 connect（SSH 经代理连接 GitHub:443）..."
        if sudo pacman -S --noconfirm connect 2>/dev/null; then
            log_success "connect 安装完成"
        else
            log_warning "connect 安装失败或未找到，可跳过"
        fi
    elif [[ "${PACKAGE_MANAGER:-}" == "dnf" ]] || [[ "${PACKAGE_MANAGER:-}" == "yum" ]]; then
        log_warning "当前包管理器为 ${PACKAGE_MANAGER}，请手动安装 connect 或 connect-proxy 后重试"
    else
        log_warning "未检测到支持的包管理器，请手动安装 connect/connect-proxy"
    fi
}

ensure_darwin() {
    if has_connect_linux_macos; then
        log_info "connect 已存在: $(command -v connect 2>/dev/null || echo '已知路径')"
        return 0
    fi
    if [[ "${PACKAGE_MANAGER:-}" != "brew" ]]; then
        log_warning "需要 Homebrew，请先安装 Homebrew"
        return 1
    fi
    log_info "安装 connect（SSH 经代理连接 GitHub:443）..."
    if brew install connect 2>/dev/null; then
        log_success "connect 安装完成"
    else
        log_warning "connect 安装失败，请手动执行: brew install connect"
    fi
}

ensure_windows() {
    local connect_exe=""
    # 优先使用环境变量（与 .chezmoi.toml.local 中 windows_git_connect_path 对应，用户可 export）
    if [[ -n "${WINDOWS_GIT_CONNECT_PATH:-}" ]] && [[ -f "${WINDOWS_GIT_CONNECT_PATH}" ]]; then
        connect_exe="${WINDOWS_GIT_CONNECT_PATH}"
    fi
    if [[ -z "$connect_exe" ]] && command -v cmd &>/dev/null; then
        local detected
        detected="$(cmd //c "if exist \"C:\\Program Files\\Git\\mingw64\\bin\\connect.exe\" (echo C:/Program Files/Git/mingw64/bin/connect.exe) else (if exist \"D:\\Program Files\\Git\\mingw64\\bin\\connect.exe\" (echo D:/Program Files/Git/mingw64/bin/connect.exe) else (echo))" 2>/dev/null || true)"
        if [[ -n "$detected" ]] && [[ -f "$detected" ]]; then
            connect_exe="$detected"
        fi
    fi
    if [[ -n "$connect_exe" ]] && [[ -f "$connect_exe" ]]; then
        log_info "connect.exe 已存在: $connect_exe"
        return 0
    fi
    log_warning "未找到 connect.exe，SSH ProxyCommand 需要 Git for Windows 自带 connect。请先安装 Git for Windows，或在 .chezmoi.toml.local 中设置 windows_git_connect_path，或 export WINDOWS_GIT_CONNECT_PATH 指向 connect.exe"
}

case "${PLATFORM:-unknown}" in
    linux)
        ensure_linux
        ;;
    macos)
        ensure_darwin
        ;;
    windows)
        ensure_windows
        ;;
    *)
        log_warning "未知平台 ${PLATFORM:-unknown}，跳过 SSH 前置检查"
        ;;
esac
