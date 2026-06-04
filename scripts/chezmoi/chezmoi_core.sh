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

# Git Bash / MSYS：规范化 HOME、USERPROFILE、USERNAME（chezmoi.exe 与模板需要）
chezmoi_normalize_windows_env() {
    if [[ ! "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        return 0
    fi

    export LANG="${LANG:-C.UTF-8}"
    export LC_ALL="${LC_ALL:-C.UTF-8}"

    if [[ -z "${USERPROFILE:-}" ]]; then
        local _up_user="${HOME##*/}"
        if [[ -n "$_up_user" && "$_up_user" != "$HOME" ]]; then
            USERPROFILE="C:/Users/${_up_user}"
        else
            USERPROFILE="C:/Users/${USERNAME:-$USER}"
        fi
        export USERPROFILE
    fi

    local _normalized_home=""
    if command -v cygpath &>/dev/null; then
        _normalized_home="$(cygpath -u "${USERPROFILE}")"
    else
        _normalized_home="/c/Users/${USERNAME:-$USER}"
    fi
    if [[ -n "${_normalized_home}" ]]; then
        export HOME="${_normalized_home}"
    fi

    if [[ -z "${USERNAME:-}" ]]; then
        if [[ -n "${USERPROFILE:-}" ]]; then
            USERNAME="${USERPROFILE##*[/\\]}"
        else
            USERNAME="${USER:-$(whoami 2>/dev/null || echo Administrator)}"
        fi
        export USERNAME
    fi
    if [[ -z "${USER:-}" ]]; then
        export USER="${USERNAME:-$(whoami 2>/dev/null || echo Administrator)}"
    fi
    unset _normalized_home
}

# 导出 chezmoi 模板渲染所需环境（避免 %userprofile% is not defined）
chezmoi_export_template_env() {
    chezmoi_normalize_windows_env

    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        export USERPROFILE="${USERPROFILE:-}"
        export USER="${USER:-${USERNAME:-}}"
        export USERNAME="${USERNAME:-${USER:-}}"
        # chezmoi.exe (Go) 在部分路径下读取小写 userprofile
        export userprofile="${USERPROFILE}"
    fi
}

# ============================================
# 代理配置
# ============================================

# 代理是否被显式禁用（PROXY=none/false 或 NO_PROXY=1）
chezmoi_proxy_disabled() {
    if [[ "${NO_PROXY:-0}" == "1" ]]; then
        return 0
    fi
    local proxy="${PROXY:-${http_proxy:-}}"
    case "$proxy" in
        none|false|NONE|FALSE) return 0 ;;
    esac
    return 1
}

# 代理检测日志（stderr，避免污染 stdout 返回值）
_chezmoi_log_proxy_detect() {
    echo "[INFO] $*" >&2
}

# 根据平台自动检测代理
# stdout 仅输出 URL；日志写 stderr
#  - 环境变量 PROXY / http_proxy（none/false 视为禁用，输出空）
#  - WSL 下从 resolv.conf 获取宿主机 IP:7890
#  - 否则 127.0.0.1:7890
chezmoi_detect_proxy() {
    if chezmoi_proxy_disabled; then
        _chezmoi_log_proxy_detect "Proxy disabled (PROXY=${PROXY:-unset}, http_proxy=${http_proxy:-unset}, NO_PROXY=${NO_PROXY:-0})"
        return 0
    fi

    local proxy="${PROXY:-${http_proxy:-}}"
    local os
    os="$(uname -s 2>/dev/null || echo unknown)"

    if [[ -n "$proxy" ]]; then
        _chezmoi_log_proxy_detect "Proxy source: env (OS=${os}, WSL=$(chezmoi_is_wsl && echo yes || echo no))"
        echo "$proxy"
        return 0
    fi

    if chezmoi_is_wsl; then
        local host_ip
        host_ip=$(awk '/^nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null)
        if [[ -n "$host_ip" ]]; then
            _chezmoi_log_proxy_detect "Proxy source: wsl_host (nameserver=${host_ip}, OS=${os})"
            echo "http://${host_ip}:7890"
            return 0
        fi
        _chezmoi_log_proxy_detect "Proxy source: wsl_fallback (no nameserver in resolv.conf, using 127.0.0.1)"
    else
        _chezmoi_log_proxy_detect "Proxy source: default_local (OS=${os}, WSL=no)"
    fi

    echo "http://127.0.0.1:7890"
}

# 清除所有代理相关环境变量
_chezmoi_unset_proxy_env() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY PROXY PROXY_HOST PROXY_PORT \
        GIT_HTTP_PROXY GIT_HTTPS_PROXY all_proxy ALL_PROXY 2>/dev/null || true
}

# 设置代理环境变量
# 参数: proxy_url (可选，默认 chezmoi_detect_proxy)
chezmoi_setup_proxy() {
    if chezmoi_proxy_disabled; then
        _chezmoi_unset_proxy_env
        echo "[INFO] No proxy set, using direct connection" >&2
        return 0
    fi

    local proxy_url="${1:-$(chezmoi_detect_proxy)}"

    if [[ -z "$proxy_url" ]]; then
        _chezmoi_unset_proxy_env
        echo "[INFO] No proxy set, using direct connection" >&2
        return 0
    fi

    if [[ ! "$proxy_url" =~ ^https?:// ]]; then
        proxy_url="http://${proxy_url}"
    fi

    export PROXY="$proxy_url"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    export GIT_HTTP_PROXY="$proxy_url"
    export GIT_HTTPS_PROXY="$proxy_url"

    local stripped="${proxy_url#*://}"
    local host="${stripped%%:*}"
    local port="${stripped#*:}"
    port="${port%%/*}"
    [[ -z "$port" || "$port" = "$host" ]] && port="7890"
    export PROXY_HOST="$host"
    export PROXY_PORT="$port"

    echo "[INFO] Proxy set: $proxy_url" >&2
    echo "[INFO] Proxy host: $host, Proxy port: $port" >&2
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

# 写入 ~/.config/chezmoi/chezmoi.toml：sourceDir 指向项目 .chezmoi；Windows 下配置 [interpreters.sh]
# chezmoi 不读取 CHEZMOI_SOURCE_DIR 环境变量，必须通过 config；未配置 [interpreters.sh] 时
# run_once 会报「%1 is not a valid Win32 application」
# 参数: project_root（仓库根目录，含 .chezmoi 子目录）
chezmoi_ensure_user_config() {
    local project_root="${1:-${CHEZMOI_PROJECT_ROOT:-}}"
    if [[ -z "$project_root" ]] || [[ ! -d "${project_root}/.chezmoi" ]]; then
        echo "[WARNING] chezmoi_ensure_user_config: invalid project root, skipped" >&2
        return 0
    fi

    local chezmoi_config_dir="${HOME}/.config/chezmoi"
    local chezmoi_config_file="${chezmoi_config_dir}/chezmoi.toml"
    local source_dir_abs
    source_dir_abs="$(cd "${project_root}" && pwd)/.chezmoi"

    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        if command -v cygpath &>/dev/null; then
            local _win_path
            _win_path="$(cygpath -w "${source_dir_abs}" 2>/dev/null)"
            [[ -n "$_win_path" ]] && source_dir_abs="${_win_path//\\//}"
            unset _win_path
        elif [[ "${source_dir_abs}" =~ ^/([a-zA-Z])/(.*) ]]; then
            source_dir_abs="${BASH_REMATCH[1]^^}:/${BASH_REMATCH[2]}"
        fi
    fi

    mkdir -p "$chezmoi_config_dir"
    local need_write=false
    if [[ ! -f "$chezmoi_config_file" ]]; then
        need_write=true
    elif ! grep -qF "sourceDir = \"${source_dir_abs}\"" "$chezmoi_config_file" 2>/dev/null; then
        if grep -q "^sourceDir = " "$chezmoi_config_file" 2>/dev/null; then
            sed -i "s|^sourceDir = .*|sourceDir = \"${source_dir_abs}\"|" "$chezmoi_config_file"
            echo "[INFO] Updated chezmoi sourceDir: ${source_dir_abs}" >&2
        else
            need_write=true
        fi
    fi

    if [[ "$need_write" == true ]]; then
        if [[ -f "$chezmoi_config_file" ]]; then
            printf 'sourceDir = "%s"\n\n' "$source_dir_abs" > "${chezmoi_config_file}.new"
            cat "$chezmoi_config_file" >> "${chezmoi_config_file}.new"
            mv "${chezmoi_config_file}.new" "$chezmoi_config_file"
        else
            printf 'sourceDir = "%s"\n\n[git]\n    autoCommit = false\n    autoPush = false\n' \
                "$source_dir_abs" > "$chezmoi_config_file"
        fi
        echo "[INFO] Written chezmoi config: ${chezmoi_config_file}" >&2
    fi

    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        local bash_cmd="bash"
        if command -v bash &>/dev/null && command -v cygpath &>/dev/null; then
            local _b
            _b="$(cygpath -w "$(command -v bash)" 2>/dev/null)"
            [[ -n "$_b" ]] && bash_cmd="${_b//\\//}"
            unset _b
        fi
        if ! grep -q '\[interpreters\.sh\]' "$chezmoi_config_file" 2>/dev/null; then
            printf '\n[interpreters.sh]\n    command = "%s"\n' "$bash_cmd" >> "$chezmoi_config_file"
            echo "[INFO] Added chezmoi [interpreters.sh] command = ${bash_cmd}" >&2
        fi
    fi

    export CHEZMOI_SOURCE_DIR="${source_dir_abs}"
}

# 导出 apply 所需的环境变量（macOS connect 路径等）
chezmoi_export_apply_env() {
    chezmoi_export_template_env
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

# Windows：检测 Git for Windows 路径（C:/ 或 D:/），写入 chezmoi --override-data-file
# stdout: 临时 TOML 路径；无检测脚本或失败时 stdout 为空
chezmoi_write_windows_git_override_data() {
    if [[ ! "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        return 0
    fi

    local source_dir="${1:-}"
    if [[ -z "$source_dir" ]]; then
        source_dir="$(chezmoi_get_source_dir)"
    fi

    local detect_script="${source_dir}/detect_windows_git_paths.sh"
    if [[ ! -f "$detect_script" ]]; then
        echo "[WARNING] detect_windows_git_paths.sh not found, skip Windows Git path override" >&2
        return 0
    fi

    local bash_path icon_path connect_path
    bash_path="$(bash "$detect_script" bash 2>/dev/null || true)"
    icon_path="$(bash "$detect_script" icon 2>/dev/null || true)"
    connect_path="$(bash "$detect_script" connect 2>/dev/null || true)"

    if [[ -z "$bash_path" ]]; then
        echo "[WARNING] Failed to detect Git for Windows paths" >&2
        return 0
    fi

    local override_file
    override_file="$(mktemp "${TMPDIR:-/tmp}/chezmoi-win-git-paths.XXXXXX.toml" 2>/dev/null || mktemp /tmp/chezmoi-win-git-paths.XXXXXX.toml)"
    {
        printf 'windows_git_bash_path = "%s"\n' "$bash_path"
        printf 'windows_git_icon_path = "%s"\n' "$icon_path"
        printf 'windows_git_connect_path = "%s"\n' "$connect_path"
    } > "$override_file"

    echo "$override_file"
}

# Windows：将 ~/.config/windows-terminal/settings.json 同步到 WT LocalState
# （override-data 改变渲染结果时 run_onchange 的 depends 不会触发，故 apply 后显式同步）
chezmoi_sync_windows_terminal_config() {
    if [[ ! "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        return 0
    fi

    local src=""
    [[ -f "$HOME/.config/windows-terminal/settings.json" ]] && src="$HOME/.config/windows-terminal/settings.json"
    [[ -z "$src" ]] && [[ -f "$HOME/run_on_windows/.config/windows-terminal/settings.json" ]] && \
        src="$HOME/run_on_windows/.config/windows-terminal/settings.json"

    if [[ -z "$src" ]] || [[ ! -f "$src" ]]; then
        echo "[INFO] Windows Terminal settings source not found, skip sync" >&2
        return 0
    fi

    local local_app_data="${LOCALAPPDATA:-$HOME/AppData/Local}"
    local wt_new_dir="${local_app_data}/Microsoft/Windows Terminal"
    local wt_classic_dir="${local_app_data}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
    local synced=false
    local dest_dir dest backup

    _wt_sync_to_dir() {
        dest_dir="$1"
        if [[ -d "$dest_dir" ]]; then
            dest="${dest_dir}/settings.json"
            cp "$src" "$dest"
            echo "[INFO] Synced Windows Terminal settings to: ${dest}" >&2
            backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$dest" "$backup" 2>/dev/null || true
            synced=true
            return 0
        fi
        return 1
    }

    if [[ -f "${wt_classic_dir}/settings.json" ]]; then
        _wt_sync_to_dir "$wt_classic_dir" || true
    fi
    _wt_sync_to_dir "$wt_new_dir" || true

    if [[ "$synced" != true ]]; then
        mkdir -p "$wt_new_dir"
        cp "$src" "${wt_new_dir}/settings.json"
        echo "[INFO] Created and synced Windows Terminal settings to: ${wt_new_dir}/settings.json" >&2
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

    local apply_args=()
    # shellcheck disable=SC2206
    read -r -a apply_args <<< "$extra_args"

    # 非交互 apply：缺 --force 时自动补上（避免 .gitconfig 等外部修改触发交互卡住）
    local _apply_arg _has_force=false
    for _apply_arg in "${apply_args[@]}"; do
        [[ "$_apply_arg" == "--force" ]] && _has_force=true
    done
    if ! $_has_force; then
        apply_args+=("--force")
    fi
    unset _apply_arg _has_force

    local user_config="${HOME}/.config/chezmoi/chezmoi.toml"
    if [[ -n "${CHEZMOI_PROJECT_ROOT:-}" ]]; then
        chezmoi_ensure_user_config "${CHEZMOI_PROJECT_ROOT}"
    fi

    # 优先使用用户 config（含 sourceDir 与 Windows [interpreters.sh]）。
    # 勿在已有 sourceDir 时再传 --source 为 Git Bash 的 /d/... 路径，否则 chezmoi.exe 可能
    # 直接 fork/exec .sh 并报「%1 is not a valid Win32 application」。
    if [[ -f "$user_config" ]]; then
        apply_args=(--config "$user_config" "${apply_args[@]}")
    else
        local source_dir
        source_dir="$(chezmoi_get_source_dir)"
        if [[ -d "$source_dir" ]]; then
            apply_args=(--source "$source_dir" "${apply_args[@]}")
        fi
    fi

    # 源内 chezmoi.toml [data] 的 Go 模板不会自动求值；Windows 下注入检测到的 Git 路径
    local win_git_override_file=""
    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        win_git_override_file="$(chezmoi_write_windows_git_override_data "")"
        if [[ -n "$win_git_override_file" && -f "$win_git_override_file" ]]; then
            apply_args=(--override-data-file "$win_git_override_file" "${apply_args[@]}")
        fi
    fi

    echo "[INFO] Running: chezmoi apply ${apply_args[*]}"
    local apply_rc=0
    if chezmoi apply "${apply_args[@]}"; then
        echo "[SUCCESS] Config applied successfully"
        apply_rc=0
    else
        echo "[ERROR] Config apply failed"
        apply_rc=1
    fi

    if [[ -n "$win_git_override_file" ]]; then
        rm -f "$win_git_override_file"
    fi

    if [[ "$apply_rc" -eq 0 ]] && [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        chezmoi_sync_windows_terminal_config
    fi

    return "$apply_rc"
}

# 验证配置是否完全同步
# 返回 0=已同步, 1=仍有差异
chezmoi_verify_sync() {
    local status_output
    local diff_output
    local platform="${1:-}"

    if [[ -z "$platform" ]]; then
        if type chezmoi_detect_platform &>/dev/null; then
            chezmoi_detect_platform >/dev/null 2>&1 || true
            platform="${PLATFORM:-$(uname -s)}"
        else
            platform="$(uname -s)"
        fi
    fi

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
        local pattern=""
        case "$platform" in
            windows|*MINGW*|*MSYS*|*CYGWIN*)
                pattern='run_on_(darwin|linux)/'
                ;;
            linux|Linux)
                pattern='run_on_(darwin|windows)/'
                ;;
            darwin|Darwin)
                pattern='run_on_(linux|windows)/'
                ;;
            *)
                case "$(uname -s)" in
                    *MINGW*|*MSYS*|*CYGWIN*) pattern='run_on_(darwin|linux)/' ;;
                    Linux) pattern='run_on_(darwin|windows)/' ;;
                    Darwin) pattern='run_on_(linux|windows)/' ;;
                esac
                ;;
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
