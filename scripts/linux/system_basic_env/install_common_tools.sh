#!/usr/bin/env bash

# 启用严格模式：遇到错误立即退出，未定义变量报错，管道中任一命令失败则整个管道失败
set -euo pipefail
# 设置默认文件权限掩码
umask 022

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取项目根目录的绝对路径
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# 通用脚本库路径
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

# 检查通用脚本库是否存在
if [[ ! -f "${COMMON_LIB}" ]]; then
    echo "[ERROR] Common script library not found: ${COMMON_LIB}" >&2
    exit 1
fi

# 引入通用日志/错误处理函数
# shellcheck disable=SC1090
source "${COMMON_LIB}"

# 日志目录
readonly LOG_DIR="${PROJECT_ROOT}/logs/system_basic_env"
# 状态目录
readonly STATE_DIR="${HOME}/.local/share/system_basic_env"
# 配置目录
readonly CONFIG_DIR="${HOME}/.config/system_basic_env"
# PATH 环境变量文件
readonly PATH_ENV_FILE="${CONFIG_DIR}/path.env"
# pacman 配置文件路径
readonly PACMAN_CONF="/etc/pacman.conf"
# 镜像列表文件路径
readonly MIRRORLIST="/etc/pacman.d/mirrorlist"
# 默认代理 URL
readonly DEFAULT_PROXY_URL="${DEFAULT_PROXY_URL:-http://192.168.1.76:7890}"
# 字体版本
readonly FONT_VERSION="${FONT_VERSION:-3.2.1}"
# 字体名称
readonly FONT_NAME="FiraMono"
# 字体下载 URL
readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip"
# 字体安装目录
readonly FONT_DIR="/usr/local/share/fonts/${FONT_NAME}-NerdFont"
# pacman 软件包列表
readonly PACMAN_PACKAGES=(
    base-devel git curl wget aria2 tmux starship github-cli lazygit git-delta
    fzf ripgrep fd bat eza trash-cli fastfetch btop unzip zip which sudo
    neovim gcc make tree net-tools openssh iputils file cmake ctags
)

# 全局变量
PROXY_URL=""
AUR_HELPER=""
LOG_FILE=""
INSTALL_USER=""

# 错误处理：捕获 ERR 信号并记录错误信息
trap 'log_error "Error detected, exiting script"; exit 1' ERR

# 确保必要的目录存在
ensure_directories() {
    ensure_directory "${LOG_DIR}"
    ensure_directory "${STATE_DIR}"
    ensure_directory "${CONFIG_DIR}"
    # 创建带时间戳的日志文件
    LOG_FILE="${LOG_DIR}/install_common_tools_$(date +%Y%m%d_%H%M%S).log"
    # 将标准输出和标准错误都重定向到日志文件，同时显示在终端
    exec > >(tee -a "${LOG_FILE}") 2>&1
    log_info "Log file: ${LOG_FILE}"
}

# 备份 PATH 环境变量
backup_path() {
    local backup_file="${STATE_DIR}/path_backup_$(date +%Y%m%d_%H%M%S).txt"
    # 使用 printf 而不是 echo，避免路径中的特殊字符问题
    printf "%s\n" "${PATH}" > "${backup_file}"
    log_info "PATH backed up to: ${backup_file}"
}

# 添加 PATH 入口
add_path_entry() {
    local path_entry="$1"
    # 检查路径是否已存在，避免重复添加
    if grep -qxF "export PATH=\"${path_entry}:\$PATH\"" "${PATH_ENV_FILE}" 2>/dev/null; then
        return 0
    fi
    # 追加路径到文件
    echo "export PATH=\"${path_entry}:\$PATH\"" >> "${PATH_ENV_FILE}"
    log_info "PATH entry recorded: ${path_entry}"
}

# 准备 PATH 管理
prepare_path_management() {
    backup_path
    # 确保文件存在
    touch "${PATH_ENV_FILE}"
    add_path_entry "/usr/local/bin"
    add_path_entry "${HOME}/.local/bin"
    add_path_entry "${HOME}/.cargo/bin"
}

# 检查是否为 Arch Linux
check_arch_linux() {
    if [[ ! -f /etc/os-release ]]; then
        error_exit "Cannot detect system version"
    fi
    # shellcheck disable=SC1091
    # 读取系统发行版信息
    source /etc/os-release
    if [[ "${ID:-}" != "arch" ]]; then
        error_exit "This script only supports Arch Linux"
    fi
    log_info "Arch Linux detected"
}

# 检测安装用户（用于 AUR 构建）
detect_install_user() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        INSTALL_USER="${SUDO_USER}"
    elif [[ -n "${PKEXEC_UID:-}" ]]; then
        # 从 PKEXEC_UID 获取用户名
        INSTALL_USER="$(id -un "${PKEXEC_UID}")"
    else
        error_exit "Please run this script with sudo to use a non-privileged user for AUR build tasks"
    fi
    log_info "Non-privileged user: ${INSTALL_USER}"
}

# 启用代理（用于非 pacman 操作）
enable_proxy() {
    # 从环境变量或默认值获取代理 URL
    PROXY_URL="${HTTP_PROXY:-${HTTPS_PROXY:-${PROXY_URL:-${DEFAULT_PROXY_URL}}}}"

    if [[ -n "${PROXY_URL:-}" ]]; then
        # 设置代理环境变量
        export http_proxy="${PROXY_URL}"
        export https_proxy="${PROXY_URL}"
        export HTTP_PROXY="${PROXY_URL}"
        export HTTPS_PROXY="${PROXY_URL}"
        log_info "Proxy enabled: ${PROXY_URL}"

        # 测试代理是否可用
        if curl -s --connect-timeout 3 --max-time 5 --proxy "${PROXY_URL}" "https://www.google.com" >/dev/null 2>&1; then
            log_info "Proxy connection test: OK"
        else
            log_warning "Proxy connection test failed, but will still use proxy"
        fi
    else
        log_info "No proxy URL configured, using direct connection"
        PROXY_URL=""
    fi
}

# 禁用代理（用于 pacman 操作，使用国内源）
disable_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    log_info "Proxy disabled for pacman operations (using Chinese mirrors)"
}

# 初始化代理配置（在脚本开始时调用）
setup_proxy() {
    # 默认启用代理（除了 pacman 操作）
    # 可以通过 NO_PROXY=1 完全禁用代理
    if [[ "${NO_PROXY:-0}" == "1" ]]; then
        log_info "Proxy disabled by NO_PROXY=1, using direct connection for all operations"
        PROXY_URL=""
        return 0
    fi

    # 默认启用代理
    enable_proxy
}

# 带进度显示的下载函数（带超时和重试，简洁进度显示）
download_with_progress() {
    local url="$1"
    local dest="$2"
    local timeout="${3:-60}"  # 默认超时60秒
    local max_retries="${4:-3}"  # 默认重试3次

    log_info "Starting download: ${url}"
    # 确保目标目录存在
    ensure_directory "$(dirname "${dest}")"

    local retry_count=0
    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        # 优先使用 curl（进度条更简洁），其次 wget，最后使用 aria2c
        if command -v curl >/dev/null 2>&1; then
            # curl 使用简洁的单行进度条
            if timeout "${timeout}" curl -fL --progress-bar --max-time "${timeout}" \
                -o "${dest}" "${url}" 2>&1; then
                echo ""  # 换行，避免进度条和成功消息在同一行
                log_success "Download completed: ${dest}"
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            # wget 使用简洁的进度条
            if timeout "${timeout}" wget --show-progress --progress=bar:force:noscroll \
                --timeout="${timeout}" -O "${dest}" "${url}" 2>&1; then
                log_success "Download completed: ${dest}"
                return 0
            fi
        elif command -v aria2c >/dev/null 2>&1; then
            # aria2c 使用适中的更新间隔（5秒），过滤重复信息，只显示进度条
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

            # 过滤并显示进度信息
            echo "${aria2_output}" | grep -E "^\[#.*\]" | tail -n 1 | sed 's/^/\r/' >&2 || true

            if [[ ${aria2_exit} -eq 0 ]]; then
                echo "" >&2  # 换行
                # 检查文件是否成功下载
                if [[ -f "${dest}" ]]; then
                    log_success "Download completed: ${dest}"
                    return 0
                fi
            fi
        else
            log_error "No download tool available (curl, wget, or aria2c)"
            return 1
        fi

        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "Download failed, retrying (${retry_count}/${max_retries})..."
            sleep 2
            rm -f "${dest}" 2>/dev/null || true
        fi
    done

    log_error "Download failed after ${max_retries} attempts: ${url}"
    return 1
}

# 配置 pacman 代理（始终移除代理配置，pacman 使用国内源直连）
configure_pacman_proxy() {
    # 使用临时文件来安全地修改配置
    local tmp_file
    tmp_file="$(mktemp)"
    local has_xfercommand=0

    # 检查是否存在 XferCommand
    while IFS= read -r line; do
        if [[ "${line}" =~ ^XferCommand ]]; then
            has_xfercommand=1
            break
        fi
    done < "${PACMAN_CONF}"

    # 始终移除 XferCommand 配置，pacman 使用国内源直连
    if [[ "${has_xfercommand}" -eq 1 ]]; then
        log_info "Removing XferCommand configuration, pacman will use direct connection (Chinese mirrors)"
        while IFS= read -r line; do
            # 跳过所有 XferCommand 行
            if [[ "${line}" =~ ^XferCommand ]]; then
                continue
            fi
            echo "${line}" >> "${tmp_file}"
        done < "${PACMAN_CONF}"
        mv "${tmp_file}" "${PACMAN_CONF}"
        log_info "XferCommand removed, pacman will use direct connection"
    else
        log_info "Pacman configured to use direct connection (Chinese mirrors)"
    fi
}

# 配置中国镜像源（基于可用性测试结果，2025年11月更新）
configure_mirrors() {
    backup_file "${MIRRORLIST}"
    cat > "${MIRRORLIST}" <<'EOF'
## Aliyun (HTTPS, primary)
Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
## USTC (HTTPS, secondary)
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
## Tencent Cloud (HTTPS, tertiary)
Server = https://mirrors.cloud.tencent.com/archlinux/$repo/os/$arch
## Huawei Cloud (HTTPS)
Server = https://mirrors.huaweicloud.com/repository/archlinux/$repo/os/$arch
## Nanjing University (HTTPS)
Server = https://mirrors.nju.edu.cn/archlinux/$repo/os/$arch
## Chongqing University (HTTPS)
Server = https://mirrors.cqu.edu.cn/archlinux/$repo/os/$arch
## Neusoft (HTTPS)
Server = https://mirrors.neusoft.edu.cn/archlinux/$repo/os/$arch
## Lanzhou University (HTTPS)
Server = https://mirror.lzu.edu.cn/archlinux/$repo/os/$arch
## Southern University of Science and Technology (HTTPS)
Server = https://mirrors.sustech.edu.cn/archlinux/$repo/os/$arch
EOF
    log_info "Chinese mirror sources applied (9 available mirrors, tested 2025-11)"
}

# 优化 pacman 配置
tune_pacman() {
    backup_file "${PACMAN_CONF}"

    # 合并 configure_china_mirrors.sh 的完整配置
    # 如果配置文件中没有 [options] 部分的关键配置，则添加
    if ! grep -q "^HoldPkg" "${PACMAN_CONF}"; then
        # 在 [options] 部分添加配置
        sed -i '/^\[options\]/a\
HoldPkg     = pacman glibc\
Architecture = auto\
CheckSpace\
SigLevel    = Required DatabaseOptional\
LocalFileSigLevel = Optional' "${PACMAN_CONF}"
    fi

    # 确保 ParallelDownloads 已启用并设置合理值
    if ! grep -q "^ParallelDownloads" "${PACMAN_CONF}"; then
        # 如果 ParallelDownloads 被注释，取消注释并设置值
        sed -i 's/^#ParallelDownloads/ParallelDownloads/' "${PACMAN_CONF}"
        # 如果还是没有，在 [options] 部分添加
        if ! grep -q "^ParallelDownloads" "${PACMAN_CONF}"; then
            sed -i '/^\[options\]/a\
ParallelDownloads = 5' "${PACMAN_CONF}"
        fi
    fi
    # 确保 ParallelDownloads 有合理的值（至少为 3）
    sed -i 's/^ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]*/ParallelDownloads = 5/' "${PACMAN_CONF}"

    # 确保 core, extra 仓库使用镜像列表（community 已合并到 extra，不再需要单独配置）
    if ! grep -q "^Include = /etc/pacman.d/mirrorlist" "${PACMAN_CONF}"; then
        sed -i '/^\[core\]/,/^\[/ { /^\[core\]/a\
Include = /etc/pacman.d/mirrorlist
}' "${PACMAN_CONF}"
        sed -i '/^\[extra\]/,/^\[/ { /^\[extra\]/a\
Include = /etc/pacman.d/mirrorlist
}' "${PACMAN_CONF}"
    fi

    # 移除已废弃的 [community] 配置（如果存在）
    if grep -q "^\[community\]" "${PACMAN_CONF}"; then
        sed -i '/^\[community\]/,/^\[/ { /^\[community\]/d; /^SigLevel/d; /^Include/d; }' "${PACMAN_CONF}"
        log_info "Removed deprecated [community] section (merged into [extra])"
    fi

    # 添加 archlinuxcn 源（基于可用性测试结果，2025年11月更新，8个可用镜像）
    # 注意：archlinuxcn-keyring 要求不使用 SigLevel，使用默认设置
    if ! grep -q "archlinuxcn" "${PACMAN_CONF}"; then
        cat <<'EOF' >> "${PACMAN_CONF}"
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
Server = https://mirrors.aliyun.com/archlinuxcn/$arch
Server = https://mirrors.cloud.tencent.com/archlinuxcn/$arch
Server = https://mirrors.huaweicloud.com/repository/archlinuxcn/$arch
Server = https://mirrors.nju.edu.cn/archlinuxcn/$arch
Server = https://mirrors.cqu.edu.cn/archlinuxcn/$arch
Server = https://mirror.lzu.edu.cn/archlinuxcn/$arch
Server = https://mirrors.sustech.edu.cn/archlinuxcn/$arch
EOF
    else
        # 如果已存在 archlinuxcn 配置，移除 SigLevel 行（如果存在）
        if grep -q "^\[archlinuxcn\]" "${PACMAN_CONF}"; then
            sed -i '/^\[archlinuxcn\]/,/^\[/ { /^SigLevel/d; }' "${PACMAN_CONF}"
            log_info "Removed SigLevel from [archlinuxcn] section (required by archlinuxcn-keyring)"
        fi
    fi

    configure_pacman_proxy
    log_info "Pacman configuration optimized"
}

# 安装 archlinuxcn-keyring（如果配置了 archlinuxcn 源）
install_archlinuxcn_keyring() {
    # 检查是否配置了 archlinuxcn 源
    if ! grep -q "^\[archlinuxcn\]" "${PACMAN_CONF}"; then
        log_info "archlinuxcn repository not configured, skipping keyring installation"
        return 0
    fi

    # 检查是否已安装
    if pacman -Qi archlinuxcn-keyring >/dev/null 2>&1; then
        log_info "archlinuxcn-keyring already installed"
        return 0
    fi

    log_info "Installing archlinuxcn-keyring to configure GPG keys for archlinuxcn repository"

    # 先同步数据库（只同步，不更新系统）
    log_info "Synchronizing package databases (including archlinuxcn)"
    local retry_count=0
    local max_retries=3
    local sync_success=0

    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        if pacman -Sy --noconfirm 2>&1; then
            sync_success=1
            break
        fi
        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "Database sync failed, retrying (${retry_count}/${max_retries})..."
            sleep 2
        fi
    done

    if [[ "${sync_success}" -eq 0 ]]; then
        log_warning "Failed to sync databases, archlinuxcn-keyring installation may fail"
    fi

    # 尝试安装 archlinuxcn-keyring
    retry_count=0
    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        if pacman -S --noconfirm archlinuxcn-keyring 2>&1; then
            log_success "archlinuxcn-keyring installed successfully"
            return 0
        fi
        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "Failed to install archlinuxcn-keyring, retrying (${retry_count}/${max_retries})..."
            sleep 2
            # 重新同步数据库
            pacman -Sy --noconfirm >/dev/null 2>&1 || true
        fi
    done

    log_warning "Failed to install archlinuxcn-keyring after ${max_retries} attempts"
    log_warning "archlinuxcn repository may not work properly until keyring is installed"
    log_warning "You can install it manually later with: sudo pacman -Sy archlinuxcn-keyring"
    log_warning "Or try switching to a different mirror if the current one is unavailable"
}

# 更新系统
update_system() {
    # pacman 操作前禁用代理（使用国内源）
    disable_proxy

    log_info "Starting system update process"

    # 步骤 1: 更新 archlinux-keyring（官方仓库的密钥环）
    log_info "Updating archlinux-keyring"
    local retry_count=0
    local max_retries=3
    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        if pacman -Sy --noconfirm archlinux-keyring 2>&1; then
            log_success "archlinux-keyring updated"
            break
        fi
        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "Keyring sync failed, retrying (${retry_count}/${max_retries})..."
            sleep 2
        else
            log_warning "Failed to update archlinux-keyring after ${max_retries} attempts, continuing..."
        fi
    done

    # 步骤 2: 安装 archlinuxcn-keyring（如果配置了 archlinuxcn 源）
    # 这必须在系统更新之前完成，以确保 archlinuxcn 源的 GPG 密钥正确配置
    install_archlinuxcn_keyring

    # 步骤 3: 更新系统（包括所有仓库）
    log_info "Updating system packages"
    retry_count=0
    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        if pacman -Syu --noconfirm 2>&1; then
            log_success "System update completed"
            break
        fi
        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "System update failed, retrying (${retry_count}/${max_retries})..."
            sleep 3
        else
            log_warning "System update failed after ${max_retries} attempts, but continuing..."
            log_warning "You may need to manually run: sudo pacman -Syu"
        fi
    done

    # pacman 操作完成后启用代理（用于后续操作）
    enable_proxy
}

# 安装软件包
install_packages() {
    # pacman 操作前禁用代理（使用国内源）
    disable_proxy

    log_info "Installing core tools: ${PACMAN_PACKAGES[*]}"
    pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

    # pacman 操作完成后启用代理（用于后续操作）
    enable_proxy
}

# 确保 AUR 助手已安装
ensure_aur_helper() {
    # pacman 操作前禁用代理（使用国内源）
    disable_proxy

    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        log_info "Installing yay as AUR helper"
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        # 设置临时目录的所有者为安装用户
        chown "${INSTALL_USER}:${INSTALL_USER}" "${tmp_dir}"
        # 使用普通用户构建 AUR 包
        sudo -u "${INSTALL_USER}" bash -s "${tmp_dir}" <<'EOF'
set -euo pipefail
cd "$1"
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg --noconfirm -si
EOF
        # 清理临时目录
        rm -rf "${tmp_dir}"
        if command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        else
            error_exit "Failed to install AUR helper"
        fi
    fi
    log_info "AUR helper: ${AUR_HELPER}"

    # pacman 操作完成后启用代理（用于后续操作）
    enable_proxy
}

# 安装字体
install_font() {
    ensure_directory "${FONT_DIR}"

    # 检查字体是否已经安装（检查目录中是否有字体文件）
    local font_files_count=0
    if [[ -d "${FONT_DIR}" ]]; then
        font_files_count=$(find "${FONT_DIR}" -name "*.ttf" -o -name "*.otf" 2>/dev/null | wc -l)
    fi

    if [[ ${font_files_count} -gt 0 ]]; then
        log_success "${FONT_NAME} Nerd Font already installed (${font_files_count} font files found)"
        # 更新字体缓存以确保字体可用
        fc-cache -f >/dev/null 2>&1 || true
        return 0
    fi

    local tmp_zip
    tmp_zip="$(mktemp)"
    # 字体文件可能较大，使用更长的超时时间（5分钟）和更多重试次数
    log_info "Downloading ${FONT_NAME} Nerd Font (this may take a while for large files)..."
    if download_with_progress "${FONT_URL}" "${tmp_zip}" 300 5; then
        log_info "Extracting font files..."
        unzip -o "${tmp_zip}" -d "${FONT_DIR}" >/dev/null 2>&1 || {
            log_warning "Some font files may have extraction issues, but continuing..."
        }
        rm -f "${tmp_zip}"
        # 更新字体缓存
        fc-cache -f >/dev/null 2>&1 || true
        log_success "Installed ${FONT_NAME} Nerd Font"
    else
        log_warning "Failed to download ${FONT_NAME} Nerd Font"
        log_warning "You can manually download and install it later from: ${FONT_URL}"
        rm -f "${tmp_zip}"
    fi
}

# 安装 Oh My Zsh
install_oh_my_zsh() {
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    export CHSH=no
    local install_script="/tmp/install_oh_my_zsh.sh"
    download_with_progress "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "${install_script}"
    chmod +x "${install_script}"
    # 使用普通用户安装，允许失败（使用 || true）
    sudo -u "${INSTALL_USER}" env \
        http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
        bash "${install_script}" || true
    rm -f "${install_script}"
    log_success "Oh My Zsh installation completed (user configuration not changed)"
}

# 安装 shell 工具
install_shell_tools() {
    # pacman 操作前禁用代理（使用国内源）
    disable_proxy

    pacman -S --needed --noconfirm zsh

    # pacman 操作完成后启用代理（用于后续操作）
    enable_proxy

    install_oh_my_zsh
}

# 安装 uv (Python 包管理器)
install_uv() {
    if command -v uv >/dev/null 2>&1; then
        log_info "uv already installed: $(uv --version)"
        return 0
    fi

    log_info "Installing uv (Python package manager)"

    # 尝试通过 AUR 安装
    if [[ -n "${AUR_HELPER:-}" ]]; then
        log_info "Using ${AUR_HELPER} to install uv"
        # 临时给普通用户读取 pacman.conf 的权限（yay 需要读取配置）
        chmod 644 "${PACMAN_CONF}" 2>/dev/null || true
        sudo -u "${INSTALL_USER}" "${AUR_HELPER}" -S --noconfirm uv 2>&1 || {
            log_warning "AUR installation failed, trying official install script"
            install_uv_official
        }
        # 恢复权限
        chmod 644 "${PACMAN_CONF}" 2>/dev/null || true
    else
        install_uv_official
    fi

    if command -v uv >/dev/null 2>&1; then
        log_success "uv installation completed: $(uv --version)"
    else
        error_exit "Failed to install uv"
    fi
}

# 使用官方脚本安装 uv
install_uv_official() {
    log_info "Using official install script to install uv"
    local install_script="/tmp/install_uv.sh"
    local user_home
    # 安全地获取用户主目录
    user_home="$(eval echo ~"${INSTALL_USER}")"

    download_with_progress "https://astral.sh/uv/install.sh" "${install_script}" 120 3
    chmod +x "${install_script}"
    # 使用普通用户安装，允许失败
    sudo -u "${INSTALL_USER}" env \
        http_proxy="${PROXY_URL:-}" https_proxy="${PROXY_URL:-}" \
        bash "${install_script}" || true
    rm -f "${install_script}"

    # 确保 uv 在 PATH 中
    if [[ -f "${user_home}/.cargo/bin/uv" ]]; then
        add_path_entry "${user_home}/.cargo/bin"
    fi
}

# 安装 fnm (Node.js 版本管理器)
install_fnm() {
    if command -v fnm >/dev/null 2>&1; then
        log_info "fnm already installed: $(fnm --version)"
        return 0
    fi

    log_info "Installing fnm (Node.js version manager)"

    # 尝试通过 AUR 安装
    if [[ -n "${AUR_HELPER:-}" ]]; then
        log_info "Using ${AUR_HELPER} to install fnm"
        # 临时给普通用户读取 pacman.conf 的权限（yay 需要读取配置）
        chmod 644 "${PACMAN_CONF}" 2>/dev/null || true
        sudo -u "${INSTALL_USER}" "${AUR_HELPER}" -S --noconfirm fnm 2>&1 || {
            log_warning "AUR installation failed, trying official install script"
            install_fnm_official
        }
        # 恢复权限
        chmod 644 "${PACMAN_CONF}" 2>/dev/null || true
    else
        install_fnm_official
    fi

    if command -v fnm >/dev/null 2>&1; then
        log_success "fnm installation completed: $(fnm --version)"
        log_info "Please add to your shell configuration file: eval \"\$(fnm env --use-on-cd)\""
    else
        error_exit "Failed to install fnm"
    fi
}

# 使用官方脚本安装 fnm
install_fnm_official() {
    log_info "Using official install script to install fnm"
    local install_script="/tmp/install_fnm.sh"
    local user_home
    # 安全地获取用户主目录
    user_home="$(eval echo ~"${INSTALL_USER}")"

    download_with_progress "https://fnm.vercel.app/install" "${install_script}" 120 3
    chmod +x "${install_script}"
    # 使用普通用户安装，允许失败
    # 使用 --skip-shell 参数避免重复添加 shell 配置
    sudo -u "${INSTALL_USER}" env \
        http_proxy="${PROXY_URL:-}" https_proxy="${PROXY_URL:-}" \
        bash "${install_script}" --skip-shell || true
    rm -f "${install_script}"

    # 确保 fnm 在 PATH 中
    # fnm 可能安装到不同的位置，检查多个可能的位置
    local fnm_paths=(
        "${user_home}/.local/share/fnm"
        "${HOME}/.local/share/fnm"
        "${user_home}/.fnm"
        "${HOME}/.fnm"
    )

    local fnm_found=0
    for fnm_dir in "${fnm_paths[@]}"; do
        if [[ -f "${fnm_dir}/fnm" ]] || [[ -f "${fnm_dir}/fnm.exe" ]]; then
            add_path_entry "${fnm_dir}"
            fnm_found=1
            log_info "fnm found at: ${fnm_dir}"
            break
        fi
    done

    # 如果通过 AUR 安装，fnm 可能在系统 PATH 中
    if [[ ${fnm_found} -eq 0 ]] && command -v fnm >/dev/null 2>&1; then
        log_info "fnm is already available in system PATH"
        fnm_found=1
    fi

    if [[ ${fnm_found} -eq 0 ]]; then
        log_warning "fnm binary not found in expected locations"
        log_info "fnm may need to be manually added to PATH"
    fi
}


# 安装 Neovim
install_neovim() {
    log_info "Installing Neovim"

    # Neovim 应该已经通过 pacman 安装，这里主要是配置
    if ! command -v nvim >/dev/null 2>&1; then
        log_warning "Neovim not installed, will be installed in install_packages"
    else
        log_info "Neovim already installed: $(nvim --version | head -n 1)"
    fi

    # 确保 uv 已安装（Neovim Python 环境需要）
    if ! command -v uv >/dev/null 2>&1; then
        install_uv
    fi

    # 获取项目根目录和 Neovim 安装脚本
    local nvim_install_script="${PROJECT_ROOT}/dotfiles/nvim/install.sh"

    # 检查并使用 submodule 安装配置
    if [[ -f "${nvim_install_script}" ]]; then
        log_info "Installing Neovim configuration using Git Submodule"
        # 确保 submodule 已初始化
        cd "${PROJECT_ROOT}" || error_exit "Failed to change to project root directory"
        sudo -u "${INSTALL_USER}" git submodule update --init dotfiles/nvim 2>/dev/null || true

        # 运行安装脚本，传递环境变量（代理和系统级 venv 配置）
        chmod +x "${nvim_install_script}"
        # 传递代理和系统级 venv 环境变量给 nvim 安装脚本
        sudo -u "${INSTALL_USER}" env \
            http_proxy="${PROXY_URL:-}" https_proxy="${PROXY_URL:-}" \
            HTTP_PROXY="${PROXY_URL:-}" HTTPS_PROXY="${PROXY_URL:-}" \
            USE_SYSTEM_NVIM_VENV="${USE_SYSTEM_NVIM_VENV:-0}" \
            INSTALL_USER="${INSTALL_USER}" \
            bash "${nvim_install_script}" || {
            log_warning "Neovim configuration installation failed, but continuing"
        }
    else
        log_warning "Neovim install script not found: ${nvim_install_script}"
        log_info "Neovim configuration will be managed by LazyVim framework"
    fi

    log_success "Neovim installation completed"

    # 输出 Windows 配置说明
    cat <<'EOF'

==========================================
Windows System Configuration Instructions
==========================================
When using Neovim on Windows, you need to configure the XDG_CONFIG_HOME
environment variable so that Neovim can correctly find the configuration file location.

Configuration steps:
1. Open System Properties -> Advanced System Settings -> Environment Variables
2. Add user variable:
   - Variable name: XDG_CONFIG_HOME
   - Variable value: C:\Users\<username>\.config\
     Example: C:\Users\Administrator\.config\
3. Restart terminal

Verify environment variable:
Run in Git Bash: echo $XDG_CONFIG_HOME
Should output: C:\Users\<username>\.config\

After configuration, Neovim configuration file path will be:
%XDG_CONFIG_HOME%\nvim\  (i.e., ~/.config/nvim/)
==========================================
EOF
}

# 安装可选工具
install_optional_tools() {
    log_info "Installing optional tools"

    # tree, ctags 等应该已经通过 pacman 安装
    # 这里主要是验证和输出信息
    local optional_tools=("tree" "ctags" "file" "net-tools" "iputils")

    for tool in "${optional_tools[@]}"; do
        if command -v "${tool}" >/dev/null 2>&1; then
            log_info "${tool} already installed"
        else
            log_warning "${tool} not installed, will be installed in install_packages"
        fi
    done

    log_success "Optional tools check completed"
}

# 打印摘要信息
print_summary() {
    log_info "PATH environment file: ${PATH_ENV_FILE}"
    log_info "Log location: ${LOG_FILE}"
    log_info "Script execution completed. Please run 'chsh' to change default shell to zsh if needed."
}

# 主函数
main() {
    start_script "Arch Basic Tools Installation"

    # 记录环境变量配置（用于调试）
    if [[ "${USE_SYSTEM_NVIM_VENV:-0}" == "1" ]]; then
        log_info "USE_SYSTEM_NVIM_VENV=1: Will use system-wide Neovim Python environment"
    else
        log_info "USE_SYSTEM_NVIM_VENV not set: Will use user-specific Neovim Python environment"
    fi

    check_root
    check_arch_linux
    detect_install_user
    ensure_directories
    prepare_path_management

    # ==========================================
    # 第一部分：pacman 相关操作（使用国内源，不走代理）
    # ==========================================
    log_info "=========================================="
    log_info "Phase 1: Pacman operations (using Chinese mirrors, no proxy)"
    log_info "=========================================="

    # 初始化代理配置（但 pacman 操作会禁用代理）
    setup_proxy

    # 配置镜像源和 pacman（这些操作不使用代理）
    configure_mirrors
    tune_pacman

    # pacman 相关操作（会自动禁用代理）
    update_system
    install_packages
    ensure_aur_helper

    # ==========================================
    # 第二部分：其他操作（使用代理）
    # ==========================================
    log_info "=========================================="
    log_info "Phase 2: Other operations (using proxy)"
    log_info "=========================================="

    # 确保代理已启用（用于后续操作）
    enable_proxy

    # 安装工具（使用代理）
    install_uv
    install_fnm

    # Neovim 配置（包括 Python 环境，由 nvim/install.sh 处理）
    install_neovim

    # 其他操作（使用代理）
    install_optional_tools
    install_font
    install_shell_tools

    print_summary
    end_script
}

# 执行主函数
main "$@"
