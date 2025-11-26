#!/bin/bash

# Git Bash 配置安装脚本
# 仅支持 Windows Git Bash 环境

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# 加载通用脚本函数
if [ -f "$SCRIPT_DIR/../../scripts/common.sh" ]; then
    source "$SCRIPT_DIR/../../scripts/common.sh"
else
    # 如果没有 common.sh，定义基本函数
    function log_info() { echo "[信息] $*"; }
    function log_success() { echo "[成功] $*"; }
    function log_warning() { echo "[警告] $*"; }
    function log_error() { echo "[错误] $*" >&2; }
fi

start_script "Git Bash 配置安装脚本 (Windows)"

# ============================================
# 系统检测
# ============================================
log_info "检测操作系统: $OS"

# 检查是否为 Windows Git Bash 环境
if [[ ! "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    log_error "此脚本仅支持 Windows Git Bash 环境"
    log_info "检测到的系统: $OS"
    log_info "请在 Git Bash 中运行此脚本"
    exit 1
fi

log_success "检测到 Windows Git Bash 环境"

# ============================================
# 配置文件路径
# ============================================
BASH_PROFILE="$HOME/.bash_profile"
BASHRC="$HOME/.bashrc"
SOURCE_BASH_PROFILE="$SCRIPT_DIR/.bash_profile"
SOURCE_BASHRC="$SCRIPT_DIR/.bashrc"

# ============================================
# 备份现有配置
# ============================================
log_info "检查现有配置文件..."

if [ -f "$BASH_PROFILE" ]; then
    BACKUP_BASH_PROFILE="${BASH_PROFILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$BASH_PROFILE" "$BACKUP_BASH_PROFILE"
    log_success "已备份 .bash_profile 到: $BACKUP_BASH_PROFILE"
fi

if [ -f "$BASHRC" ]; then
    BACKUP_BASHRC="${BASHRC}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$BASHRC" "$BACKUP_BASHRC"
    log_success "已备份 .bashrc 到: $BACKUP_BASHRC"
fi

# ============================================
# 检查源配置文件
# ============================================
if [ ! -f "$SOURCE_BASH_PROFILE" ]; then
    log_error "未找到源配置文件: $SOURCE_BASH_PROFILE"
    exit 1
fi

# ============================================
# 同步配置文件
# ============================================
log_info "同步配置文件..."

# 检查是否已存在配置标记
if grep -q "# Loaded from dotfiles/git_bash" "$BASH_PROFILE" 2>/dev/null; then
    log_warning "配置已存在于 $BASH_PROFILE"
    read -p "是否更新配置？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 移除旧的配置标记和 source 行
        sed -i '/# Loaded from dotfiles\/git_bash/,+1d' "$BASH_PROFILE" 2>/dev/null || true
        # 添加新的配置
        echo "" >> "$BASH_PROFILE"
        echo "# Loaded from dotfiles/git_bash" >> "$BASH_PROFILE"
        echo "source $SOURCE_BASH_PROFILE" >> "$BASH_PROFILE"
        log_success "已更新配置到 $BASH_PROFILE"
    else
        log_info "跳过配置更新"
    fi
else
    # 添加配置
    echo "" >> "$BASH_PROFILE"
    echo "# Loaded from dotfiles/git_bash" >> "$BASH_PROFILE"
    echo "source $SOURCE_BASH_PROFILE" >> "$BASH_PROFILE"
    log_success "已添加配置到 $BASH_PROFILE"
fi

# ============================================
# 同步 .bashrc 配置
# ============================================
if [ ! -f "$SOURCE_BASHRC" ]; then
    log_warning "未找到源 .bashrc 配置文件: $SOURCE_BASHRC"
    log_info "将创建基本的 .bashrc 配置"
    # 创建基本的 .bashrc
    if [ ! -f "$BASHRC" ]; then
        cat > "$BASHRC" << 'EOF'
# Git Bash .bashrc
# 加载 .bash_profile（如果存在）
if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi
EOF
        log_success "已创建基本 .bashrc"
    fi
else
    # 检查是否已存在配置标记
    if grep -q "# Loaded from dotfiles/git_bash" "$BASHRC" 2>/dev/null; then
        log_warning "配置已存在于 $BASHRC"
        read -p "是否更新配置？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 移除旧的配置标记和 source 行
            sed -i '/# Loaded from dotfiles\/git_bash/,+1d' "$BASHRC" 2>/dev/null || true
            # 添加新的配置
            echo "" >> "$BASHRC"
            echo "# Loaded from dotfiles/git_bash" >> "$BASHRC"
            echo "source $SOURCE_BASHRC" >> "$BASHRC"
            log_success "已更新配置到 $BASHRC"
        else
            log_info "跳过配置更新"
        fi
    else
        # 添加配置
        echo "" >> "$BASHRC"
        echo "# Loaded from dotfiles/git_bash" >> "$BASHRC"
        echo "source $SOURCE_BASHRC" >> "$BASHRC"
        log_success "已添加配置到 $BASHRC"
    fi
fi

# ============================================
# 安装完成
# ============================================
end_script

log_success "Git Bash 配置安装完成！"
echo ""
echo "配置文件位置:"
echo "  - .bash_profile: $BASH_PROFILE"
echo "  - .bashrc: $BASHRC"
echo ""
echo "请运行以下命令重新加载配置:"
echo "  source $BASH_PROFILE"
echo "或重新打开 Git Bash"

