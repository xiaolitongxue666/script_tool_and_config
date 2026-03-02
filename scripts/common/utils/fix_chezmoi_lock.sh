#!/bin/bash

# ============================================
# 修复 chezmoi 锁文件问题
# 解决 "timeout obtaining persistent state lock" 错误
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
fi

log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "修复 chezmoi 锁文件问题"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================
# 1. 调用非交互解锁脚本（与 install.sh / deploy.sh 一致）
# ============================================
ENSURE_UNLOCKED="${SCRIPT_DIR}/ensure_chezmoi_unlocked.sh"
if [ -f "$ENSURE_UNLOCKED" ]; then
    log_info ""
    bash "$ENSURE_UNLOCKED" || true
else
    log_warning "未找到 ensure_chezmoi_unlocked.sh，请从 scripts/common/utils 目录执行或检查路径"
fi

# ============================================
# 2. 测试 chezmoi 命令
# ============================================
log_info ""
log_info "2. 测试 chezmoi 命令..."

if command -v chezmoi &> /dev/null; then
    log_info "测试: chezmoi version"
    if chezmoi version &>/dev/null; then
        log_success "chezmoi 命令正常"
    else
        log_error "chezmoi 命令异常"
        exit 1
    fi

    log_info "测试: chezmoi status (带超时)"
    if timeout 5 chezmoi status &>/dev/null; then
        log_success "chezmoi status 正常"
    else
        log_warning "chezmoi status 超时或失败"
    fi
else
    log_error "chezmoi 未安装"
    exit 1
fi

log_info ""
log_success "修复完成！"
log_info ""
log_info "现在可以尝试运行:"
log_info "  chezmoi apply -v"
log_info "  或"
log_info "  ./deploy.sh"

