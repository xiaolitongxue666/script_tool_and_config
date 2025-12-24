#!/bin/bash

# ============================================
# 远端初始化脚本
# 在 Arch Linux 上运行此脚本来初始化项目
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
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

start_script "远端项目初始化"

# ============================================
# 检查操作系统
# ============================================
OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
    log_warning "此脚本设计用于 Linux 系统，当前系统: $OS"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error_exit "用户取消操作"
    fi
fi

# ============================================
# 检查项目目录
# ============================================
if [ ! -f "${PROJECT_ROOT}/install.sh" ]; then
    error_exit "未找到 install.sh，请确保在项目根目录运行此脚本"
fi

# ============================================
# 检查 .chezmoi 目录
# ============================================
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
if [ ! -d "$CHEZMOI_DIR" ]; then
    log_warning ".chezmoi 目录不存在，install.sh 会自动创建"
else
    log_success ".chezmoi 目录已存在"
fi

# ============================================
# 初始化 Git Submodule（如果需要）
# ============================================
if [ -f "${PROJECT_ROOT}/.gitmodules" ]; then
    log_info "检测到 Git Submodule，开始初始化..."
    cd "$PROJECT_ROOT"
    git submodule update --init --recursive || log_warning "Git Submodule 初始化失败，可能不是 Git 仓库"
fi

# ============================================
# 运行安装脚本
# ============================================
log_info "运行安装脚本..."
cd "$PROJECT_ROOT"
bash ./install.sh

# ============================================
# 验证安装
# ============================================
log_info "验证安装..."

if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
else
    log_warning "chezmoi 未找到，请检查安装"
fi

if [ -d "$CHEZMOI_DIR" ] && [ "$(ls -A $CHEZMOI_DIR 2>/dev/null)" ]; then
    log_success ".chezmoi 目录已初始化"

    # 设置源状态目录
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

    # 检查配置状态
    log_info "检查配置状态..."
    if command -v chezmoi &> /dev/null; then
        chezmoi status || log_warning "chezmoi status 执行失败"
    fi
else
    log_warning ".chezmoi 目录为空，可能需要先运行迁移脚本"
fi

# ============================================
# 完成
# ============================================
end_script

log_success "初始化完成！"
echo ""
log_info "下一步："
log_info "  1. 检查配置: export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\" && chezmoi diff"
log_info "  2. 应用配置: export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\" && chezmoi apply -v"
log_info "  3. 查看状态: export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\" && chezmoi status"
echo ""

