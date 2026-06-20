#!/usr/bin/env bash

# ============================================
# 软件升级策略与 run_once 脚本发现
# 与 docs/SOFTWARE_LIST.md 对齐；供 ensure_platform_software.sh 使用
# ============================================

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
        90-install-claude-code|91-install-codex|92-install-codewhale|93-install-cursor|94-install-pi) echo "latest" ;;
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

# common-tools 命令列表（与 run_once_install-common-tools 一致）
get_common_tool_commands() {
    echo "bat eza fd ripgrep fzf lazygit git-delta gh trash btop fastfetch"
}

# 返回 common-tools 中命令对应的包名 / winget id
# 参数: command_name, platform, package_manager
get_common_tool_package() {
    local cmd="$1"
    local platform="$2"
    local pkg_mgr="$3"
    local plat="$platform"
    [[ "$plat" == "macos" ]] && plat="darwin"

    if [[ "$plat" == "darwin" || "$plat" == "macos" ]]; then
        case "$cmd" in
            bat) echo "bat" ;;
            eza) echo "eza" ;;
            fd) echo "fd" ;;
            ripgrep) echo "ripgrep" ;;
            fzf) echo "fzf" ;;
            lazygit) echo "lazygit" ;;
            git-delta) echo "git-delta" ;;
            gh) echo "gh" ;;
            trash) echo "trash-cli" ;;
            btop) echo "btop" ;;
            fastfetch) echo "fastfetch" ;;
            *) echo "$cmd" ;;
        esac
        return 0
    fi

    if [[ "$plat" == "linux" ]]; then
        if [[ "$pkg_mgr" == "pacman" ]]; then
            case "$cmd" in
                bat) echo "bat" ;;
                eza) echo "eza" ;;
                fd) echo "fd" ;;
                ripgrep) echo "ripgrep" ;;
                fzf) echo "fzf" ;;
                lazygit) echo "lazygit" ;;
                git-delta) echo "git-delta" ;;
                gh) echo "github-cli" ;;
                trash) echo "trash-cli" ;;
                btop) echo "btop" ;;
                fastfetch) echo "fastfetch" ;;
                *) echo "$cmd" ;;
            esac
        elif [[ "$pkg_mgr" == "apt" ]]; then
            case "$cmd" in
                fd) echo "fd-find" ;;
                trash) echo "trash-cli" ;;
                *) echo "$cmd" ;;
            esac
        else
            echo "$cmd"
        fi
        return 0
    fi

    if [[ "$plat" == "windows" ]]; then
        if [[ "$pkg_mgr" == "winget" ]]; then
            case "$cmd" in
                bat) echo "sharkdp.bat" ;;
                eza) echo "eza-community.eza" ;;
                fd) echo "sharkdp.fd" ;;
                ripgrep) echo "BurntSushi.ripgrep" ;;
                fzf) echo "junegunn.fzf" ;;
                lazygit) echo "jesseduffield.lazygit" ;;
                git-delta) echo "dandavison.delta" ;;
                gh) echo "GitHub.cli" ;;
                *) echo "" ;;
            esac
        elif [[ "$pkg_mgr" == "pacman" ]]; then
            case "$cmd" in
                gh) echo "github-cli" ;;
                trash) echo "trash-cli" ;;
                *) echo "$cmd" ;;
            esac
        fi
    fi
}

# Layer 4 npm 包 spec
get_npm_global_spec() {
    local name="$1"
    case "$name" in
        90-install-claude-code) echo "@anthropic-ai/claude-code" ;;
        91-install-codex)       echo "@openai/codex" ;;
        92-install-codewhale)
            if [[ -n "${CODEWHALE_NPM_VERSION:-}" ]]; then
                echo "codewhale@${CODEWHALE_NPM_VERSION}"
            else
                echo "codewhale"
            fi
            ;;
        94-install-pi)
            if [[ -n "${PI_NPM_VERSION:-}" ]]; then
                echo "@earendil-works/pi-coding-agent@${PI_NPM_VERSION}"
            else
                echo "@earendil-works/pi-coding-agent"
            fi
            ;;
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
