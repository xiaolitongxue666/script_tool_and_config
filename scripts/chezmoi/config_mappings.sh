#!/usr/bin/env bash

# ============================================
# chezmoi 配置路径映射（单一来源）
# 供 audit_configs.sh、force_apply_configs.sh、diagnose 等复用
# 格式：目标路径(~/.xxx) -> 仓库内源模板相对路径（相对 PROJECT_ROOT）
#
# bash 3.2 兼容：使用平行数组，禁止 declare -A / local -n（macOS 默认 bash 3.2）
# ============================================

CHEZMOI_MAP_TARGETS=()
CHEZMOI_MAP_SOURCES=()

_chezmoi_map_reset() {
    CHEZMOI_MAP_TARGETS=()
    CHEZMOI_MAP_SOURCES=()
}

_chezmoi_map_add() {
    CHEZMOI_MAP_TARGETS+=("$1")
    CHEZMOI_MAP_SOURCES+=("$2")
}

# 填充映射；结果写入全局 CHEZMOI_MAP_TARGETS / CHEZMOI_MAP_SOURCES
# 用法：chezmoi_fill_config_mappings <platform>
# platform: linux | darwin | windows
chezmoi_fill_config_mappings() {
    local platform="${1:-unknown}"

    _chezmoi_map_reset

    # 跨平台（模板内按 os 条件渲染；Windows 上 tmux 模板为空）
    _chezmoi_map_add "~/.zshrc" ".chezmoi/dot_zshrc.tmpl"
    _chezmoi_map_add "~/.bashrc" ".chezmoi/dot_bashrc.tmpl"
    _chezmoi_map_add "~/.bash_profile" ".chezmoi/dot_bash_profile.tmpl"
    _chezmoi_map_add "~/.zprofile" ".chezmoi/dot_zprofile.tmpl"
    _chezmoi_map_add "~/.config/starship/starship.toml" ".chezmoi/dot_config/starship/starship.toml.tmpl"
    _chezmoi_map_add "~/.ssh/config" ".chezmoi/dot_ssh/config.tmpl"

    case "$platform" in
        linux)
            _chezmoi_map_add "~/.tmux.conf" ".chezmoi/dot_tmux.conf.tmpl"
            _chezmoi_map_add "~/.config/alacritty/alacritty.toml" ".chezmoi/run_on_linux/dot_config/alacritty/alacritty.toml.tmpl"
            _chezmoi_map_add "~/.config/i3/config" ".chezmoi/run_on_linux/dot_config/i3/config.tmpl"
            ;;
        darwin)
            _chezmoi_map_add "~/.tmux.conf" ".chezmoi/dot_tmux.conf.tmpl"
            _chezmoi_map_add "~/.config/ghostty/config" ".chezmoi/run_on_darwin/dot_config/ghostty/config.tmpl"
            _chezmoi_map_add "~/.yabairc" ".chezmoi/run_on_darwin/dot_yabairc.tmpl"
            _chezmoi_map_add "~/.skhdrc" ".chezmoi/run_on_darwin/dot_skhdrc.tmpl"
            ;;
        windows)
            _chezmoi_map_add "~/.rmux.conf" ".chezmoi/dot_rmux.conf.tmpl"
            _chezmoi_map_add "~/.config/windows-terminal/settings.json" ".chezmoi/dot_config/windows-terminal/settings.json.tmpl"
            ;;
    esac
}

# 检测当前平台名（与 audit_configs 一致）
chezmoi_detect_platform_name() {
    local os
    os="$(uname -s)"
    if [[ "$os" == "Darwin" ]]; then
        echo "darwin"
    elif [[ "$os" == "Linux" ]]; then
        echo "linux"
    elif [[ "$os" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}
