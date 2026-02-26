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
    # 如果设置了 NO_PROXY=1，则完全禁用代理
    if [[ "${NO_PROXY:-0}" == "1" ]]; then
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
        echo "[INFO] 代理已禁用 (NO_PROXY=1)"
        return 0
    fi
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    echo "[INFO] 代理已设置: $proxy_url"
}

# 启用代理（用于非 pacman/Homebrew 操作）
enable_proxy() {
    local proxy_url="${1:-${http_proxy:-${HTTP_PROXY:-http://127.0.0.1:7890}}}"
    if [[ -n "${proxy_url:-}" ]] && [[ "${NO_PROXY:-0}" != "1" ]]; then
        export http_proxy="${proxy_url}"
        export https_proxy="${proxy_url}"
        export HTTP_PROXY="${proxy_url}"
        export HTTPS_PROXY="${proxy_url}"
        echo "[INFO] 代理已启用: ${proxy_url}"
    fi
}

# 禁用代理（用于 pacman/Homebrew 操作，使用国内源）
disable_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    echo "[INFO] 代理已禁用（用于包管理器操作）"
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
# Neovim 版本检查（与 dotfiles/nvim 配置最低要求一致）
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

# 跨平台 Cask 包安装函数（主要用于 macOS Homebrew Cask）
# 参数: package_name
install_cask_package() {
    local package_name="$1"
    if [ -z "$package_name" ]; then
        echo "[ERROR] 包名不能为空"
        return 1
    fi

    # 确保已检测操作系统
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_os_and_package_manager || return 1
    fi

    echo "[INFO] 安装 Cask 包: $package_name"

    case "$PACKAGE_MANAGER" in
        brew)
            brew install --cask "$package_name" || return 1
            ;;
        *)
            echo "[ERROR] Cask 包仅支持 Homebrew (macOS)"
            return 1
            ;;
    esac

    echo "[SUCCESS] Cask 包安装成功: $package_name"
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
# 下载函数
# ============================================

# 带进度显示的下载函数（带超时和重试）
# 参数: url dest [timeout] [max_retries]
download_with_progress() {
    local url="$1"
    local dest="$2"
    local timeout="${3:-60}"
    local max_retries="${4:-3}"

    log_info "开始下载: ${url}"

    # 确保目标目录存在
    local dest_dir=$(dirname "${dest}")
    if [[ ! -d "${dest_dir}" ]]; then
        mkdir -p "${dest_dir}" || {
            log_error "无法创建目录: ${dest_dir}"
            return 1
        }
    fi

    local retry_count=0
    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        # 优先使用 curl（进度条更简洁），其次 wget，最后使用 aria2c
        if command -v curl >/dev/null 2>&1; then
            if timeout "${timeout}" curl -fL --progress-bar --max-time "${timeout}" \
                -o "${dest}" "${url}" 2>&1; then
                echo ""
                log_success "下载完成: ${dest}"
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            if timeout "${timeout}" wget --show-progress --progress=bar:force:noscroll \
                --timeout="${timeout}" -O "${dest}" "${url}" 2>&1; then
                log_success "下载完成: ${dest}"
                return 0
            fi
        elif command -v aria2c >/dev/null 2>&1; then
            local aria2_output
            aria2_output=$(aria2c --check-certificate=false \
                --max-connection-per-server=8 \
                --split=8 \
                --dir="$(dirname "${dest}")" \
                --out="$(basename "${dest}")" \
                --summary-interval=5 \
                --console-log-level=warn \
                --timeout="${timeout}" \
                --max-tries="${max_retries}" \
                --quiet=false \
                "${url}" 2>&1)

            local aria2_exit=$?
            echo "${aria2_output}" | grep -E "^\[#.*\]" | tail -n 1 | sed 's/^/\r/' >&2 || true

            if [[ ${aria2_exit} -eq 0 ]] && [[ -f "${dest}" ]]; then
                echo "" >&2
                log_success "下载完成: ${dest}"
                return 0
            fi
        else
            log_error "没有可用的下载工具 (curl, wget, 或 aria2c)"
            return 1
        fi

        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "下载失败，重试中 (${retry_count}/${max_retries})..."
            sleep 2
            rm -f "${dest}" 2>/dev/null || true
        fi
    done

    log_error "下载失败，已重试 ${max_retries} 次: ${url}"
    return 1
}

# ============================================
# PATH 管理函数
# ============================================

# 备份 PATH 环境变量
# 参数: backup_dir (可选，默认 ~/.local/share/system_basic_env)
backup_path() {
    local backup_dir="${1:-${HOME}/.local/share/system_basic_env}"
    mkdir -p "${backup_dir}" || return 1
    local backup_file="${backup_dir}/path_backup_$(date +%Y%m%d_%H%M%S).txt"
    printf "%s\n" "${PATH}" > "${backup_file}"
    log_info "PATH 已备份到: ${backup_file}"
}

# 添加 PATH 入口
# 参数: path_entry path_env_file (可选，默认 ~/.config/system_basic_env/path.env)
add_path_entry() {
    local path_entry="$1"
    local path_env_file="${2:-${HOME}/.config/system_basic_env/path.env}"

    if [[ -z "${path_entry}" ]]; then
        log_error "PATH 入口不能为空"
        return 1
    fi

    # 确保文件存在
    local path_env_dir=$(dirname "${path_env_file}")
    if [[ ! -d "${path_env_dir}" ]]; then
        mkdir -p "${path_env_dir}" || return 1
    fi
    touch "${path_env_file}" || return 1

    # 检查路径是否已存在，避免重复添加
    if grep -qxF "export PATH=\"${path_entry}:\$PATH\"" "${path_env_file}" 2>/dev/null; then
        log_info "PATH 入口已存在: ${path_entry}"
        return 0
    fi

    # 追加路径到文件
    echo "export PATH=\"${path_entry}:\$PATH\"" >> "${path_env_file}"
    log_info "PATH 入口已记录: ${path_entry}"
}

# 准备 PATH 管理
# 参数: backup_dir (可选)
prepare_path_management() {
    local backup_dir="${1:-${HOME}/.local/share/system_basic_env}"
    backup_path "${backup_dir}"
    add_path_entry "/usr/local/bin"
    add_path_entry "${HOME}/.local/bin"
    add_path_entry "${HOME}/.cargo/bin"
}

# ============================================
# 日志管理函数
# ============================================

# 确保必要的目录存在
# 参数: log_dir state_dir config_dir
ensure_directories() {
    local log_dir="${1:-${HOME}/.local/share/system_basic_env/logs}"
    local state_dir="${2:-${HOME}/.local/share/system_basic_env}"
    local config_dir="${3:-${HOME}/.config/system_basic_env}"

    mkdir -p "${log_dir}" "${state_dir}" "${config_dir}" || {
        log_error "无法创建必要的目录"
        return 1
    }
    log_info "目录已创建: ${log_dir}, ${state_dir}, ${config_dir}"
}

# ============================================
# 权限检查函数
# ============================================

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限，请使用 sudo 运行"
        return 1
    fi
    return 0
}

# 检测安装用户（用于 AUR 构建）
# 返回: INSTALL_USER 变量
detect_install_user() {
    if [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
        INSTALL_USER="${SUDO_USER}"
    elif [[ -n "${PKEXEC_UID:-}" ]]; then
        INSTALL_USER="$(id -un "${PKEXEC_UID}")"
    else
        log_error "请使用 sudo 运行此脚本，以便使用非特权用户进行 AUR 构建任务"
        return 1
    fi
    log_info "非特权用户: ${INSTALL_USER}"
    return 0
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
