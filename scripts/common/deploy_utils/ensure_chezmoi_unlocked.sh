#!/usr/bin/env bash
# 确保 chezmoi 未占用（非交互）
# 供 install.sh / deploy.sh / fix_chezmoi_lock.sh 在 apply 前调用
# 逻辑已统一到 scripts/chezmoi/chezmoi_core.sh → chezmoi_ensure_unlocked

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CHEZMOI_CORE="${PROJECT_ROOT}/scripts/chezmoi/chezmoi_core.sh"

if [[ ! -f "$CHEZMOI_CORE" ]]; then
    echo "[ERROR] chezmoi_core.sh not found: $CHEZMOI_CORE" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$CHEZMOI_CORE"

chezmoi_ensure_unlocked "${CHEZMOI_UNLOCK_WAIT:-5}"
