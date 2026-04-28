#!/usr/bin/env bash
# ============================================
# Zsh 启动时间测量脚本
# 执行 time zsh -i -c exit 并解析输出，便于统一记录格式
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_SH}" ]]; then
    # shellcheck source=../../common.sh
    source "${COMMON_SH}"
else
    function log_info() { echo "[INFO] $*"; }
fi

RUNS="${1:-3}"

log_info "测量 zsh 启动时间 (zsh -i -c exit)，共 ${RUNS} 次"
for ((i=1; i<=RUNS; i++)); do
    # time 输出到 stderr，格式因 shell 而异（bash: real 0m0.123s）
    log_info "--- 第 ${i} 次 ---"
    { time zsh -i -c exit; } 2>&1
done

log_info "请将上述 real 时间记录到 docs/ZSH_STARTUP_TIME.md"

log_info "记录可写入 docs/ZSH_STARTUP_TIME.md"
