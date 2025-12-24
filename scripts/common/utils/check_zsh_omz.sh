#!/bin/bash

# ============================================
# Zsh 和 Oh My Zsh 安装状态检查脚本
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

start_script "Zsh 和 Oh My Zsh 检查"

# ============================================
# 1. 检查 Zsh 安装
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "1. 检查 Zsh 安装"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v zsh &> /dev/null; then
    ZSH_VERSION=$(zsh --version 2>/dev/null || echo "未知版本")
    log_success "Zsh 已安装: $ZSH_VERSION"
    log_info "  安装路径: $(which zsh)"

    # 检查当前 shell
    CURRENT_SHELL=$(echo $SHELL)
    if [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
        log_success "  当前 Shell: $CURRENT_SHELL"
    else
        log_info "  当前 Shell: $CURRENT_SHELL (不是 zsh)"
    fi
else
    log_error "Zsh 未安装"
    log_info "  需要运行: ./deploy.sh 或手动安装 zsh"
fi

# ============================================
# 2. 检查 Oh My Zsh 安装
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "2. 检查 Oh My Zsh 安装"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

OMZ_DIR="$HOME/.oh-my-zsh"
if [ -d "$OMZ_DIR" ]; then
    log_success "Oh My Zsh 已安装"
    log_info "  安装路径: $OMZ_DIR"

    # 检查版本
    if [ -f "$OMZ_DIR/.git/config" ]; then
        OMZ_VERSION=$(cd "$OMZ_DIR" && git describe --tags --abbrev=0 2>/dev/null || echo "未知版本")
        log_info "  版本: $OMZ_VERSION"
    fi

    # 检查 .zshrc 中的 ZSH 变量
    if [ -f "$HOME/.zshrc" ]; then
        ZSH_VAR=$(grep -E "^export ZSH=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
        if [ -n "$ZSH_VAR" ]; then
            log_success "  .zshrc 中已配置 ZSH 变量"
            log_info "  $ZSH_VAR"
        else
            log_warning "  .zshrc 中未找到 ZSH 变量"
        fi
    fi
else
    log_error "Oh My Zsh 未安装"
    log_info "  需要运行: ./deploy.sh 或手动安装 Oh My Zsh"
    log_info "  安装命令: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# ============================================
# 3. 检查 Oh My Zsh 插件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "3. 检查 Oh My Zsh 插件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "$OMZ_DIR" ]; then
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    log_info "插件目录: $ZSH_CUSTOM"

    # 检查 .zshrc 中配置的插件
    if [ -f "$HOME/.zshrc" ]; then
        PLUGINS_LINE=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
        if [ -n "$PLUGINS_LINE" ]; then
            log_info "  .zshrc 中配置的插件:"
            log_info "  $PLUGINS_LINE"
        else
            log_warning "  .zshrc 中未找到 plugins 配置"
        fi
    fi

    # 检查常用插件
    declare -A EXPECTED_PLUGINS=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    )

    log_info ""
    log_info "检查已安装的插件："
    INSTALLED_COUNT=0
    for plugin_name in "${!EXPECTED_PLUGINS[@]}"; do
        plugin_path="$ZSH_CUSTOM/$plugin_name"
        if [ -d "$plugin_path" ]; then
            log_success "  ✓ $plugin_name 已安装"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))

            # 检查插件版本
            if [ -d "$plugin_path/.git" ]; then
                plugin_version=$(cd "$plugin_path" && git describe --tags --abbrev=0 2>/dev/null || echo "未知版本")
                log_info "    版本: $plugin_version"
            fi
        else
            log_warning "  ✗ $plugin_name 未安装"
            log_info "    安装命令: git clone ${EXPECTED_PLUGINS[$plugin_name]} $plugin_path"
        fi
    done

    log_info ""
    log_info "已安装插件数量: $INSTALLED_COUNT/${#EXPECTED_PLUGINS[@]}"
else
    log_warning "Oh My Zsh 未安装，跳过插件检查"
fi

# ============================================
# 4. 检查安装脚本
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "4. 检查安装脚本和模板"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
if [ -d "$CHEZMOI_DIR" ]; then
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

    # 检查安装脚本
    INSTALL_SCRIPT="$CHEZMOI_DIR/run_once_install-zsh.sh.tmpl"
    if [ -f "$INSTALL_SCRIPT" ]; then
        log_success "安装脚本存在: run_once_install-zsh.sh.tmpl"
        log_info "  文件大小: $(ls -lh "$INSTALL_SCRIPT" | awk '{print $5}')"

        # 检查脚本是否已执行（通过检查 chezmoi 状态）
        if command -v chezmoi &> /dev/null; then
            SCRIPT_STATUS=$(chezmoi state get "$INSTALL_SCRIPT" 2>/dev/null || echo "")
            if [ -n "$SCRIPT_STATUS" ]; then
                log_info "  脚本状态: 已执行"
            else
                log_warning "  脚本状态: 未执行（可能需要运行 chezmoi apply）"
            fi
        fi
    else
        log_error "安装脚本不存在: run_once_install-zsh.sh.tmpl"
    fi

    # 检查 zsh 配置文件模板
    ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"
    if [ -f "$ZSHRC_TEMPLATE" ]; then
        log_success "Zsh 配置模板存在: dot_zshrc.tmpl"
        log_info "  文件大小: $(ls -lh "$ZSHRC_TEMPLATE" | awk '{print $5}')"

        # 检查模板中是否包含 Oh My Zsh 配置
        if grep -q "ZSH=" "$ZSHRC_TEMPLATE" 2>/dev/null; then
            log_success "  模板中包含 Oh My Zsh 配置"
        else
            log_warning "  模板中未找到 Oh My Zsh 配置"
        fi

        # 检查模板中是否包含插件配置
        if grep -q "plugins=" "$ZSHRC_TEMPLATE" 2>/dev/null; then
            log_success "  模板中包含插件配置"
            PLUGINS_IN_TEMPLATE=$(grep -E "^plugins=" "$ZSHRC_TEMPLATE" 2>/dev/null | head -1)
            log_info "  $PLUGINS_IN_TEMPLATE"
        else
            log_warning "  模板中未找到插件配置"
        fi
    else
        log_error "Zsh 配置模板不存在: dot_zshrc.tmpl"
    fi
else
    log_error "chezmoi 源目录不存在: $CHEZMOI_DIR"
fi

# ============================================
# 5. 检查 .zshrc 文件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "5. 检查 .zshrc 文件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$HOME/.zshrc" ]; then
    log_success ".zshrc 文件存在"
    log_info "  文件大小: $(ls -lh "$HOME/.zshrc" | awk '{print $5}')"
    log_info "  修改时间: $(ls -l "$HOME/.zshrc" | awk '{print $6, $7, $8}')"

    # 检查是否包含 Oh My Zsh 配置
    if grep -q "ZSH=" "$HOME/.zshrc" 2>/dev/null; then
        log_success "  包含 Oh My Zsh 配置"
        ZSH_LINE=$(grep -E "^export ZSH=" "$HOME/.zshrc" 2>/dev/null | head -1)
        log_info "  $ZSH_LINE"
    else
        log_warning "  未找到 Oh My Zsh 配置"
    fi

    # 检查是否包含插件配置
    if grep -q "plugins=" "$HOME/.zshrc" 2>/dev/null; then
        log_success "  包含插件配置"
        PLUGINS_LINE=$(grep -E "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -1)
        log_info "  $PLUGINS_LINE"
    else
        log_warning "  未找到插件配置"
    fi

    # 检查是否包含 source $ZSH/oh-my-zsh.sh
    if grep -q "source.*oh-my-zsh.sh" "$HOME/.zshrc" 2>/dev/null; then
        log_success "  包含 Oh My Zsh 初始化"
    else
        log_warning "  未找到 Oh My Zsh 初始化"
    fi
else
    log_error ".zshrc 文件不存在"
    log_info "  需要运行: ./deploy.sh 或手动创建"
fi

# ============================================
# 6. 检查 run_once 脚本执行状态
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "6. 检查 run_once 脚本执行状态"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v chezmoi &> /dev/null && [ -d "$CHEZMOI_DIR" ]; then
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

    # 检查 chezmoi 状态目录
    CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
    if [ -d "$CHEZMOI_STATE_DIR" ]; then
        log_info "chezmoi 状态目录: $CHEZMOI_STATE_DIR"

        # 检查 run_once 脚本是否已执行
        RUN_ONCE_SCRIPTS=$(find "$CHEZMOI_DIR" -name "run_once_install-zsh.sh.tmpl" 2>/dev/null)
        if [ -n "$RUN_ONCE_SCRIPTS" ]; then
            log_info "检查 run_once_install-zsh.sh.tmpl 执行状态..."
            # chezmoi 会在状态目录中记录已执行的 run_once 脚本
            # 检查方法：查看 chezmoi 状态
            if chezmoi state get "run_once_install-zsh.sh.tmpl" &>/dev/null; then
                log_success "  脚本已执行"
            else
                log_warning "  脚本未执行（可能需要运行 chezmoi apply）"
            fi
        fi
    else
        log_warning "chezmoi 状态目录不存在: $CHEZMOI_STATE_DIR"
    fi
fi

# ============================================
# 总结和建议
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "总结和建议"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查所有关键组件
ALL_OK=true

if ! command -v zsh &> /dev/null; then
    log_warning "Zsh 未安装"
    ALL_OK=false
fi

if [ ! -d "$OMZ_DIR" ]; then
    log_warning "Oh My Zsh 未安装"
    ALL_OK=false
fi

if [ ! -f "$HOME/.zshrc" ]; then
    log_warning ".zshrc 文件不存在"
    ALL_OK=false
fi

if [ "$ALL_OK" = true ]; then
    log_success "所有关键组件都已安装！"
    log_info ""
    log_info "如果 source ~/.zshrc 没有变化，可能的原因："
    log_info "  1. 当前 shell 不是 zsh（运行: chsh -s $(which zsh)）"
    log_info "  2. .zshrc 配置有问题（检查: cat ~/.zshrc）"
    log_info "  3. Oh My Zsh 插件未正确加载（检查插件目录）"
    log_info ""
    log_info "建议："
    log_info "  1. 切换到 zsh: chsh -s $(which zsh)"
    log_info "  2. 重新打开终端或运行: exec zsh"
    log_info "  3. 检查 .zshrc: cat ~/.zshrc | head -50"
else
    log_warning "部分组件缺失，需要安装"
    log_info ""
    log_info "建议运行: ./deploy.sh"
    log_info "或手动安装缺失的组件"
fi

end_script

