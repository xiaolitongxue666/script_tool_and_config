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
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

readonly TEMPLATE_DIR="${MODULE_ROOT}/.aiconfig/templates"
readonly TARGET_CURSOR_RULES_DIR="${PROJECT_ROOT}/.cursor/rules"
readonly TARGET_OPENCODE_DIR="${PROJECT_ROOT}/.opencode"
readonly TARGET_CODEX_DIR="${PROJECT_ROOT}/.codex"

function ensure_templates() {
    [[ -f "${TEMPLATE_DIR}/PROJECT-AGENT-SHARED-PRINCIPLES.md" ]] || error_exit "缺少模板: PROJECT-AGENT-SHARED-PRINCIPLES.md"
    [[ -f "${TEMPLATE_DIR}/project-cursor-rule.mdc" ]] || error_exit "缺少模板: project-cursor-rule.mdc"
    [[ -f "${TEMPLATE_DIR}/PROJECT-OPENCODE-AGENTS.md" ]] || error_exit "缺少模板: PROJECT-OPENCODE-AGENTS.md"
    [[ -f "${TEMPLATE_DIR}/PROJECT-CODEX-AGENTS.md" ]] || error_exit "缺少模板: PROJECT-CODEX-AGENTS.md"
}

function sync_project_constraints() {
    mkdir -p "${TARGET_CURSOR_RULES_DIR}" "${TARGET_OPENCODE_DIR}" "${TARGET_CODEX_DIR}" "${PROJECT_ROOT}/.aiconfig/templates"

    cp "${TEMPLATE_DIR}/PROJECT-AGENT-SHARED-PRINCIPLES.md" "${PROJECT_ROOT}/.aiconfig/templates/PROJECT-AGENT-SHARED-PRINCIPLES.md"
    cp "${TEMPLATE_DIR}/project-cursor-rule.mdc" "${TARGET_CURSOR_RULES_DIR}/ai-project-principles.mdc"
    cp "${TEMPLATE_DIR}/PROJECT-OPENCODE-AGENTS.md" "${TARGET_OPENCODE_DIR}/AGENTS.md"
    cp "${TEMPLATE_DIR}/PROJECT-CODEX-AGENTS.md" "${TARGET_CODEX_DIR}/AGENTS.md"
}

start_script "同步项目级 AI 约束文档"
ensure_templates
sync_project_constraints
log_success "项目级约束已同步到 .cursor/.opencode/.codex"
end_script
