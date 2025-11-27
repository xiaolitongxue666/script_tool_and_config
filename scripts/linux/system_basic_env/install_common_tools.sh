#!/usr/bin/env bash

set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

if [[ ! -f "${COMMON_LIB}" ]]; then
    echo "[错误] 未找到通用脚本: ${COMMON_LIB}" >&2
    exit 1
fi

# 引入通用日志/错误处理函数
# shellcheck disable=SC1090
source "${COMMON_LIB}"

readonly LOG_DIR="${PROJECT_ROOT}/logs/system_basic_env"
readonly STATE_DIR="${HOME}/.local/share/system_basic_env"
readonly CONFIG_DIR="${HOME}/.config/system_basic_env"
readonly PATH_ENV_FILE="${CONFIG_DIR}/path.env"
readonly PACMAN_CONF="/etc/pacman.conf"
readonly MIRRORLIST="/etc/pacman.d/mirrorlist"
readonly DEFAULT_PROXY_URL="${DEFAULT_PROXY_URL:-http://127.0.0.1:7890}"
readonly FONT_VERSION="${FONT_VERSION:-3.2.1}"
readonly FONT_NAME="FiraMono"
readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip"
readonly FONT_DIR="/usr/local/share/fonts/${FONT_NAME}-NerdFont"
readonly PACMAN_PACKAGES=(
    base-devel git curl wget aria2 tmux starship github-cli lazygit git-delta
    fzf ripgrep fd bat eza trash-cli fastfetch btop unzip zip which sudo
)

PROXY_URL=""
AUR_HELPER=""
LOG_FILE=""
INSTALL_USER=""

trap 'log_error "检测到错误，退出脚本"; exit 1' ERR

ensure_directories() {
    ensure_directory "${LOG_DIR}"
    ensure_directory "${STATE_DIR}"
    ensure_directory "${CONFIG_DIR}"
    LOG_FILE="${LOG_DIR}/install_common_tools_$(date +%Y%m%d_%H%M%S).log"
    exec > >(tee -a "${LOG_FILE}") 2>&1
    log_info "日志文件: ${LOG_FILE}"
}

backup_path() {
    local backup_file="${STATE_DIR}/path_backup_$(date +%Y%m%d_%H%M%S).txt"
    printf "%s\n" "${PATH}" > "${backup_file}"
    log_info "已备份 PATH 至: ${backup_file}"
}

add_path_entry() {
    local path_entry="$1"
    grep -qxF "export PATH=\"${path_entry}:\$PATH\"" "${PATH_ENV_FILE}" 2>/dev/null && return 0
    echo "export PATH=\"${path_entry}:\$PATH\"" >> "${PATH_ENV_FILE}"
    log_info "已记录 PATH 入口: ${path_entry}"
}

prepare_path_management() {
    backup_path
    touch "${PATH_ENV_FILE}"
    add_path_entry "/usr/local/bin"
    add_path_entry "${HOME}/.local/bin"
    add_path_entry "${HOME}/.cargo/bin"
}

check_arch_linux() {
    if [[ ! -f /etc/os-release ]]; then
        error_exit "无法检测系统版本"
    fi
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID}" != "arch" ]]; then
        error_exit "此脚本仅支持 Arch Linux"
    fi
    log_info "检测到 Arch Linux"
}

detect_install_user() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        INSTALL_USER="${SUDO_USER}"
    elif [[ -n "${PKEXEC_UID:-}" ]]; then
        INSTALL_USER="$(id -un "${PKEXEC_UID}")"
    else
        error_exit "请通过 sudo 执行此脚本，以便使用普通用户运行 AUR 构建任务"
    }
    log_info "非特权用户: ${INSTALL_USER}"
}

setup_proxy() {
    PROXY_URL="${HTTP_PROXY:-${HTTPS_PROXY:-${PROXY_URL:-${DEFAULT_PROXY_URL}}}}"
    export http_proxy="${PROXY_URL}"
    export https_proxy="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    log_info "已设置代理: ${PROXY_URL}"
}

download_with_progress() {
    local url="$1"
    local dest="$2"
    log_info "开始下载: ${url}"
    ensure_directory "$(dirname "${dest}")"
    if command -v aria2c >/dev/null 2>&1; then
        aria2c --check-certificate=false --max-connection-per-server=8 \
            --split=8 --dir="$(dirname "${dest}")" --out="$(basename "${dest}")" \
            --summary-interval=1 "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget --show-progress --progress=bar:force:noscroll -O "${dest}" "${url}"
    else
        curl -fL --progress-bar -o "${dest}" "${url}"
    fi
    log_success "下载完成: ${dest}"
}

configure_pacman_proxy() {
    if ! grep -q "^XferCommand" "${PACMAN_CONF}"; then
        cat <<'EOF' >> "${PACMAN_CONF}"
XferCommand = /usr/bin/curl -L -C - -f --retry 3 --progress-bar -o %o %u
EOF
    fi
}

configure_mirrors() {
    backup_file "${MIRRORLIST}"
    cat > "${MIRRORLIST}" <<'EOF'
## 清华大学
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
## 163
Server = http://mirrors.163.com/archlinux/$repo/os/$arch
## 阿里云
Server = http://mirrors.aliyun.com/archlinux/$repo/os/$arch
EOF
    log_info "已应用中国镜像加速"
}

tune_pacman() {
    backup_file "${PACMAN_CONF}"
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' "${PACMAN_CONF}"
    if ! grep -q "archlinuxcn" "${PACMAN_CONF}"; then
        cat <<'EOF' >> "${PACMAN_CONF}"
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF
    fi
    configure_pacman_proxy
}

update_system() {
    log_info "同步系统与 keyring"
    pacman -Sy --noconfirm archlinux-keyring
    pacman -Syu --noconfirm
}

install_packages() {
    log_info "安装核心工具: ${PACMAN_PACKAGES[*]}"
    pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

ensure_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        log_info "正在安装 yay 作为 AUR 助手"
        tmp_dir="$(mktemp -d)"
        chown "${INSTALL_USER}:${INSTALL_USER}" "${tmp_dir}"
        sudo -u "${INSTALL_USER}" bash -s "${tmp_dir}" <<'EOF'
set -euo pipefail
cd "$1"
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg --noconfirm -si
EOF
        rm -rf "${tmp_dir}"
        if command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        else
            error_exit "安装 AUR 助手失败"
        fi
    fi
    log_info "AUR 助手: ${AUR_HELPER}"
}

install_font() {
    ensure_directory "${FONT_DIR}"
    local tmp_zip
    tmp_zip="$(mktemp)"
    download_with_progress "${FONT_URL}" "${tmp_zip}"
    unzip -o "${tmp_zip}" -d "${FONT_DIR}"
    rm -f "${tmp_zip}"
    fc-cache -f
    log_success "已安装 ${FONT_NAME} Nerd Font"
}

install_oh_my_zsh() {
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    export CHSH=no
    local install_script="/tmp/install_oh_my_zsh.sh"
    download_with_progress "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "${install_script}"
    chmod +x "${install_script}"
    sudo -u "${INSTALL_USER}" env \
        http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
        bash "${install_script}" || true
    rm -f "${install_script}"
    log_success "Oh My Zsh 安装完成（未更改用户配置）"
}

install_shell_tools() {
    pacman -S --needed --noconfirm zsh
    install_oh_my_zsh
}

print_summary() {
    log_info "PATH 环境文件: ${PATH_ENV_FILE}"
    log_info "日志位置: ${LOG_FILE}"
    log_info "脚本执行完毕，请视需要运行 chsh 将默认 shell 切换为 zsh。"
}

main() {
    start_script "Arch 基础工具安装"
    check_root
    check_arch_linux
    detect_install_user
    ensure_directories
    prepare_path_management
    setup_proxy
    configure_mirrors
    tune_pacman
    update_system
    install_packages
    ensure_aur_helper
    install_font
    install_shell_tools
    print_summary
    end_script
}

main "$@"
