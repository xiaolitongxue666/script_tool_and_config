#!/usr/bin/env bash

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

log_setup "audit_configs"
start_script "Config audit"

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

log_info "Platform: $PLATFORM_NAME ($OS)"

# ============================================
# 设置路径
# ============================================
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
SOFTWARE_LIST="${PROJECT_ROOT}/docs/SOFTWARE_LIST.md"
AUDIT_REPORT="${PROJECT_ROOT}/.audit_configs_report.txt"

if [ ! -f "$SOFTWARE_LIST" ]; then
    error_exit "Software list not found: $SOFTWARE_LIST"
fi

if [ ! -d "$CHEZMOI_DIR" ]; then
    error_exit "chezmoi source dir not found: $CHEZMOI_DIR"
fi

# ============================================
# 定义配置映射（scripts/chezmoi/config_mappings.sh 为单一来源）
# ============================================
CONFIG_MAPPINGS_SH="${SCRIPT_DIR}/config_mappings.sh"
if [[ -f "$CONFIG_MAPPINGS_SH" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_MAPPINGS_SH"
    chezmoi_fill_config_mappings "$PLATFORM"
else
    log_warning "config_mappings.sh not found, using minimal fallback"
    CHEZMOI_MAP_TARGETS=("~/.bashrc")
    CHEZMOI_MAP_SOURCES=(".chezmoi/dot_bashrc.tmpl")
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
log_info "Starting config audit"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MISSING_COUNT=0
NOT_TEMPLATE_COUNT=0
OK_COUNT=0

# 清空报告文件
> "$AUDIT_REPORT"

_map_idx=0
while [[ "$_map_idx" -lt "${#CHEZMOI_MAP_TARGETS[@]}" ]]; do
    target_path="${CHEZMOI_MAP_TARGETS[$_map_idx]}"
    source_path="${CHEZMOI_MAP_SOURCES[$_map_idx]}"
    _map_idx=$((_map_idx + 1))

    # audit_config 在 MISSING/NOT_TEMPLATE 时返回非 0；命令替换在 set -e 下会误触发退出
    set +e
    audit_result=$(audit_config "$target_path" "$source_path" 2>&1)
    exit_code=$?
    set -e

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
if [ ! -f "${CHEZMOI_DIR}/run_once_install-neovim.sh.tmpl" ]; then
    echo "MISSING: run_once_install-neovim.sh.tmpl 不存在" | tee -a "$AUDIT_REPORT"
    MISSING_COUNT=$((MISSING_COUNT + 1))
else
    log_info "run_once_install-neovim.sh.tmpl 存在"
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
log_info "Audit summary"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "OK mappings: $OK_COUNT"
log_info "Missing source: $MISSING_COUNT"
log_info "Non-template source: $NOT_TEMPLATE_COUNT"

if [ -f "$AUDIT_REPORT" ] && [ -s "$AUDIT_REPORT" ]; then
    log_info ""
    log_info "详细报告已保存到: $AUDIT_REPORT"
    log_info ""
    log_info "需要处理的问题:"
    cat "$AUDIT_REPORT"
else
    log_success "All mapped configs are managed correctly"
fi

end_script

