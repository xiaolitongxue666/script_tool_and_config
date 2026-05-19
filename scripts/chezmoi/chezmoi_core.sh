#!/usr/bin/env bash

# ============================================
# chezmoi 核心操作封装层
# 提供统一的 chezmoi 操作接口：
#   - apply / status / diff / unlock
#   - 环境检测与初始化
#   - 锁检测与释放
# 被 install.sh / deploy.sh / manage_dotfiles.sh 共享
# ============================================

# ============================================
# 环境检测
# ============================================

# 检测平台（与 common_install.sh 的 detect_platform 一致）
chezmoi_detect_platform() {
    OS="$(uname -s)"
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="darwin"
        PLATFORM_NAME="macOS"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        PLATFORM_NAME="Linux"
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        PLATFORM_NAME="Windows"
    else
        echo "[ERROR] Unsupported OS: $OS"
        return 1
    fi
    echo "[INFO] Platform: $PLATFORM_NAME ($OS)"
}

# 检测是否为 WSL
chezmoi_is_wsl() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        return 1
    fi
    grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]
}

# ============================================
# 代理配置
# ============================================

# 根据平台自动检测代理
# 返回（设置到 PROXY 变量）：
#  - 环境变量 PROXY / http_proxy
#  - WSL 下从 resolv.conf 获取宿主机 IP:7890
#  - 否则 127.0.0.1:7890
chezmoi_detect_proxy() {
    local proxy="${PROXY:-${http_proxy:-}}"

    # 如果已设代理，返回
    if [[ -n "$proxy" ]]; then
        echo "$proxy"
        return 0
    fi

    # WSL：从 resolv.conf 获取宿主机 IP
    if chezmoi_is_wsl; then
        local host_ip
        host_ip=$(awk '/^nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null)
        if [[ -n "$host_ip" ]]; then
            echo "http://${host_ip}:7890"
            return 0
        fi
    fi

    # 默认
    echo "http://127.0.0.1:7890"
}

# 设置代理环境变量
# 参数: proxy_url (可选)
chezmoi_setup_proxy() {
    local proxy_url="${1:-$(chezmoi_detect_proxy)}"

    if [[ -z "$proxy_url" ]]; then
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY PROXY PROXY_HOST PROXY_PORT
        echo "[INFO] No proxy set, using direct connection"
        return 0
    fi

    # 确保格式正确
    if [[ ! "$proxy_url" =~ ^https?:// ]]; then
        proxy_url="http://${proxy_url}"
    fi

    export PROXY="$proxy_url"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"

    # 解析 host:port 供模板使用
    local stripped="${proxy_url#*://}"
    local host="${stripped%%:*}"
    local port="${stripped#*:}"
    port="${port%%/*}"
    [[ -z "$port" || "$port" = "$host" ]] && port="7890"
    export PROXY_HOST="$host"
    export PROXY_PORT="$port"

    echo "[INFO] Proxy set: $proxy_url"
    echo "[INFO] Proxy host: $host, Proxy port: $port"
}

# ============================================
# chezmoi 锁管理
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

# 确保 chezmoi 未占用（若占用则等待或清理）
# 参数: max_wait_seconds (可选，默认 30)
chezmoi_ensure_unlocked() {
    local max_wait="${1:-30}"
    local waited=0

    while ! chezmoi_check_lock; do
        if [[ "$waited" -ge "$max_wait" ]]; then
            echo "[WARNING] Lock wait timeout, force releasing..."
            rm -f "${HOME}/.local/share/chezmoi/.lock" 2>/dev/null || true
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    echo "[INFO] chezmoi is available (not locked)"
}

# ============================================
# chezmoi 配置管理
# ============================================

# 获取 chezmoi 源状态目录（优先环境变量，其次默认路径）
chezmoi_get_source_dir() {
    local project_root="${CHEZMOI_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd 2>/dev/null || echo "")}"
    if [[ -n "$project_root" ]] && [[ -d "${project_root}/.chezmoi" ]]; then
        echo "${project_root}/.chezmoi"
    else
        echo "${CHEZMOI_SOURCE_DIR:-${HOME}/.local/share/chezmoi}"
    fi
}

# 检查 chezmoi 是否已安装
chezmoi_is_installed() {
    command -v chezmoi &>/dev/null
}

# 检查 chezmoi 源目录是否非空
chezmoi_source_dir_ok() {
    local source_dir
    source_dir=$(chezmoi_get_source_dir)
    [[ -d "$source_dir" ]] && [[ -n "$(ls -A "$source_dir" 2>/dev/null)" ]]
}

# 导出 apply 所需的环境变量（macOS connect 路径等）
chezmoi_export_apply_env() {
    export CHEZMOI_PAGER=""
    export PAGER=cat

    # macOS connect 路径
    if [[ "$(uname -s)" == "Darwin" ]]; then
        local connect_path=""
        if command -v connect &>/dev/null; then
            connect_path="$(command -v connect)"
        elif [[ -x /opt/homebrew/bin/connect ]]; then
            connect_path="/opt/homebrew/bin/connect"
        elif [[ -x /usr/local/bin/connect ]]; then
            connect_path="/usr/local/bin/connect"
        fi
        if [[ -n "$connect_path" ]]; then
            export CHEZMOI_MACOS_CONNECT_PATH="$connect_path"
        fi
    fi
}

# ============================================
# chezmoi 核心操作
# ============================================

# chezmoi status（检查配置状态）
# 输出到 stdout
chezmoi_run_status() {
    echo "[INFO] Checking config status (chezmoi status)..."
    chezmoi status 2>&1 || true
}

# chezmoi diff（检查配置差异）
# 输出到 stdout
chezmoi_run_diff() {
    echo "[INFO] Checking config diff (chezmoi diff)..."
    chezmoi diff 2>&1 || true
}

# chezmoi apply（应用配置）
# 参数: extra_args (可选，如 -v --force)
chezmoi_run_apply() {
    local extra_args="${1:--v --force}"

    if ! chezmoi_is_installed; then
        echo "[ERROR] chezmoi not installed, cannot apply"
        return 1
    fi

    # 确保解锁
    chezmoi_ensure_unlocked

    # 导出环境变量
    chezmoi_export_apply_env

    echo "[INFO] Running: chezmoi apply $extra_args"
    if chezmoi apply ${extra_args}; then
        echo "[SUCCESS] Config applied successfully"
        return 0
    else
        echo "[ERROR] Config apply failed"
        return 1
    fi
}

# 验证配置是否完全同步
# 返回 0=已同步, 1=仍有差异
chezmoi_verify_sync() {
    local status_output
    local diff_output

    status_output=$(chezmoi status 2>&1 || true)
    diff_output=$(chezmoi diff 2>&1 || true)

    # 过滤 run 脚本的状态行（run_*/run_once_* 已执行后仍显示 R，属正常）
    local status_clean
    status_clean=$(echo "$status_output" | grep -vE '^[[:space:]]*R[[:space:]]' || true)

    if [[ -z "$status_clean" ]] && [[ -z "$diff_output" ]]; then
        echo "[SUCCESS] Config fully synced"
        return 0
    fi

    # 检查差异是否仅包含其他平台的 run_on_* 文件
    if [[ -n "$status_clean" ]] || [[ -n "$diff_output" ]]; then
        local platform="${1:-$(uname -s)}"
        local pattern=""
        case "$platform" in
            *MINGW*|*MSYS*|*CYGWIN*) pattern='run_on_(darwin|linux)/' ;;
            Linux)  pattern='run_on_(darwin|windows)/' ;;
            Darwin) pattern='run_on_(linux|windows)/' ;;
        esac

        if [[ -n "$pattern" ]]; then
            local combined="${status_clean}"$'\n'"${diff_output}"
            local non_other
            non_other=$(echo "$combined" | grep -vE "$pattern" | grep -v '^[[:space:]]*$' || true)
            if [[ -z "$non_other" ]]; then
                echo "[INFO] Config synced; remaining items are other-OS run_on_* files (expected)"
                return 0
            fi
        fi
    fi

    echo "[WARNING] Config still has differences after apply"
    return 1
}
