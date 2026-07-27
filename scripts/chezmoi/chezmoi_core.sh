#!/usr/bin/env bash

# ============================================
# chezmoi 核心操作封装层（聚合入口）
# 提供统一的 chezmoi 操作接口：
#   - apply / status / diff / unlock
#   - 环境检测与初始化
#   - 锁检测与释放
# 被 install.sh / deploy.sh / manage_dotfiles.sh 共享
# 子模块：detect_platform / chezmoi_proxy / chezmoi_lock / chezmoi_apply
# ============================================

_CHEZMOI_CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
[[ -f "${_CHEZMOI_CORE_DIR}/detect_platform.sh" ]] && source "${_CHEZMOI_CORE_DIR}/detect_platform.sh"

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

# 检测是否为 headless 原生 Linux（VPS：无 GUI、非 WSL）
chezmoi_is_headless_native_linux() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        return 1
    fi
    if chezmoi_is_wsl; then
        return 1
    fi
    if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        return 1
    fi
    if [[ -d /mnt/wslg ]]; then
        return 1
    fi
    if [[ -n "${XDG_SESSION_TYPE:-}" && "${XDG_SESSION_TYPE}" != "tty" ]]; then
        return 1
    fi
    return 0
}

# shellcheck disable=SC1090
source "${_CHEZMOI_CORE_DIR}/chezmoi_proxy.sh"
# shellcheck disable=SC1090
source "${_CHEZMOI_CORE_DIR}/chezmoi_lock.sh"
# shellcheck disable=SC1090
source "${_CHEZMOI_CORE_DIR}/chezmoi_apply.sh"
