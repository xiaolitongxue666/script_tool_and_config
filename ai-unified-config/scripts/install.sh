#!/usr/bin/env bash
set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${MODULE_ROOT}/.." && pwd)"
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

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

readonly GLOBAL_AICONFIG_DIR="${HOME}/.config/aiconfig"
readonly SOURCE_AICONFIG_DIR="${MODULE_ROOT}/.aiconfig"
readonly SYNC_CURSOR_SCRIPT="${SCRIPT_DIR}/sync-cursor.sh"
readonly SYNC_CODEX_SCRIPT="${SCRIPT_DIR}/sync-codex.sh"

function ensure_required_source() {
    [[ -d "${SOURCE_AICONFIG_DIR}" ]] || error_exit "缺少目录: ${SOURCE_AICONFIG_DIR}"
}

function sync_global_content() {
    mkdir -p "${GLOBAL_AICONFIG_DIR}"
    rm -rf "${GLOBAL_AICONFIG_DIR}/agents" \
        "${GLOBAL_AICONFIG_DIR}/skills" \
        "${GLOBAL_AICONFIG_DIR}/resources" \
        "${GLOBAL_AICONFIG_DIR}/templates"

    cp -R "${SOURCE_AICONFIG_DIR}/agents" "${GLOBAL_AICONFIG_DIR}/agents"
    cp -R "${SOURCE_AICONFIG_DIR}/skills" "${GLOBAL_AICONFIG_DIR}/skills"
    cp -R "${SOURCE_AICONFIG_DIR}/resources" "${GLOBAL_AICONFIG_DIR}/resources"
    cp -R "${SOURCE_AICONFIG_DIR}/templates" "${GLOBAL_AICONFIG_DIR}/templates"
}

function sync_cursor_and_codex() {
    if [[ -x "${SYNC_CURSOR_SCRIPT}" ]]; then
        bash "${SYNC_CURSOR_SCRIPT}"
    else
        log_warning "未找到 Cursor 同步脚本: ${SYNC_CURSOR_SCRIPT}"
    fi

    if [[ -x "${SYNC_CODEX_SCRIPT}" ]]; then
        bash "${SYNC_CODEX_SCRIPT}"
    else
        log_warning "未找到 Codex 同步脚本: ${SYNC_CODEX_SCRIPT}"
    fi
}

start_script "AI 配置模块安装"
ensure_required_source
sync_global_content
sync_cursor_and_codex
log_success "AI 配置模块已安装到全局目录"
end_script
