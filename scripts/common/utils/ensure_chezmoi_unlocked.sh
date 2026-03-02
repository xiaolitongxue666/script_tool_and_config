#!/usr/bin/env bash

# ============================================
# 确保 chezmoi 未占用（非交互）
# 供 install.sh / deploy.sh 在 apply 前调用；区分 Linux/macOS/WSL 与 Windows
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "$COMMON_SH" ]]; then
    # shellcheck disable=SC1090
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

CHEZMOI_STATE_DIR="${CHEZMOI_STATE_DIR:-$HOME/.local/share/chezmoi}"
LOCK_FILE="${CHEZMOI_STATE_DIR}/.chezmoi.lock"
WAIT_SECONDS="${CHEZMOI_UNLOCK_WAIT:-5}"

# 检测平台（用于日志）
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" == "Linux" ]]; then
    if grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        PLATFORM="wsl"
    else
        PLATFORM="linux"
    fi
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
else
    PLATFORM="unknown"
fi

log_info "确保 chezmoi 可写 (平台: ${PLATFORM})..."

# 无锁则直接成功
if [[ ! -f "$LOCK_FILE" ]]; then
    log_success "无锁文件，可继续"
    exit 0
fi

# 收集占用 chezmoi 的进程 PID（多行输出，空格分隔供 kill 使用）
get_chezmoi_pids() {
    # 优先使用 pgrep（Linux/macOS/WSL 及 Git Bash 下常有）
    if command -v pgrep &>/dev/null; then
        pgrep -f "chezmoi" 2>/dev/null || true
        return 0
    fi
    # Windows 下 pgrep 不可用时用 tasklist
    if [[ "$PLATFORM" == "windows" ]] && command -v tasklist &>/dev/null; then
        local line pids=""
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$line" =~ \"([0-9]+)\" ]]; then
                pids="${pids} ${BASH_REMATCH[1]}"
            fi
        done < <(tasklist /FI "IMAGENAME eq chezmoi.exe" /FO CSV /NH 2>/dev/null)
        echo "$pids"
        return 0
    fi
    echo ""
    return 0
}

# 终止进程：Linux/macOS/WSL 用 kill；Windows 用 taskkill
kill_chezmoi_processes() {
    local pids="$1"
    if [[ -z "$pids" ]]; then
        return 0
    fi
    if [[ "$PLATFORM" == "windows" ]]; then
        if command -v taskkill &>/dev/null; then
            for pid in $pids; do
                taskkill //PID "$pid" //F 2>/dev/null || true
            done
        fi
        return 0
    fi
    for pid in $pids; do
        kill "$pid" 2>/dev/null || true
    done
    sleep 1
    local remaining
    remaining=$(pgrep -f "chezmoi" 2>/dev/null || true)
    if [[ -n "$remaining" ]]; then
        for pid in $remaining; do
            kill -9 "$pid" 2>/dev/null || true
        done
    fi
    return 0
}

# 有锁：先尝试等待
log_info "发现锁文件，等待 ${WAIT_SECONDS} 秒..."
sleep "$WAIT_SECONDS"

PIDS=$(get_chezmoi_pids)
if [[ -n "$PIDS" ]]; then
    log_warning "存在 chezmoi 进程，将终止以便继续: $PIDS"
    kill_chezmoi_processes "$PIDS"
    sleep 1
fi

# 再次检查：若锁仍存在且无进程，视为残留
if [[ -f "$LOCK_FILE" ]]; then
    PIDS=$(get_chezmoi_pids)
    if [[ -n "$PIDS" ]]; then
        log_warning "进程仍在，强制终止: $PIDS"
        kill_chezmoi_processes "$PIDS"
        sleep 1
    fi
    rm -f "$LOCK_FILE"
    log_success "已移除锁文件"
fi

log_success "chezmoi 可写，可继续 apply"
exit 0
