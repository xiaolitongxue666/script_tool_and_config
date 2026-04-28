#!/usr/bin/env bash
set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_AICONFIG_DIR="${MODULE_ROOT}/.aiconfig"

TARGET_PROJECT_DIR="${1:-}"
if [[ -z "${TARGET_PROJECT_DIR}" ]]; then
    echo "[ERROR] 用法: $0 <project-path>" >&2
    exit 1
fi

if command -v cygpath &>/dev/null; then
    TARGET_PROJECT_DIR="$(cygpath -u "${TARGET_PROJECT_DIR}" 2>/dev/null || echo "${TARGET_PROJECT_DIR}")"
fi

if [[ ! -d "${TARGET_PROJECT_DIR}" ]]; then
    echo "[ERROR] 目标项目不存在: ${TARGET_PROJECT_DIR}" >&2
    exit 1
fi

TARGET_AICONFIG_DIR="${TARGET_PROJECT_DIR}/.aiconfig"
mkdir -p "${TARGET_AICONFIG_DIR}"

rm -rf "${TARGET_AICONFIG_DIR}/agents" \
    "${TARGET_AICONFIG_DIR}/skills" \
    "${TARGET_AICONFIG_DIR}/resources" \
    "${TARGET_AICONFIG_DIR}/templates"

cp -R "${SOURCE_AICONFIG_DIR}/agents" "${TARGET_AICONFIG_DIR}/agents"
cp -R "${SOURCE_AICONFIG_DIR}/skills" "${TARGET_AICONFIG_DIR}/skills"
cp -R "${SOURCE_AICONFIG_DIR}/resources" "${TARGET_AICONFIG_DIR}/resources"
cp -R "${SOURCE_AICONFIG_DIR}/templates" "${TARGET_AICONFIG_DIR}/templates"

echo "[SUCCESS] 已同步到项目: ${TARGET_AICONFIG_DIR}"
