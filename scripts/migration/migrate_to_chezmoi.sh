#!/bin/bash

# ============================================
# 迁移脚本：将现有 dotfiles 转换为 chezmoi 格式
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
DOTFILES_DIR="${PROJECT_ROOT}/dotfiles"
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

start_script "迁移 dotfiles 到 chezmoi 格式"

# ============================================
# 检查目录
# ============================================
if [ ! -d "$DOTFILES_DIR" ]; then
    error_exit "dotfiles 目录不存在: $DOTFILES_DIR"
fi

if [ ! -d "$CHEZMOI_DIR" ]; then
    log_info "创建 chezmoi 目录: $CHEZMOI_DIR"
    mkdir -p "$CHEZMOI_DIR"
fi

# ============================================
# 迁移函数
# ============================================

# 迁移单个文件到 chezmoi 格式
# 参数: source_file target_name [platform]
migrate_file() {
    local source_file="$1"
    local target_name="$2"
    local platform="${3:-}"
    
    if [ ! -f "$source_file" ]; then
        log_warning "源文件不存在: $source_file"
        return 1
    fi
    
    local target_dir="$CHEZMOI_DIR"
    if [ -n "$platform" ]; then
        target_dir="${CHEZMOI_DIR}/run_on_${platform}"
        mkdir -p "$target_dir"
    fi
    
    local target_file="${target_dir}/${target_name}"
    local target_dir_path=$(dirname "$target_file")
    
    # 创建目标目录
    mkdir -p "$target_dir_path"
    
    # 复制文件
    cp "$source_file" "$target_file"
    log_success "迁移: $source_file -> $target_file"
}

# 迁移目录到 chezmoi 格式
# 参数: source_dir target_name [platform]
migrate_directory() {
    local source_dir="$1"
    local target_name="$2"
    local platform="${3:-}"
    
    if [ ! -d "$source_dir" ]; then
        log_warning "源目录不存在: $source_dir"
        return 1
    fi
    
    local target_dir="$CHEZMOI_DIR"
    if [ -n "$platform" ]; then
        target_dir="${CHEZMOI_DIR}/run_on_${platform}"
        mkdir -p "$target_dir"
    fi
    
    local target_path="${target_dir}/${target_name}"
    
    # 复制目录
    cp -r "$source_dir" "$target_path"
    log_success "迁移目录: $source_dir -> $target_path"
}

# ============================================
# 开始迁移
# ============================================

log_info "开始迁移 dotfiles 到 chezmoi 格式..."

# Bash 配置
if [ -f "${DOTFILES_DIR}/bash/config.sh" ]; then
    migrate_file "${DOTFILES_DIR}/bash/config.sh" "dot_bashrc.tmpl"
fi

# Zsh 配置
if [ -f "${DOTFILES_DIR}/zsh/.zshrc" ]; then
    migrate_file "${DOTFILES_DIR}/zsh/.zshrc" "dot_zshrc"
fi
if [ -f "${DOTFILES_DIR}/zsh/.zprofile" ]; then
    migrate_file "${DOTFILES_DIR}/zsh/.zprofile" "dot_zprofile"
fi

# Fish 配置
if [ -f "${DOTFILES_DIR}/fish/config.fish" ]; then
    migrate_file "${DOTFILES_DIR}/fish/config.fish" "dot_config/fish/config.fish"
fi
if [ -d "${DOTFILES_DIR}/fish/completions" ]; then
    migrate_directory "${DOTFILES_DIR}/fish/completions" "dot_config/fish/completions"
fi
if [ -d "${DOTFILES_DIR}/fish/conf.d" ]; then
    migrate_directory "${DOTFILES_DIR}/fish/conf.d" "dot_config/fish/conf.d"
fi

# Starship 配置
if [ -f "${DOTFILES_DIR}/starship/starship.toml" ]; then
    migrate_file "${DOTFILES_DIR}/starship/starship.toml" "dot_config/starship/starship.toml"
fi

# Tmux 配置
if [ -f "${DOTFILES_DIR}/tmux/tmux.conf" ]; then
    migrate_file "${DOTFILES_DIR}/tmux/tmux.conf" "dot_tmux.conf"
fi

# Alacritty 配置
if [ -f "${DOTFILES_DIR}/alacritty/alacritty.toml" ]; then
    migrate_file "${DOTFILES_DIR}/alacritty/alacritty.toml" "dot_config/alacritty/alacritty.toml"
fi

# Windows Git Bash 配置
if [ -f "${DOTFILES_DIR}/git_bash/.bash_profile" ]; then
    migrate_file "${DOTFILES_DIR}/git_bash/.bash_profile" "dot_bash_profile" "windows"
fi
if [ -f "${DOTFILES_DIR}/git_bash/.bashrc" ]; then
    migrate_file "${DOTFILES_DIR}/git_bash/.bashrc" "dot_bashrc" "windows"
fi

# Linux 特定配置
if [ -f "${DOTFILES_DIR}/i3wm/config" ]; then
    migrate_file "${DOTFILES_DIR}/i3wm/config" "dot_config/i3/config" "linux"
fi

# macOS 特定配置
if [ -f "${DOTFILES_DIR}/yabai/yabairc" ]; then
    migrate_file "${DOTFILES_DIR}/yabai/yabairc" "dot_yabairc" "darwin"
fi
if [ -f "${DOTFILES_DIR}/skhd/skhdrc" ]; then
    migrate_file "${DOTFILES_DIR}/skhd/skhdrc" "dot_skhdrc" "darwin"
fi

# ============================================
# 完成
# ============================================
log_success "迁移完成！"
log_info "chezmoi 源状态目录: $CHEZMOI_DIR"
log_info "下一步："
log_info "  1. 检查迁移的文件"
log_info "  2. 运行: chezmoi apply -v"
log_info "  3. 提交到 Git: git add .chezmoi && git commit -m 'Migrate dotfiles to chezmoi'"

end_script
