#!/bin/bash

# ============================================
# chezmoi 安装脚本
# 支持 Linux、macOS、Windows 多平台安装
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

start_script "chezmoi 安装脚本"

# ============================================
# 检测操作系统
# ============================================
OS="$(uname -s)"
log_info "检测到操作系统: $OS"

if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
else
    error_exit "不支持的操作系统: $OS"
fi

log_success "平台: $PLATFORM"

# ============================================
# 检查 chezmoi 是否已安装
# ============================================
if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "跳过安装"
        end_script
    fi
fi

# ============================================
# 代理配置
# ============================================
PROXY="${PROXY:-${http_proxy:-http://127.0.0.1:7890}}"
export http_proxy="$PROXY"
export https_proxy="$PROXY"
export HTTP_PROXY="$PROXY"
export HTTPS_PROXY="$PROXY"
log_info "使用代理: $PROXY"

# ============================================
# 安装 chezmoi
# ============================================
log_info "开始安装 chezmoi..."

case "$PLATFORM" in
    Darwin)
        # macOS: 使用 Homebrew（推荐）或官方安装脚本
        if command -v brew &> /dev/null; then
            log_info "使用 Homebrew 安装 chezmoi..."
            brew install chezmoi
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
            else
                log_warning "Homebrew 安装失败，尝试使用官方安装脚本..."
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            fi
        else
            log_info "使用官方安装脚本安装 chezmoi..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
                # 添加到 PATH
                if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bash_profile" 2>/dev/null || \
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
                    log_info "已将 ~/.local/bin 添加到 PATH"
                fi
            else
                error_exit "chezmoi 安装失败"
            fi
        fi
        ;;
    Linux)
        # Linux: 优先使用包管理器，否则使用官方安装脚本
        if command -v pacman &> /dev/null; then
            log_info "使用 pacman 安装 chezmoi..."
            sudo pacman -S --noconfirm chezmoi
        elif command -v apt-get &> /dev/null; then
            log_info "使用 apt-get 安装 chezmoi..."
            sudo apt-get update
            sudo apt-get install -y chezmoi
        elif command -v dnf &> /dev/null; then
            log_info "使用 dnf 安装 chezmoi..."
            sudo dnf install -y chezmoi
        elif command -v yum &> /dev/null; then
            log_info "使用 yum 安装 chezmoi..."
            sudo yum install -y chezmoi
        else
            log_info "使用官方安装脚本安装 chezmoi..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
                # 添加到 PATH
                if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || \
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
                    log_info "已将 ~/.local/bin 添加到 PATH"
                fi
            else
                error_exit "chezmoi 安装失败"
            fi
        fi
        ;;
    windows)
        # Windows: 使用 winget 或官方安装脚本
        if command -v winget &> /dev/null; then
            log_info "使用 winget 安装 chezmoi..."
            winget install --id=twpayne.chezmoi -e --accept-source-agreements --accept-package-agreements
        else
            log_info "使用官方安装脚本安装 chezmoi..."
            # Windows Git Bash 环境
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
                # 添加到 PATH
                if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bash_profile" 2>/dev/null || true
                    log_info "已将 ~/.local/bin 添加到 PATH"
                fi
            else
                error_exit "chezmoi 安装失败，请手动安装: https://www.chezmoi.io/install/"
            fi
        fi
        ;;
esac

# ============================================
# 验证安装
# ============================================
if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 安装成功: $CHEZMOI_VERSION"
    log_info "安装路径: $(which chezmoi)"
else
    log_warning "chezmoi 可能未正确添加到 PATH"
    log_info "请确保 ~/.local/bin 在 PATH 中，或重新打开终端"
fi

# ============================================
# 完成
# ============================================
end_script
