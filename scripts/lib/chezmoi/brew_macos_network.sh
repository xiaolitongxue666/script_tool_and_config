#!/usr/bin/env bash

# 代理配置与 macOS Homebrew 网络策略（由 common_install.sh source）

# ============================================

# 设置代理环境变量
# 参数: proxy_url (可选，默认 http://127.0.0.1:7890)
setup_proxy() {
    local proxy_url="${1:-http://127.0.0.1:7890}"
    # 如果设置了 NO_PROXY=1，则完全禁用代理
    if [[ "${NO_PROXY:-0}" == "1" ]]; then
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
        echo "[INFO] 代理已禁用 (NO_PROXY=1)"
        return 0
    fi
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    echo "[INFO] 代理已设置: $proxy_url"
}

# 启用代理（用于非 pacman/Homebrew 操作）
enable_proxy() {
    local proxy_url="${1:-${http_proxy:-${HTTP_PROXY:-http://127.0.0.1:7890}}}"
    if [[ -n "${proxy_url:-}" ]] && [[ "${NO_PROXY:-0}" != "1" ]]; then
        export http_proxy="${proxy_url}"
        export https_proxy="${proxy_url}"
        export HTTP_PROXY="${proxy_url}"
        export HTTPS_PROXY="${proxy_url}"
        echo "[INFO] 代理已启用: ${proxy_url}"
    fi
}

# 禁用代理（用于 Linux 包管理器走国内源；macOS Homebrew 有代理时勿调用）
disable_proxy() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
    echo "[INFO] 代理已禁用（用于包管理器操作）"
}

# macOS：有代理时把 brew.git origin 从国内镜像切回 GitHub（tuna 高峰会排队卡死）
_brew_macos_prefer_github_remote() {
    [[ "$(uname -s)" == "Darwin" ]] || return 0
    local proxy_url="${http_proxy:-${HTTP_PROXY:-${https_proxy:-${HTTPS_PROXY:-}}}}"
    [[ -n "$proxy_url" && "${NO_PROXY:-0}" != "1" ]] || return 0
    command -v brew &>/dev/null || return 0

    local brew_repo
    brew_repo="$(brew --repository 2>/dev/null || true)"
    [[ -n "$brew_repo" && -d "$brew_repo/.git" ]] || return 0

    local current
    current="$(git -C "$brew_repo" remote get-url origin 2>/dev/null || true)"
    case "$current" in
        *mirrors.tuna.tsinghua.edu.cn*|*mirrors.ustc.edu.cn*|*mirrors.aliyun.com*)
            local github_url="https://github.com/Homebrew/brew.git"
            echo "[INFO] macOS brew: proxy on, switching origin mirror -> GitHub" >&2
            git -C "$brew_repo" remote set-url origin "$github_url" 2>/dev/null \
                && echo "[INFO] Homebrew origin -> ${github_url}" >&2 \
                || echo "[WARNING] Failed to switch Homebrew origin to GitHub" >&2
            ;;
    esac
    unset HOMEBREW_API_DOMAIN HOMEBREW_BOTTLE_DOMAIN HOMEBREW_BREW_GIT_REMOTE 2>/dev/null || true
}

# Intel Mac：Homebrew 2026-09 起不再提供 x86_64 bottle，upgrade 常走源码编译
_brew_is_intel_macos() {
    [[ "$(uname -s)" == "Darwin" ]] || return 1
    case "$(uname -m)" in
        x86_64|i386|i686) return 0 ;;
        *) return 1 ;;
    esac
}

_brew_macos_restore_one() {
    local var_name="$1"
    local saved="$2"
    if [[ -n "$saved" ]]; then
        export "${var_name}=${saved}"
    else
        unset "$var_name"
    fi
}

# macOS Homebrew：保留已设置的代理（7890→GitHub 通常稳于卸代理直连清华）；始终禁隐式 auto-update
_brew_macos_prepare_env() {
    __BREW_MACOS_SAVED_NO_AUTO="${HOMEBREW_NO_AUTO_UPDATE:-}"
    __BREW_MACOS_SAVED_NO_HINTS="${HOMEBREW_NO_ENV_HINTS:-}"
    __BREW_MACOS_SAVED_NO_DEPS="${HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK:-}"
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_ENV_HINTS=1

    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi

    case "$(uname -m)" in
        x86_64|i386|i686)
            # 仍升级目标 formula；不顺带检查/升级 installed dependents
            export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
            ;;
    esac

    local proxy_url="${http_proxy:-${HTTP_PROXY:-${https_proxy:-${HTTPS_PROXY:-}}}}"
    if [[ -n "$proxy_url" && "${NO_PROXY:-0}" != "1" ]]; then
        # 补齐 all_proxy，供 git/curl 经代理访问 GitHub
        export all_proxy="${all_proxy:-$proxy_url}"
        export ALL_PROXY="${ALL_PROXY:-$proxy_url}"
        echo "[INFO] macOS brew: keeping proxy ${proxy_url}" >&2
        _brew_macos_prefer_github_remote
    fi
}

_brew_macos_restore_env() {
    _brew_macos_restore_one HOMEBREW_NO_AUTO_UPDATE "${__BREW_MACOS_SAVED_NO_AUTO:-}"
    _brew_macos_restore_one HOMEBREW_NO_ENV_HINTS "${__BREW_MACOS_SAVED_NO_HINTS:-}"
    _brew_macos_restore_one HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK "${__BREW_MACOS_SAVED_NO_DEPS:-}"
    unset __BREW_MACOS_SAVED_NO_AUTO __BREW_MACOS_SAVED_NO_HINTS __BREW_MACOS_SAVED_NO_DEPS
}

# Intel 无 bottle 时，这些依赖源码编译常 10–30+ 分钟且 Xcode 警告后几乎无输出
_brew_intel_is_heavy_dep() {
    local name="${1:-}"
    [[ -n "$name" ]] || return 1
    case "$name" in
        imagemagick|ghostscript|llvm|gcc|rust|boost|ffmpeg|opencv|glib|harfbuzz|pango|qt|qt@5|qt@6|node|openjdk|openjdk@*|python@*|webkitgtk)
            return 0
            ;;
    esac
    return 1
}

# 解析 brew upgrade --dry-run 文本：仅看「依赖」段，不看 requested package 自身
# 返回 0 = 会升级/新装重型依赖
_brew_intel_dryrun_mentions_heavy_dep() {
    local text="${1:-}"
    local in_deps=0
    local line name
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            "==> Would install"*"dependencies:"*|*"Would install"*"dependencies:"*)
                in_deps=1
                continue
                ;;
            "==> Would upgrade"*"dependencies:"*|*"Would upgrade"*"dependencies:"*)
                in_deps=1
                continue
                ;;
            "==>"*|*"Would upgrade"*"requested"*|*"Would install"*"requested"*)
                in_deps=0
                continue
                ;;
        esac
        [[ "$in_deps" -eq 1 ]] || continue
        name="${line%% *}"
        [[ -n "$name" ]] || continue
        _brew_intel_is_heavy_dep "$name" && return 0
    done <<< "$text"
    return 1
}

# 已装 formula 的 Intel 升级：若 dry-run 会源码编重型依赖则跳过（非致命）
# 仅 Darwin x86_64；Linux / Windows / Apple Silicon 不调用
_brew_intel_should_skip_heavy_dep_upgrade() {
    local name="${1:-}"
    [[ -n "$name" ]] || return 1
    _brew_is_intel_macos || return 1
    command -v brew >/dev/null 2>&1 || return 1
    local dry_out
    dry_out="$(brew upgrade --dry-run --formula "$name" 2>&1 || true)"
    _brew_intel_dryrun_mentions_heavy_dep "$dry_out"
}

# Intel：brew 在 "Xcode is outdated" 后可能数分钟无输出。心跳避免被当成卡死。
# 参数: label command [args...]
_brew_intel_run_with_heartbeat() {
    local label="$1"
    shift
    if [[ $# -lt 1 ]]; then
        return 1
    fi
    if ! _brew_is_intel_macos; then
        "$@"
        return $?
    fi
    echo "[INFO] Starting brew for ${label}. 'Xcode is outdated' is a warning, not a hang; Intel source compile may print nothing for several minutes." >&2
    "$@" &
    local brew_pid=$!
    local elapsed=0
    local interval=20
    local rc=0
    while kill -0 "$brew_pid" 2>/dev/null; do
        sleep "$interval"
        if kill -0 "$brew_pid" 2>/dev/null; then
            elapsed=$((elapsed + interval))
            echo "[INFO] brew still running for ${label} (${elapsed}s). Not stuck; compiling after Xcode warning." >&2
        fi
    done
    wait "$brew_pid" || rc=$?
    return "$rc"
}

# 中断 upgrade 后 keg 可能仍在 Cellar 但未 link（command -v 失败 → common-tools 被当成 Missing）
_brew_link_existing_keg() {
    local name="${1:-}"
    [[ -n "$name" ]] || return 0
    command -v brew >/dev/null 2>&1 || return 0
    brew list --formula "$name" >/dev/null 2>&1 || return 0
    if brew link --overwrite "$name" >/dev/null 2>&1; then
        echo "[INFO] Linked existing keg: $name" >&2
    fi
}

# 检查代理是否可用
check_proxy() {
    local proxy_url="${1:-${http_proxy:-http://127.0.0.1:7890}}"
    if curl -s --proxy "$proxy_url" --max-time 5 https://www.google.com > /dev/null 2>&1; then
        echo "[INFO] 代理可用: $proxy_url"
        return 0
    else
        echo "[WARNING] 代理不可用: $proxy_url"
        return 1
    fi
}

# ============================================
