#!/usr/bin/env bash
set -euo pipefail
umask 022

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
readonly SOURCE_AGENTS_DIR="${SOURCE_AICONFIG_DIR}/agents"
readonly SOURCE_SKILLS_DIR="${SOURCE_AICONFIG_DIR}/skills"
readonly TARGET_OPENCODE_DIR="${HOME}/.config/opencode"
readonly TARGET_OPENCODE_META_DIR="${TARGET_OPENCODE_DIR}/.opencode"
readonly TARGET_AGENTS_DIR="${TARGET_OPENCODE_META_DIR}/agents"
readonly TARGET_SKILLS_DIR="${TARGET_OPENCODE_META_DIR}/skills"

function ensure_source_dirs() {
    [[ -d "${SOURCE_AGENTS_DIR}" ]] || error_exit "缺少 agents 目录: ${SOURCE_AGENTS_DIR}"
    [[ -d "${SOURCE_SKILLS_DIR}" ]] || error_exit "缺少 skills 目录: ${SOURCE_SKILLS_DIR}"
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
    sync_tree_dir "${SOURCE_AGENTS_DIR}" "${TARGET_AGENTS_DIR}"
    sync_tree_dir "${SOURCE_SKILLS_DIR}" "${TARGET_SKILLS_DIR}"
}

start_script "同步 OpenCode agents/skills"
ensure_source_dirs
sync_opencode_content
log_success "OpenCode 已同步: ${TARGET_OPENCODE_META_DIR}"
end_script
