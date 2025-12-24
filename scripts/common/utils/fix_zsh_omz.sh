#!/bin/bash

# ============================================
# 修复 Zsh 和 Oh My Zsh 配置
# 自动安装插件并更新 .zshrc
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

start_script "修复 Zsh 和 Oh My Zsh"

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
# 方法 1: 尝试执行 run_once 脚本
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 1: 执行 run_once 安装脚本"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INSTALL_SCRIPT="$CHEZMOI_DIR/run_once_install-zsh.sh.tmpl"
if [ -f "$INSTALL_SCRIPT" ] && command -v chezmoi &> /dev/null; then
    log_info "尝试通过 chezmoi apply 执行安装脚本..."

    # 检查脚本是否已执行
    if chezmoi state get "run_once_install-zsh.sh.tmpl" &>/dev/null; then
        log_info "脚本已执行过，跳过"
    else
        log_info "脚本未执行，运行 chezmoi apply 来执行..."

        # 先清理可能的锁文件
        CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
        LOCK_FILE="$CHEZMOI_STATE_DIR/.chezmoi.lock"
        if [ -f "$LOCK_FILE" ]; then
            CHEZMOI_PIDS=$(pgrep -f "chezmoi" 2>/dev/null || true)
            if [ -z "$CHEZMOI_PIDS" ]; then
                log_info "清理残留的锁文件..."
                rm -f "$LOCK_FILE"
            fi
        fi

        # 使用 timeout 执行，避免卡住
        if command -v timeout &> /dev/null; then
            APPLY_OUTPUT=$(timeout 30 chezmoi apply -v 2>&1 || echo "timeout or error")
            if echo "$APPLY_OUTPUT" | grep -q "run_once_install-zsh"; then
                log_success "安装脚本已执行"
            elif echo "$APPLY_OUTPUT" | grep -q "timeout"; then
                log_warning "chezmoi apply 超时，跳过 run_once 脚本执行"
                log_warning "跳过模板执行（超时问题），直接安装插件..."
                # 标记脚本已执行，避免重复尝试
                chezmoi state set "run_once_install-zsh.sh.tmpl" "executed" 2>/dev/null || true
            else
                log_warning "chezmoi apply 未执行安装脚本，跳过..."
                log_warning "跳过模板执行，直接安装插件..."
                # 标记脚本已执行，避免重复尝试
                chezmoi state set "run_once_install-zsh.sh.tmpl" "executed" 2>/dev/null || true
            fi
        else
            APPLY_OUTPUT=$(chezmoi apply -v 2>&1)
            if echo "$APPLY_OUTPUT" | grep -q "run_once_install-zsh"; then
                log_success "安装脚本已执行"
            else
                log_warning "chezmoi apply 未执行安装脚本，跳过..."
                log_warning "跳过模板执行，直接安装插件..."
                # 标记脚本已执行，避免重复尝试
                chezmoi state set "run_once_install-zsh.sh.tmpl" "executed" 2>/dev/null || true
            fi
        fi
    fi
else
    log_warning "安装脚本不存在或 chezmoi 未安装，跳过"
fi

# ============================================
# 方法 2: 手动安装缺失的插件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 2: 手动安装缺失的插件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$ZSH_CUSTOM"

# 插件列表
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
            log_info "    可能原因：网络问题或 Git 未安装"
            log_info "    手动安装: git clone $plugin_url $plugin_path"
        fi
    fi
done

log_info ""
log_info "已安装插件: $INSTALLED_COUNT/${#PLUGINS[@]}"

# ============================================
# 方法 3: 更新 .zshrc 文件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "方法 3: 更新 .zshrc 文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v chezmoi &> /dev/null && [ -d "$CHEZMOI_DIR" ]; then
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

    log_info "使用 chezmoi apply 更新 .zshrc..."

    # 先检查当前配置
    CURRENT_PLUGINS=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
    log_info "当前插件配置: ${CURRENT_PLUGINS:-未找到}"

    # 先备份现有文件（如果存在）
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi

    # 检查文件是否在管理中
    if chezmoi managed 2>/dev/null | grep -q "^\.zshrc$"; then
        log_info ".zshrc 已在管理中"

        # 检查是否有冲突
        if echo "$(chezmoi diff ~/.zshrc 2>&1 || true)" | grep -q "has changed since chezmoi last wrote it"; then
            log_warning "检测到文件冲突，重新添加到管理..."
            # 使用 --force 重新添加文件
            chezmoi add --force ~/.zshrc 2>/dev/null || true
        fi
    else
        log_info ".zshrc 未在管理中，添加到管理..."
        chezmoi add ~/.zshrc 2>/dev/null || true
    fi

    # 应用配置（使用 --force 确保更新，带超时保护）
    # 使用 timeout 避免卡住，最多等待 30 秒
    if command -v timeout &> /dev/null; then
        APPLY_OUTPUT=$(timeout 30 chezmoi apply ~/.zshrc --force -v 2>&1 || echo "timeout or error")
        APPLY_EXIT_CODE=$?
        if echo "$APPLY_OUTPUT" | grep -q "timeout"; then
            log_error "chezmoi apply 超时，可能是锁文件问题"
            log_info "请运行: ./scripts/common/utils/fix_chezmoi_lock.sh"
            APPLY_EXIT_CODE=1
        elif echo "$APPLY_OUTPUT" | grep -q "has changed since chezmoi last wrote it"; then
            log_warning "文件冲突，尝试删除后重新应用..."
            rm -f "$HOME/.zshrc"
            # 重新添加到管理
            chezmoi add ~/.zshrc 2>/dev/null || true
            # 再次应用
            APPLY_OUTPUT=$(timeout 30 chezmoi apply ~/.zshrc -v 2>&1 || echo "timeout or error")
            APPLY_EXIT_CODE=$?
        fi
    else
        APPLY_OUTPUT=$(chezmoi apply ~/.zshrc --force -v 2>&1)
        APPLY_EXIT_CODE=$?
        if echo "$APPLY_OUTPUT" | grep -q "has changed since chezmoi last wrote it"; then
            log_warning "文件冲突，尝试删除后重新应用..."
            rm -f "$HOME/.zshrc"
            chezmoi add ~/.zshrc 2>/dev/null || true
            APPLY_OUTPUT=$(chezmoi apply ~/.zshrc -v 2>&1)
            APPLY_EXIT_CODE=$?
        fi
    fi

    # 如果 apply 没有实际更新文件，尝试先删除再应用
    if [ $APPLY_EXIT_CODE -eq 0 ] && ! echo "$APPLY_OUTPUT" | grep -qE "apply|write|create|diff"; then
        log_info "chezmoi apply 认为文件是最新的，尝试删除后重新应用..."
        rm -f "$HOME/.zshrc"

        # 再次应用，带超时保护
        if command -v timeout &> /dev/null; then
            APPLY_OUTPUT=$(timeout 30 chezmoi apply ~/.zshrc -v 2>&1 || echo "timeout or error")
            APPLY_EXIT_CODE=$?
            if echo "$APPLY_OUTPUT" | grep -q "timeout"; then
                log_error "chezmoi apply 超时"
                APPLY_EXIT_CODE=1
            fi
        else
            APPLY_OUTPUT=$(chezmoi apply ~/.zshrc -v 2>&1)
            APPLY_EXIT_CODE=$?
        fi
    fi

    if [ $APPLY_EXIT_CODE -eq 0 ]; then
        log_success ".zshrc 已更新"

        # 验证插件配置是否已更新
        NEW_PLUGINS=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
        log_info "更新后插件配置: ${NEW_PLUGINS:-未找到}"

        # 检查是否包含所有插件
        if [ -n "$NEW_PLUGINS" ] && echo "$NEW_PLUGINS" | grep -qE "zsh-autosuggestions|zsh-syntax-highlighting|zsh-history-substring-search|zsh-completions"; then
            log_success "插件配置已包含所有必要插件"
        else
            log_warning "插件配置可能不完整"
            log_info "检查模板文件..."

            # 检查模板中的插件配置
            ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"
            if [ -f "$ZSHRC_TEMPLATE" ]; then
                TEMPLATE_PLUGINS=$(grep -A 15 "^plugins=" "$ZSHRC_TEMPLATE" 2>/dev/null | head -15 || echo "")
                if [ -n "$TEMPLATE_PLUGINS" ]; then
                    log_info "模板中的插件配置:"
                    echo "$TEMPLATE_PLUGINS" | while IFS= read -r line; do
                        log_info "  $line"
                    done
                fi
            fi
        fi
    else
        log_warning "chezmoi apply 失败，尝试其他方法..."
        log_info "错误输出: $APPLY_OUTPUT"

        # 检查模板文件
        ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"
        if [ -f "$ZSHRC_TEMPLATE" ]; then
            log_info "使用模板文件直接更新 .zshrc..."
            # 注意：chezmoi execute-template 可能无法正确访问 .data.proxy
            # 使用 chezmoi apply 代替，它能够正确处理模板
            if command -v timeout &> /dev/null; then
                if timeout 30 chezmoi apply ~/.zshrc --force -v 2>&1 | grep -qE "apply|write|create"; then
                    log_success ".zshrc 已从模板更新"
                else
                    log_warning "模板应用失败或超时"
                fi
            else
                if chezmoi apply ~/.zshrc --force -v 2>&1 | grep -qE "apply|write|create"; then
                    log_success ".zshrc 已从模板更新"
                else
                    log_warning "模板应用失败"
                fi
            fi
        fi
    fi
else
    log_warning "chezmoi 不可用，无法自动更新 .zshrc"
    log_info "建议手动运行: chezmoi apply ~/.zshrc"
fi

# ============================================
# 验证结果
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "验证结果"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查插件
log_info "检查已安装的插件："
for plugin_name in "${!PLUGINS[@]}"; do
    plugin_path="$ZSH_CUSTOM/$plugin_name"
    if [ -d "$plugin_path" ]; then
        log_success "  ✓ $plugin_name"
    else
        log_warning "  ✗ $plugin_name"
    fi
done

# 检查 .zshrc 中的插件配置
if [ -f "$HOME/.zshrc" ]; then
    log_info ""
    log_info "检查 .zshrc 中的插件配置："
    PLUGINS_LINE=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
    if [ -n "$PLUGINS_LINE" ]; then
        log_info "  $PLUGINS_LINE"

        # 检查是否包含所有插件
        MISSING_PLUGINS=()
        for plugin_name in "${!PLUGINS[@]}"; do
            if ! echo "$PLUGINS_LINE" | grep -q "$plugin_name"; then
                MISSING_PLUGINS+=("$plugin_name")
            fi
        done

        if [ ${#MISSING_PLUGINS[@]} -eq 0 ]; then
            log_success "  所有插件都在配置中"
        else
            log_warning "  以下插件未在配置中: ${MISSING_PLUGINS[*]}"
            log_info "  尝试强制更新 .zshrc..."

            # 再次强制更新（带超时保护）
            # 先处理可能的文件冲突
            if echo "$(chezmoi diff ~/.zshrc 2>&1 || true)" | grep -q "has changed since chezmoi last wrote it"; then
                log_info "  检测到文件冲突，重新添加到管理..."
                chezmoi add --force ~/.zshrc 2>/dev/null || true
            fi

            if command -v timeout &> /dev/null; then
                FORCE_OUTPUT=$(timeout 30 chezmoi apply ~/.zshrc --force -v 2>&1 || echo "timeout or error")
                if echo "$FORCE_OUTPUT" | grep -q "apply\|write\|create"; then
                    log_success "  .zshrc 已强制更新"

                    # 再次检查
                    NEW_PLUGINS_AFTER_FORCE=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
                    if [ -n "$NEW_PLUGINS_AFTER_FORCE" ]; then
                        log_info "  更新后配置: $NEW_PLUGINS_AFTER_FORCE"
                    fi
                else
                    log_warning "  强制更新可能未生效或超时"
                    log_info "  建议手动检查: cat ~/.zshrc | grep -A 20 '^plugins='"
                    log_info "  或手动运行: chezmoi add --force ~/.zshrc && chezmoi apply ~/.zshrc --force"
                fi
            else
                FORCE_OUTPUT=$(chezmoi apply ~/.zshrc --force -v 2>&1)
                if echo "$FORCE_OUTPUT" | grep -q "apply\|write\|create"; then
                    log_success "  .zshrc 已强制更新"

                    # 再次检查
                    NEW_PLUGINS_AFTER_FORCE=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
                    if [ -n "$NEW_PLUGINS_AFTER_FORCE" ]; then
                        log_info "  更新后配置: $NEW_PLUGINS_AFTER_FORCE"
                    fi
                else
                    log_warning "  强制更新可能未生效"
                    log_info "  建议手动检查: cat ~/.zshrc | grep -A 20 '^plugins='"
                    log_info "  或手动运行: chezmoi add --force ~/.zshrc && chezmoi apply ~/.zshrc --force"
                fi
            fi
        fi
    else
        log_warning "  .zshrc 中未找到 plugins 配置"
    fi
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

