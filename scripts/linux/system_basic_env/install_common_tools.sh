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
readonly DEFAULT_PROXY_URL="${DEFAULT_PROXY_URL:-http://127.0.0.1:7890}"
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

# 设置代理（优先使用代理）
setup_proxy() {
    # 从环境变量或默认值获取代理 URL
    PROXY_URL="${HTTP_PROXY:-${HTTPS_PROXY:-${PROXY_URL:-${DEFAULT_PROXY_URL}}}}"

    # 优先使用代理，即使测试失败也尝试使用
    if [[ -n "${PROXY_URL:-}" ]]; then
        # 设置代理环境变量（优先使用代理）
        export http_proxy="${PROXY_URL}"
        export https_proxy="${PROXY_URL}"
        export HTTP_PROXY="${PROXY_URL}"
        export HTTPS_PROXY="${PROXY_URL}"
        log_info "Proxy set: ${PROXY_URL}"

        # 测试代理是否可用（仅用于信息提示，不影响代理使用）
        if curl -s --connect-timeout 3 --max-time 5 --proxy "${PROXY_URL}" "https://www.google.com" >/dev/null 2>&1; then
            log_info "Proxy connection test: OK"
        else
            log_warning "Proxy connection test failed, but will still use proxy"
            log_warning "If proxy is not available, you can disable it by: unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy"
            log_warning "Or set NO_PROXY=1 to skip proxy configuration"
        fi
    else
        log_info "No proxy configured, using direct connection"
    fi
}

# 带进度显示的下载函数
download_with_progress() {
    local url="$1"
    local dest="$2"
    log_info "Starting download: ${url}"
    # 确保目标目录存在
    ensure_directory "$(dirname "${dest}")"
    # 优先使用 aria2c，其次 wget，最后使用 curl
    if command -v aria2c >/dev/null 2>&1; then
        aria2c --check-certificate=false --max-connection-per-server=8 \
            --split=8 --dir="$(dirname "${dest}")" --out="$(basename "${dest}")" \
            --summary-interval=1 "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget --show-progress --progress=bar:force:noscroll -O "${dest}" "${url}"
    else
        curl -fL --progress-bar -o "${dest}" "${url}"
    fi
    log_success "Download completed: ${dest}"
}

# 配置 pacman 代理（优先使用代理）
configure_pacman_proxy() {
    # 检查是否禁用代理
    if [[ "${NO_PROXY:-0}" == "1" ]]; then
        log_info "Proxy disabled by NO_PROXY=1, skipping XferCommand configuration"
        return 0
    fi

    # 优先使用代理配置
    if [[ -z "${PROXY_URL:-}" ]]; then
        # 没有代理配置，不设置 XferCommand
        return 0
    fi

    log_info "Configuring pacman to use proxy: ${PROXY_URL}"

    # 使用临时文件来安全地修改配置
    local tmp_file
    tmp_file="$(mktemp)"
    local in_options_section=0
    local xfer_added=0
    local xfer_in_options=0

    # 首先检查 XferCommand 是否已经在 [options] 部分
    local current_section=""
    while IFS= read -r line; do
        if [[ "${line}" =~ ^\[([^\]]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
        elif [[ "${line}" =~ ^XferCommand ]]; then
            if [[ "${current_section}" == "options" ]]; then
                xfer_in_options=1
            fi
        fi
    done < "${PACMAN_CONF}"

    # 重新读取文件，移除所有 XferCommand，然后在 [options] 部分添加
    current_section=""
    while IFS= read -r line; do
        # 检测是否进入 [options] 部分
        if [[ "${line}" =~ ^\[options\] ]]; then
            in_options_section=1
            current_section="options"
            echo "${line}" >> "${tmp_file}"
            # 在 [options] 部分后立即添加 XferCommand（使用代理）
            echo "XferCommand = /usr/bin/curl -L -C - -f --retry 3 --progress-bar --proxy ${PROXY_URL} -o %o %u" >> "${tmp_file}"
            xfer_added=1
        # 检测是否进入其他部分（遇到下一个 [ 开头的行）
        elif [[ "${line}" =~ ^\[([^\]]+)\] ]]; then
            in_options_section=0
            current_section="${BASH_REMATCH[1]}"
            echo "${line}" >> "${tmp_file}"
        # 跳过所有现有的 XferCommand 行（无论在哪里）
        elif [[ "${line}" =~ ^XferCommand ]]; then
            # 忽略这一行，我们会在 [options] 部分添加新的
            continue
        else
            echo "${line}" >> "${tmp_file}"
        fi
    done < "${PACMAN_CONF}"

    # 如果没有 [options] 部分，在文件开头添加
    if [[ "${xfer_added}" -eq 0 ]]; then
        {
            echo "[options]"
            echo "XferCommand = /usr/bin/curl -L -C - -f --retry 3 --progress-bar --proxy ${PROXY_URL} -o %o %u"
            echo ""
            cat "${tmp_file}"
        } > "${tmp_file}.new"
        mv "${tmp_file}.new" "${tmp_file}"
    fi

    mv "${tmp_file}" "${PACMAN_CONF}"
    log_info "XferCommand configured in [options] section with proxy: ${PROXY_URL}"
}

# 配置中国镜像源
configure_mirrors() {
    backup_file "${MIRRORLIST}"
    cat > "${MIRRORLIST}" <<'EOF'
## Tsinghua University
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
## 163
Server = http://mirrors.163.com/archlinux/$repo/os/$arch
## Aliyun
Server = http://mirrors.aliyun.com/archlinux/$repo/os/$arch
EOF
    log_info "Chinese mirror sources applied"
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

    # 确保 ParallelDownloads 已启用
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' "${PACMAN_CONF}"

    # 确保 core, extra, community 仓库使用镜像列表
    if ! grep -q "^Include = /etc/pacman.d/mirrorlist" "${PACMAN_CONF}"; then
        sed -i '/^\[core\]/,/^\[/ { /^\[core\]/a\
Include = /etc/pacman.d/mirrorlist
}' "${PACMAN_CONF}"
        sed -i '/^\[extra\]/,/^\[/ { /^\[extra\]/a\
Include = /etc/pacman.d/mirrorlist
}' "${PACMAN_CONF}"
        sed -i '/^\[community\]/,/^\[/ { /^\[community\]/a\
Include = /etc/pacman.d/mirrorlist
}' "${PACMAN_CONF}"
    fi

    # 添加 archlinuxcn 源
    if ! grep -q "archlinuxcn" "${PACMAN_CONF}"; then
        cat <<'EOF' >> "${PACMAN_CONF}"
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF
    fi

    configure_pacman_proxy
    log_info "Pacman configuration optimized"
}

# 更新系统
update_system() {
    log_info "Synchronizing system and keyring"
    pacman -Sy --noconfirm archlinux-keyring
    pacman -Syu --noconfirm
}

# 安装软件包
install_packages() {
    log_info "Installing core tools: ${PACMAN_PACKAGES[*]}"
    pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

# 确保 AUR 助手已安装
ensure_aur_helper() {
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
}

# 安装字体
install_font() {
    ensure_directory "${FONT_DIR}"
    local tmp_zip
    tmp_zip="$(mktemp)"
    download_with_progress "${FONT_URL}" "${tmp_zip}"
    unzip -o "${tmp_zip}" -d "${FONT_DIR}"
    rm -f "${tmp_zip}"
    # 更新字体缓存
    fc-cache -f
    log_success "Installed ${FONT_NAME} Nerd Font"
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
    pacman -S --needed --noconfirm zsh
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
        sudo -u "${INSTALL_USER}" "${AUR_HELPER}" -S --noconfirm uv || {
            log_warning "AUR installation failed, trying official install script"
            install_uv_official
        }
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

    download_with_progress "https://astral.sh/uv/install.sh" "${install_script}"
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
        sudo -u "${INSTALL_USER}" "${AUR_HELPER}" -S --noconfirm fnm || {
            log_warning "AUR installation failed, trying official install script"
            install_fnm_official
        }
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

    download_with_progress "https://fnm.vercel.app/install" "${install_script}"
    chmod +x "${install_script}"
    # 使用普通用户安装，允许失败
    sudo -u "${INSTALL_USER}" env \
        http_proxy="${PROXY_URL:-}" https_proxy="${PROXY_URL:-}" \
        bash "${install_script}" || true
    rm -f "${install_script}"

    # 确保 fnm 在 PATH 中
    if [[ -f "${user_home}/.local/share/fnm/fnm" ]]; then
        add_path_entry "${user_home}/.local/share/fnm"
    fi
}

# 为 Neovim 安装 Python 工具
install_python_tools_for_neovim() {
    # 确保 uv 已安装
    if ! command -v uv >/dev/null 2>&1; then
        install_uv
    fi

    local user_home
    # 安全地获取用户主目录
    user_home="$(eval echo ~"${INSTALL_USER}")"
    local venv_dir="${user_home}/.config/nvim/venv"
    local venv_path="${venv_dir}/nvim-python"

    log_info "Creating Python virtual environment for Neovim"
    ensure_directory "${venv_dir}"

    # 如果虚拟环境已存在，则更新包
    if [[ -d "${venv_path}" ]]; then
        log_warning "Virtual environment already exists: ${venv_path}"
        log_info "Will update packages in existing environment"
    else
        log_info "Creating virtual environment: ${venv_path}"
        sudo -u "${INSTALL_USER}" uv venv "${venv_path}" || error_exit "Failed to create virtual environment"
    fi

    # 安装 Python 包
    log_info "Installing Neovim Python tools"
    local python_packages=(
        pynvim
        pyright
        ruff-lsp
        debugpy
        black
        isort
        flake8
        mypy
    )

    # 使用 uv pip 安装包
    # 注意：使用数组展开时需要用引号保护
    sudo -u "${INSTALL_USER}" bash -c "
        source '${venv_path}/bin/activate' && \
        uv pip install -U ${python_packages[*]}
    " || {
        log_warning "Some packages failed to install, but continuing"
    }

    log_success "Neovim Python tools installation completed"

    # 输出配置说明
    cat <<EOF

==========================================
Neovim Python Environment Configuration
==========================================

Virtual environment location: ${venv_path}

Add the following configuration to your Neovim config (init.lua):

-- Specify Python interpreter
vim.g.python3_host_prog = "${venv_path}/bin/python"

-- Add virtual environment site-packages to pythonpath
local venv_path = "${venv_path}"
vim.opt.pp:prepend(venv_path .. "/lib/python*/site-packages")

Daily maintenance commands:

# Upgrade all packages
source ${venv_path}/bin/activate
uv pip upgrade -r <(uv pip freeze)

# Add new package
uv pip install <package_name>

# Rebuild environment (if needed)
rm -rf ${venv_path}
cd ${venv_dir} && uv venv nvim-python && uv pip install -U pynvim pyright ruff-lsp debugpy black isort flake8 mypy

==========================================
EOF
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

    # 获取项目根目录和 Neovim 安装脚本
    local nvim_install_script="${PROJECT_ROOT}/dotfiles/nvim/install.sh"

    # 检查并使用 submodule 安装配置
    if [[ -f "${nvim_install_script}" ]]; then
        log_info "Installing Neovim configuration using Git Submodule"
        # 确保 submodule 已初始化
        cd "${PROJECT_ROOT}" || error_exit "Failed to change to project root directory"
        sudo -u "${INSTALL_USER}" git submodule update --init dotfiles/nvim 2>/dev/null || true

        # 运行安装脚本
        chmod +x "${nvim_install_script}"
        sudo -u "${INSTALL_USER}" bash "${nvim_install_script}" || {
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
    install_uv
    install_fnm
    install_python_tools_for_neovim
    install_neovim
    install_optional_tools
    install_font
    install_shell_tools
    print_summary
    end_script
}

# 执行主函数
main "$@"
