#!/usr/bin/env bash

# chezmoi apply/status/diff、override-data、WT 同步（由 chezmoi_core.sh source）

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

# 导出 apply 所需的环境变量（macOS connect 路径、headless 代理等）
chezmoi_export_apply_env() {
    chezmoi_export_template_env
    export CHEZMOI_PAGER=""
    export PAGER=cat

    if chezmoi_is_headless_native_linux && ! chezmoi_proxy_disabled; then
        chezmoi_setup_proxy "$(chezmoi_detect_proxy)" >/dev/null 2>&1 || true
        echo "[INFO] Environment: headless-linux (VPS-like); proxy for apply: ${PROXY:-none}" >&2
    fi

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

# headless 原生 Linux：探测代理端口并写入 chezmoi --override-data-file（渲染 dot_gitconfig 等）
# stdout: 临时 TOML 路径；不适用或失败时 stdout 为空
chezmoi_write_headless_proxy_override_data() {
    if ! chezmoi_is_headless_native_linux; then
        return 0
    fi
    if chezmoi_proxy_disabled; then
        return 0
    fi

    local proxy_url proxy_host proxy_port stripped
    proxy_url="$(chezmoi_detect_proxy 2>/dev/null || true)"
    if [[ -z "$proxy_url" ]]; then
        return 0
    fi

    stripped="${proxy_url#*://}"
    proxy_host="${stripped%%:*}"
    proxy_port="${stripped#*:}"
    proxy_port="${proxy_port%%/*}"
    [[ -z "$proxy_port" || "$proxy_port" = "$proxy_host" ]] && proxy_port="7890"

    local override_file
    override_file="$(mktemp "${TMPDIR:-/tmp}/chezmoi-headless-proxy.XXXXXX.toml" 2>/dev/null || mktemp /tmp/chezmoi-headless-proxy.XXXXXX.toml)"
    {
        printf 'proxy = "%s"\n' "$proxy_url"
        printf 'proxy_host = "%s"\n' "$proxy_host"
        printf 'proxy_port = "%s"\n' "$proxy_port"
    } > "$override_file"

    echo "[INFO] Headless Linux proxy override: ${proxy_url} (for chezmoi template data)" >&2
    echo "$override_file"
}

# 合并多个 override TOML 到单一临时文件（stdout: 路径）
chezmoi_merge_override_data_files() {
    local merged_file
    merged_file="$(mktemp "${TMPDIR:-/tmp}/chezmoi-override-merged.XXXXXX.toml" 2>/dev/null || mktemp /tmp/chezmoi-override-merged.XXXXXX.toml)"
    : > "$merged_file"
    local f
    for f in "$@"; do
        [[ -n "$f" && -f "$f" ]] || continue
        cat "$f" >> "$merged_file"
        printf '\n' >> "$merged_file"
    done
    echo "$merged_file"
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

# 构建 chezmoi 公共 CLI 前缀（--config/--source、override-data-file）
# 结果写入全局 CHEZMOI_BASE_ARGS；临时 override 路径在 CHEZMOI_OVERRIDE_FILES
chezmoi_build_base_args() {
    CHEZMOI_BASE_ARGS=()
    CHEZMOI_OVERRIDE_FILES=()
    CHEZMOI_WIN_GIT_OVERRIDE_FILE=""

    if [[ -n "${CHEZMOI_PROJECT_ROOT:-}" ]]; then
        chezmoi_ensure_user_config "${CHEZMOI_PROJECT_ROOT}"
    fi

    local user_config="${HOME}/.config/chezmoi/chezmoi.toml"
    if [[ -f "$user_config" ]]; then
        CHEZMOI_BASE_ARGS=(--config "$user_config")
    else
        local source_dir
        source_dir="$(chezmoi_get_source_dir)"
        if [[ -d "$source_dir" ]]; then
            CHEZMOI_BASE_ARGS=(--source "$source_dir")
        fi
    fi

    local -a override_parts=()
    local win_override headless_override merged_override

    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        win_override="$(chezmoi_write_windows_git_override_data "")"
        if [[ -n "$win_override" && -f "$win_override" ]]; then
            CHEZMOI_WIN_GIT_OVERRIDE_FILE="$win_override"
            override_parts+=("$win_override")
        fi
    fi

    if chezmoi_is_headless_native_linux; then
        headless_override="$(chezmoi_write_headless_proxy_override_data 2>/dev/null || true)"
        if [[ -n "$headless_override" && -f "$headless_override" ]]; then
            override_parts+=("$headless_override")
        fi
    fi

    if [[ ${#override_parts[@]} -gt 0 ]]; then
        merged_override="$(chezmoi_merge_override_data_files "${override_parts[@]}")"
        CHEZMOI_OVERRIDE_FILES+=("$merged_override")
        local _part
        for _part in "${override_parts[@]}"; do
            CHEZMOI_OVERRIDE_FILES+=("$_part")
        done
        unset _part
        CHEZMOI_BASE_ARGS=(--override-data-file "$merged_override" "${CHEZMOI_BASE_ARGS[@]}")
    fi
}

# 删除 override 临时文件
chezmoi_cleanup_win_git_override() {
    chezmoi_cleanup_override_files
}

chezmoi_cleanup_override_files() {
    local f
    for f in "${CHEZMOI_OVERRIDE_FILES[@]:-}"; do
        [[ -n "$f" ]] && rm -f "$f" 2>/dev/null || true
    done
    CHEZMOI_OVERRIDE_FILES=()
    if [[ -n "${CHEZMOI_WIN_GIT_OVERRIDE_FILE:-}" ]]; then
        rm -f "$CHEZMOI_WIN_GIT_OVERRIDE_FILE" 2>/dev/null || true
        CHEZMOI_WIN_GIT_OVERRIDE_FILE=""
    fi
}

# chezmoi status 原始输出（含 Windows override-data）
chezmoi_capture_status() {
    chezmoi_build_base_args
    chezmoi status "${CHEZMOI_BASE_ARGS[@]}" 2>&1 || true
    chezmoi_cleanup_win_git_override
}

# chezmoi diff 原始输出（含 Windows override-data）
chezmoi_capture_diff() {
    chezmoi_build_base_args
    chezmoi diff "${CHEZMOI_BASE_ARGS[@]}" 2>&1 || true
    chezmoi_cleanup_win_git_override
}

# chezmoi status（检查配置状态）
# 输出到 stdout
chezmoi_run_status() {
    echo "[INFO] Checking config status (chezmoi status)..."
    chezmoi_capture_status
}

# chezmoi diff（检查配置差异）
# 输出到 stdout
chezmoi_run_diff() {
    echo "[INFO] Checking config diff (chezmoi diff)..."
    chezmoi_capture_diff
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

    local extra_apply_args=()
    # shellcheck disable=SC2206
    read -r -a extra_apply_args <<< "$extra_args"

    # 非交互 apply：缺 --force 时自动补上（避免 .gitconfig 等外部修改触发交互卡住）
    local _apply_arg _has_force=false
    for _apply_arg in "${extra_apply_args[@]}"; do
        [[ "$_apply_arg" == "--force" ]] && _has_force=true
    done
    if ! $_has_force; then
        extra_apply_args+=("--force")
    fi
    unset _apply_arg _has_force

    chezmoi_build_base_args
    local apply_args=("${CHEZMOI_BASE_ARGS[@]}" "${extra_apply_args[@]}")

    echo "[INFO] Running: chezmoi apply ${apply_args[*]}"
    local apply_rc=0
    if chezmoi apply "${apply_args[@]}"; then
        echo "[SUCCESS] Config applied successfully"
        apply_rc=0
    else
        echo "[ERROR] Config apply failed"
        apply_rc=1
    fi

    chezmoi_cleanup_override_files

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

    status_output="$(chezmoi_capture_status)"
    diff_output="$(chezmoi_capture_diff)"

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
