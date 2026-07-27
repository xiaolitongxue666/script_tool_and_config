#!/usr/bin/env bash

# ============================================
# 通用安装函数库（聚合入口）
# 用于 chezmoi run_once_ 脚本
# 子模块：detect_platform / brew_macos_network / package_install
# ============================================

_COMMON_INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 平台检测 SSOT
# shellcheck disable=SC1090
source "${_COMMON_INSTALL_DIR}/detect_platform.sh"

# 代理 + macOS Homebrew 网络策略
# shellcheck disable=SC1090
source "${_COMMON_INSTALL_DIR}/brew_macos_network.sh"

# 包安装 / 升级
# shellcheck disable=SC1090
source "${_COMMON_INSTALL_DIR}/package_install.sh"

# common-tools 包名 / 命令检测（batcat/fdfind 等）
# shellcheck disable=SC1090
source "${_COMMON_INSTALL_DIR}/software_policies.sh"

# ============================================
# Neovim 版本检查（与 ~/.config/nvim 配置最低要求一致）
# ============================================

# 检查已安装的 Neovim 是否 >= 0.11.0（本仓库配置要求）
# 返回 0 表示满足，返回 1 表示未安装、解析失败或版本低于 0.11.0
is_nvim_version_ge_0_11() {
    if ! command -v nvim &> /dev/null; then
        return 1
    fi
    local first_line
    first_line=$(nvim --version 2>/dev/null | head -n 1) || return 1
    # 解析 "NVIM v0.11.0" 或 "NVIM v0.11" 格式，提取 major.minor
    local major minor
    major=$(echo "$first_line" | sed -n 's/.*[vV]\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1/p')
    minor=$(echo "$first_line" | sed -n 's/.*[vV]\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\2/p')
    [[ -z "$major" || -z "$minor" ]] && return 1
    # >= 0.11.0: major>0 或 (major==0 且 minor>=11)
    if [[ "$major" -gt 0 ]]; then
        return 0
    fi
    if [[ "$minor" -ge 11 ]]; then
        return 0
    fi
    return 1
}

# ============================================
# run_once 上下文
# ============================================

# run_once 脚本的标准上下文初始化
# 参数 1: 脚本的 SCRIPT_DIR（通常为 $(dirname "${BASH_SOURCE[0]}")）
# 参数 2: 脚本显示名称（可选，用于日志）
# 此函数将：
#   1. 探测并 source common_install.sh
#   2. 如果无法 source，提供内联 fallback 函数
#   3. 调用 setup_proxy
#   4. 调用 detect_os_and_package_manager
load_run_once_context() {
    local caller_script_dir="$1"
    local script_display_name="${2:-run_once_script}"

    # 尝试从调用者的上下文推导 PROJECT_ROOT
    local project_root="${CHEZMOI_PROJECT_ROOT:-}"
    if [[ -z "$project_root" ]]; then
        # 向上查找直到找到 scripts/common.sh
        local probe_dir="$caller_script_dir"
        for _ in 1 2 3 4 5; do
            if [[ -f "${probe_dir}/scripts/common.sh" ]]; then
                project_root="$probe_dir"
                break
            fi
            probe_dir="$(cd "$probe_dir/.." && pwd 2>/dev/null)"
        done
    fi
    if [[ -z "$project_root" ]]; then
        project_root="${HOME}/.local/share/chezmoi"
    fi
    export CHEZMOI_PROJECT_ROOT="$project_root"

    # 尝试加载 common_install.sh
    local common_install="${COMMON_INSTALL:-${project_root}/scripts/chezmoi/common_install.sh}"
    if [[ ! -f "$common_install" ]]; then
        common_install="$HOME/.local/share/chezmoi/scripts/chezmoi/common_install.sh"
    fi

    local loaded=false
    if [[ -f "$common_install" ]]; then
        source "$common_install"
        loaded=true
    fi

    # 如果 source 失败或不可用，提供内联 fallback
    if [[ "$loaded" != "true" ]]; then
        echo "[WARNING] 未找到 common_install.sh ($common_install)，使用基本 fallback 函数"

        if ! type log_info &> /dev/null; then
            # shellcheck disable=SC2317
            function log_info() { echo "[INFO] $*"; }
            # shellcheck disable=SC2317
            function log_success() { echo "[SUCCESS] $*"; }
            # shellcheck disable=SC2317
            function log_warning() { echo "[WARNING] $*"; }
            # shellcheck disable=SC2317
            function log_error() { echo "[ERROR] $*" >&2; }
        fi

        if ! type setup_proxy &> /dev/null; then
            # shellcheck disable=SC2317
            function setup_proxy() {
                local proxy_url="${1:-http://127.0.0.1:7890}"
                if [[ "${NO_PROXY:-0}" == "1" ]]; then
                    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
                    return 0
                fi
                export http_proxy="$proxy_url" https_proxy="$proxy_url"
                export HTTP_PROXY="$proxy_url" HTTPS_PROXY="$proxy_url"
            }
        fi

        if ! type detect_os_and_package_manager &> /dev/null; then
            # shellcheck disable=SC2317
            function detect_os_and_package_manager() {
                OS="$(uname -s)"
                if [[ "$OS" == "Darwin" ]]; then
                    PLATFORM="darwin"; PACKAGE_MANAGER="brew"
                elif [[ "$OS" == "Linux" ]]; then
                    PLATFORM="linux"
                    command -v pacman &>/dev/null && PACKAGE_MANAGER="pacman"
                    command -v apt-get &>/dev/null && PACKAGE_MANAGER="apt"
                    command -v dnf &>/dev/null && PACKAGE_MANAGER="dnf"
                    command -v yum &>/dev/null && PACKAGE_MANAGER="yum"
                elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
                    PLATFORM="windows"
                    command -v winget &>/dev/null && PACKAGE_MANAGER="winget"
                    command -v pacman.exe &>/dev/null && PACKAGE_MANAGER="pacman"
                fi
                echo "[INFO] 平台: $PLATFORM, 包管理器: $PACKAGE_MANAGER"
            }
        fi

        if ! type install_package &> /dev/null; then
            # shellcheck disable=SC2317
            function install_package() {
                local pkg="$1"
                if [[ -z "${PACKAGE_MANAGER:-}" ]]; then
                    echo "[ERROR] 未检测到包管理器"
                    return 1
                fi
                case "$PACKAGE_MANAGER" in
                    brew) brew install "$pkg" ;;
                    pacman)
                        if [[ "${PLATFORM:-}" == "windows" ]]; then
                            pacman.exe -S --noconfirm "$pkg"
                        else
                            sudo pacman -S --noconfirm "$pkg"
                        fi
                        ;;
                    apt) sudo apt-get install -y "$pkg" ;;
                    dnf) sudo dnf install -y "$pkg" ;;
                    yum) sudo yum install -y "$pkg" ;;
                    winget) winget install --id="$pkg" -e --accept-source-agreements --accept-package-agreements ;;
                    *) echo "[ERROR] 不支持的包管理器: $PACKAGE_MANAGER"; return 1 ;;
                esac
            }
        fi

        if ! type is_nvim_version_ge_0_11 &> /dev/null; then
            # shellcheck disable=SC2317
            function is_nvim_version_ge_0_11() { return 1; }
        fi
    fi

    # 设置代理（run_once 模板可先 export PROXY；勿在此嵌入 Go 模板语法）
    local proxy_url="${PROXY:-${http_proxy:-${HTTP_PROXY:-http://127.0.0.1:7890}}}"
    setup_proxy "$proxy_url"

    # 检测操作系统和包管理器
    detect_os_and_package_manager || return 1

    echo "[INFO] 上下文已加载: ${script_display_name}"
    echo "[INFO] 平台: ${PLATFORM:-未知}, 包管理器: ${PACKAGE_MANAGER:-未知}"
}
