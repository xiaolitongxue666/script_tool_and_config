#!/usr/bin/env bash

# ============================================
# 软件升级策略与 run_once 脚本发现
# common-tools 包名 SSOT：packages.conf；策略表与 docs/SOFTWARE_LIST.md 对齐
# 供 ensure_platform_software.sh 使用
# ============================================

_SOFTWARE_POLICIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PACKAGES_CONF="${PACKAGES_CONF:-${_SOFTWARE_POLICIES_DIR}/packages.conf}"

# 加载 packages.conf（幂等）
_load_packages_conf() {
    if [[ "${_PACKAGES_CONF_LOADED:-0}" == "1" ]]; then
        return 0
    fi
    if [[ ! -f "${_PACKAGES_CONF}" ]]; then
        echo "[WARNING] packages.conf not found: ${_PACKAGES_CONF}" >&2
        COMMON_TOOLS_COMMANDS="${COMMON_TOOLS_COMMANDS:-bat eza fd ripgrep fzf lazygit git-delta gh trash btop fastfetch}"
        COMMON_TOOLS_PKG_LINES="${COMMON_TOOLS_PKG_LINES:-}"
        _PACKAGES_CONF_LOADED=1
        return 0
    fi
    # shellcheck disable=SC1090
    source "${_PACKAGES_CONF}"
    _PACKAGES_CONF_LOADED=1
}

# 返回软件升级策略：latest | minimum:VER | pinned:VER | skip
# 参数: software_name（extract_software_name_from_script 输出）
get_software_policy() {
    local name="$1"
    case "$name" in
        00-install-version-managers) echo "latest" ;;
        install-git|git)           echo "latest" ;;
        common-tools)              echo "latest" ;;
        zsh|starship|tmux|alacritty|lazyssh|i3wm|dwm) echo "latest" ;;
        oh-my-posh|windows-terminal|install-windows-terminal) echo "latest" ;;
        ghostty|connect|maccy|yabai|skhd) echo "latest" ;;
        90-install-claude-code|91-install-codex|93-install-cursor) echo "latest" ;;
        install-rmux|rmux)         echo "pinned:0.5.0" ;;
        neovim|install-neovim)     echo "minimum:0.11.0" ;;
        nerd-fonts|install-nerd-fonts) echo "skip" ;;
        configure-pacman|configure-homebrew|aur-helper|install-aur-helper) echo "skip" ;;
        arch-base-packages|install-arch-base-packages) echo "latest" ;;
        *)                         echo "latest" ;;
    esac
}

# 列出当前平台适用的 run_once 模板（字母序，与 chezmoi 一致）
# 参数: chezmoi_dir, platform
# stdout: 每行一个绝对路径
list_applicable_run_once_scripts() {
    local chezmoi_dir="$1"
    local platform="$2"
    [[ -d "$chezmoi_dir" ]] || return 0

    local all_scripts=""
    if [[ "$platform" == "windows" ]]; then
        if [[ -x /usr/bin/find ]]; then
            all_scripts=$(/usr/bin/find "$chezmoi_dir" -name 'run_once_*.sh.tmpl' -type f 2>/dev/null || true)
        fi
        if [[ -z "$all_scripts" ]]; then
            local _d="$chezmoi_dir"
            shopt -s nullglob 2>/dev/null || true
            local f
            for f in \
                "$_d"/run_once_*.sh.tmpl \
                "$_d"/run_on_linux/run_once_*.sh.tmpl \
                "$_d"/run_on_darwin/run_once_*.sh.tmpl \
                "$_d"/run_on_windows/run_once_*.sh.tmpl; do
                [[ -f "$f" ]] && all_scripts+="${f}"$'\n'
            done
        fi
    else
        all_scripts=$(find "$chezmoi_dir" -name 'run_once_*.sh.tmpl' -type f 2>/dev/null || true)
    fi

    [[ -z "$all_scripts" ]] && return 0

    local script
    while IFS= read -r script; do
        [[ -z "$script" ]] && continue
        if type script_applicable_to_platform &>/dev/null; then
            script_applicable_to_platform "$script" "$platform" || continue
        fi
        echo "$script"
    done <<< "$(echo "$all_scripts" | sort -u)"
}

# common-tools 命令列表（SSOT: packages.conf）
get_common_tool_commands() {
    _load_packages_conf
    echo "${COMMON_TOOLS_COMMANDS}"
}

# 判断 common-tools 命令是否可用（含 Debian/Ubuntu 二进制别名）
# bat → batcat；fd → fdfind；trash → trash-cli
# 参数: tool_cmd
# 返回: 0=可用, 1=不可用
common_tool_command_present() {
    local tool="$1"
    case "$tool" in
        bat)
            command -v bat &>/dev/null || command -v batcat &>/dev/null
            ;;
        fd)
            command -v fd &>/dev/null || command -v fdfind &>/dev/null
            ;;
        trash)
            command -v trash &>/dev/null || command -v trash-cli &>/dev/null
            ;;
        *)
            command -v "$tool" &>/dev/null
            ;;
    esac
}

# 从 COMMON_TOOLS_PKG_LINES 解析包名
# 列: cmd|darwin|linux_pacman|linux_apt|linux_other|windows_winget|windows_pacman
# 参数: command_name, platform, package_manager
# stdout: 包名；跳过安装时输出空字符串
get_common_tool_package() {
    local cmd="$1"
    local platform="$2"
    local pkg_mgr="$3"
    local plat="$platform"
    local field=0
    local line col_cmd pkg

    [[ "$plat" == "macos" ]] && plat="darwin"
    _load_packages_conf

    case "$plat" in
        darwin) field=2 ;;
        linux)
            case "$pkg_mgr" in
                pacman) field=3 ;;
                apt) field=4 ;;
                *) field=5 ;;
            esac
            ;;
        windows)
            case "$pkg_mgr" in
                winget) field=6 ;;
                pacman) field=7 ;;
                *) field=0 ;;
            esac
            ;;
        *) field=0 ;;
    esac

    if [[ "$field" -eq 0 ]]; then
        echo ""
        return 0
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        col_cmd="${line%%|*}"
        [[ "$col_cmd" != "$cmd" ]] && continue
        pkg="$(echo "$line" | cut -d'|' -f"$field")"
        if [[ "$pkg" == "-" ]]; then
            echo ""
        else
            echo "$pkg"
        fi
        return 0
    done <<< "${COMMON_TOOLS_PKG_LINES}"

    echo ""
}

# Layer 4 npm 包 spec
get_npm_global_spec() {
    local name="$1"
    case "$name" in
        90-install-claude-code) echo "@anthropic-ai/claude-code" ;;
        91-install-codex)       echo "@openai/codex" ;;
        *) echo "" ;;
    esac
}

# Cursor 升级用的包 id / 命令
get_cursor_upgrade_target() {
    local pkg_mgr="${PACKAGE_MANAGER:-}"
    case "$pkg_mgr" in
        brew)   echo "brew:cursor" ;;
        winget) echo "winget:Anysphere.Cursor" ;;
        pacman) echo "pacman:cursor-bin" ;;
        *)      echo "" ;;
    esac
}
