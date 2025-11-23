#!/bin/bash

# Starship 提示符安装脚本
# 用于安装 Starship 并同步配置文件

# 引入通用函数库
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || cd "$(dirname "$0")" && pwd)")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
COMMON_SH="$PROJECT_ROOT/scripts/common.sh"

if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    echo "错误: 无法找到 common.sh 脚本. 请确保其位于 $PROJECT_ROOT/scripts/common.sh"
    exit 1
fi

start_script "Starship 提示符安装"

# ============================================
# 检测操作系统
# ============================================
OS_TYPE=$(uname -s)
log_info "检测到操作系统: $OS_TYPE"

# ============================================
# 检查 Starship 是否已安装
# ============================================
if command -v starship &> /dev/null; then
    STARSHIP_VERSION=$(starship --version | head -n 1)
    log_success "Starship 已安装: $STARSHIP_VERSION"
else
    log_warning "Starship 未安装，开始安装..."
    
    # 根据操作系统选择安装方法
    case "$OS_TYPE" in
        Darwin)
            # macOS: 使用 Homebrew
            if command -v brew &> /dev/null; then
                log_info "使用 Homebrew 安装 Starship..."
                brew install starship
                if [ $? -eq 0 ]; then
                    log_success "✅ Starship 安装成功"
                else
                    error_exit "Starship 安装失败"
                fi
            else
                log_warning "未检测到 Homebrew，尝试使用官方安装脚本..."
                curl -sS https://starship.rs/install.sh | sh
                if [ $? -eq 0 ]; then
                    log_success "✅ Starship 安装成功"
                else
                    error_exit "Starship 安装失败，请手动安装: https://starship.rs/guide/#%F0%9F%9A%80-installation"
                fi
            fi
            ;;
        Linux)
            # Linux: 使用官方安装脚本
            log_info "使用官方安装脚本安装 Starship..."
            curl -sS https://starship.rs/install.sh | sh
            if [ $? -eq 0 ]; then
                log_success "✅ Starship 安装成功"
            else
                error_exit "Starship 安装失败，请手动安装: https://starship.rs/guide/#%F0%9F%9A%80-installation"
            fi
            ;;
        *)
            log_error "不支持的操作系统: $OS_TYPE"
            log_info "请手动安装 Starship: https://starship.rs/guide/#%F0%9F%9A%80-installation"
            ;;
    esac
fi

# ============================================
# 同步配置文件
# ============================================
log_info "正在同步配置文件..."

STARSHIP_CONFIG_DIR="$HOME/.config/starship"
ensure_directory "$STARSHIP_CONFIG_DIR"

STARSHIP_CONFIG_FILE="$STARSHIP_CONFIG_DIR/starship.toml"
PROJECT_CONFIG_FILE="$SCRIPT_DIR/starship.toml"

if [ ! -f "$PROJECT_CONFIG_FILE" ]; then
    error_exit "未找到配置文件: $PROJECT_CONFIG_FILE"
fi

# 备份现有配置（如果存在）
if [ -f "$STARSHIP_CONFIG_FILE" ]; then
    backup_file "$STARSHIP_CONFIG_FILE"
fi

# 复制配置文件
cp "$PROJECT_CONFIG_FILE" "$STARSHIP_CONFIG_FILE"
if [ $? -eq 0 ]; then
    log_success "✅ 配置文件已复制到 $STARSHIP_CONFIG_FILE"
else
    error_exit "配置文件复制失败"
fi

# ============================================
# 初始化 Shell 配置
# ============================================
log_info "检查 Shell 配置..."

# 检测当前 Shell
CURRENT_SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")

case "$CURRENT_SHELL" in
    fish)
        FISH_CONFIG="$HOME/.config/fish/config.fish"
        ensure_directory "$(dirname "$FISH_CONFIG")"
        
        if ! grep -q "starship init fish" "$FISH_CONFIG" 2>/dev/null; then
            log_info "正在添加 Starship 初始化到 Fish 配置..."
            echo "" >> "$FISH_CONFIG"
            echo "# Starship 提示符设置" >> "$FISH_CONFIG"
            echo "if command -v starship > /dev/null" >> "$FISH_CONFIG"
            echo "    starship init fish | source" >> "$FISH_CONFIG"
            echo "end" >> "$FISH_CONFIG"
            log_success "✅ Fish 配置已更新"
        else
            log_info "Fish 配置中已存在 Starship 初始化"
        fi
        ;;
    bash)
        BASH_CONFIG="$HOME/.bashrc"
        if [ ! -f "$BASH_CONFIG" ]; then
            BASH_CONFIG="$HOME/.bash_profile"
        fi
        
        if [ -f "$BASH_CONFIG" ]; then
            if ! grep -q "starship init bash" "$BASH_CONFIG" 2>/dev/null; then
                log_info "正在添加 Starship 初始化到 Bash 配置..."
                echo "" >> "$BASH_CONFIG"
                echo "# Starship 提示符设置" >> "$BASH_CONFIG"
                echo 'eval "$(starship init bash)"' >> "$BASH_CONFIG"
                log_success "✅ Bash 配置已更新"
            else
                log_info "Bash 配置中已存在 Starship 初始化"
            fi
        fi
        ;;
    zsh)
        ZSH_CONFIG="$HOME/.zshrc"
        if [ -f "$ZSH_CONFIG" ]; then
            if ! grep -q "starship init zsh" "$ZSH_CONFIG" 2>/dev/null; then
                log_info "正在添加 Starship 初始化到 Zsh 配置..."
                echo "" >> "$ZSH_CONFIG"
                echo "# Starship 提示符设置" >> "$ZSH_CONFIG"
                echo 'eval "$(starship init zsh)"' >> "$ZSH_CONFIG"
                log_success "✅ Zsh 配置已更新"
            else
                log_info "Zsh 配置中已存在 Starship 初始化"
            fi
        fi
        ;;
    *)
        log_warning "未检测到支持的 Shell: $CURRENT_SHELL"
        log_info "请手动在您的 Shell 配置文件中添加以下内容："
        echo ""
        echo "  Fish:"
        echo "    starship init fish | source"
        echo ""
        echo "  Bash:"
        echo "    eval \"\$(starship init bash)\""
        echo ""
        echo "  Zsh:"
        echo "    eval \"\$(starship init zsh)\""
        ;;
esac

# ============================================
# 完成
# ============================================
echo ""
log_success "=========================================="
log_success "Starship 安装和配置完成！"
log_success "=========================================="
echo ""
log_info "下一步："
echo "  1. 重新启动终端或重新加载 Shell 配置"
echo "  2. 新的提示符将自动应用"
echo ""
log_info "配置文件位置: $STARSHIP_CONFIG_FILE"
log_info "如需自定义，请编辑: $STARSHIP_CONFIG_FILE"
echo ""

end_script "Starship 提示符安装"

