#!/usr/bin/env bash

# chezmoi 锁检测与释放（由 chezmoi_core.sh source）

# ============================================

# 检查 chezmoi 是否被占用（锁检测，非交互）
# 返回 0=未占用, 1=已占用
chezmoi_check_lock() {
    local lock_file="${HOME}/.local/share/chezmoi/.lock"

    if [[ ! -f "$lock_file" ]]; then
        return 0
    fi

    local lock_pid
    lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")

    if [[ -z "$lock_pid" ]]; then
        return 0
    fi

    # 检查进程是否存在
    if kill -0 "$lock_pid" 2>/dev/null; then
        echo "[WARNING] chezmoi locked by PID=$lock_pid"
        return 1
    fi

    # 进程已不存在，清理残留锁
    rm -f "$lock_file"
    echo "[INFO] Cleaned stale chezmoi lock"
    return 0
}

# 清理残留锁文件（.lock 与 .chezmoi.lock）
_chezmoi_remove_stale_locks() {
    local state_dir="${HOME}/.local/share/chezmoi"
    local lock_path
    for lock_path in "${state_dir}/.lock" "${state_dir}/.chezmoi.lock"; do
        [[ -f "$lock_path" ]] || continue
        rm -f "$lock_path" 2>/dev/null || true
    done
}

# 终止残留 chezmoi 进程（Windows taskkill / Unix kill）
_chezmoi_kill_stale_processes() {
    local os pids pid line
    os="$(uname -s 2>/dev/null || echo "")"
    if [[ "$os" =~ ^(MINGW|MSYS|CYGWIN) ]] && command -v taskkill &>/dev/null; then
        taskkill //F //IM chezmoi.exe 2>/dev/null || true
        return 0
    fi
    if command -v pgrep &>/dev/null; then
        pids=$(pgrep -f "chezmoi" 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            for pid in $pids; do
                kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
            done
        fi
    fi
}

# 确保 chezmoi 未占用（若占用则等待或清理）
# 参数: max_wait_seconds (可选，默认 30)
chezmoi_ensure_unlocked() {
    local max_wait="${1:-30}"
    local waited=0

    while ! chezmoi_check_lock; do
        if [[ "$waited" -ge "$max_wait" ]]; then
            echo "[WARNING] Lock wait timeout, force releasing..."
            _chezmoi_kill_stale_processes
            _chezmoi_remove_stale_locks
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    # deploy.sh 历史路径：无 PID 的 .chezmoi.lock 也清理
    if [[ -f "${HOME}/.local/share/chezmoi/.chezmoi.lock" ]]; then
        rm -f "${HOME}/.local/share/chezmoi/.chezmoi.lock" 2>/dev/null || true
        echo "[INFO] Removed stale .chezmoi.lock"
    fi

    echo "[INFO] chezmoi is available (not locked)"
}

# ============================================
# chezmoi 配置管理
