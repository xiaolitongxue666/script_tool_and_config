#!/usr/bin/env bash
set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_LIB}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

readonly SOURCE_AICONFIG_DIR="${HOME}/.config/aiconfig"
readonly CODEX_AICONFIG_DIR="${HOME}/.config/codex/aiconfig"

start_script "同步 Codex AI 配置"
[[ -d "${SOURCE_AICONFIG_DIR}" ]] || error_exit "缺少目录: ${SOURCE_AICONFIG_DIR}"
mkdir -p "$(dirname "${CODEX_AICONFIG_DIR}")"
rm -rf "${CODEX_AICONFIG_DIR}"
cp -R "${SOURCE_AICONFIG_DIR}" "${CODEX_AICONFIG_DIR}"
log_success "Codex 已同步: ${CODEX_AICONFIG_DIR}"
end_script
