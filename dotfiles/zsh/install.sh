#!/bin/bash

# Zsh 安装脚本
# 支持 macOS、Linux、Windows Git Bash 系统

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

start_script "Zsh 安装脚本"

log_info "检测到操作系统: $OS"
echo ""

# ============================================
# 代理设置（可选）
# ============================================
# 检测环境变量中的代理设置，默认使用 localhost:7890
PROXY="${http_proxy:-${https_proxy:-http://127.0.0.1:7890}}"
if [ -n "$PROXY" ]; then
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    log_info "使用代理: $PROXY"
fi

# ============================================
# 检测操作系统
# ============================================
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
    if command -v brew &> /dev/null; then
        INSTALL_CMD="brew install zsh"
    else
        log_info "注意: macOS 通常已预装 Zsh"
        INSTALL_CMD=""
    fi
    ZSH_PATH="/bin/zsh"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
    if command -v pacman &> /dev/null; then
        INSTALL_CMD="sudo pacman -S --noconfirm zsh"
    elif command -v apt-get &> /dev/null; then
        INSTALL_CMD="sudo apt-get install -y zsh"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="sudo yum install -y zsh"
    else
        log_error "未检测到支持的包管理器"
        exit 1
    fi
    ZSH_PATH="/usr/bin/zsh"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
    # Windows Git Bash 环境
    # 检测 winget
    if command -v winget &> /dev/null; then
        log_info "检测到 winget，将使用 winget 安装 zsh"
        INSTALL_CMD="winget_install_zsh"
    else
        log_error "未找到 winget，请先安装 Windows Package Manager"
        log_info "安装方法: 从 Microsoft Store 安装 'App Installer'"
        exit 1
    fi
    # Git Bash 中 zsh 通常安装在 /usr/bin/zsh
    ZSH_PATH="/usr/bin/zsh"
else
    log_error "不支持的操作系统: $OS"
    exit 1
fi

# ============================================
# Windows winget 安装函数
# ============================================
winget_install_zsh() {
    log_info "使用 winget 安装 zsh..."
    
    # 方法1: 尝试安装 MSYS2（包含 zsh）
    log_info "尝试安装 MSYS2（包含 zsh）..."
    if winget install --id=MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements 2>&1; then
        log_success "MSYS2 安装成功"
        # 等待 MSYS2 安装完成
        sleep 2
        # 检查 zsh 是否可用
        if command -v zsh &> /dev/null; then
            log_success "zsh 已可用"
            return 0
        fi
    fi
    
    # 方法2: 如果 MSYS2 已安装，尝试通过 pacman 安装 zsh
    if [ -f "/usr/bin/pacman" ]; then
        log_info "检测到 MSYS2，尝试通过 pacman 安装 zsh..."
        if pacman -S --noconfirm zsh 2>&1; then
            log_success "zsh 安装成功"
            return 0
        fi
    fi
    
    # 方法3: 手动下载 zsh（如果上述方法失败）
    log_warning "自动安装失败，请手动安装 zsh"
    log_info "方法1: 从 MSYS2 仓库下载 zsh 包"
    log_info "方法2: 使用 Git Bash 自带的包管理器"
    return 1
}

# ============================================
# 检查并安装 Zsh
# ============================================
if command -v zsh &> /dev/null; then
    log_success "Zsh 已安装: $(which zsh)"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        SKIP_INSTALL=true
    fi
fi

# 安装 Zsh
if [ "$SKIP_INSTALL" != "true" ] && [ -n "$INSTALL_CMD" ]; then
    log_info "正在安装 Zsh..."
    if [ "$INSTALL_CMD" == "winget_install_zsh" ]; then
        winget_install_zsh
    else
        eval "$INSTALL_CMD"
    fi
fi

# ============================================
# 安装 Oh My Zsh
# ============================================
echo ""
read -p "是否安装 Oh My Zsh (OMZ)？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "正在安装 Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh 已存在，跳过安装"
    else
        # 使用代理安装（如果设置了代理）
        if [ -n "$PROXY" ]; then
            log_info "使用代理安装 Oh My Zsh: $PROXY"
            curl_proxy="-x $PROXY"
        else
            curl_proxy=""
        fi
        
        if sh -c "$(curl $curl_proxy -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_success "Oh My Zsh 安装成功"
        else
            log_warning "Oh My Zsh 安装失败，请检查网络连接或代理设置"
        fi
    fi
fi

# ============================================
# 同步配置文件
# ============================================
echo ""
log_info "同步配置文件..."
ZSH_CONFIG_FILE="$HOME/.zshrc"

# 检查统一配置文件是否存在
if [ ! -f "$SCRIPT_DIR/.zshrc" ]; then
    log_warning "未找到统一配置文件: $SCRIPT_DIR/.zshrc"
    log_info "将使用 Oh My Zsh 默认配置"
else
    # 备份现有配置（如果存在）
    if [ -f "$ZSH_CONFIG_FILE" ]; then
        BACKUP_FILE="${ZSH_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ZSH_CONFIG_FILE" "$BACKUP_FILE"
        log_success "已备份现有配置到: $BACKUP_FILE"
    fi

    # 复制统一配置文件
    cp "$SCRIPT_DIR/.zshrc" "$ZSH_CONFIG_FILE"
    log_success "已同步配置文件到: $ZSH_CONFIG_FILE"
fi

# ============================================
# 设置 Zsh 为默认 Shell
# ============================================
echo ""
read -p "是否将 Zsh 设置为默认 Shell？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$ZSH_PATH" ]; then
        if chsh -s "$ZSH_PATH" 2>/dev/null; then
            log_success "已将 Zsh 设置为默认 Shell"
        else
            log_warning "chsh 命令失败，可能需要手动设置"
            if [ "$PLATFORM" == "windows" ]; then
                log_info "Windows Git Bash 设置方法："
                log_info "  在 ~/.bash_profile 或 ~/.bashrc 中添加："
                log_info "    [ -t 1 ] && exec zsh"
            fi
        fi
    else
        ZSH_ACTUAL_PATH=$(which zsh 2>/dev/null)
        if [ -n "$ZSH_ACTUAL_PATH" ]; then
            if chsh -s "$ZSH_ACTUAL_PATH" 2>/dev/null; then
                log_success "已将 Zsh 设置为默认 Shell: $ZSH_ACTUAL_PATH"
            else
                log_warning "chsh 命令失败，可能需要手动设置"
            fi
        else
            log_warning "未找到 Zsh 可执行文件"
        fi
    fi
fi

# ============================================
# 检测和安装 Nerd Fonts（Windows）
# ============================================
if [ "$PLATFORM" == "windows" ]; then
    echo ""
    log_info "检查 Nerd Fonts..."
    
    # 检测常见 Nerd Fonts
    NERD_FONTS_INSTALLED=false
    if [ -d "/c/Windows/Fonts" ]; then
        # 检查是否已安装 Nerd Fonts（通过检查字体文件）
        for font in "FiraCode" "Meslo" "CascadiaCode" "JetBrainsMono"; do
            if find /c/Windows/Fonts -name "*${font}*Nerd*" -o -name "*${font}*NF*" 2>/dev/null | grep -q .; then
                NERD_FONTS_INSTALLED=true
                log_success "检测到 Nerd Fonts: $font"
                break
            fi
        done
    fi
    
    if [ "$NERD_FONTS_INSTALLED" == "false" ]; then
        log_warning "未检测到 Nerd Fonts"
        read -p "是否使用 winget 安装 Nerd Fonts？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "正在安装 Nerd Fonts (Cascadia Code)..."
            if winget install --id=CascadiaCode.NerdFont -e --accept-source-agreements --accept-package-agreements 2>&1; then
                log_success "Nerd Fonts 安装成功"
            else
                log_warning "Nerd Fonts 安装失败，请手动安装"
                log_info "手动安装方法："
                log_info "  1. 访问 https://www.nerdfonts.com/font-downloads"
                log_info "  2. 下载并安装字体（推荐: Cascadia Code, Fira Code, Meslo）"
                log_info "  3. 在终端设置中选择安装的字体"
            fi
        else
            log_info "跳过 Nerd Fonts 安装"
            log_info "提示: agnoster 主题需要 Nerd Fonts 才能正确显示图标"
        fi
    fi
fi

# ============================================
# 安装完成
# ============================================
end_script

log_success "Zsh 安装和配置完成！"
echo ""
echo "配置文件位置: $ZSH_CONFIG_FILE"
echo "重新加载配置: source $ZSH_CONFIG_FILE"
echo "或重新打开终端"
if [ "$PLATFORM" == "windows" ]; then
    echo ""
    echo "Windows Git Bash 使用提示："
    echo "  如果 zsh 未自动启动，请在 ~/.bash_profile 或 ~/.bashrc 中添加："
    echo "    [ -t 1 ] && exec zsh"
fi

