#!/usr/bin/env bash

# ============================================
# chezmoi 配置路径映射（单一来源）
# 供 audit_configs.sh、force_apply_configs.sh、diagnose 等复用
# 格式：目标路径(~/.xxx) -> 仓库内源模板相对路径（相对 PROJECT_ROOT）
# ============================================

# 填充关联数组：chezmoi_fill_config_mappings <数组名> <platform>
# platform: linux | darwin | windows
chezmoi_fill_config_mappings() {
    local -n _map="$1"
    local platform="${2:-unknown}"

    # 跨平台（模板内按 os 条件渲染；Windows 上 tmux 模板为空）
    _map["~/.zshrc"]=".chezmoi/dot_zshrc.tmpl"
    _map["~/.bashrc"]=".chezmoi/dot_bashrc.tmpl"
    _map["~/.bash_profile"]=".chezmoi/dot_bash_profile.tmpl"
    _map["~/.zprofile"]=".chezmoi/dot_zprofile.tmpl"
    _map["~/.config/starship/starship.toml"]=".chezmoi/dot_config/starship/starship.toml.tmpl"
    _map["~/.ssh/config"]=".chezmoi/dot_ssh/config.tmpl"

    case "$platform" in
        linux)
            _map["~/.tmux.conf"]=".chezmoi/dot_tmux.conf.tmpl"
            _map["~/.config/alacritty/alacritty.toml"]=".chezmoi/run_on_linux/dot_config/alacritty/alacritty.toml.tmpl"
            _map["~/.config/i3/config"]=".chezmoi/run_on_linux/dot_config/i3/config.tmpl"
            ;;
        darwin)
            _map["~/.tmux.conf"]=".chezmoi/dot_tmux.conf.tmpl"
            _map["~/.config/ghostty/config"]=".chezmoi/run_on_darwin/dot_config/ghostty/config.tmpl"
            _map["~/.yabairc"]=".chezmoi/run_on_darwin/dot_yabairc.tmpl"
            _map["~/.skhdrc"]=".chezmoi/run_on_darwin/dot_skhdrc.tmpl"
            ;;
        windows)
            _map["~/.rmux.conf"]=".chezmoi/dot_rmux.conf.tmpl"
            _map["~/.config/windows-terminal/settings.json"]=".chezmoi/dot_config/windows-terminal/settings.json.tmpl"
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
