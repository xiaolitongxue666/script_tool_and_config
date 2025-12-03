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
# 检查已安装版本并询问是否更新
# ============================================
log_info "检查已安装的 Alacritty..."

SKIP_INSTALL=false
if [ "$PLATFORM" == "macos" ]; then
    # macOS: 检查 Applications 目录中的旧版本
    if [ -d "/Applications/Alacritty.app" ]; then
        OLD_VERSION=$(/Applications/Alacritty.app/Contents/MacOS/alacritty --version 2>/dev/null | head -1 || echo "未知版本")
        log_info "检测到已安装的 Alacritty: $OLD_VERSION"
        read -p "是否更新到最新版本？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "跳过更新，保留现有版本"
            SKIP_INSTALL=true
        else
            log_info "将更新到最新版本..."
            # 卸载旧版本（Homebrew 会自动处理）
            if command -v brew &> /dev/null; then
                brew uninstall --cask alacritty 2>/dev/null || log_info "旧版本将通过 Homebrew 更新"
            fi
        fi
    fi
elif [ "$PLATFORM" == "windows" ]; then
    # Windows: 检查是否已安装
    if command -v alacritty.exe &> /dev/null; then
        OLD_VERSION=$(alacritty.exe --version 2>/dev/null | head -1 || echo "未知版本")
        log_info "检测到已安装的 Alacritty: $OLD_VERSION"
        read -p "是否更新到最新版本？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "跳过更新，保留现有版本"
            SKIP_INSTALL=true
        else
            log_info "将更新到最新版本..."
            if command -v winget &> /dev/null; then
                winget upgrade --id=Alacritty.Alacritty -e 2>/dev/null || log_info "将通过 winget 安装最新版本"
            fi
        fi
    fi
fi

# ============================================
# 检查并处理 terminfo 文件冲突
# ============================================
# Terminfo 文件说明（参考: https://github.com/alacritty/alacritty）:
# - 作用：终端信息数据库，用于描述终端的特性和功能
# - 位置：~/.terminfo/61/alacritty 和 ~/.terminfo/61/alacritty-direct
# - 权限问题：旧版本可能以 root 权限安装，导致新版本无法覆盖
# - 影响：如果不处理，brew 安装会失败
# - 解决方案：删除或修复权限，或安装到用户目录
if [ "$PLATFORM" == "macos" ] && [ "$SKIP_INSTALL" != "true" ]; then
    TERMINFO_DIR="$HOME/.terminfo/61"
    TERMINFO_FILES=("alacritty" "alacritty-direct")
    FOUND_ROOT_FILES=()

    # 检查所有 terminfo 文件
    for terminfo_file in "${TERMINFO_FILES[@]}"; do
        if [ -f "$TERMINFO_DIR/$terminfo_file" ] || [ -L "$TERMINFO_DIR/$terminfo_file" ]; then
            FILE_OWNER=$(stat -f "%Su" "$TERMINFO_DIR/$terminfo_file" 2>/dev/null || echo "unknown")
            if [ "$FILE_OWNER" = "root" ]; then
                FOUND_ROOT_FILES+=("$terminfo_file")
            fi
        fi
    done

    # 如果发现 root 拥有的文件，询问是否删除
    if [ ${#FOUND_ROOT_FILES[@]} -gt 0 ]; then
        log_warning "检测到 root 拥有的 terminfo 文件: ${FOUND_ROOT_FILES[*]}"
        read -p "是否删除这些 root 拥有的 terminfo 文件？(y/n，推荐 y) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for terminfo_file in "${FOUND_ROOT_FILES[@]}"; do
                if sudo rm -f "$TERMINFO_DIR/$terminfo_file" 2>/dev/null; then
                    log_success "已删除 root 拥有的 terminfo 文件: $terminfo_file"
                else
                    log_error "无法删除 terminfo 文件: $terminfo_file"
                fi
            done
        else
            log_warning "保留 terminfo 文件，如果安装失败请手动处理"
        fi
    fi
fi

# ============================================
# 使用 Homebrew 安装（macOS）
# ============================================
if [ "$PLATFORM" == "macos" ] && [ "$SKIP_INSTALL" != "true" ]; then
    if ! command -v brew &> /dev/null; then
        log_error "未找到 Homebrew，请先安装 Homebrew"
        log_info "安装方法: https://brew.sh"
        exit 1
    fi

    log_info "使用 Homebrew 安装 Alacritty..."
    log_info "执行: brew install --cask alacritty"

    # 执行安装，如果失败直接退出
    BREW_OUTPUT=$(brew install --cask alacritty 2>&1)
    BREW_EXIT_CODE=$?

    if [ $BREW_EXIT_CODE -ne 0 ]; then
        log_error "Homebrew 安装失败（退出码: $BREW_EXIT_CODE）"
        echo "$BREW_OUTPUT" | grep -i "error\|fail" || echo "$BREW_OUTPUT"

        # 检查是否是 terminfo 冲突
        if echo "$BREW_OUTPUT" | grep -qi "terminfo\|alacritty-direct"; then
            log_error "检测到 terminfo 文件冲突问题"
            log_info "参考解决方案: https://github.com/alacritty/alacritty"
            log_info ""
            log_info "解决方法："
            log_info "1. 删除 root 拥有的 terminfo 文件:"
            log_info "   sudo rm -f $HOME/.terminfo/61/alacritty"
            log_info "   sudo rm -f $HOME/.terminfo/61/alacritty-direct"
            log_info ""
            log_info "2. 或者安装到用户目录（推荐）:"
            log_info "   mkdir -p ~/.terminfo/61"
            log_info "   cd /tmp"
            log_info "   curl -L -o alacritty.info https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info"
            log_info "   tic -xe alacritty,alacritty-direct -o ~/.terminfo alacritty.info"
            log_info ""
            log_info "3. 然后重新运行此脚本"
        else
            log_error "请检查错误信息并手动解决"
        fi

        exit 1
    fi

    log_success "通过 Homebrew 安装成功"
    INSTALL_METHOD="homebrew"
elif [ "$PLATFORM" == "windows" ]; then
    # Windows: 使用 winget 安装
    if [ "$SKIP_INSTALL" != "true" ]; then
        if ! command -v winget &> /dev/null; then
            log_error "未找到 winget，请先安装 Windows Package Manager"
            log_info "安装方法: 从 Microsoft Store 安装 'App Installer'"
            log_info "或访问: https://aka.ms/getwinget"
            exit 1
        fi

        log_info "使用 winget 安装 Alacritty..."

        # 检测代理设置
        PROXY="${http_proxy:-${https_proxy:-}}"
        if [ -n "$PROXY" ]; then
            export http_proxy="$PROXY"
            export https_proxy="$PROXY"
            export HTTP_PROXY="$PROXY"
            export HTTPS_PROXY="$PROXY"
            log_info "使用代理: $PROXY"
        fi

        log_info "执行: winget install --id=Alacritty.Alacritty -e"

        # 执行安装，如果失败直接退出
        if ! winget install --id=Alacritty.Alacritty -e --accept-source-agreements --accept-package-agreements; then
            log_error "winget 安装失败"
            log_error "请检查错误信息并手动解决"
            exit 1
        fi

        log_success "通过 winget 安装成功"
        INSTALL_METHOD="winget"
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
    # 尝试从 Windows 环境变量获取 APPDATA
    if [ -z "$APPDATA" ]; then
        # 在 Git Bash 中，APPDATA 可能未设置，尝试从 Windows 环境变量获取
        if command -v cmd.exe &> /dev/null; then
            APPDATA=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' | sed 's|\\|/|g')
        fi
    fi

    if [ -n "$APPDATA" ] && [ "$APPDATA" != "%APPDATA%" ]; then
        CONFIG_DIR="$APPDATA/alacritty"
    else
        # 如果无法获取 APPDATA，使用默认路径
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

        # macOS: 自动检测并配置 zsh 路径
        if [ "$PLATFORM" == "macos" ]; then
            log_info "检测 macOS 平台，配置 zsh 路径..."
            ZSH_PATH=""

            # 优先使用 Homebrew 安装的 zsh（Apple Silicon）
            if [ -f "/opt/homebrew/bin/zsh" ]; then
                ZSH_PATH="/opt/homebrew/bin/zsh"
                log_info "检测到 Homebrew 安装的 zsh: $ZSH_PATH"
            # 其次使用系统默认的 zsh
            elif [ -f "/bin/zsh" ]; then
                ZSH_PATH="/bin/zsh"
                log_info "使用系统默认的 zsh: $ZSH_PATH"
            fi

            if [ -n "$ZSH_PATH" ]; then
                # 使用 sed 更新配置文件中的 zsh 路径
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS 使用 BSD sed，需要不同的语法
                    sed -i '' "s|program = \"/opt/homebrew/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null || \
                    sed -i '' "s|program = \"/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null
                else
                    # Linux 使用 GNU sed
                    sed -i "s|program = \"/opt/homebrew/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null || \
                    sed -i "s|program = \"/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null
                fi
                log_success "已配置 Alacritty 使用 zsh: $ZSH_PATH"
            else
                log_warning "未找到 zsh，Alacritty 将使用系统默认 shell"
            fi
        fi

        log_success "配置文件已复制到: $CONFIG_FILE"
        log_info "注意: 配置文件已根据平台自动调整"
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

            # macOS: 自动检测并配置 zsh 路径
            if [ "$PLATFORM" == "macos" ]; then
                log_info "检测 macOS 平台，配置 zsh 路径..."
                ZSH_PATH=""

                # 优先使用 Homebrew 安装的 zsh（Apple Silicon）
                if [ -f "/opt/homebrew/bin/zsh" ]; then
                    ZSH_PATH="/opt/homebrew/bin/zsh"
                    log_info "检测到 Homebrew 安装的 zsh: $ZSH_PATH"
                # 其次使用系统默认的 zsh
                elif [ -f "/bin/zsh" ]; then
                    ZSH_PATH="/bin/zsh"
                    log_info "使用系统默认的 zsh: $ZSH_PATH"
                fi

                if [ -n "$ZSH_PATH" ]; then
                    # 使用 sed 更新配置文件中的 zsh 路径
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        # macOS 使用 BSD sed，需要不同的语法
                        sed -i '' "s|program = \"/opt/homebrew/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null || \
                        sed -i '' "s|program = \"/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null
                    else
                        # Linux 使用 GNU sed
                        sed -i "s|program = \"/opt/homebrew/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null || \
                        sed -i "s|program = \"/bin/zsh\"|program = \"$ZSH_PATH\"|g" "$CONFIG_FILE" 2>/dev/null
                    fi
                    log_success "已配置 Alacritty 使用 zsh: $ZSH_PATH"
                else
                    log_warning "未找到 zsh，Alacritty 将使用系统默认 shell"
                fi
            fi

            log_success "配置文件已更新: $CONFIG_FILE"
            log_info "注意: 配置文件已根据平台自动调整"
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
    if [ -n "$CONFIG_FILE" ]; then
        # 将路径转换为 Windows 格式显示
        WIN_CONFIG_PATH=$(echo "$CONFIG_FILE" | sed 's|/|\\|g')
        echo "  - $WIN_CONFIG_PATH"
    else
        echo "  - %APPDATA%\\alacritty\\alacritty.toml (推荐)"
    fi
    echo ""
    echo "启动方式："
    echo "  从开始菜单搜索 'Alacritty' 并打开"
    echo "  或在命令行运行: alacritty"
    echo ""
    echo "如果无法启动，请检查："
    echo "  1. 配置文件路径是否正确"
    echo "  2. shell 配置是否正确（如果配置了 Git Bash，请确保路径存在）"
    echo "  3. 尝试删除配置文件，让 Alacritty 使用默认配置"
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

