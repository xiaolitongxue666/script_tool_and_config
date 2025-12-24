#!/bin/bash

# ============================================
# 自动修复部署问题
# 解决源文件存在但未被应用的问题
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

start_script "自动修复部署"

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
# 检查当前状态
# ============================================
log_info "检查当前状态..."
MANAGED_FILES=$(chezmoi managed 2>/dev/null || true)

if [ -n "$MANAGED_FILES" ]; then
    log_success "已有配置文件在管理中，跳过初始化"
    log_info "直接应用配置..."
    chezmoi apply -v
    end_script
    exit 0
fi

log_warning "没有配置文件在管理中，需要初始化"

# ============================================
# 方法 1: 尝试使用 chezmoi init（如果支持）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 1: 尝试初始化源文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查是否有 chezmoi init 命令
if chezmoi init --help &>/dev/null; then
    log_info "尝试使用 chezmoi init 初始化..."
    # 注意：chezmoi init 通常用于从现有文件初始化，这里我们尝试另一种方法
    log_info "chezmoi init 不适用于此场景，跳过"
fi

# ============================================
# 方法 2: 对于已存在的文件，使用 chezmoi add
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 2: 添加已存在的文件到管理"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查并添加已存在的文件
add_if_exists() {
    local target_file="$1"
    local description="$2"

    if [ -f "$target_file" ]; then
        log_info "添加 $description: $target_file"
        if chezmoi add "$target_file" 2>/dev/null; then
            log_success "  ✓ 已添加到管理"
        else
            log_warning "  ✗ 添加失败（可能已存在或源文件冲突）"
        fi
    else
        log_info "跳过 $description: $target_file（不存在）"
    fi
}

add_if_exists "$HOME/.zshrc" "Zsh 配置"
add_if_exists "$HOME/.tmux.conf" "Tmux 配置"
add_if_exists "$HOME/.bashrc" "Bash 配置"
add_if_exists "$HOME/.bash_profile" "Bash Profile"
add_if_exists "$HOME/.config/starship/starship.toml" "Starship 配置"
add_if_exists "$HOME/.config/alacritty/alacritty.toml" "Alacritty 配置"
add_if_exists "$HOME/.config/fish/config.fish" "Fish 配置"

# ============================================
# 方法 3: 使用 chezmoi source 命令强制应用
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 3: 使用 chezmoi source 命令强制应用"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "chezmoi source 命令可以列出所有源文件，然后我们可以逐个应用"

# 获取所有源文件
SOURCE_FILES=$(chezmoi source-path --recursive 2>/dev/null || find "$CHEZMOI_DIR" -type f ! -path '*/.git/*' ! -name 'chezmoi.toml' ! -name '*.swp' ! -name '*.swo' 2>/dev/null)

if [ -n "$SOURCE_FILES" ]; then
    log_info "发现源文件，尝试应用..."

    # 尝试直接应用（chezmoi 应该能够识别源文件）
    log_info "执行: chezmoi apply -v"
    APPLY_OUTPUT=$(chezmoi apply -v 2>&1)
    APPLY_EXIT_CODE=$?

    # 显示输出
    echo "$APPLY_OUTPUT"

    if [ $APPLY_EXIT_CODE -eq 0 ]; then
        # 检查是否有文件被应用
        if echo "$APPLY_OUTPUT" | grep -qE "(create|update|apply|write)"; then
            log_success "配置应用成功！"
        else
            log_warning "没有文件被应用，尝试其他方法..."

            # 尝试使用 chezmoi source-state 命令
            log_info "尝试使用 chezmoi source-state 命令..."
            SOURCE_STATE=$(chezmoi source-state 2>&1 || true)
            if [ -n "$SOURCE_STATE" ]; then
                log_info "源状态: $SOURCE_STATE"
            fi
        fi
    else
        log_warning "chezmoi apply 退出码: $APPLY_EXIT_CODE"
    fi
else
    log_warning "未找到源文件"
fi

# ============================================
# 方法 4: 使用 chezmoi execute-template 处理模板文件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 4: 处理模板文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 处理模板文件
process_template() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"

    if [ -f "$source_file" ] && [ ! -f "$target_file" ]; then
        log_info "处理 $description: $target_file"

        # 创建目标目录
        local target_dir=$(dirname "$target_file")
        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
            log_info "  创建目录: $target_dir"
        fi

        # 如果是模板文件，使用 chezmoi execute-template
        if [[ "$source_file" =~ \.tmpl$ ]]; then
            log_info "  使用 chezmoi execute-template 处理模板..."
            if chezmoi execute-template < "$source_file" > "$target_file" 2>/dev/null; then
                log_success "  ✓ 已创建（模板已处理）"
            else
                log_warning "  ✗ chezmoi execute-template 失败，尝试直接复制..."
                cp "$source_file" "$target_file"
                log_warning "  ⚠ 已直接复制（未处理模板变量）"
            fi
        else
            # 直接复制非模板文件
            cp "$source_file" "$target_file"
            log_success "  ✓ 已创建"
        fi
    fi
}

# ============================================
# 方法 5: 手动创建缺失的文件（如果源文件存在）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 4: 检查并创建缺失的文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 定义源文件到目标文件的映射
declare -A FILE_MAPPINGS=(
    ["$CHEZMOI_DIR/dot_tmux.conf"]="$HOME/.tmux.conf"
    ["$CHEZMOI_DIR/dot_config/starship/starship.toml"]="$HOME/.config/starship/starship.toml"
    ["$CHEZMOI_DIR/dot_config/alacritty/alacritty.toml"]="$HOME/.config/alacritty/alacritty.toml"
    ["$CHEZMOI_DIR/dot_config/fish/config.fish"]="$HOME/.config/fish/config.fish"
)

create_if_missing() {
    local source_file="$1"
    local target_file="$2"
    local description="$3"

    if [ -f "$source_file" ] && [ ! -f "$target_file" ]; then
        log_info "创建 $description: $target_file"

        # 创建目标目录
        local target_dir=$(dirname "$target_file")
        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
            log_info "  创建目录: $target_dir"
        fi

        # 如果是模板文件，需要先处理
        if [[ "$source_file" =~ \.tmpl$ ]]; then
            log_info "  源文件是模板，使用 chezmoi 处理..."
            # 尝试使用 chezmoi 应用
            if chezmoi apply "$target_file" 2>/dev/null; then
                log_success "  ✓ 已创建（通过 chezmoi）"
            else
                log_warning "  ✗ chezmoi 应用失败，尝试直接复制..."
                # 作为备选方案，直接复制（不推荐，但可以工作）
                cp "$source_file" "$target_file"
                log_warning "  ⚠ 已直接复制（未处理模板变量）"
            fi
        else
            # 直接复制非模板文件
            cp "$source_file" "$target_file"
            log_success "  ✓ 已创建"
        fi
    elif [ ! -f "$source_file" ]; then
        log_info "跳过 $description: 源文件不存在"
    else
        log_info "跳过 $description: 目标文件已存在"
    fi
}

# 处理映射的文件
for source_file in "${!FILE_MAPPINGS[@]}"; do
    target_file="${FILE_MAPPINGS[$source_file]}"
    description=$(basename "$target_file")
    create_if_missing "$source_file" "$target_file" "$description"
done

# ============================================
# 最终验证
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "最终验证"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "检查关键配置文件..."
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
    log_info "建议："
    log_info "  1. 检查源文件是否在 .chezmoi 目录中"
    log_info "  2. 运行: export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\" && chezmoi apply -v"
    log_info "  3. 或手动添加: chezmoi add <target_file>"
fi

# ============================================
# 完成
# ============================================
end_script

log_success "修复完成！"
log_info ""
log_info "下一步："
log_info "  1. 运行: ./deploy.sh 验证部署"
log_info "  2. 或运行: export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\" && chezmoi apply -v"

