#!/usr/bin/env bash
# ============================================
# OpenCode 安装验证脚本
# 检查：opencode 在 PATH、版本、基础配置文件是否存在
# 可单独运行或供 verify_installation.sh 复用
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_SH}" ]]; then
    # shellcheck source=../common.sh
    source "${COMMON_SH}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

EXIT_CODE=0

# OpenCode 是否在 PATH
if ! command -v opencode &>/dev/null; then
    log_error "opencode 未在 PATH 中"
    EXIT_CODE=1
else
    log_success "opencode: $(command -v opencode)"
    version_line="$(opencode --version 2>/dev/null)" || true
    version_line="$(echo "${version_line}" | head -n1)"
    if [[ -n "${version_line:-}" ]]; then
        log_info "版本: ${version_line}"
        # 建议 >= 1.0.150
        if echo "$version_line" | grep -qE "1\.[0-9]+\.[0-9]+"; then
            log_success "版本格式正常"
        else
            log_warning "建议 opencode >= 1.0.150，当前: ${version_line}"
        fi
    else
        log_warning "无法获取 opencode 版本"
    fi
fi

# ~/.config/opencode/opencode.json 是否存在
OC_JSON="${HOME}/.config/opencode/opencode.json"
# MSYS2/Git Bash 子进程中 HOME 可能为 /home/xxx，尝试用 USERPROFILE 修正
if [[ ! -f "$OC_JSON" ]]; then
    local_win_home="${USERPROFILE:-$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r\n' || true)}"
    if [[ -n "${local_win_home:-}" ]]; then
        local_win_home="$(cygpath -u "${local_win_home}" 2>/dev/null || echo "${local_win_home}")"
        OC_JSON="${local_win_home}/.config/opencode/opencode.json"
    fi
fi
if [[ ! -f "$OC_JSON" ]]; then
    log_warning "配置文件不存在: ${OC_JSON}"
    EXIT_CODE=1
else
    log_success "opencode 配置文件存在: ${OC_JSON}"
fi

exit "$EXIT_CODE"
