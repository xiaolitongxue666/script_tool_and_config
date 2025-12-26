#!/bin/bash

# ============================================
# 统一配置管理脚本
# 功能：检测模板更新、生成配置、应用配置
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

start_script "配置管理"

# 设置路径
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
CHEZMOI_STATE_FILE="${PROJECT_ROOT}/.chezmoi_state.json"

log_info "项目根目录: $PROJECT_ROOT"
log_info "Chezmoi 目录: $CHEZMOI_DIR"

# 检查 chezmoi 是否可用
if ! command -v chezmoi >/dev/null 2>&1; then
    error_exit "chezmoi 未安装，请先安装 chezmoi"
fi

log_success "chezmoi 已安装: $(chezmoi --version | head -n 1)"

# 设置 CHEZMOI_SOURCE_DIR
export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

log_info "应用所有配置..."
if chezmoi apply -v; then
    log_success "配置应用成功"
else
    log_error "配置应用失败"
    exit 1
fi

end_script

