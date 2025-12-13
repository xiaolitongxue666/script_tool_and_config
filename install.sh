#!/bin/bash

# ============================================
# 一键安装脚本
# 自动检测系统、安装 chezmoi、应用所有配置
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR}/scripts/common.sh"

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

start_script "一键安装脚本"

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
# 代理配置（可选）
# ============================================
if [ -n "${PROXY:-}" ] || [ -n "${http_proxy:-}" ]; then
    PROXY="${PROXY:-${http_proxy:-http://127.0.0.1:7890}}"
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    log_info "使用代理: $PROXY"
fi

# ============================================
# 安装 chezmoi
# ============================================
log_info "检查 chezmoi 安装状态..."
if ! command -v chezmoi &> /dev/null; then
    log_info "chezmoi 未安装，开始安装..."
    bash "${SCRIPT_DIR}/scripts/chezmoi/install_chezmoi.sh"
else
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
fi

# ============================================
# 初始化 chezmoi 仓库
# ============================================
CHEZMOI_DIR="${SCRIPT_DIR}/.chezmoi"

if [ ! -d "$CHEZMOI_DIR" ]; then
    log_info "创建 chezmoi 源状态目录..."
    mkdir -p "$CHEZMOI_DIR"
    
    # 初始化 Git 仓库
    if [ ! -d "${CHEZMOI_DIR}/.git" ]; then
        log_info "初始化 Git 仓库..."
        cd "$CHEZMOI_DIR"
        git init
        cd - > /dev/null
    fi
else
    log_info "chezmoi 源状态目录已存在: $CHEZMOI_DIR"
fi

# ============================================
# 应用配置
# ============================================
log_info "应用所有配置..."
if [ -d "$CHEZMOI_DIR" ] && [ "$(ls -A $CHEZMOI_DIR 2>/dev/null)" ]; then
    # 设置源状态目录
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
    
    # 应用配置
    log_info "运行: chezmoi apply -v"
    chezmoi apply -v
    
    log_success "配置应用完成！"
else
    log_warning "chezmoi 源状态目录为空"
    log_info "请先运行迁移脚本: ./scripts/migration/migrate_to_chezmoi.sh"
    log_info "或手动添加配置: chezmoi add ~/.zshrc"
fi

# ============================================
# 完成
# ============================================
end_script

log_success "安装完成！"
echo ""
log_info "下一步："
log_info "  1. 检查配置: chezmoi diff"
log_info "  2. 编辑配置: chezmoi edit ~/.zshrc"
log_info "  3. 查看状态: chezmoi status"
echo ""
log_info "使用帮助: ./scripts/manage_dotfiles.sh help"
