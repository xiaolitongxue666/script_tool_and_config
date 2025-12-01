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

    # 方法1: 检查 MSYS2 是否已安装并包含 zsh
    log_info "检查 MSYS2 是否已安装..."
    MSYS2_DIR=""
    for drive in /c /d /e; do
        for path in "$drive/msys64" "$drive/Program Files/msys64" "$drive/Program Files (x86)/msys64"; do
            if [ -d "$path" ] && [ -f "$path/usr/bin/pacman.exe" ]; then
                MSYS2_DIR="$path"
                log_success "找到 MSYS2: $MSYS2_DIR"
                break 2
            fi
        done
    done

    if [ -n "$MSYS2_DIR" ]; then
        # 检查 zsh 是否已安装在 MSYS2 中
        if [ -f "$MSYS2_DIR/usr/bin/zsh.exe" ]; then
            log_info "MSYS2 中已包含 zsh，配置 zsh 以在 Git Bash 中使用..."

            # 配置 zsh 以在 Git Bash 中使用
            configure_zsh_for_gitbash "$MSYS2_DIR"
            return $?
        else
            # 尝试通过 MSYS2 的 pacman 安装 zsh
            log_info "通过 MSYS2 pacman 安装 zsh..."
            if "$MSYS2_DIR/usr/bin/pacman.exe" -S --noconfirm zsh 2>&1; then
                log_success "zsh 安装成功"
                # 配置 zsh 以在 Git Bash 中使用
                configure_zsh_for_gitbash "$MSYS2_DIR"
                return $?
            else
                log_warning "通过 pacman 安装 zsh 失败"
            fi
        fi
    fi

    # 方法2: 尝试安装 MSYS2（如果未安装）
    log_info "尝试安装 MSYS2（包含 zsh）..."
    if winget install --id=MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements 2>&1; then
        log_success "MSYS2 安装成功"
        # 等待 MSYS2 安装完成
        sleep 3
        # 重新查找 MSYS2 目录
        for drive in /c /d /e; do
            for path in "$drive/msys64" "$drive/Program Files/msys64" "$drive/Program Files (x86)/msys64"; do
                if [ -d "$path" ] && [ -f "$path/usr/bin/zsh.exe" ]; then
                    MSYS2_DIR="$path"
                    log_success "找到新安装的 MSYS2: $MSYS2_DIR"
                    configure_zsh_for_gitbash "$MSYS2_DIR"
                    return $?
                fi
            done
        done
    fi

    # 方法3: 手动下载 zsh（如果上述方法失败）
    log_warning "自动安装失败，请手动安装 zsh"
    log_info "方法1: 从 MSYS2 仓库下载 zsh 包"
    log_info "方法2: 使用 Git Bash 自带的包管理器"
    return 1
}

# ============================================
# 配置 zsh 以在 Git Bash 中使用（Windows）
# ============================================
configure_zsh_for_gitbash() {
    local msys2_dir="$1"
    local msys2_bin="$msys2_dir/usr/bin"
    local git_bin="/usr/bin"

    if [ ! -d "$msys2_bin" ] || [ ! -f "$msys2_bin/zsh.exe" ]; then
        log_error "MSYS2 zsh 不存在: $msys2_bin/zsh.exe"
        return 1
    fi

    log_info "配置 zsh 以在 Git Bash 中使用..."

    # 1. 创建符号链接或复制 zsh
    if [ ! -f "$git_bin/zsh" ] && [ ! -L "$git_bin/zsh" ]; then
        log_info "创建 zsh 符号链接..."
        if ln -s "$msys2_bin/zsh.exe" "$git_bin/zsh" 2>/dev/null; then
            log_success "zsh 符号链接创建成功"
        else
            log_info "符号链接失败，尝试复制..."
            if cp "$msys2_bin/zsh.exe" "$git_bin/zsh" 2>/dev/null; then
                log_success "zsh 复制成功"
            else
                log_error "无法创建 zsh 链接或复制"
                return 1
            fi
        fi
    else
        log_info "zsh 已存在于 $git_bin"
    fi

    # 2. 复制依赖的 DLL 文件
    log_info "复制 zsh 依赖文件..."
    local deps=("msys-zsh-5.9.dll" "msys-ncursesw6.dll" "msys-readline8.dll")
    local deps_found=0
    for dep in "${deps[@]}"; do
        if [ -f "$msys2_bin/$dep" ]; then
            if [ ! -f "$git_bin/$dep" ]; then
                cp "$msys2_bin/$dep" "$git_bin/" 2>/dev/null && \
                    log_success "已复制: $dep" || \
                    log_warning "复制失败: $dep"
            fi
            deps_found=$((deps_found + 1))
        else
            # 尝试查找其他版本的 DLL
            local dep_pattern=$(echo "$dep" | sed 's/[0-9]/[0-9]/g')
            local found_dep=$(find "$msys2_bin" -name "$dep_pattern" 2>/dev/null | head -1)
            if [ -n "$found_dep" ]; then
                local dep_name=$(basename "$found_dep")
                if [ ! -f "$git_bin/$dep_name" ]; then
                    cp "$found_dep" "$git_bin/" 2>/dev/null && \
                        log_success "已复制: $dep_name" || \
                        log_warning "复制失败: $dep_name"
                fi
                deps_found=$((deps_found + 1))
            fi
        fi
    done

    if [ $deps_found -eq 0 ]; then
        log_warning "未找到 zsh 依赖文件，可能需要手动处理"
    fi

    # 3. 添加 MSYS2 到 PATH（在 Git Bash 配置中）
    log_info "配置 PATH 以包含 MSYS2..."
    local bash_profile="$HOME/.bash_profile"
    if [ -f "$bash_profile" ] && ! grep -q "$msys2_bin" "$bash_profile" 2>/dev/null; then
        echo "" >> "$bash_profile"
        echo "# 添加 MSYS2 zsh 到 PATH（由 zsh 安装脚本自动添加）" >> "$bash_profile"
        echo "export PATH=\"$msys2_bin:\$PATH\"" >> "$bash_profile"
        log_success "已添加 MSYS2 到 PATH"
    elif [ -f "$bash_profile" ]; then
        log_info "MSYS2 已在 PATH 中"
    fi

    # 4. 验证 zsh 是否可用
    export PATH="$msys2_bin:$PATH"
    if command -v zsh &> /dev/null; then
        local zsh_version=$(zsh --version 2>&1 | head -1)
        log_success "zsh 配置完成: $zsh_version"
        return 0
    else
        log_warning "zsh 配置完成，但当前会话中不可用，请重新打开终端"
        return 0
    fi
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
# 检测是否从 Git Bash 安装脚本调用（自动安装模式）
AUTO_INSTALL_OMZ="${AUTO_INSTALL_OMZ:-false}"
if [ "$AUTO_INSTALL_OMZ" == "true" ] || [ -n "$GIT_BASH_INSTALL_CALL" ]; then
    INSTALL_OMZ=true
    log_info "检测到自动安装模式，将自动安装 Oh My Zsh"
else
    echo ""
    read -p "是否安装 Oh My Zsh (OMZ)？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_OMZ=true
    else
        INSTALL_OMZ=false
    fi
fi

if [ "$INSTALL_OMZ" == "true" ]; then
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

        log_info "正在从 GitHub 下载 Oh My Zsh 安装脚本..."
        if sh -c "$(curl $curl_proxy -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc 2>&1; then
            log_success "Oh My Zsh 安装成功"
        else
            log_error "Oh My Zsh 安装失败"
            log_info "可能的原因："
            log_info "  1. 网络连接问题"
            log_info "  2. 代理设置不正确（当前代理: ${PROXY:-未设置}）"
            log_info "  3. GitHub 访问受限"
            log_info ""
            log_info "手动安装方法："
            log_info "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
            if [ "$PLATFORM" == "windows" ]; then
                log_info ""
                log_info "Windows 用户提示："
                log_info "  如果网络不通，请确保代理设置正确："
                log_info "    export http_proxy=http://127.0.0.1:7890"
                log_info "    export https_proxy=http://127.0.0.1:7890"
            fi
        fi
    fi
fi

# ============================================
# 同步配置文件
# ============================================
echo ""
log_info "同步配置文件..."

# 根据操作系统确定配置文件位置
determine_zshrc_path() {
    local zshrc_path=""

    if [[ "$PLATFORM" == "windows" ]]; then
        # Windows Git Bash 环境
        # Git Bash 中的 HOME 通常是 /c/Users/username 或 /home/username 格式
        # 优先使用 $HOME，如果不存在或无效，尝试从 $USERPROFILE 转换
        if [[ -n "$HOME" ]] && [[ -d "$HOME" ]]; then
            # HOME 存在且是有效目录，直接使用
            zshrc_path="$HOME/.zshrc"
        elif [[ -n "$USERPROFILE" ]]; then
            # 从 Windows 环境变量转换路径
            # C:\Users\username -> /c/Users/username
            local win_path="$USERPROFILE"
            # 替换反斜杠为正斜杠
            win_path=$(echo "$win_path" | sed 's|\\|/|g')
            # 转换盘符格式：C:/ -> /c/
            if [[ "$win_path" =~ ^([A-Za-z]):(.*)$ ]]; then
                local drive_letter=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
                local rest_path="${BASH_REMATCH[2]}"
                # 移除开头的斜杠（如果有）
                rest_path=$(echo "$rest_path" | sed 's|^/||')
                zshrc_path="/${drive_letter}/${rest_path}/.zshrc"
            else
                # 如果无法解析，使用 $HOME
                zshrc_path="$HOME/.zshrc"
            fi
        else
            # 最后回退到 $HOME
            zshrc_path="$HOME/.zshrc"
        fi
    elif [[ "$PLATFORM" == "macos" ]]; then
        # macOS 使用标准路径
        zshrc_path="$HOME/.zshrc"
    elif [[ "$PLATFORM" == "linux" ]]; then
        # Linux 使用标准路径
        zshrc_path="$HOME/.zshrc"
    else
        # 默认使用 $HOME/.zshrc
        zshrc_path="$HOME/.zshrc"
    fi

    echo "$zshrc_path"
}

ZSH_CONFIG_FILE=$(determine_zshrc_path)
ZSH_PROFILE_FILE="${ZSH_CONFIG_FILE%/.zshrc}/.zprofile"
log_info "Zsh 配置文件路径: $ZSH_CONFIG_FILE"
log_info "Zsh 登录配置文件路径: $ZSH_PROFILE_FILE"

# 检查统一配置文件是否存在
if [ ! -f "$SCRIPT_DIR/.zshrc" ]; then
    log_warning "未找到统一配置文件: $SCRIPT_DIR/.zshrc"
    log_info "将使用 Oh My Zsh 默认配置"
else
    # 备份现有配置（如果存在）
    for config_file in "$ZSH_CONFIG_FILE" "$ZSH_PROFILE_FILE"; do
        if [ -f "$config_file" ]; then
            BACKUP_FILE="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$config_file" "$BACKUP_FILE" 2>/dev/null || {
                log_warning "备份失败: $config_file，但将继续安装"
            }
            if [ -f "$BACKUP_FILE" ]; then
                log_success "已备份现有配置到: $BACKUP_FILE"
            fi
        fi
    done

    # 确保目标目录存在
    zshrc_dir=$(dirname "$ZSH_CONFIG_FILE")
    if [ ! -d "$zshrc_dir" ]; then
        mkdir -p "$zshrc_dir" 2>/dev/null || {
            log_error "无法创建配置目录: $zshrc_dir"
            exit 1
        }
        log_info "已创建配置目录: $zshrc_dir"
    fi

    # 复制 .zshrc 配置文件
    if cp "$SCRIPT_DIR/.zshrc" "$ZSH_CONFIG_FILE" 2>/dev/null; then
        log_success "已同步配置文件到: $ZSH_CONFIG_FILE"
    else
        log_error "复制配置文件失败"
        log_info "源文件: $SCRIPT_DIR/.zshrc"
        log_info "目标文件: $ZSH_CONFIG_FILE"
        exit 1
    fi

    # 复制 .zprofile 配置文件（登录 shell 环境变量配置）
    if [ -f "$SCRIPT_DIR/.zprofile" ]; then
        if cp "$SCRIPT_DIR/.zprofile" "$ZSH_PROFILE_FILE" 2>/dev/null; then
            log_success "已同步登录配置文件到: $ZSH_PROFILE_FILE"
            log_info "此文件确保所有登录方式（包括 SSH）都能正确加载环境变量"
        else
            log_warning "复制 .zprofile 配置文件失败，但继续安装"
            log_info "源文件: $SCRIPT_DIR/.zprofile"
            log_info "目标文件: $ZSH_PROFILE_FILE"
        fi
    else
        log_warning "未找到 .zprofile 配置文件: $SCRIPT_DIR/.zprofile"
        log_info "将跳过登录配置文件安装"
    fi
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
# 安装后验证
# ============================================
echo ""
log_info "验证安装结果..."

VERIFICATION_PASSED=true

# 验证 zsh 是否可执行
if command -v zsh &> /dev/null; then
    ZSH_VERSION_OUTPUT=$(zsh --version 2>/dev/null || echo "未知版本")
    log_success "Zsh 已安装: $ZSH_VERSION_OUTPUT"
else
    log_error "Zsh 未安装或不在 PATH 中"
    VERIFICATION_PASSED=false
fi

# 验证 oh-my-zsh（如果已安装）
if [ "$INSTALL_OMZ" == "true" ] || [ -d "$HOME/.oh-my-zsh" ]; then
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh 已安装: $HOME/.oh-my-zsh"
    else
        log_warning "Oh My Zsh 未安装（可能安装失败）"
        VERIFICATION_PASSED=false
    fi
fi

# 验证配置文件
if [ -f "$ZSH_CONFIG_FILE" ]; then
    log_success "Zsh 配置文件已存在: $ZSH_CONFIG_FILE"
else
    log_warning "Zsh 配置文件不存在: $ZSH_CONFIG_FILE"
    VERIFICATION_PASSED=false
fi

# 验证 .zprofile 配置文件
if [ -f "$ZSH_PROFILE_FILE" ]; then
    log_success "Zsh 登录配置文件已存在: $ZSH_PROFILE_FILE"
    log_info "此文件确保所有登录方式（包括 SSH）都能正确加载环境变量"
else
    log_warning "Zsh 登录配置文件不存在: $ZSH_PROFILE_FILE"
    log_info "SSH 登录时可能无法正确加载环境变量（如 fnm、uv 等）"
    VERIFICATION_PASSED=false
fi

# ============================================
# 安装完成
# ============================================
end_script

if [ "$VERIFICATION_PASSED" == "true" ]; then
    log_success "Zsh 安装和配置完成！"
else
    log_warning "安装完成，但部分验证未通过，请检查上述信息"
fi

echo ""
echo "配置文件位置: $ZSH_CONFIG_FILE"
echo "重新加载配置: source $ZSH_CONFIG_FILE"
echo "或重新打开终端"
if [ "$PLATFORM" == "windows" ]; then
    echo ""
    echo "Windows Git Bash 使用提示："
    echo "  如果 zsh 未自动启动，请在 ~/.bash_profile 或 ~/.bashrc 中添加："
    echo "    [ -t 1 ] && exec zsh"
    echo ""
    if [ "$VERIFICATION_PASSED" == "true" ]; then
        echo "启动流程："
        echo "  1. 打开 Alacritty"
        echo "  2. Alacritty 自动启动 Git Bash"
        echo "  3. Git Bash 自动切换到 Zsh"
        echo "  4. Zsh 加载 Oh My Zsh 配置"
    fi
fi

