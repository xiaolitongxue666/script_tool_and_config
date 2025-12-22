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
# 默认代理 URL
readonly DEFAULT_PROXY_URL="${DEFAULT_PROXY_URL:-http://127.0.0.1:7890}"

# Homebrew 公式（formula）工具列表
readonly BREW_FORMULA_PACKAGES=(
    git curl wget aria2 tmux starship gh lazygit git-delta
    fzf ripgrep fd bat eza trash-cli fastfetch btop
    neovim gcc make tree openssh file cmake ctags
    unzip zip which
)

# Homebrew Cask 工具（GUI 应用）列表
readonly BREW_CASK_PACKAGES=(
    maccy  # 轻量级剪贴板管理器
)

# 全局变量
PROXY_URL=""
LOG_FILE=""

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

# 检查是否为 macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error_exit "This script only supports macOS"
    fi
    log_info "macOS detected: $(sw_vers -productVersion)"
}

# 配置代理
setup_proxy() {
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

# 检查 Homebrew 包是否已安装
is_package_installed() {
    local package="$1"
    if brew list "${package}" 2>/dev/null | grep -q "^${package}$"; then
        return 0
    fi
    return 1
}

# 检查 Homebrew Cask 包是否已安装
is_cask_installed() {
    local package="$1"
    if brew list --cask "${package}" 2>/dev/null | grep -q "^${package}$"; then
        return 0
    fi
    return 1
}

# 检查命令是否已安装
is_command_installed() {
    local command="$1"
    if command -v "${command}" &> /dev/null; then
        return 0
    fi
    return 1
}

# 检查字体是否已安装
is_font_installed() {
    local font_name="$1"
    # 检查系统字体目录和用户字体目录
    local font_dirs=(
        "/Library/Fonts"
        "${HOME}/Library/Fonts"
    )

    for font_dir in "${font_dirs[@]}"; do
        if [[ -d "${font_dir}" ]]; then
            # 检查字体文件（支持 .ttf 和 .otf）
            if find "${font_dir}" -name "*${font_name}*" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | grep -q .; then
                return 0
            fi
        fi
    done
    return 1
}

# 检查并安装 Homebrew
check_homebrew() {
    if command -v brew &> /dev/null; then
        log_info "Homebrew already installed: $(brew --version | head -n 1)"
        # 确保 Homebrew 在 PATH 中
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true
        fi
        return 0
    fi

    log_info "Homebrew not found, installing Homebrew..."
    local install_script="/tmp/install_homebrew.sh"

    # 下载 Homebrew 安装脚本
    if command -v curl &> /dev/null; then
        curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" -o "${install_script}" || {
            error_exit "Failed to download Homebrew install script"
        }
    else
        error_exit "curl not found, please install curl first"
    fi

    chmod +x "${install_script}"

    # 使用代理安装（如果设置了代理）
    if [[ -n "${PROXY_URL:-}" ]]; then
        env http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
            HTTP_PROXY="${PROXY_URL}" HTTPS_PROXY="${PROXY_URL}" \
            bash "${install_script}" || {
            log_error "Homebrew installation failed"
            rm -f "${install_script}"
            error_exit "Failed to install Homebrew"
        }
    else
        bash "${install_script}" || {
            log_error "Homebrew installation failed"
            rm -f "${install_script}"
            error_exit "Failed to install Homebrew"
        }
    fi

    rm -f "${install_script}"

    # 添加 Homebrew 到 PATH（Apple Silicon 和 Intel 路径不同）
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        add_path_entry "/opt/homebrew/bin"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        add_path_entry "/usr/local/bin"
    fi

    if command -v brew &> /dev/null; then
        log_success "Homebrew installed successfully"
    else
        error_exit "Homebrew installation completed but brew command not found"
    fi
}

# 更新 Homebrew
update_homebrew() {
    log_info "Updating Homebrew..."
    if brew update; then
        log_success "Homebrew updated successfully"
    else
        log_warning "Homebrew update failed, but continuing..."
    fi
}

# 安装 Homebrew 公式工具
install_packages() {
    log_info "Installing Homebrew formula packages..."
    local installed_count=0
    local skipped_count=0

    for package in "${BREW_FORMULA_PACKAGES[@]}"; do
        if is_package_installed "${package}"; then
            log_info "Package '${package}' already installed, skipping"
            skipped_count=$((skipped_count + 1))
        else
            log_info "Installing package: ${package}"
            if brew install "${package}"; then
                log_success "Installed: ${package}"
                installed_count=$((installed_count + 1))
            else
                log_warning "Failed to install: ${package}"
            fi
        fi
    done

    log_info "Package installation summary: ${installed_count} installed, ${skipped_count} skipped"
}

# 安装 Homebrew Cask 工具
install_cask_packages() {
    if [[ ${#BREW_CASK_PACKAGES[@]} -eq 0 ]]; then
        log_info "No Cask packages to install"
        return 0
    fi

    log_info "Installing Homebrew Cask packages..."
    local installed_count=0
    local skipped_count=0

    for package in "${BREW_CASK_PACKAGES[@]}"; do
        if is_cask_installed "${package}"; then
            log_info "Cask package '${package}' already installed, skipping"
            skipped_count=$((skipped_count + 1))
        else
            log_info "Installing Cask package: ${package}"
            if brew install --cask "${package}"; then
                log_success "Installed: ${package}"
                installed_count=$((installed_count + 1))
            else
                log_warning "Failed to install: ${package}"
            fi
        fi
    done

    log_info "Cask package installation summary: ${installed_count} installed, ${skipped_count} skipped"
}

# 安装 uv (Python 包管理器)
install_uv() {
    if is_command_installed uv; then
        log_info "uv already installed: $(uv --version 2>/dev/null || echo 'unknown version')"
        return 0
    fi

    log_info "Installing uv (Python package manager)"

    # 优先尝试通过 Homebrew 安装
    if is_package_installed uv; then
        log_info "uv already installed via Homebrew"
        return 0
    fi

    log_info "Installing uv via Homebrew..."
    if brew install uv; then
        if is_command_installed uv; then
            log_success "uv installation completed: $(uv --version 2>/dev/null || echo 'unknown version')"
            return 0
        fi
    fi

    # Homebrew 安装失败，使用官方安装脚本
    log_warning "Homebrew installation failed, trying official install script"
    local install_script="/tmp/install_uv.sh"

    if command -v curl &> /dev/null; then
        curl -fsSL "https://astral.sh/uv/install.sh" -o "${install_script}" || {
            log_error "Failed to download uv install script"
            return 1
        }
    else
        log_error "curl not found"
        return 1
    fi

    chmod +x "${install_script}"

    # 使用代理安装（如果设置了代理）
    if [[ -n "${PROXY_URL:-}" ]]; then
        env http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
            HTTP_PROXY="${PROXY_URL}" HTTPS_PROXY="${PROXY_URL}" \
            bash "${install_script}" || {
            log_warning "uv installation via official script failed"
            rm -f "${install_script}"
            return 1
        }
    else
        bash "${install_script}" || {
            log_warning "uv installation via official script failed"
            rm -f "${install_script}"
            return 1
        }
    fi

    rm -f "${install_script}"

    # 确保 uv 在 PATH 中
    if [[ -f "${HOME}/.cargo/bin/uv" ]]; then
        add_path_entry "${HOME}/.cargo/bin"
    fi

    if is_command_installed uv; then
        log_success "uv installation completed: $(uv --version 2>/dev/null || echo 'unknown version')"
    else
        log_warning "uv installation completed but command not found in PATH"
    fi
}

# 安装 fnm (Node.js 版本管理器)
install_fnm() {
    if is_command_installed fnm; then
        log_info "fnm already installed: $(fnm --version 2>/dev/null || echo 'unknown version')"
        return 0
    fi

    log_info "Installing fnm (Node.js version manager)"

    # 优先尝试通过 Homebrew 安装
    if is_package_installed fnm; then
        log_info "fnm already installed via Homebrew"
        return 0
    fi

    log_info "Installing fnm via Homebrew..."
    if brew install fnm; then
        if is_command_installed fnm; then
            log_success "fnm installation completed: $(fnm --version 2>/dev/null || echo 'unknown version')"
            log_info "Please add to your shell configuration file: eval \"\$(fnm env --use-on-cd)\""
            return 0
        fi
    fi

    # Homebrew 安装失败，使用官方安装脚本
    log_warning "Homebrew installation failed, trying official install script"
    local install_script="/tmp/install_fnm.sh"

    if command -v curl &> /dev/null; then
        curl -fsSL "https://fnm.vercel.app/install" -o "${install_script}" || {
            log_error "Failed to download fnm install script"
            return 1
        }
    else
        log_error "curl not found"
        return 1
    fi

    chmod +x "${install_script}"

    # 使用代理安装（如果设置了代理），使用 --skip-shell 参数避免重复添加 shell 配置
    if [[ -n "${PROXY_URL:-}" ]]; then
        env http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
            HTTP_PROXY="${PROXY_URL}" HTTPS_PROXY="${PROXY_URL}" \
            bash "${install_script}" --skip-shell || {
            log_warning "fnm installation via official script failed"
            rm -f "${install_script}"
            return 1
        }
    else
        bash "${install_script}" --skip-shell || {
            log_warning "fnm installation via official script failed"
            rm -f "${install_script}"
            return 1
        }
    fi

    rm -f "${install_script}"

    # 确保 fnm 在 PATH 中
    local fnm_paths=(
        "${HOME}/.local/share/fnm"
        "${HOME}/.fnm"
    )

    for fnm_dir in "${fnm_paths[@]}"; do
        if [[ -d "${fnm_dir}" ]]; then
            add_path_entry "${fnm_dir}"
            log_info "fnm found at: ${fnm_dir}"
            break
        fi
    done

    if is_command_installed fnm; then
        log_success "fnm installation completed: $(fnm --version 2>/dev/null || echo 'unknown version')"
        log_info "Please add to your shell configuration file: eval \"\$(fnm env --use-on-cd)\""
    else
        log_warning "fnm installation completed but command not found in PATH"
    fi
}

# 安装 lazyssh (SSH 管理器)
install_lazyssh() {
    if is_command_installed lazyssh; then
        log_info "lazyssh already installed: $(lazyssh --version 2>/dev/null || echo 'unknown version')"
        return 0
    fi

    log_info "Installing lazyssh (SSH manager)"

    # 优先尝试通过 Homebrew tap 安装
    log_info "Trying to install lazyssh via Homebrew tap..."
    if brew tap Adembc/homebrew-tap 2>/dev/null || true; then
        if brew install Adembc/homebrew-tap/lazyssh 2>/dev/null; then
            if is_command_installed lazyssh; then
                log_success "lazyssh installation completed: $(lazyssh --version 2>/dev/null || echo 'unknown version')"
                return 0
            fi
        fi
    fi

    # Homebrew 安装失败，尝试下载二进制文件
    log_warning "Homebrew installation failed, trying to download binary from GitHub Releases"
    install_lazyssh_binary
}

# 从 GitHub Releases 下载 lazyssh 二进制文件
install_lazyssh_binary() {
    local install_dir="${HOME}/.local/bin"
    local binary_path="${install_dir}/lazyssh"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local tar_file="${tmp_dir}/lazyssh.tar.gz"

    # 确保安装目录存在
    mkdir -p "${install_dir}"

    # 检测系统架构
    local os_name
    local arch_name
    os_name="$(uname)"
    arch_name="$(uname -m)"

    # 转换为 GitHub Releases 使用的格式
    case "${os_name}" in
        Darwin)
            os_name="Darwin"
            ;;
        Linux)
            os_name="Linux"
            ;;
        *)
            log_error "Unsupported OS: ${os_name}"
            rm -rf "${tmp_dir}"
            return 1
            ;;
    esac

    case "${arch_name}" in
        x86_64)
            arch_name="amd64"
            ;;
        arm64|aarch64)
            arch_name="arm64"
            ;;
        *)
            log_error "Unsupported architecture: ${arch_name}"
            rm -rf "${tmp_dir}"
            return 1
            ;;
    esac

    # 获取最新版本标签
    log_info "Fetching latest lazyssh version..."
    local latest_tag
    if [[ -n "${PROXY_URL:-}" ]]; then
        latest_tag=$(curl -fsSL --proxy "${PROXY_URL}" "https://api.github.com/repos/Adembc/lazyssh/releases/latest" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$' || echo "")
    else
        latest_tag=$(curl -fsSL "https://api.github.com/repos/Adembc/lazyssh/releases/latest" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$' || echo "")
    fi

    if [[ -z "${latest_tag}" ]]; then
        log_error "Failed to fetch latest version tag"
        rm -rf "${tmp_dir}"
        return 1
    fi

    log_info "Latest version: ${latest_tag}"

    # 构建下载 URL
    local download_url="https://github.com/Adembc/lazyssh/releases/download/${latest_tag}/lazyssh_${os_name}_${arch_name}.tar.gz"

    log_info "Downloading lazyssh from: ${download_url}"

    # 下载文件
    if [[ -n "${PROXY_URL:-}" ]]; then
        if ! curl -fsSL --proxy "${PROXY_URL}" -L -o "${tar_file}" "${download_url}"; then
            log_error "Failed to download lazyssh"
            rm -rf "${tmp_dir}"
            return 1
        fi
    else
        if ! curl -fsSL -L -o "${tar_file}" "${download_url}"; then
            log_error "Failed to download lazyssh"
            rm -rf "${tmp_dir}"
            return 1
        fi
    fi

    # 解压文件
    log_info "Extracting lazyssh..."
    if ! tar -xzf "${tar_file}" -C "${tmp_dir}"; then
        log_error "Failed to extract lazyssh"
        rm -rf "${tmp_dir}"
        return 1
    fi

    # 查找二进制文件
    local extracted_binary
    extracted_binary=$(find "${tmp_dir}" -name "lazyssh" -type f | head -n 1)

    if [[ -z "${extracted_binary}" ]] || [[ ! -f "${extracted_binary}" ]]; then
        log_error "lazyssh binary not found in downloaded archive"
        rm -rf "${tmp_dir}"
        return 1
    fi

    # 复制二进制文件到安装目录
    log_info "Installing lazyssh to ${binary_path}..."
    cp "${extracted_binary}" "${binary_path}"
    chmod +x "${binary_path}"

    # 清理临时文件
    rm -rf "${tmp_dir}"

    # 确保安装目录在 PATH 中
    add_path_entry "${install_dir}"

    if is_command_installed lazyssh; then
        log_success "lazyssh installation completed: $(lazyssh --version 2>/dev/null || echo 'unknown version')"
    else
        log_warning "lazyssh installation completed but command not found in PATH"
        log_info "Please ensure ${install_dir} is in your PATH"
    fi
}

# 安装字体
install_font() {
    local font_name="FiraMonoNerdFont"

    if is_font_installed "${font_name}"; then
        log_success "FiraMono Nerd Font already installed"
        return 0
    fi

    log_info "Installing FiraMono Nerd Font via Homebrew Cask..."

    if is_cask_installed "font-fira-mono-nerd-font"; then
        log_info "font-fira-mono-nerd-font already installed via Homebrew Cask"
        return 0
    fi

    if brew install --cask "font-fira-mono-nerd-font"; then
        log_success "FiraMono Nerd Font installed successfully"
    else
        log_warning "Failed to install FiraMono Nerd Font via Homebrew Cask"
        log_info "You can manually install it later from: https://github.com/ryanoasis/nerd-fonts"
    fi
}

# 安装 Oh My Zsh
install_oh_my_zsh() {
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi

    export RUNZSH=no
    export KEEP_ZSHRC=yes
    export CHSH=no
    local install_script="/tmp/install_oh_my_zsh.sh"

    if command -v curl &> /dev/null; then
        curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" -o "${install_script}" || {
            log_error "Failed to download Oh My Zsh install script"
            return 1
        }
    else
        log_error "curl not found"
        return 1
    fi

    chmod +x "${install_script}"

    # 使用代理安装（如果设置了代理）
    if [[ -n "${PROXY_URL:-}" ]]; then
        env http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
            HTTP_PROXY="${PROXY_URL}" HTTPS_PROXY="${PROXY_URL}" \
            bash "${install_script}" || {
            log_warning "Oh My Zsh installation failed"
            rm -f "${install_script}"
            return 1
        }
    else
        bash "${install_script}" || {
            log_warning "Oh My Zsh installation failed"
            rm -f "${install_script}"
            return 1
        }
    fi

    rm -f "${install_script}"
    log_success "Oh My Zsh installation completed (user configuration not changed)"
}

# 安装 Oh My Zsh 插件（Fish-like 体验）
install_omz_plugins() {
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        log_warning "Oh My Zsh not installed, skipping plugin installation"
        return 0
    fi

    log_info "Installing Oh My Zsh plugins (Fish-like experience)"
    local zsh_custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"
    mkdir -p "${zsh_custom}"

    # 插件列表
    declare -A plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    )

    for plugin_name in "${!plugins[@]}"; do
        local plugin_url="${plugins[$plugin_name]}"
        local plugin_path="${zsh_custom}/${plugin_name}"

        if [[ -d "${plugin_path}" ]]; then
            log_info "Plugin ${plugin_name} already installed, skipping"
        else
            log_info "Installing plugin ${plugin_name}..."
            if git clone "${plugin_url}" "${plugin_path}" 2>/dev/null; then
                log_success "Plugin ${plugin_name} installed successfully"
            else
                log_warning "Failed to install plugin ${plugin_name}, continuing..."
            fi
        fi
    done

    log_success "Oh My Zsh plugins installation completed"
}

# 安装 shell 工具
install_shell_tools() {
    # zsh 通常已经预装在 macOS 上
    if is_command_installed zsh; then
        log_info "zsh already installed: $(zsh --version 2>/dev/null || echo 'unknown version')"
    else
        log_info "Installing zsh..."
        if brew install zsh; then
            log_success "zsh installed successfully"
        else
            log_warning "Failed to install zsh"
        fi
    fi

    install_oh_my_zsh
    install_omz_plugins
}

# 安装 Neovim
install_neovim() {
    log_info "Configuring Neovim"

    # Neovim 应该已经通过 Homebrew 安装
    if ! is_command_installed nvim; then
        log_warning "Neovim not installed, will be installed in install_packages"
    else
        log_info "Neovim already installed: $(nvim --version | head -n 1)"
    fi

    # 确保 uv 已安装（Neovim Python 环境需要）
    if ! is_command_installed uv; then
        install_uv
    fi

    # 获取项目根目录和 Neovim 安装脚本
    local nvim_install_script="${PROJECT_ROOT}/dotfiles/nvim/install.sh"

    # 检查并使用 submodule 安装配置
    if [[ -f "${nvim_install_script}" ]]; then
        log_info "Installing Neovim configuration using Git Submodule"
        # 确保 submodule 已初始化
        cd "${PROJECT_ROOT}" || error_exit "Failed to change to project root directory"
        git submodule update --init dotfiles/nvim 2>/dev/null || true

        # 运行安装脚本，传递环境变量（代理）
        chmod +x "${nvim_install_script}"
        # 传递代理环境变量给 nvim 安装脚本
        if [[ -n "${PROXY_URL:-}" ]]; then
            env http_proxy="${PROXY_URL}" https_proxy="${PROXY_URL}" \
                HTTP_PROXY="${PROXY_URL}" HTTPS_PROXY="${PROXY_URL}" \
                bash "${nvim_install_script}" || {
                log_warning "Neovim configuration installation failed, but continuing"
            }
        else
            bash "${nvim_install_script}" || {
                log_warning "Neovim configuration installation failed, but continuing"
            }
        fi
    else
        log_warning "Neovim install script not found: ${nvim_install_script}"
        log_info "Neovim configuration will be managed by LazyVim framework"
    fi

    log_success "Neovim installation completed"
}

# 打印摘要信息
print_summary() {
    log_info "PATH environment file: ${PATH_ENV_FILE}"
    log_info "Log location: ${LOG_FILE}"
    log_info ""
    log_info "环境变量配置说明："
    log_info "  - PATH 配置已记录到: ${PATH_ENV_FILE}"
    log_info "  - 如果使用 zsh，环境变量会在 ~/.zprofile 中统一管理"
    log_info "  - ~/.zprofile 确保所有登录方式（本地登录、SSH 登录）都能正确加载环境变量"
    log_info ""
    log_info "Script execution completed. Please run 'chsh -s $(which zsh)' to change default shell to zsh if needed."
}

# 主函数
main() {
    start_script "macOS Basic Tools Installation"

    check_macos
    ensure_directories
    prepare_path_management
    setup_proxy
    check_homebrew
    update_homebrew

    # 安装工具
    install_packages
    install_cask_packages

    # 安装编程工具
    install_uv
    install_fnm

    # Neovim 配置（包括 Python 环境，由 nvim/install.sh 处理）
    install_neovim

    # 安装 lazyssh
    install_lazyssh

    # 其他操作
    install_font
    install_shell_tools

    print_summary
    end_script
}

# 执行主函数
main "$@"

