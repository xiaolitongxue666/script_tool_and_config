#!/bin/bash

# ============================================
# 完整修复 Zsh 和 Oh My Zsh 配置
# 解决所有已知问题：文件冲突、run_once 未执行、配置不完整
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

start_script "完整修复 Zsh 和 Oh My Zsh"

# ============================================
# 检查前置条件
# ============================================
if ! command -v zsh &> /dev/null; then
    log_error "Zsh 未安装，请先安装 zsh"
    exit 1
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_error "Oh My Zsh 未安装，请先安装 Oh My Zsh"
    exit 1
fi

# ============================================
# 设置环境变量
# ============================================
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
if [ -d "$CHEZMOI_DIR" ]; then
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
fi

# ============================================
# 步骤 1: 清理锁文件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 1: 清理锁文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
LOCK_FILE="$CHEZMOI_STATE_DIR/.chezmoi.lock"

if [ -f "$LOCK_FILE" ]; then
    CHEZMOI_PIDS=$(pgrep -f "chezmoi" 2>/dev/null || true)
    if [ -z "$CHEZMOI_PIDS" ]; then
        log_info "清理残留的锁文件..."
        rm -f "$LOCK_FILE"
        log_success "锁文件已清理"
    else
        log_warning "发现正在运行的 chezmoi 进程，等待其完成..."
        sleep 2
        rm -f "$LOCK_FILE"
    fi
else
    log_success "没有锁文件"
fi

# ============================================
# 步骤 2: 安装插件（不依赖 run_once 脚本）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 2: 安装 Oh My Zsh 插件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$ZSH_CUSTOM"

declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
)

INSTALLED_COUNT=0
for plugin_name in "${!PLUGINS[@]}"; do
    plugin_url="${PLUGINS[$plugin_name]}"
    plugin_path="$ZSH_CUSTOM/$plugin_name"

    if [ -d "$plugin_path" ]; then
        log_info "  ✓ $plugin_name 已安装"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        log_info "  安装插件: $plugin_name..."
        if git clone "$plugin_url" "$plugin_path" 2>/dev/null; then
            log_success "  ✓ $plugin_name 安装成功"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            log_warning "  ✗ $plugin_name 安装失败"
        fi
    fi
done

log_info ""
log_info "已安装插件: $INSTALLED_COUNT/${#PLUGINS[@]}"

# ============================================
# 步骤 3: 强制更新 .zshrc 文件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 3: 强制更新 .zshrc 文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v chezmoi &> /dev/null && [ -d "$CHEZMOI_DIR" ]; then
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

    # 备份现有文件
    if [ -f "$HOME/.zshrc" ]; then
        BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc" "$BACKUP_FILE"
        log_info "已备份现有文件: $BACKUP_FILE"
    fi

    # 策略：先删除文件，然后从模板创建
    log_info "删除现有 .zshrc 文件..."
    rm -f "$HOME/.zshrc"

    # 使用 chezmoi apply 从模板创建新文件
    log_info "从模板创建新的 .zshrc 文件..."
    ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"

    if [ ! -f "$ZSHRC_TEMPLATE" ]; then
        log_error "模板文件不存在: $ZSHRC_TEMPLATE"
        exit 1
    fi

    # 策略 1: 尝试使用 chezmoi apply（最可靠）
    if command -v timeout &> /dev/null; then
        APPLY_OUTPUT=$(timeout 30 chezmoi apply ~/.zshrc -v 2>&1 || echo "timeout or error")
        if echo "$APPLY_OUTPUT" | grep -q "timeout"; then
            log_warning "chezmoi apply 超时，使用备用方案..."
            USE_FALLBACK=true
        elif echo "$APPLY_OUTPUT" | grep -qE "(apply|create|write)"; then
            log_success ".zshrc 已从模板创建（通过 chezmoi apply）"
            USE_FALLBACK=false
        else
            log_warning "chezmoi apply 没有创建文件，使用备用方案..."
            USE_FALLBACK=true
        fi
    else
        if chezmoi apply ~/.zshrc -v 2>&1 | grep -qE "(apply|create|write)"; then
            log_success ".zshrc 已从模板创建（通过 chezmoi apply）"
            USE_FALLBACK=false
        else
            log_warning "chezmoi apply 失败，使用备用方案..."
            USE_FALLBACK=true
        fi
    fi

    # 策略 2: 如果 chezmoi apply 失败，使用 chezmoi execute-template
    if [ "$USE_FALLBACK" = true ]; then
        log_info "尝试使用 chezmoi execute-template..."
        if chezmoi execute-template < "$ZSHRC_TEMPLATE" > "$HOME/.zshrc" 2>/dev/null; then
            log_success ".zshrc 已从模板创建（通过 chezmoi execute-template）"
        else
            log_warning "chezmoi execute-template 失败，直接复制模板文件..."
            # 策略 3: 直接复制模板文件（.zshrc.tmpl 中没有模板变量，可以直接复制）
            if cp "$ZSHRC_TEMPLATE" "$HOME/.zshrc" 2>/dev/null; then
                log_success ".zshrc 已从模板创建（直接复制）"
            else
                log_error "所有方法都失败，无法创建 .zshrc"
                exit 1
            fi
        fi
    fi

    # 添加到管理（使用 --force 避免冲突）
    log_info "添加 .zshrc 到 chezmoi 管理..."
    chezmoi add --force ~/.zshrc 2>/dev/null || log_warning "添加到管理失败（可能已在管理中）"

    # 验证插件配置
    if [ -f "$HOME/.zshrc" ]; then
        log_info "验证 .zshrc 文件..."
        FILE_SIZE=$(wc -c < "$HOME/.zshrc" 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -lt 1000 ]; then
            log_error ".zshrc 文件太小（可能创建失败），文件大小: $FILE_SIZE 字节"
            log_info "检查文件内容..."
            head -20 "$HOME/.zshrc" || true
        else
            log_success ".zshrc 文件大小正常: $FILE_SIZE 字节"
        fi

        # 检查 plugins 配置（可能跨多行）
        PLUGINS_SECTION=$(grep -A 15 "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -16 || echo "")
        if [ -n "$PLUGINS_SECTION" ]; then
            log_info "找到 plugins 配置:"
            echo "$PLUGINS_SECTION" | head -5 | while IFS= read -r line; do
                log_info "  $line"
            done

            # 检查是否包含所有插件
            MISSING_PLUGINS=()
            for plugin_name in "${!PLUGINS[@]}"; do
                if ! echo "$PLUGINS_SECTION" | grep -q "$plugin_name"; then
                    MISSING_PLUGINS+=("$plugin_name")
                fi
            done

            if [ ${#MISSING_PLUGINS[@]} -eq 0 ]; then
                log_success "所有插件都在配置中"
            else
                log_warning "以下插件未在配置中: ${MISSING_PLUGINS[*]}"
                log_info "但插件已安装，可以手动添加到 .zshrc"
            fi
        else
            log_warning "未找到 plugins 配置"
            log_info "检查文件内容（前50行）..."
            head -50 "$HOME/.zshrc" | grep -E "plugins|ZSH|oh-my-zsh" || log_warning "未找到相关配置"
        fi
    else
        log_error ".zshrc 文件不存在"
    fi
else
    log_error "chezmoi 不可用或源目录不存在"
    exit 1
fi

# ============================================
# 步骤 4: 标记 run_once 脚本为已执行
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 4: 标记 run_once 脚本为已执行"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v chezmoi &> /dev/null; then
    chezmoi state set "run_once_install-zsh.sh.tmpl" "executed" 2>/dev/null || true
    log_success "已标记 run_once 脚本为已执行"
fi

# ============================================
# 完成
# ============================================
end_script

log_success "修复完成！"
log_info ""
log_info "下一步："
log_info "  1. 重新加载配置: source ~/.zshrc"
log_info "  2. 或重新打开终端"
log_info "  3. 检查效果: 应该看到语法高亮和自动建议"
log_info ""
log_info "如果还有问题，请检查:"
log_info "  - 插件是否已安装: ls ~/.oh-my-zsh/custom/plugins/"
log_info "  - .zshrc 配置: cat ~/.zshrc | grep -A 20 '^plugins='"

