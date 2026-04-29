#!/usr/bin/env bash
# ============================================
# OpenCode 安装验证脚本
# 检查：opencode 在 PATH、版本、基础配置文件、oh-my-opencode 遗留路径、agents/skills 目录
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
OPENCODE_HOME="${HOME}/.config/opencode"
OC_JSON="${OPENCODE_HOME}/opencode.json"

# MSYS2/Git Bash 子进程中 HOME 可能为 /home/xxx，尝试用 USERPROFILE 修正
if [[ ! -f "$OC_JSON" ]]; then
    local_win_home="${USERPROFILE:-$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r\n' || true)}"
    if [[ -n "${local_win_home:-}" ]]; then
        local_win_home="$(cygpath -u "${local_win_home}" 2>/dev/null || echo "${local_win_home}")"
        OPENCODE_HOME="${local_win_home}/.config/opencode"
        OC_JSON="${OPENCODE_HOME}/opencode.json"
    fi
fi

if [[ ! -f "$OC_JSON" ]]; then
    log_warning "配置文件不存在: ${OC_JSON}"
    EXIT_CODE=1
else
    log_success "opencode 配置文件存在: ${OC_JSON}"
fi

# OpenCode 新版本已移除 oh-my-opencode；Git Bash 下 HOME 与 USERPROFILE 可能对应两套路径，需都检查
LEGACY_CHECK_ROOTS=("${OPENCODE_HOME}")
if [[ -n "${USERPROFILE:-}" ]]; then
    profile_unix="$(cygpath -u "${USERPROFILE}" 2>/dev/null)" || profile_unix=""
    if [[ -n "${profile_unix}" ]]; then
        alt_oc="${profile_unix}/.config/opencode"
        if [[ "${alt_oc}" != "${OPENCODE_HOME}" ]]; then
            LEGACY_CHECK_ROOTS+=("${alt_oc}")
        fi
    fi
fi
legacy_omo_ok=1
for legacy_oc_root in "${LEGACY_CHECK_ROOTS[@]}"; do
    if [[ -e "${legacy_oc_root}/oh-my-opencode" ]]; then
        log_error "遗留路径仍存在，请删除: ${legacy_oc_root}/oh-my-opencode"
        EXIT_CODE=1
        legacy_omo_ok=0
    fi
done
if [[ "${legacy_omo_ok}" -eq 1 ]]; then
    log_success "未检测到 oh-my-opencode 遗留路径"
fi

# 检查 .opencode 目录结构
AGENTS_DIR="${OPENCODE_HOME}/.opencode/agents"
SKILLS_DIR="${OPENCODE_HOME}/.opencode/skills"

if [[ ! -d "${AGENTS_DIR}" ]]; then
    log_warning "agents 目录不存在: ${AGENTS_DIR}"
    EXIT_CODE=1
else
    if [[ -n "$(ls -A "${AGENTS_DIR}" 2>/dev/null)" ]]; then
        log_success "agents 目录存在且非空: ${AGENTS_DIR}"
    else
        log_warning "agents 目录为空: ${AGENTS_DIR}"
        EXIT_CODE=1
    fi
fi

if [[ ! -d "${SKILLS_DIR}" ]]; then
    log_warning "skills 目录不存在: ${SKILLS_DIR}"
    EXIT_CODE=1
else
    if [[ -n "$(ls -A "${SKILLS_DIR}" 2>/dev/null)" ]]; then
        log_success "skills 目录存在且非空: ${SKILLS_DIR}"
    else
        log_warning "skills 目录为空: ${SKILLS_DIR}"
        EXIT_CODE=1
    fi
fi

if [[ -f "${AGENTS_DIR}/ORCHESTRATOR-CORE.md" ]]; then
    log_success "关键 agent 文件可读: ${AGENTS_DIR}/ORCHESTRATOR-CORE.md"
else
    log_warning "缺少可选 agent 文件（未同步或自定义布局时可忽略）: ${AGENTS_DIR}/ORCHESTRATOR-CORE.md"
fi

exit "$EXIT_CODE"
