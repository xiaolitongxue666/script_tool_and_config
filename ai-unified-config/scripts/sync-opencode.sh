#!/usr/bin/env bash
set -euo pipefail
umask 022

# Git Bash/MSYS 默认 HOME 可能与 Windows 用户配置目录不一致，OpenCode 读取后者；与 install.sh 对齐
if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    if [[ -z "${USERPROFILE:-}" ]]; then
        current_user_name="${USERNAME:-${USER:-$(whoami 2>/dev/null || echo Administrator)}}"
        USERPROFILE="C:/Users/${current_user_name}"
        export USERPROFILE
        unset current_user_name
    fi
    if command -v cygpath &>/dev/null; then
        export HOME="$(cygpath -u "${USERPROFILE}")"
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${MODULE_ROOT}/.." && pwd)"
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_LIB}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

readonly SOURCE_AICONFIG_DIR="${HOME}/.config/aiconfig"
readonly FALLBACK_SOURCE_AICONFIG_DIR="${MODULE_ROOT}/.aiconfig"
readonly TARGET_OPENCODE_DIR="${HOME}/.config/opencode"
readonly TARGET_OPENCODE_META_DIR="${TARGET_OPENCODE_DIR}/.opencode"
readonly TARGET_AGENTS_DIR="${TARGET_OPENCODE_META_DIR}/agents"
readonly TARGET_SKILLS_DIR="${TARGET_OPENCODE_META_DIR}/skills"

source_aiconfig_dir=""
source_agents_dir=""
source_skills_dir=""

function resolve_source_dirs() {
    local preferred_agents_dir="${SOURCE_AICONFIG_DIR}/agents"
    local preferred_skills_dir="${SOURCE_AICONFIG_DIR}/skills"
    local fallback_agents_dir="${FALLBACK_SOURCE_AICONFIG_DIR}/agents"
    local fallback_skills_dir="${FALLBACK_SOURCE_AICONFIG_DIR}/skills"

    if [[ -d "${preferred_agents_dir}" && -d "${preferred_skills_dir}" ]]; then
        source_aiconfig_dir="${SOURCE_AICONFIG_DIR}"
        source_agents_dir="${preferred_agents_dir}"
        source_skills_dir="${preferred_skills_dir}"
        return 0
    fi

    if [[ -d "${fallback_agents_dir}" && -d "${fallback_skills_dir}" ]]; then
        source_aiconfig_dir="${FALLBACK_SOURCE_AICONFIG_DIR}"
        source_agents_dir="${fallback_agents_dir}"
        source_skills_dir="${fallback_skills_dir}"
        log_warning "未检测到全局 aiconfig，改用仓库内置模板源: ${source_aiconfig_dir}"
        return 0
    fi

    error_exit "缺少可用的 aiconfig 源目录（已检查: ${SOURCE_AICONFIG_DIR} 与 ${FALLBACK_SOURCE_AICONFIG_DIR}）"
}

function backup_target_dir_if_exists() {
    local target_dir="$1"
    if [[ -d "${target_dir}" ]]; then
        local backup_suffix
        backup_suffix="$(date +%Y%m%d_%H%M%S)"
        local backup_dir="${target_dir}.backup.${backup_suffix}"
        rm -rf "${backup_dir}"
        cp -R "${target_dir}" "${backup_dir}"
        log_info "已备份目录: ${backup_dir}"
    fi
}

function sync_tree_dir() {
    local source_dir="$1"
    local target_dir="$2"

    backup_target_dir_if_exists "${target_dir}"
    rm -rf "${target_dir}"
    mkdir -p "$(dirname "${target_dir}")"
    cp -R "${source_dir}" "${target_dir}"
}

function sync_opencode_content() {
    mkdir -p "${TARGET_OPENCODE_DIR}" "${TARGET_OPENCODE_META_DIR}"
    sync_tree_dir "${source_agents_dir}" "${TARGET_AGENTS_DIR}"
    sync_tree_dir "${source_skills_dir}" "${TARGET_SKILLS_DIR}"
}

start_script "同步 OpenCode agents/skills"
resolve_source_dirs
sync_opencode_content
log_success "OpenCode 已同步: ${TARGET_OPENCODE_META_DIR}"
end_script



