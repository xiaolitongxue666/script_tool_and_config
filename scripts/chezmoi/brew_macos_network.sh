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

# macOS Homebrew：保留已设置的代理（7890→GitHub 通常稳于卸代理直连清华）；始终禁隐式 auto-update
_brew_macos_prepare_env() {
    __BREW_MACOS_SAVED_NO_AUTO="${HOMEBREW_NO_AUTO_UPDATE:-}"
    export HOMEBREW_NO_AUTO_UPDATE=1

    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi

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
    if [[ -n "${__BREW_MACOS_SAVED_NO_AUTO:-}" ]]; then
        export HOMEBREW_NO_AUTO_UPDATE="$__BREW_MACOS_SAVED_NO_AUTO"
    else
        unset HOMEBREW_NO_AUTO_UPDATE
    fi
    unset __BREW_MACOS_SAVED_NO_AUTO
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
