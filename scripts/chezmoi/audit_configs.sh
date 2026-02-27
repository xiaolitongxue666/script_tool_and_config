#!/bin/bash

# ============================================
# 配置审计脚本
# 基于 SOFTWARE_LIST.md 扫描并识别未纳入 chezmoi 管理的配置
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

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

start_script "配置审计"

# ============================================
# 检测当前平台
# ============================================
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
    PLATFORM="unknown"
    PLATFORM_NAME="Unknown"
fi

log_info "当前平台: $PLATFORM_NAME ($OS)"

# ============================================
# 设置路径
# ============================================
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
SOFTWARE_LIST="${PROJECT_ROOT}/SOFTWARE_LIST.md"
AUDIT_REPORT="${PROJECT_ROOT}/.audit_configs_report.txt"

if [ ! -f "$SOFTWARE_LIST" ]; then
    error_exit "软件清单文件不存在: $SOFTWARE_LIST"
fi

if [ ! -d "$CHEZMOI_DIR" ]; then
    error_exit "chezmoi 源状态目录不存在: $CHEZMOI_DIR"
fi

# ============================================
# 定义配置映射（基于 SOFTWARE_LIST.md）
# ============================================
declare -A CONFIG_MAPPINGS

# 通用配置（所有平台）
CONFIG_MAPPINGS["~/.tmux.conf"]=".chezmoi/dot_tmux.conf.tmpl"
CONFIG_MAPPINGS["~/.zshrc"]=".chezmoi/dot_zshrc.tmpl"
CONFIG_MAPPINGS["~/.bashrc"]=".chezmoi/dot_bashrc.tmpl"
CONFIG_MAPPINGS["~/.bash_profile"]=".chezmoi/dot_bash_profile.tmpl"
CONFIG_MAPPINGS["~/.zprofile"]=".chezmoi/dot_zprofile"
CONFIG_MAPPINGS["~/.config/starship/starship.toml"]=".chezmoi/dot_config/starship/starship.toml"
CONFIG_MAPPINGS["~/.config/fish/config.fish"]=".chezmoi/dot_config/fish/config.fish"
CONFIG_MAPPINGS["~/.config/fish/completions/alacritty.fish"]=".chezmoi/dot_config/fish/completions/alacritty.fish"
CONFIG_MAPPINGS["~/.config/fish/conf.d/fnm.fish"]=".chezmoi/dot_config/fish/conf.d/fnm.fish"
CONFIG_MAPPINGS["~/.config/fish/conf.d/omf.fish"]=".chezmoi/dot_config/fish/conf.d/omf.fish"
CONFIG_MAPPINGS["~/.ssh/config"]=".chezmoi/dot_ssh/config.tmpl"

# Linux 特定配置
if [[ "$PLATFORM" == "linux" ]]; then
    CONFIG_MAPPINGS["~/.config/alacritty/alacritty.toml"]=".chezmoi/run_on_linux/dot_config/alacritty/alacritty.toml.tmpl"
    CONFIG_MAPPINGS["~/.config/i3/config"]=".chezmoi/run_on_linux/dot_config/i3/config"
fi

# macOS 特定配置
if [[ "$PLATFORM" == "darwin" ]]; then
    CONFIG_MAPPINGS["~/.config/ghostty/config"]=".chezmoi/run_on_darwin/dot_config/ghostty/config.tmpl"
    CONFIG_MAPPINGS["~/.yabairc"]=".chezmoi/run_on_darwin/dot_yabairc"
    CONFIG_MAPPINGS["~/.skhdrc"]=".chezmoi/run_on_darwin/dot_skhdrc"
fi

# Windows 特定配置
if [[ "$PLATFORM" == "windows" ]]; then
    CONFIG_MAPPINGS["~/.bash_profile"]=".chezmoi/run_on_windows/dot_bash_profile"
    CONFIG_MAPPINGS["~/.bashrc"]=".chezmoi/run_on_windows/dot_bashrc"
fi

# ============================================
# 审计函数
# ============================================
audit_config() {
    local target_path="$1"
    local source_path="$2"
    # 替换 ~ 为实际 HOME 路径
    local expanded_target="${target_path//\~/$HOME}"
    local expanded_source="${PROJECT_ROOT}/${source_path}"

    # 检查目标文件是否存在
    if [ ! -f "$expanded_target" ] && [ ! -d "$expanded_target" ]; then
        return 0  # 文件不存在，跳过
    fi

    # 检查源文件是否存在
    if [ ! -f "$expanded_source" ] && [ ! -d "$expanded_source" ]; then
        echo "MISSING: $target_path → $source_path (目标文件存在，但源文件不存在)"
        return 1
    fi

    # 检查是否是模板文件（检查文件名是否包含 .tmpl）
    if [[ ! "$source_path" == *.tmpl ]] && [[ ! "$source_path" == *.tmpl.* ]] && [[ ! "$source_path" =~ \.tmpl$ ]]; then
        echo "NOT_TEMPLATE: $target_path → $source_path (源文件不是模板格式)"
        return 2
    fi

    return 0
}

# ============================================
# 执行审计
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "开始审计配置"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MISSING_COUNT=0
NOT_TEMPLATE_COUNT=0
OK_COUNT=0

# 清空报告文件
> "$AUDIT_REPORT"

for target_path in "${!CONFIG_MAPPINGS[@]}"; do
    source_path="${CONFIG_MAPPINGS[$target_path]}"

    audit_result=$(audit_config "$target_path" "$source_path" 2>&1)
    exit_code=$?

    case $exit_code in
        1)
            echo "$audit_result" | tee -a "$AUDIT_REPORT"
            MISSING_COUNT=$((MISSING_COUNT + 1))
            ;;
        2)
            echo "$audit_result" | tee -a "$AUDIT_REPORT"
            NOT_TEMPLATE_COUNT=$((NOT_TEMPLATE_COUNT + 1))
            ;;
        0)
            OK_COUNT=$((OK_COUNT + 1))
            ;;
    esac
done

# ============================================
# 检查 Neovim run_once 模板（nvim 为独立项目，本仓库仅负责 clone 并执行其 install.sh）
# ============================================
log_info ""
log_info "检查 Neovim run_once 模板..."
if [ ! -f "${CHEZMOI_DIR}/run_once_install-neovim-config.sh.tmpl" ]; then
    echo "MISSING: run_once_install-neovim-config.sh.tmpl 不存在" | tee -a "$AUDIT_REPORT"
    MISSING_COUNT=$((MISSING_COUNT + 1))
else
    log_info "run_once_install-neovim-config.sh.tmpl 存在"
fi

# ============================================
# 检查 tmux 插件配置
# ============================================
log_info ""
log_info "检查 Tmux 插件配置..."
TMUX_PLUGIN_DIR="$HOME/.config/tmux/plugins"
if [ -d "$TMUX_PLUGIN_DIR" ]; then
    log_info "Tmux 插件目录存在: $TMUX_PLUGIN_DIR"
    # catppuccin 主题应该通过 run_once 脚本安装
    if [ -d "$TMUX_PLUGIN_DIR/catppuccin" ]; then
        log_success "Catppuccin 主题已安装"
    fi
fi

# ============================================
# 输出审计结果
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "审计结果摘要"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "正常配置: $OK_COUNT"
log_info "缺失源文件: $MISSING_COUNT"
log_info "非模板格式: $NOT_TEMPLATE_COUNT"

if [ -f "$AUDIT_REPORT" ] && [ -s "$AUDIT_REPORT" ]; then
    log_info ""
    log_info "详细报告已保存到: $AUDIT_REPORT"
    log_info ""
    log_info "需要处理的问题:"
    cat "$AUDIT_REPORT"
else
    log_success "所有配置都已正确管理！"
fi

end_script

