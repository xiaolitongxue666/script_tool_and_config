#!/bin/bash

# Alacritty 终端模拟器安装脚本
# 支持 macOS、Windows 系统
# 参考：https://github.com/alacritty/alacritty
# 官方安装文档：https://github.com/alacritty/alacritty/blob/master/INSTALL.md

set -e

# 加载通用脚本函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../../scripts/common.sh" ]; then
    source "$SCRIPT_DIR/../../scripts/common.sh"
else
    # 如果没有 common.sh，定义基本函数
    function log_info() { echo "[信息] $*"; }
    function log_success() { echo "[成功] $*"; }
    function log_warning() { echo "[警告] $*"; }
    function log_error() { echo "[错误] $*" >&2; }
fi

# 检测操作系统
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
else
    log_error "不支持的操作系统: $OS"
    exit 1
fi

start_script "Alacritty 安装脚本 ($PLATFORM)"

# ============================================
# 代理设置（可选）
# ============================================
# 如果网络不通，可以通过环境变量设置代理
# export http_proxy=http://127.0.0.1:7890
# export https_proxy=http://127.0.0.1:7890

# 检查并设置代理
if [ -n "$http_proxy" ] || [ -n "$https_proxy" ]; then
    export HTTP_PROXY="${http_proxy:-$HTTP_PROXY}"
    export HTTPS_PROXY="${https_proxy:-$HTTPS_PROXY}"
    log_info "使用代理: $HTTP_PROXY"
fi

# ============================================
# 检查并删除旧版本
# ============================================
log_info "检查已安装的 Alacritty..."

if [ "$PLATFORM" == "macos" ]; then
    # macOS: 检查 Applications 目录中的旧版本
    if [ -d "/Applications/Alacritty.app" ]; then
        OLD_VERSION=$(/Applications/Alacritty.app/Contents/MacOS/alacritty --version 2>/dev/null | head -1 || echo "未知版本")
        log_warning "检测到已安装的 Alacritty: $OLD_VERSION"
        
        # 备份旧版本
        BACKUP_NAME="Alacritty.app.backup.$(date +%Y%m%d_%H%M%S)"
        if [ -d "/Applications/$BACKUP_NAME" ]; then
            rm -rf "/Applications/$BACKUP_NAME"
        fi
        mv "/Applications/Alacritty.app" "/Applications/$BACKUP_NAME" 2>/dev/null && \
            log_info "已备份旧版本到: $BACKUP_NAME" || \
            log_warning "无法备份旧版本，可能正在使用中"
    fi
elif [ "$PLATFORM" == "windows" ]; then
    # Windows: 检查是否已安装
    if command -v alacritty.exe &> /dev/null; then
        OLD_VERSION=$(alacritty.exe --version 2>/dev/null | head -1 || echo "未知版本")
        log_warning "检测到已安装的 Alacritty: $OLD_VERSION"
        read -p "是否卸载旧版本？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command -v winget &> /dev/null; then
                winget uninstall --id=Alacritty.Alacritty -e 2>/dev/null || log_warning "卸载失败，请手动卸载"
            fi
        fi
    fi
fi

# 检查并处理 terminfo 文件冲突
# Terminfo 文件说明：
# - 作用：终端信息数据库，用于描述终端的特性和功能
# - 位置：~/.terminfo/61/alacritty (用户目录) 或系统目录
# - 权限问题：旧版本可能以 root 权限安装，导致新版本无法覆盖
# - 影响：如果不处理，brew 安装会失败，但手动安装不受影响
if [ -f "$HOME/.terminfo/61/alacritty" ]; then
    log_info "检测到 terminfo 文件: $HOME/.terminfo/61/alacritty"
    FILE_OWNER=$(stat -f "%Su" "$HOME/.terminfo/61/alacritty" 2>/dev/null || echo "unknown")
    if [ "$FILE_OWNER" = "root" ]; then
        log_warning "terminfo 文件属于 root，可能需要 sudo 权限删除"
        log_info "如果 brew 安装失败，将使用手动安装方式"
    fi
fi

# ============================================
# 安装方法选择
# ============================================
INSTALL_METHOD=""

if [ "$PLATFORM" == "macos" ]; then
    # macOS: 使用 Homebrew 安装
    if command -v brew &> /dev/null; then
        log_info "检测到 Homebrew，尝试使用 Homebrew 安装（推荐）..."
        
        # 尝试通过 brew 安装
        if [ -z "$INSTALL_METHOD" ]; then
            log_info "执行: brew install --cask alacritty"
            if brew install --cask alacritty 2>&1 | tee /tmp/brew_install.log; then
                INSTALL_METHOD="homebrew"
                log_success "通过 Homebrew 安装成功"
            else
                # 检查是否是 terminfo 冲突
                if grep -q "terminfo" /tmp/brew_install.log; then
                    log_warning "Homebrew 安装失败：terminfo 文件冲突"
                    log_info "将使用手动安装方式（DMG 下载）"
                else
                    log_warning "Homebrew 安装失败，将尝试其他方法"
                fi
            fi
        fi
    fi
elif [ "$PLATFORM" == "windows" ]; then
    # Windows: 使用 winget 安装
    if command -v winget &> /dev/null; then
        # 检查是否已安装
        if winget list --id=Alacritty.Alacritty 2>/dev/null | grep -q "Alacritty"; then
            INSTALLED_VERSION=$(winget list --id=Alacritty.Alacritty 2>/dev/null | grep "Alacritty" | awk '{print $3}' || echo "未知")
            log_success "检测到已安装的 Alacritty: $INSTALLED_VERSION"
            INSTALL_METHOD="winget"
            SKIP_INSTALL=true
        else
            log_info "检测到 winget，尝试使用 winget 安装（推荐）..."
            
            # 检测代理设置
            PROXY="${http_proxy:-${https_proxy:-http://127.0.0.1:7890}}"
            if [ -n "$PROXY" ]; then
                export http_proxy="$PROXY"
                export https_proxy="$PROXY"
                export HTTP_PROXY="$PROXY"
                export HTTPS_PROXY="$PROXY"
                log_info "使用代理: $PROXY"
            fi
            
            log_info "执行: winget install --id=Alacritty.Alacritty -e"
            if winget install --id=Alacritty.Alacritty -e --accept-source-agreements --accept-package-agreements 2>&1; then
                INSTALL_METHOD="winget"
                log_success "通过 winget 安装成功"
            else
                # 检查是否是"已安装"或"无更新"的错误
                if winget list --id=Alacritty.Alacritty 2>/dev/null | grep -q "Alacritty"; then
                    INSTALLED_VERSION=$(winget list --id=Alacritty.Alacritty 2>/dev/null | grep "Alacritty" | awk '{print $3}' || echo "未知")
                    log_success "Alacritty 已安装: $INSTALLED_VERSION"
                    INSTALL_METHOD="winget"
                    SKIP_INSTALL=true
                else
                    log_warning "winget 安装失败，将尝试手动安装方式"
                fi
            fi
        fi
    else
        log_error "未找到 winget，请先安装 Windows Package Manager"
        log_info "安装方法: 从 Microsoft Store 安装 'App Installer'"
        log_info "或访问: https://aka.ms/getwinget"
        exit 1
    fi
fi

# ============================================
# 手动安装（如果自动安装失败）
# ============================================
if [ "$INSTALL_METHOD" != "homebrew" ] && [ "$INSTALL_METHOD" != "winget" ] && [ "$SKIP_INSTALL" != "true" ]; then
    if [ "$PLATFORM" == "macos" ]; then
        log_info "使用手动安装方式（下载 DMG 文件）..."
        
        # 获取最新版本号（从 GitHub API）
        ALACRITTY_VERSION="v0.16.1"  # 默认版本，可以从 API 获取最新版本
        DMG_URL="https://github.com/alacritty/alacritty/releases/download/${ALACRITTY_VERSION}/Alacritty-${ALACRITTY_VERSION}.dmg"
        DMG_FILE="/tmp/Alacritty-${ALACRITTY_VERSION}.dmg"
        
        log_info "下载 Alacritty ${ALACRITTY_VERSION}..."
        if curl -L -f -o "$DMG_FILE" "$DMG_URL" 2>/dev/null; then
            log_success "下载完成: $(du -h "$DMG_FILE" | cut -f1)"
            
            # 挂载 DMG
            log_info "挂载 DMG 文件..."
            hdiutil attach "$DMG_FILE" -quiet -nobrowse
            
            # 查找挂载的卷名
            VOLUME_NAME=$(ls /Volumes/ | grep -i alacritty | head -1)
            if [ -n "$VOLUME_NAME" ] && [ -d "/Volumes/$VOLUME_NAME/Alacritty.app" ]; then
                log_info "找到安装包: /Volumes/$VOLUME_NAME/Alacritty.app"
                
                # 复制应用到 Applications
                log_info "安装到 /Applications..."
                cp -R "/Volumes/$VOLUME_NAME/Alacritty.app" /Applications/
                
                # 卸载 DMG
                hdiutil detach "/Volumes/$VOLUME_NAME" -quiet
                
                # 验证安装
                if [ -d "/Applications/Alacritty.app" ]; then
                    INSTALLED_VERSION=$(/Applications/Alacritty.app/Contents/MacOS/alacritty --version 2>/dev/null | head -1 || echo "未知")
                    log_success "安装成功: $INSTALLED_VERSION"
                    INSTALL_METHOD="manual"
                else
                    log_error "安装失败：应用未正确复制"
                    exit 1
                fi
            else
                log_error "无法找到安装包"
                hdiutil detach "/Volumes/$VOLUME_NAME" -quiet 2>/dev/null
                exit 1
            fi
            
            # 清理临时文件
            rm -f "$DMG_FILE"
        else
            log_error "下载失败，请检查网络连接或代理设置"
            log_info "提示：如果网络不通，可以设置代理："
            log_info "  export http_proxy=http://127.0.0.1:7890"
            log_info "  export https_proxy=http://127.0.0.1:7890"
            exit 1
        fi
    elif [ "$PLATFORM" == "windows" ]; then
        log_info "使用手动安装方式（下载 exe 安装程序）..."
        
        # 获取最新版本号
        ALACRITTY_VERSION="v0.16.1"  # 默认版本
        EXE_URL="https://github.com/alacritty/alacritty/releases/download/${ALACRITTY_VERSION}/Alacritty-${ALACRITTY_VERSION}-installer.exe"
        EXE_FILE="/tmp/Alacritty-${ALACRITTY_VERSION}-installer.exe"
        
        # 检测代理设置
        PROXY="${http_proxy:-${https_proxy:-http://127.0.0.1:7890}}"
        CURL_PROXY=""
        if [ -n "$PROXY" ]; then
            CURL_PROXY="-x $PROXY"
            log_info "使用代理下载: $PROXY"
        fi
        
        log_info "下载 Alacritty ${ALACRITTY_VERSION}..."
        if curl $CURL_PROXY -L -f -o "$EXE_FILE" "$EXE_URL" 2>/dev/null; then
            log_success "下载完成"
            log_info "请手动运行安装程序: $EXE_FILE"
            log_info "或双击下载的文件进行安装"
            INSTALL_METHOD="manual"
        else
            log_error "下载失败，请检查网络连接或代理设置"
            log_info "提示：如果网络不通，可以设置代理："
            log_info "  export http_proxy=http://127.0.0.1:7890"
            log_info "  export https_proxy=http://127.0.0.1:7890"
            log_info "或从 GitHub Releases 手动下载: https://github.com/alacritty/alacritty/releases"
            exit 1
        fi
    fi
fi

# ============================================
# 安装 Terminfo（可选但推荐，仅 macOS/Linux）
# ============================================
# Terminfo 说明：
# - 作用：终端信息数据库，描述终端的特性和功能（如颜色支持、光标移动等）
# - 位置：系统目录 (/usr/share/terminfo) 或用户目录 (~/.terminfo)
# - 权限问题：旧版本可能以 root 权限安装到用户目录，导致新版本无法覆盖
# - 影响：如果不安装，某些程序可能无法正确识别 Alacritty 终端类型
# - 解决方案：通常 Homebrew 会自动处理，手动安装时可选
# - Windows: 不需要安装 terminfo

if [ "$PLATFORM" != "windows" ]; then
    log_info "检查 Terminfo 安装..."
    
    # 检查是否已安装 terminfo
    if command -v infocmp &> /dev/null; then
        if infocmp alacritty &> /dev/null; then
            log_success "Terminfo 已安装"
        else
            log_info "Terminfo 未安装，尝试安装..."
            
            # 尝试从已安装的 Alacritty 获取 terminfo
            if [ "$PLATFORM" == "macos" ] && [ -f "/Applications/Alacritty.app/Contents/Resources/alacritty.info" ]; then
                log_info "找到 alacritty.info 文件，安装 Terminfo..."
                if sudo tic -xe alacritty,alacritty-direct /Applications/Alacritty.app/Contents/Resources/alacritty.info 2>/dev/null; then
                    log_success "Terminfo 安装成功"
                else
                    log_warning "Terminfo 安装失败（可能需要 sudo 权限）"
                    log_info "可以稍后手动安装: sudo tic -xe alacritty,alacritty-direct /Applications/Alacritty.app/Contents/Resources/alacritty.info"
                fi
            else
                log_warning "未找到 alacritty.info 文件，跳过 Terminfo 安装"
                log_info "这通常不影响 Alacritty 的正常使用"
            fi
        fi
    else
        log_warning "未找到 infocmp 命令，跳过 Terminfo 检查"
    fi
fi

# 安装 Shell 自动补全
echo ""
echo "正在安装 Shell 自动补全..."

# Fish Shell 自动补全
if command -v fish &> /dev/null; then
    echo "安装 Fish Shell 自动补全..."
    FISH_COMPLETE_DIR="$HOME/.config/fish/completions"
    mkdir -p "$FISH_COMPLETE_DIR"
    
    # 尝试从不同位置复制补全文件
    if [ -f "/Applications/Alacritty.app/Contents/Resources/completions/alacritty.fish" ]; then
        cp /Applications/Alacritty.app/Contents/Resources/completions/alacritty.fish "$FISH_COMPLETE_DIR/"
    elif [ -f "/usr/local/share/fish/vendor_completions.d/alacritty.fish" ]; then
        cp /usr/local/share/fish/vendor_completions.d/alacritty.fish "$FISH_COMPLETE_DIR/"
    else
        echo "警告: 未找到 Fish 补全文件"
    fi
fi

# Zsh 自动补全
if command -v zsh &> /dev/null; then
    echo "安装 Zsh 自动补全..."
    ZSH_COMPLETE_DIR="$HOME/.zsh/completions"
    mkdir -p "$ZSH_COMPLETE_DIR"
    
    if [ -f "/Applications/Alacritty.app/Contents/Resources/completions/_alacritty" ]; then
        cp /Applications/Alacritty.app/Contents/Resources/completions/_alacritty "$ZSH_COMPLETE_DIR/"
        # 添加到 .zshrc
        if ! grep -q "fpath.*zsh/completions" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# Alacritty completions" >> "$HOME/.zshrc"
            echo "fpath=(\$HOME/.zsh/completions \$fpath)" >> "$HOME/.zshrc"
        fi
    fi
fi

# Bash 自动补全
if command -v bash &> /dev/null; then
    echo "安装 Bash 自动补全..."
    BASH_COMPLETE_DIR="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$BASH_COMPLETE_DIR"
    
    if [ -f "/Applications/Alacritty.app/Contents/Resources/completions/alacritty.bash" ]; then
        cp /Applications/Alacritty.app/Contents/Resources/completions/alacritty.bash "$BASH_COMPLETE_DIR/"
    fi
fi

# ============================================
# 安装配置文件（可选）
# ============================================
log_info "检查配置文件..."

# 确定配置文件目录
if [ "$PLATFORM" == "windows" ]; then
    # Windows: 使用 %APPDATA%\alacritty
    CONFIG_DIR="$APPDATA/alacritty"
    if [ -z "$CONFIG_DIR" ]; then
        # 如果 APPDATA 未设置，使用默认路径
        CONFIG_DIR="$HOME/AppData/Roaming/alacritty"
    fi
else
    # macOS/Linux: 使用 ~/.config/alacritty
    CONFIG_DIR="$HOME/.config/alacritty"
fi

CONFIG_FILE="$CONFIG_DIR/alacritty.toml"
SOURCE_CONFIG="$SCRIPT_DIR/alacritty.toml"

if [ -f "$SOURCE_CONFIG" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "复制配置文件..."
        mkdir -p "$CONFIG_DIR"
        cp "$SOURCE_CONFIG" "$CONFIG_FILE"
        
        # Windows: 配置 Git Bash 作为 shell
        if [ "$PLATFORM" == "windows" ]; then
            log_info "配置 Windows 特定的 shell 设置..."
            # 检测 Git Bash 路径
            GIT_BASH_PATH=""
            if command -v bash.exe &> /dev/null; then
                GIT_BASH_PATH=$(where.exe bash.exe 2>/dev/null | head -1 | tr -d '\r')
            fi
            
            # 常见的 Git Bash 路径
            if [ -z "$GIT_BASH_PATH" ]; then
                for path in \
                    "C:\\Program Files\\Git\\usr\\bin\\bash.exe" \
                    "C:\\Program Files\\Git\\bin\\bash.exe" \
                    "D:\\Program Files\\Git\\usr\\bin\\bash.exe" \
                    "D:\\Program Files\\Git\\bin\\bash.exe"; do
                    if [ -f "$path" ]; then
                        GIT_BASH_PATH="$path"
                        break
                    fi
                done
            fi
            
            if [ -n "$GIT_BASH_PATH" ]; then
                log_success "检测到 Git Bash: $GIT_BASH_PATH"
                # 转义路径中的反斜杠（TOML 需要双反斜杠）
                ESCAPED_PATH=$(echo "$GIT_BASH_PATH" | sed 's|\\|\\\\|g')
                
                # 迁移旧的 [shell] 配置到 [terminal.shell]（如果存在）
                if grep -q "^\[shell\]" "$CONFIG_FILE"; then
                    log_info "检测到旧的 [shell] 配置，迁移到 [terminal.shell]..."
                    sed -i 's|^\[shell\]|[terminal.shell]|g' "$CONFIG_FILE"
                fi
                
                # 检查配置文件中是否已有 [terminal.shell] 配置
                if grep -q "^\[terminal.shell\]" "$CONFIG_FILE"; then
                    # 如果已有配置，更新它
                    if grep -q "^  program" "$CONFIG_FILE"; then
                        # 更新现有的 program
                        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw" ]]; then
                            # Git Bash 环境，使用 sed
                            # TOML 只支持双引号字符串，路径中的反斜杠需要转义
                            sed -i "s|^  program = .*|  program = \"$ESCAPED_PATH\"|" "$CONFIG_FILE"
                            sed -i "s|^  args = .*|  args = [\"--login\"]|" "$CONFIG_FILE"
                        else
                            # 其他环境，可能需要不同的处理
                            log_warning "无法自动更新配置文件，请手动编辑: $CONFIG_FILE"
                            log_info "添加以下配置到 [terminal.shell] 部分："
                            log_info "  program = \"$ESCAPED_PATH\""
                            log_info "  args = [\"--login\"]"
                        fi
                    else
                        # 添加 program 和 args
                        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw" ]]; then
                            # TOML 只支持双引号字符串，路径中的反斜杠需要转义
                            sed -i "/^\[terminal.shell\]/a\\  program = \"$ESCAPED_PATH\"\n  args = [\"--login\"]" "$CONFIG_FILE"
                        else
                            log_warning "无法自动更新配置文件，请手动编辑: $CONFIG_FILE"
                        fi
                    fi
                else
                    # 添加新的 [terminal.shell] 配置
                    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw" ]]; then
                        # 在注释后添加配置，TOML 只支持双引号字符串
                        sed -i "/^# \[terminal.shell\]/a\\[terminal.shell]\n  program = \"$ESCAPED_PATH\"\n  args = [\"--login\"]" "$CONFIG_FILE"
                    else
                        log_warning "无法自动更新配置文件，请手动编辑: $CONFIG_FILE"
                        log_info "添加以下配置："
                        log_info "[terminal.shell]"
                        log_info "  program = \"$ESCAPED_PATH\""
                        log_info "  args = [\"--login\"]"
                    fi
                fi
                log_success "已配置 Git Bash 作为 Alacritty 的默认 shell"
            else
                log_warning "未找到 Git Bash，请手动配置 shell"
                log_info "在 $CONFIG_FILE 中添加："
                log_info "[terminal.shell]"
                log_info "  program = \"C:\\\\Program Files\\\\Git\\\\usr\\\\bin\\\\bash.exe\""
                log_info "  args = [\"--login\"]"
            fi
        fi
        
        log_success "配置文件已复制到: $CONFIG_FILE"
    else
        log_info "配置文件已存在: $CONFIG_FILE"
        read -p "是否覆盖现有配置文件？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 备份现有配置
            BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CONFIG_FILE" "$BACKUP_FILE"
            log_info "已备份现有配置到: $BACKUP_FILE"
            cp "$SOURCE_CONFIG" "$CONFIG_FILE"
            
            # Windows: 重新配置 Git Bash
            if [ "$PLATFORM" == "windows" ]; then
                # 检测 Git Bash 路径并配置（同上）
                GIT_BASH_PATH=""
                if command -v bash.exe &> /dev/null; then
                    GIT_BASH_PATH=$(where.exe bash.exe 2>/dev/null | head -1 | tr -d '\r')
                fi
                
                if [ -z "$GIT_BASH_PATH" ]; then
                    for path in \
                        "C:\\Program Files\\Git\\usr\\bin\\bash.exe" \
                        "C:\\Program Files\\Git\\bin\\bash.exe" \
                        "D:\\Program Files\\Git\\usr\\bin\\bash.exe" \
                        "D:\\Program Files\\Git\\bin\\bash.exe"; do
                        if [ -f "$path" ]; then
                            GIT_BASH_PATH="$path"
                            break
                        fi
                    done
                fi
                
                if [ -n "$GIT_BASH_PATH" ]; then
                    # 转义路径中的反斜杠（TOML 需要双反斜杠）
                    ESCAPED_PATH=$(echo "$GIT_BASH_PATH" | sed 's|\\|\\\\|g')
                    # 迁移旧的 [shell] 配置到 [terminal.shell]（如果存在）
                    if grep -q "^\[shell\]" "$CONFIG_FILE"; then
                        sed -i 's|^\[shell\]|[terminal.shell]|g' "$CONFIG_FILE"
                    fi
                    if grep -q "^\[terminal.shell\]" "$CONFIG_FILE"; then
                        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw" ]]; then
                            # TOML 只支持双引号字符串，路径中的反斜杠需要转义
                            sed -i "s|^  program = .*|  program = \"$ESCAPED_PATH\"|" "$CONFIG_FILE"
                            sed -i "s|^  args = .*|  args = [\"--login\"]|" "$CONFIG_FILE"
                        fi
                    else
                        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw" ]]; then
                            sed -i "/^# \[terminal.shell\]/a\\[terminal.shell]\n  program = \"$ESCAPED_PATH\"\n  args = [\"--login\"]" "$CONFIG_FILE"
                        fi
                    fi
                    log_success "已重新配置 Git Bash"
                fi
            fi
            
            log_success "配置文件已更新: $CONFIG_FILE"
        else
            log_info "跳过配置文件更新"
        fi
    fi
else
    log_warning "未找到源配置文件: $SOURCE_CONFIG"
fi

# ============================================
# 安装完成
# ============================================
end_script

echo ""
log_success "Alacritty 安装完成！"
echo ""
echo "安装信息："
echo "  - 安装方法: $INSTALL_METHOD"
if [ "$PLATFORM" == "macos" ] && [ -d "/Applications/Alacritty.app" ]; then
    INSTALLED_VERSION=$(/Applications/Alacritty.app/Contents/MacOS/alacritty --version 2>/dev/null | head -1 || echo "未知")
    echo "  - 版本: $INSTALLED_VERSION"
    echo "  - 位置: /Applications/Alacritty.app"
elif [ "$PLATFORM" == "windows" ] && command -v alacritty.exe &> /dev/null; then
    INSTALLED_VERSION=$(alacritty.exe --version 2>/dev/null | head -1 || echo "未知")
    echo "  - 版本: $INSTALLED_VERSION"
fi
echo ""
if [ "$PLATFORM" == "windows" ]; then
    echo "配置文件位置："
    echo "  - %APPDATA%\\alacritty\\alacritty.toml (推荐)"
    echo ""
    echo "启动方式："
    echo "  从开始菜单搜索 'Alacritty' 并打开"
    echo "  或在命令行运行: alacritty"
else
    echo "配置文件位置（按优先级顺序）："
    echo "  1. \$XDG_CONFIG_HOME/alacritty/alacritty.toml"
    echo "  2. \$XDG_CONFIG_HOME/alacritty.toml"
    echo "  3. ~/.config/alacritty/alacritty.toml (推荐)"
    echo "  4. ~/.alacritty.toml"
    echo ""
    echo "启动方式："
    echo "  open -a Alacritty"
    echo "  或从应用程序文件夹打开"
fi
echo ""
echo "注意：Alacritty 从 0.13.0 版本开始使用 TOML 格式配置文件"
echo "旧版本的 YAML 格式配置文件 (alacritty.yml) 已不再支持"
echo ""
echo "更多信息请访问: https://github.com/alacritty/alacritty"

