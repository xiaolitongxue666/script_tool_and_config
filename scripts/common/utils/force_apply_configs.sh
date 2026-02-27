#!/bin/bash

# ============================================
# 强制应用配置文件
# 直接处理源文件，不依赖 chezmoi managed
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

start_script "强制应用配置"

# ============================================
# 检查 chezmoi
# ============================================
if ! command -v chezmoi &> /dev/null; then
    log_error "chezmoi 未安装"
    exit 1
fi

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
# 定义文件映射（源文件 -> 目标文件）
# ============================================
declare -A FILE_MAPPINGS=(
    # 通用配置文件
    ["$CHEZMOI_DIR/dot_tmux.conf"]="$HOME/.tmux.conf"
    ["$CHEZMOI_DIR/dot_zshrc.tmpl"]="$HOME/.zshrc"
    ["$CHEZMOI_DIR/dot_bashrc.tmpl"]="$HOME/.bashrc"
    ["$CHEZMOI_DIR/dot_bash_profile.tmpl"]="$HOME/.bash_profile"
    ["$CHEZMOI_DIR/dot_zprofile"]="$HOME/.zprofile"

    # 配置目录
    ["$CHEZMOI_DIR/dot_config/starship/starship.toml"]="$HOME/.config/starship/starship.toml"
    ["$CHEZMOI_DIR/dot_config/fish/config.fish"]="$HOME/.config/fish/config.fish"
)

# 平台特定配置
case "$(uname -s)" in
    Linux)
        FILE_MAPPINGS["$CHEZMOI_DIR/run_on_linux/dot_config/alacritty/alacritty.toml.tmpl"]="$HOME/.config/alacritty/alacritty.toml"
        ;;
    Darwin)
        FILE_MAPPINGS["$CHEZMOI_DIR/run_on_darwin/dot_config/ghostty/config.tmpl"]="$HOME/.config/ghostty/config"
        ;;
esac

# ============================================
# 处理文件映射
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "处理配置文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

process_file() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"

    if [ ! -f "$source_file" ]; then
        log_info "跳过 $description: 源文件不存在"
        return
    fi

    log_info ""
    log_info "处理: $description"
    log_info "  源文件: $source_file"
    log_info "  目标文件: $target_file"

    # 创建目标目录
    local target_dir=$(dirname "$target_file")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
        log_info "  ✓ 创建目录: $target_dir"
    fi

    # 检查目标文件是否存在
    if [ -f "$target_file" ]; then
        log_info "  ⚠ 目标文件已存在"

        # 先尝试使用 chezmoi apply 更新（如果文件已在管理中）
        if chezmoi apply "$target_file" 2>/dev/null; then
            log_success "  ✓ 已更新（通过 chezmoi）"
        else
            # 如果失败，尝试添加到管理
            log_info "  chezmoi apply 失败，尝试添加到管理..."
            if chezmoi add "$target_file" 2>/dev/null; then
                log_success "  ✓ 已添加到管理"
                # 添加后再次尝试应用
                if chezmoi apply "$target_file" 2>/dev/null; then
                    log_success "  ✓ 已更新（通过 chezmoi）"
                else
                    log_warning "  ⚠ 添加到管理后仍无法应用"
                fi
            else
                log_warning "  ⚠ 添加到管理失败"
                log_info "  文件可能已存在但内容不同，需要手动处理"
            fi
        fi
    else
        # 目标文件不存在，需要创建
        log_info "  目标文件不存在，创建..."

        # 如果是模板文件，使用 chezmoi execute-template
        if [[ "$source_file" =~ \.tmpl$ ]]; then
            log_info "  使用 chezmoi execute-template 处理模板..."
            if chezmoi execute-template < "$source_file" > "$target_file" 2>/dev/null; then
                log_success "  ✓ 已创建（模板已处理）"
            else
                log_warning "  ✗ chezmoi execute-template 失败"
                log_info "  尝试使用 chezmoi apply 创建..."
                # 尝试使用 chezmoi apply 创建
                if chezmoi apply "$target_file" 2>/dev/null; then
                    log_success "  ✓ 已创建（通过 chezmoi apply）"
                else
                    log_warning "  ✗ chezmoi apply 也失败，直接复制（未处理模板）"
                    cp "$source_file" "$target_file"
                    log_warning "  ⚠ 已直接复制（未处理模板变量）"
                fi
            fi
        else
            # 非模板文件，直接复制
            log_info "  直接复制非模板文件..."
            cp "$source_file" "$target_file"
            log_success "  ✓ 已创建"
        fi
    fi
}

# 处理所有文件映射
for source_file in "${!FILE_MAPPINGS[@]}"; do
    target_file="${FILE_MAPPINGS[$source_file]}"
    description=$(basename "$target_file")
    process_file "$source_file" "$target_file" "$description"
done

# ============================================
# 自动添加所有文件到管理（如果不在管理中）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "自动添加文件到管理"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MANAGED_FILES=$(chezmoi managed 2>/dev/null || true)
if [ -z "$MANAGED_FILES" ]; then
    log_info "没有文件在管理中，尝试自动添加..."

    ADDED_COUNT=0
    for source_file in "${!FILE_MAPPINGS[@]}"; do
        target_file="${FILE_MAPPINGS[$source_file]}"
        if [ -f "$target_file" ]; then
            log_info "添加到管理: $target_file"
            if chezmoi add "$target_file" 2>/dev/null; then
                log_success "  ✓ 已添加"
                ADDED_COUNT=$((ADDED_COUNT + 1))
            else
                log_warning "  ✗ 添加失败（可能已存在或内容冲突）"
            fi
        fi
    done

    if [ $ADDED_COUNT -gt 0 ]; then
        log_success "成功添加 $ADDED_COUNT 个文件到管理"
    else
        log_warning "没有文件被添加到管理"
    fi
else
    log_info "已有文件在管理中，跳过自动添加"
fi

# ============================================
# 尝试使用 chezmoi apply 应用所有配置
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "使用 chezmoi apply 应用所有配置"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "执行: chezmoi apply -v"
APPLY_OUTPUT=$(chezmoi apply -v 2>&1)
APPLY_EXIT_CODE=$?

# 显示输出
if [ -n "$APPLY_OUTPUT" ]; then
    echo "$APPLY_OUTPUT"
fi

if [ $APPLY_EXIT_CODE -eq 0 ]; then
    if echo "$APPLY_OUTPUT" | grep -qE "(create|update|apply|write)"; then
        log_success "chezmoi apply 成功应用了配置"
    else
        log_info "chezmoi apply 没有输出（可能所有文件都是最新的）"
    fi
else
    log_warning "chezmoi apply 退出码: $APPLY_EXIT_CODE"
fi

# ============================================
# 最终验证
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "最终验证"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_files=(
    "$HOME/.zshrc"
    "$HOME/.tmux.conf"
    "$HOME/.config/starship/starship.toml"
)

all_exist=true
for file in "${check_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "  ✓ $(basename "$file") 存在"
    else
        log_warning "  ✗ $(basename "$file") 不存在"
        all_exist=false
    fi
done

if [ "$all_exist" = true ]; then
    log_success "所有关键配置文件都已存在！"
else
    log_warning "部分配置文件仍缺失"
    log_info "建议运行: ./scripts/common/utils/diagnose_deployment.sh 进行诊断"
fi

end_script

log_success "处理完成！"

