#!/bin/bash

# ============================================
# 部署诊断脚本
# 用于检查为什么某些配置文件没有被应用
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

start_script "部署诊断"

# ============================================
# 检查 chezmoi
# ============================================
if ! command -v chezmoi &> /dev/null; then
    log_error "chezmoi 未安装"
    exit 1
fi

CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
log_success "chezmoi 已安装: $CHEZMOI_VERSION"

# ============================================
# 设置源状态目录
# ============================================
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
if [ ! -d "$CHEZMOI_DIR" ]; then
    log_error "chezmoi 源状态目录不存在: $CHEZMOI_DIR"
    exit 1
fi

export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
log_info "源状态目录: $CHEZMOI_SOURCE_DIR"

# ============================================
# 检查源文件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "1. 检查源文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_source_file() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"

    log_info ""
    log_info "检查: $description"
    log_info "  源文件: $source_file"
    log_info "  目标文件: $target_file"

    if [ -f "$source_file" ]; then
        log_success "  ✓ 源文件存在"
        log_info "  文件大小: $(ls -lh "$source_file" | awk '{print $5}')"
    else
        log_warning "  ✗ 源文件不存在"
    fi

    if [ -f "$target_file" ]; then
        log_success "  ✓ 目标文件存在"
        log_info "  文件大小: $(ls -lh "$target_file" | awk '{print $5}')"
        log_info "  修改时间: $(ls -l "$target_file" | awk '{print $6, $7, $8}')"
    else
        log_warning "  ✗ 目标文件不存在"
    fi
}

# 检查几个关键配置文件
check_source_file "$CHEZMOI_DIR/dot_zshrc.tmpl" "$HOME/.zshrc" "Zsh 配置"
check_source_file "$CHEZMOI_DIR/dot_tmux.conf" "$HOME/.tmux.conf" "Tmux 配置"
check_source_file "$CHEZMOI_DIR/dot_config/starship/starship.toml" "$HOME/.config/starship/starship.toml" "Starship 配置"

# ============================================
# 检查 chezmoi 管理状态
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "2. 检查 chezmoi 管理状态"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MANAGED_FILES=$(chezmoi managed 2>/dev/null || true)
if [ -n "$MANAGED_FILES" ]; then
    MANAGED_COUNT=$(echo "$MANAGED_FILES" | wc -l)
    log_success "当前管理 $MANAGED_COUNT 个文件："
    echo "$MANAGED_FILES" | head -10 | while IFS= read -r file; do
        log_info "  ✓ $file"
    done
else
    log_warning "当前没有受管理的文件"
    log_info "这意味着配置文件还没有被添加到 chezmoi 管理"
fi

# ============================================
# 检查 chezmoi 状态
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "3. 检查 chezmoi 状态"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS_OUTPUT=$(chezmoi status 2>&1 || true)
if [ -n "$STATUS_OUTPUT" ]; then
    log_info "发现未同步的配置："
    echo "$STATUS_OUTPUT" | while IFS= read -r line; do
        log_info "  $line"
    done
else
    log_info "所有配置文件都是最新的（或没有受管理的文件）"
fi

# ============================================
# 检查配置差异
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "4. 检查配置差异"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DIFF_OUTPUT=$(chezmoi diff 2>&1 || true)
if [ -n "$DIFF_OUTPUT" ]; then
    log_info "发现配置差异："
    echo "$DIFF_OUTPUT" | head -20 | while IFS= read -r line; do
        log_info "  $line"
    done
else
    log_info "没有配置差异"
fi

# ============================================
# 测试应用配置（dry-run）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "5. 测试应用配置（详细输出）"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "执行: chezmoi apply -v --dry-run"
APPLY_DRY_RUN=$(chezmoi apply -v --dry-run 2>&1 || true)
if [ -n "$APPLY_DRY_RUN" ]; then
    echo "$APPLY_DRY_RUN" | head -30 | while IFS= read -r line; do
        log_info "  $line"
    done
else
    log_info "没有需要应用的配置"
fi

# ============================================
# 诊断结果和建议
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "诊断结果和建议"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -z "$MANAGED_FILES" ]; then
    log_warning "问题：配置文件还没有被添加到 chezmoi 管理"
    log_info ""
    log_info "解决方案："
    log_info "  1. 如果目标文件已存在，需要先添加到管理："
    log_info "     export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\""
    log_info "     chezmoi add ~/.zshrc"
    log_info "     chezmoi add ~/.tmux.conf"
    log_info "     chezmoi add ~/.config/starship/starship.toml"
    log_info ""
    log_info "  2. 如果目标文件不存在，chezmoi apply 应该会自动创建"
    log_info "     但需要确保源文件在 .chezmoi 目录中"
    log_info ""
    log_info "  3. 运行完整应用："
    log_info "     export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\""
    log_info "     chezmoi apply -v"
else
    log_info "配置文件已在管理列表中，但可能没有应用"
    log_info ""
    log_info "建议："
    log_info "  1. 检查 chezmoi diff 查看差异"
    log_info "  2. 运行 chezmoi apply -v 应用配置"
fi

end_script

