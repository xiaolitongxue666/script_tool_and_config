#!/bin/bash

# ============================================
# 快速部署脚本
# 应用所有配置到当前系统
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR}/scripts/common.sh"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

start_script "快速部署"

# ============================================
# 确保子脚本有执行权限
# ============================================
log_info "检查并设置子脚本执行权限..."

DIAGNOSE_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/diagnose_deployment.sh"
FORCE_APPLY_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/force_apply_configs.sh"
CHECK_ZSH_OMZ_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/check_zsh_omz.sh"
FIX_ZSH_OMZ_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/fix_zsh_omz.sh"
FIX_LOCK_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/fix_chezmoi_lock.sh"

if [ -f "$DIAGNOSE_SCRIPT" ]; then
    if [ ! -x "$DIAGNOSE_SCRIPT" ]; then
        log_info "设置执行权限: $DIAGNOSE_SCRIPT"
        chmod +x "$DIAGNOSE_SCRIPT"
    fi
else
    log_warning "诊断脚本不存在: $DIAGNOSE_SCRIPT"
fi

if [ -f "$FORCE_APPLY_SCRIPT" ]; then
    if [ ! -x "$FORCE_APPLY_SCRIPT" ]; then
        log_info "设置执行权限: $FORCE_APPLY_SCRIPT"
        chmod +x "$FORCE_APPLY_SCRIPT"
    fi
else
    log_warning "强制应用脚本不存在: $FORCE_APPLY_SCRIPT"
fi

if [ -f "$CHECK_ZSH_OMZ_SCRIPT" ]; then
    if [ ! -x "$CHECK_ZSH_OMZ_SCRIPT" ]; then
        log_info "设置执行权限: $CHECK_ZSH_OMZ_SCRIPT"
        chmod +x "$CHECK_ZSH_OMZ_SCRIPT"
    fi
else
    log_warning "Zsh/OMZ 检查脚本不存在: $CHECK_ZSH_OMZ_SCRIPT"
fi

if [ -f "$FIX_ZSH_OMZ_SCRIPT" ]; then
    if [ ! -x "$FIX_ZSH_OMZ_SCRIPT" ]; then
        log_info "设置执行权限: $FIX_ZSH_OMZ_SCRIPT"
        chmod +x "$FIX_ZSH_OMZ_SCRIPT"
    fi
else
    log_warning "Zsh/OMZ 修复脚本不存在: $FIX_ZSH_OMZ_SCRIPT"
fi

FIX_ZSH_OMZ_COMPLETE_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/fix_zsh_omz_complete.sh"
if [ -f "$FIX_ZSH_OMZ_COMPLETE_SCRIPT" ]; then
    if [ ! -x "$FIX_ZSH_OMZ_COMPLETE_SCRIPT" ]; then
        log_info "设置执行权限: $FIX_ZSH_OMZ_COMPLETE_SCRIPT"
        chmod +x "$FIX_ZSH_OMZ_COMPLETE_SCRIPT"
    fi
fi

if [ -f "$FIX_LOCK_SCRIPT" ]; then
    if [ ! -x "$FIX_LOCK_SCRIPT" ]; then
        log_info "设置执行权限: $FIX_LOCK_SCRIPT"
        chmod +x "$FIX_LOCK_SCRIPT"
    fi
fi

# ============================================
# 检查 chezmoi
# ============================================
if ! command -v chezmoi &> /dev/null; then
    error_exit "chezmoi 未安装，请先运行: ./install.sh"
fi

# ============================================
# 检查并修复 chezmoi 锁文件问题
# ============================================
FIX_LOCK_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/fix_chezmoi_lock.sh"
if [ -f "$FIX_LOCK_SCRIPT" ]; then
    if [ ! -x "$FIX_LOCK_SCRIPT" ]; then
        chmod +x "$FIX_LOCK_SCRIPT"
    fi

    # 检查是否有锁文件问题
    CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
    LOCK_FILE="$CHEZMOI_STATE_DIR/.chezmoi.lock"

    if [ -f "$LOCK_FILE" ]; then
        log_warning "发现 chezmoi 锁文件，检查是否有问题..."

        # 检查是否有进程在使用锁文件
        CHEZMOI_PIDS=$(pgrep -f "chezmoi" 2>/dev/null || true)

        if [ -z "$CHEZMOI_PIDS" ]; then
            # 没有进程，但锁文件存在，可能是残留的
            LOCK_AGE=$(find "$LOCK_FILE" -mmin +1 2>/dev/null || echo "")
            if [ -n "$LOCK_AGE" ]; then
                log_warning "锁文件已存在超过 1 分钟且没有相关进程，可能是残留的"
                log_info "自动清理锁文件..."
                rm -f "$LOCK_FILE"
                log_success "锁文件已清理"
            fi
        else
            log_info "发现正在运行的 chezmoi 进程，等待其完成..."
            # 等待最多 10 秒
            for i in {1..10}; do
                sleep 1
                CHEZMOI_PIDS=$(pgrep -f "chezmoi" 2>/dev/null || true)
                if [ -z "$CHEZMOI_PIDS" ]; then
                    log_success "进程已完成"
                    rm -f "$LOCK_FILE"
                    break
                fi
            done

            if [ -n "$(pgrep -f "chezmoi" 2>/dev/null || true)" ]; then
                log_warning "chezmoi 进程仍在运行，可能需要手动处理"
                log_info "可以运行: $FIX_LOCK_SCRIPT"
            fi
        fi
    fi
fi

# ============================================
# 检测操作系统
# ============================================
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="darwin"
    PLATFORM_NAME="macOS"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
    PLATFORM_NAME="Linux"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
    PLATFORM_NAME="Windows"
else
    PLATFORM="unknown"
    PLATFORM_NAME="Unknown"
fi

log_info "检测到操作系统: $PLATFORM_NAME ($OS)"

# ============================================
# 设置源状态目录和环境变量
# ============================================
CHEZMOI_DIR="${SCRIPT_DIR}/.chezmoi"
if [ ! -d "$CHEZMOI_DIR" ]; then
    error_exit "chezmoi 源状态目录不存在: $CHEZMOI_DIR"
fi

# 自动设置环境变量，确保 chezmoi 使用项目内的 .chezmoi 目录
export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
log_success "已设置 CHEZMOI_SOURCE_DIR: $CHEZMOI_SOURCE_DIR"

# ============================================
# 设置代理（如果提供）
# ============================================
# 优先使用环境变量，然后是默认值
PROXY="${PROXY:-192.168.1.76:7890}"

if [ -n "$PROXY" ] && [ "$PROXY" != "none" ] && [ "$PROXY" != "false" ]; then
    # 确保代理格式正确（添加 http:// 前缀如果没有）
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    export GIT_HTTP_PROXY="$PROXY"
    export GIT_HTTPS_PROXY="$PROXY"
    log_info "已设置代理: $PROXY"
else
    log_info "未设置代理，使用直连"
    unset PROXY
fi

# ============================================
# 禁用 chezmoi pager（避免进入交互模式）
# ============================================
export CHEZMOI_PAGER=""

# ============================================
# 检查 .chezmoi 目录内容
# ============================================
log_info "检查源状态目录内容..."
if [ -z "$(ls -A $CHEZMOI_DIR 2>/dev/null)" ]; then
    log_warning ".chezmoi 目录为空"
    log_info "这意味着还没有配置文件被添加到 chezmoi 管理"
    log_info ""
    log_info "如果需要添加配置，可以："
    log_info "  1. 从 Windows 同步 .chezmoi 目录（如果 Windows 上有配置）"
    log_info "  2. 手动添加配置: export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\" && chezmoi add ~/.zshrc"
    log_info "  3. 运行迁移脚本: ./scripts/migration/migrate_to_chezmoi.sh"
    log_info ""
    log_warning "当前没有配置需要应用，退出"
    end_script
    exit 0
fi

# 统计文件数量
FILE_COUNT=$(find "$CHEZMOI_DIR" -type f ! -path '*/.git/*' 2>/dev/null | wc -l)
log_info "源状态目录包含 $FILE_COUNT 个文件"

# 显示当前系统对应的配置文件
log_info "检查 $PLATFORM_NAME 系统对应的配置文件..."
PLATFORM_DIR="${CHEZMOI_DIR}/run_on_${PLATFORM}"

# ============================================
# 1. 跨平台软件配置（三系统都支持）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "跨平台软件配置（Linux/macOS/Windows 都支持）"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 跨平台配置文件（根目录下的文件，排除平台特定目录）
CROSS_PLATFORM_FILES=$(find "$CHEZMOI_DIR" -maxdepth 1 -type f ! -path '*/.git/*' ! -name 'chezmoi.toml' ! -name '*.swp' ! -name '*.swo' 2>/dev/null)
CROSS_PLATFORM_DIRS=$(find "$CHEZMOI_DIR" -maxdepth 1 -type d ! -path "$CHEZMOI_DIR" ! -path '*/.git/*' ! -name 'run_on_*' 2>/dev/null)

CROSS_PLATFORM_COUNT=0

# 显示跨平台配置文件
if [ -n "$CROSS_PLATFORM_FILES" ]; then
    echo "$CROSS_PLATFORM_FILES" | while IFS= read -r file; do
        BASENAME=$(basename "$file")
        # 识别软件类型
        if [[ "$BASENAME" =~ ^run_once_install- ]]; then
            SOFTWARE_NAME="${BASENAME#run_once_install-}"
            SOFTWARE_NAME="${SOFTWARE_NAME%.sh.tmpl}"
            SOFTWARE_NAME="${SOFTWARE_NAME%.sh}"
            log_info "  📦 安装脚本: $SOFTWARE_NAME ($BASENAME)"
        elif [[ "$BASENAME" =~ ^dot_ ]]; then
            CONFIG_NAME="${BASENAME#dot_}"
            CONFIG_NAME="${CONFIG_NAME%.tmpl}"
            log_info "  ⚙️  配置文件: $CONFIG_NAME ($BASENAME)"
        else
            log_info "  📄 $BASENAME"
        fi
    done
    CROSS_PLATFORM_COUNT=$(echo "$CROSS_PLATFORM_FILES" | wc -l)
fi

# 显示跨平台配置目录（如 dot_config/）
if [ -n "$CROSS_PLATFORM_DIRS" ]; then
    echo "$CROSS_PLATFORM_DIRS" | while IFS= read -r dir; do
        DIR_NAME=$(basename "$dir")
        if [[ "$DIR_NAME" == "dot_config" ]]; then
            log_info "  📁 配置目录: ~/.config/ (包含 Alacritty, Fish, Starship 等)"
            # 显示子目录
            find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while IFS= read -r subdir; do
                SUBDIR_NAME=$(basename "$subdir")
                log_info "      └─ $SUBDIR_NAME/"
            done
        else
            log_info "  📁 $DIR_NAME/"
        fi
    done
fi

# 跨平台软件列表
log_info ""
log_info "跨平台软件包括："
log_info "  • 开发工具: Git, Neovim"
log_info "  • 终端工具: Alacritty, Tmux, Starship"
log_info "  • Shell: Bash, Zsh, Fish"
log_info "  • 版本管理器: fnm, uv, rustup"
log_info "  • 字体: Nerd Fonts"
log_info "  • 其他: 各种命令行工具（bat, eza, fd, rg, fzf 等）"

# ============================================
# 2. 平台特定配置
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "$PLATFORM_NAME 特定配置（仅当前系统）"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "$PLATFORM_DIR" ]; then
    PLATFORM_FILE_COUNT=$(find "$PLATFORM_DIR" -type f ! -path '*/.git/*' 2>/dev/null | wc -l)
    if [ "$PLATFORM_FILE_COUNT" -gt 0 ]; then
        log_info "发现 $PLATFORM_FILE_COUNT 个 $PLATFORM_NAME 特定配置文件："
        find "$PLATFORM_DIR" -type f ! -path '*/.git/*' ! -name '*.swp' ! -name '*.swo' 2>/dev/null | while IFS= read -r file; do
            REL_PATH="${file#$PLATFORM_DIR/}"
            # 识别配置类型
            if [[ "$REL_PATH" =~ ^run_once_install- ]]; then
                SOFTWARE_NAME="${REL_PATH#run_once_install-}"
                SOFTWARE_NAME="${SOFTWARE_NAME%.sh.tmpl}"
                SOFTWARE_NAME="${SOFTWARE_NAME%.sh}"
                log_info "  📦 安装脚本: $SOFTWARE_NAME"
            elif [[ "$REL_PATH" =~ ^dot_ ]]; then
                CONFIG_NAME="${REL_PATH#dot_}"
                CONFIG_NAME="${CONFIG_NAME%.tmpl}"
                log_info "  ⚙️  配置文件: $CONFIG_NAME"
            elif [[ "$REL_PATH" =~ ^run_once_configure- ]]; then
                CONFIG_NAME="${REL_PATH#run_once_configure-}"
                CONFIG_NAME="${CONFIG_NAME%.sh.tmpl}"
                CONFIG_NAME="${CONFIG_NAME%.sh}"
                log_info "  🔧 配置脚本: $CONFIG_NAME"
            else
                log_info "  📄 $REL_PATH"
            fi
        done

        # 显示平台特定软件说明
        log_info ""
        case "$PLATFORM" in
            linux)
                log_info "$PLATFORM_NAME 特定软件包括："
                log_info "  • 窗口管理器: i3wm, dwm"
                log_info "  • 包管理器配置: pacman 镜像源"
                log_info "  • AUR 助手: yay"
                ;;
            darwin)
                log_info "$PLATFORM_NAME 特定软件包括："
                log_info "  • 窗口管理器: Yabai, skhd"
                log_info "  • 包管理器配置: Homebrew"
                log_info "  • 系统工具: Maccy (剪贴板管理)"
                ;;
            windows)
                log_info "$PLATFORM_NAME 特定软件包括："
                log_info "  • Shell 配置: Git Bash"
                log_info "  • 提示符工具: Oh My Posh"
                log_info "  • 系统工具: SecureCRT 脚本"
                ;;
        esac
    else
        log_info "$PLATFORM_NAME 特定配置目录存在但为空"
    fi
else
    log_info "$PLATFORM_NAME 特定配置目录不存在（这是正常的，如果该平台没有特定配置）"
fi

log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "配置应用说明"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "chezmoi 会自动根据当前系统（$PLATFORM_NAME）应用对应的配置："
log_info "  ✓ 跨平台配置 → 应用到所有系统（Linux/macOS/Windows）"
log_info "  ✓ $PLATFORM_NAME 特定配置 → 仅应用到当前系统"
log_info "  ✓ 模板文件（.tmpl）→ 根据系统变量自动生成对应内容"
log_info ""

# ============================================
# 检查配置状态（带超时）
# ============================================
log_info "检查配置状态..."
# 使用 timeout 避免卡住，最多等待 5 秒
if command -v timeout &> /dev/null; then
    STATUS_OUTPUT=$(timeout 5 chezmoi status 2>&1 || echo "timeout or error")
else
    STATUS_OUTPUT=$(chezmoi status 2>&1 || true)
fi
if [ -n "$STATUS_OUTPUT" ]; then
    log_info "配置状态："
    echo "$STATUS_OUTPUT" | while IFS= read -r line; do
        if [[ "$line" =~ ^(M|A|D|R) ]]; then
            log_info "  $line"
        fi
    done
else
    log_info "所有配置文件都是最新的"
fi

# ============================================
# 显示配置差异（如果有，带超时）
# ============================================
log_info "检查配置差异..."
# 使用 timeout 避免卡住，最多等待 5 秒
if command -v timeout &> /dev/null; then
    DIFF_OUTPUT=$(timeout 5 chezmoi diff 2>&1 || echo "timeout or error")
else
    DIFF_OUTPUT=$(chezmoi diff 2>&1 || true)
fi
if [ -n "$DIFF_OUTPUT" ]; then
    log_info "发现配置差异，将应用以下更改："
    echo "$DIFF_OUTPUT" | head -20 | while IFS= read -r line; do
        log_info "  $line"
    done
    if [ $(echo "$DIFF_OUTPUT" | wc -l) -gt 20 ]; then
        log_info "  ... (还有更多差异，共 $(echo "$DIFF_OUTPUT" | wc -l) 行)"
    fi
else
    log_info "没有配置差异，所有文件都是最新的"
fi

# ============================================
# 诊断部署状态
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "诊断部署状态"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$DIAGNOSE_SCRIPT" ] && [ -x "$DIAGNOSE_SCRIPT" ]; then
    log_info "运行诊断脚本..."
    "$DIAGNOSE_SCRIPT" || log_warning "诊断脚本执行失败或返回警告"
else
    log_warning "诊断脚本不可用，跳过诊断步骤"
fi

# ============================================
# 安装和配置 Zsh + Oh My Zsh + 插件（在应用配置之前）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "安装和配置 Zsh + Oh My Zsh + 插件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查是否需要安装 Zsh
if ! command -v zsh &> /dev/null; then
    log_info "Zsh 未安装，开始安装..."
    case "$PLATFORM" in
        linux)
            if command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm zsh || log_warning "Zsh 安装失败"
            elif command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y zsh || log_warning "Zsh 安装失败"
            fi
            ;;
        darwin)
            if command -v brew &> /dev/null; then
                brew install zsh || log_warning "Zsh 安装失败"
            fi
            ;;
    esac
fi

# 安装 Oh My Zsh
OMZ_DIR="$HOME/.oh-my-zsh"
if [ ! -d "$OMZ_DIR" ]; then
    log_info "Oh My Zsh 未安装，开始安装..."
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    export CHSH=no

    if [ -n "$PROXY" ]; then
        log_info "使用代理安装 Oh My Zsh: $PROXY"
        if curl --proxy "$PROXY" -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh; then
            log_success "Oh My Zsh 安装成功"
        else
            log_warning "Oh My Zsh 安装失败"
        fi
    else
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            log_success "Oh My Zsh 安装成功"
        else
            log_warning "Oh My Zsh 安装失败"
        fi
    fi
else
    log_info "Oh My Zsh 已安装，检查更新..."
    if [ -d "$OMZ_DIR/.git" ]; then
        cd "$OMZ_DIR"
        if git pull --quiet 2>/dev/null; then
            log_success "Oh My Zsh 已更新到最新版本"
        else
            log_info "Oh My Zsh 已是最新版本或更新失败"
        fi
        cd - > /dev/null
    fi
fi

# 检查并修复缺失的内置插件（copydir, copyfile 等）
if [ -d "$OMZ_DIR" ]; then
    OMZ_PLUGINS_DIR="$OMZ_DIR/plugins"
    MISSING_BUILTIN_PLUGINS=()

    # 检查模板中配置的内置插件
    ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"
    if [ -f "$ZSHRC_TEMPLATE" ]; then
        BUILTIN_PLUGINS=$(grep -A 20 "^plugins=" "$ZSHRC_TEMPLATE" 2>/dev/null | grep -E "^\s+(copydir|copyfile|extract|web-search|colored-man-pages|dirhistory)" | sed 's/^[[:space:]]*//' | sed 's/#.*$//' | grep -v "^$" || echo "")

        if [ -n "$BUILTIN_PLUGINS" ]; then
            while IFS= read -r plugin_name; do
                if [ -n "$plugin_name" ] && [[ ! "$plugin_name" =~ ^# ]]; then
                    plugin_path="$OMZ_PLUGINS_DIR/$plugin_name"
                    if [ ! -d "$plugin_path" ]; then
                        MISSING_BUILTIN_PLUGINS+=("$plugin_name")
                    fi
                fi
            done <<< "$BUILTIN_PLUGINS"
        fi
    fi

    # 如果有缺失的插件，尝试更新 Oh My Zsh
    if [ ${#MISSING_BUILTIN_PLUGINS[@]} -gt 0 ]; then
        log_warning "发现缺失的内置插件: ${MISSING_BUILTIN_PLUGINS[*]}"
        log_info "尝试更新 Oh My Zsh 以获取最新插件..."
        if [ -d "$OMZ_DIR/.git" ]; then
            cd "$OMZ_DIR"
            if git pull --quiet 2>/dev/null; then
                log_success "Oh My Zsh 已更新"
            else
                log_warning "Oh My Zsh 更新失败"
            fi
            cd - > /dev/null
        fi
    fi
fi

# 安装自定义插件
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$ZSH_CUSTOM"

PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
)

INSTALLED_COUNT=0
TOTAL_PLUGINS=${#PLUGINS[@]}

for plugin_entry in "${PLUGINS[@]}"; do
    plugin_name="${plugin_entry%%|*}"
    plugin_url="${plugin_entry#*|}"
    plugin_path="$ZSH_CUSTOM/$plugin_name"

    if [ -d "$plugin_path" ]; then
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        log_info "安装插件: $plugin_name..."
        if [ -n "$PROXY" ]; then
            git config --global http.proxy "$PROXY" 2>/dev/null || true
            git config --global https.proxy "$PROXY" 2>/dev/null || true
        fi

        if git clone "$plugin_url" "$plugin_path" 2>&1 | tee /tmp/git_clone_output.log; then
            log_success "  ✓ $plugin_name 安装成功"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            log_warning "  ✗ $plugin_name 安装失败"
            rm -f /tmp/git_clone_output.log 2>/dev/null || true
        fi
    fi
done

log_info "已安装插件: $INSTALLED_COUNT/$TOTAL_PLUGINS"

# ============================================
# 应用配置
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "应用配置"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查是否有文件在管理中
MANAGED_FILES=$(chezmoi managed 2>/dev/null || true)

if [ -z "$MANAGED_FILES" ]; then
    log_warning "没有文件在 chezmoi 管理中"
    log_info "使用强制应用脚本处理源文件..."

    if [ -f "$FORCE_APPLY_SCRIPT" ] && [ -x "$FORCE_APPLY_SCRIPT" ]; then
        log_info "运行强制应用脚本..."
        "$FORCE_APPLY_SCRIPT" || log_warning "强制应用脚本执行失败"
    else
        log_warning "强制应用脚本不可用，尝试直接应用..."
        log_info "chezmoi 将根据当前系统（$PLATFORM_NAME）自动应用对应的配置："
        log_info "  ✓ 跨平台配置（Git, Neovim, Starship, Alacritty, Fish, Tmux 等）"
        log_info "  ✓ $PLATFORM_NAME 特定配置（仅当前系统）"
        log_info "  ✓ 模板文件会根据系统变量自动生成对应内容"
        log_info ""
        log_info "执行: chezmoi apply -v --force"
        echo ""

        # 执行并捕获输出（禁用 pager，使用 --force 避免交互）
        export CHEZMOI_PAGER=""
        if command -v timeout &> /dev/null; then
            APPLY_OUTPUT=$(timeout 60 chezmoi apply -v --force 2>&1 || echo "timeout or error")
            APPLY_EXIT_CODE=$?
            if echo "$APPLY_OUTPUT" | grep -q "timeout"; then
                log_error "chezmoi apply 超时"
                APPLY_EXIT_CODE=1
            fi
        else
            APPLY_OUTPUT=$(chezmoi apply -v --force 2>&1)
            APPLY_EXIT_CODE=$?
        fi

        # 显示输出
        echo "$APPLY_OUTPUT"
        echo ""

        # 分析输出
        if [ $APPLY_EXIT_CODE -eq 0 ]; then
            if echo "$APPLY_OUTPUT" | grep -qE "(apply|create|update|remove)"; then
                APPLIED_COUNT=$(echo "$APPLY_OUTPUT" | grep -E "(apply|create|update|remove)" | wc -l)
                APPLIED_COUNT=$((APPLIED_COUNT + 0))
                log_success "配置应用成功，处理了 $APPLIED_COUNT 个文件"
            else
                log_info "所有配置文件都是最新的，无需更新"
            fi
        else
            log_warning "chezmoi apply 退出码: $APPLY_EXIT_CODE"
            log_info "请检查上面的输出以了解详细信息"
        fi
    fi
else
    log_info "发现已管理的文件，直接应用配置..."
    log_info "chezmoi 将根据当前系统（$PLATFORM_NAME）自动应用对应的配置："
    log_info "  ✓ 跨平台配置（Git, Neovim, Starship, Alacritty, Fish, Tmux 等）"
    log_info "  ✓ $PLATFORM_NAME 特定配置（仅当前系统）"
    log_info "  ✓ 模板文件会根据系统变量自动生成对应内容"
    log_info ""
    log_info "执行: chezmoi apply -v --force"
    echo ""

    # 对于 .zshrc 等模板文件，优先使用 execute-template 避免进入 pager
    ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"
    if [ -f "$ZSHRC_TEMPLATE" ]; then
        log_info "检测到 .zshrc 模板，优先使用 execute-template 生成/更新..."
        export CHEZMOI_PAGER=""

        # 备份现有文件
        if [ -f "$HOME/.zshrc" ]; then
            BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$HOME/.zshrc" "$BACKUP_FILE" 2>/dev/null || true
            log_info "已备份现有 .zshrc: $BACKUP_FILE"
        fi

        # 使用 execute-template 生成文件
        if command -v timeout &> /dev/null; then
            if timeout 30 chezmoi execute-template < "$ZSHRC_TEMPLATE" > "$HOME/.zshrc" 2>&1; then
                log_success ".zshrc 已通过 execute-template 生成/更新"
                chezmoi add --force ~/.zshrc 2>/dev/null || true
            else
                log_warning "execute-template 失败，将使用 chezmoi apply"
            fi
        else
            if chezmoi execute-template < "$ZSHRC_TEMPLATE" > "$HOME/.zshrc" 2>&1; then
                log_success ".zshrc 已通过 execute-template 生成/更新"
                chezmoi add --force ~/.zshrc 2>/dev/null || true
            else
                log_warning "execute-template 失败，将使用 chezmoi apply"
            fi
        fi
    fi

    # 执行并捕获输出（带超时，禁用 pager，使用 --force 避免交互）
    export CHEZMOI_PAGER=""
    if command -v timeout &> /dev/null; then
        APPLY_OUTPUT=$(timeout 60 chezmoi apply -v --force 2>&1 || echo "timeout or error")
        APPLY_EXIT_CODE=$?
        if echo "$APPLY_OUTPUT" | grep -q "timeout"; then
            log_error "chezmoi apply 超时，可能是锁文件问题"
            log_info "请运行: $FIX_LOCK_SCRIPT"
            APPLY_EXIT_CODE=1
        fi
    else
        APPLY_OUTPUT=$(chezmoi apply -v --force 2>&1)
        APPLY_EXIT_CODE=$?
    fi

    # 显示输出
    echo "$APPLY_OUTPUT"
    echo ""

    # 分析输出，统计应用的文件
    if [ $APPLY_EXIT_CODE -eq 0 ]; then
        # 统计应用的文件数量
        # 使用 grep 查找匹配行，然后统计行数，避免 grep -c 可能的换行符问题
        if echo "$APPLY_OUTPUT" | grep -qE "(apply|create|update|remove)"; then
            APPLIED_COUNT=$(echo "$APPLY_OUTPUT" | grep -E "(apply|create|update|remove)" | wc -l)
            # 去除可能的空白字符
            APPLIED_COUNT=$((APPLIED_COUNT + 0))  # 强制转换为整数
            log_success "配置应用成功，处理了 $APPLIED_COUNT 个文件"
        else
            log_info "所有配置文件都是最新的，无需更新"
        fi
    else
        log_warning "chezmoi apply 退出码: $APPLY_EXIT_CODE"
        log_info "请检查上面的输出以了解详细信息"
    fi
fi

# ============================================
# 验证部署结果
# ============================================
log_info "验证部署结果..."
FINAL_STATUS=$(chezmoi status 2>&1 || true)
if [ -z "$FINAL_STATUS" ]; then
    log_success "所有配置文件已同步，部署成功！"
else
    log_warning "仍有未同步的配置："
    echo "$FINAL_STATUS" | while IFS= read -r line; do
        log_info "  $line"
    done
fi

# ============================================
# 显示受管理的文件数量和信息
# ============================================
log_info "显示受管理的配置文件..."
MANAGED_FILES=$(chezmoi managed 2>/dev/null || true)
if [ -n "$MANAGED_FILES" ]; then
    MANAGED_COUNT=$(echo "$MANAGED_FILES" | wc -l)
    log_success "当前管理 $MANAGED_COUNT 个配置文件："
    echo "$MANAGED_FILES" | head -20 | while IFS= read -r file; do
        log_info "  ✓ $file"
    done
    if [ "$MANAGED_COUNT" -gt 20 ]; then
        log_info "  ... (还有 $((MANAGED_COUNT - 20)) 个文件)"
    fi
else
    log_info "当前没有受管理的配置文件（这是正常的，如果配置还未被添加到 chezmoi 管理）"
    log_info ""
    log_info "配置源状态："
    log_info "  - 源目录: $CHEZMOI_DIR"
    FILE_COUNT=$(find "$CHEZMOI_DIR" -type f ! -path '*/.git/*' 2>/dev/null | wc -l)
    log_info "  - 源文件数量: $FILE_COUNT"
    log_info ""
    log_info "说明："
    log_info "  - .chezmoi 目录中的配置文件会通过 chezmoi apply 应用到系统"
    log_info "  - 只有被添加到 chezmoi 管理的文件才会出现在 'chezmoi managed' 列表中"
    log_info "  - 如果配置文件已应用且没有变更，'chezmoi managed' 可能返回空"
    log_info ""
    log_info "如果需要将现有配置文件添加到 chezmoi 管理："
    log_info "  export CHEZMOI_SOURCE_DIR=\"\$(pwd)/.chezmoi\""
    log_info "  chezmoi add ~/.zshrc"
fi

log_success "部署完成！"
echo ""

# ============================================
# 检查 Zsh 和 Oh My Zsh 安装状态
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "检查 Zsh 和 Oh My Zsh 安装状态"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================
# 检查并修复 Zsh 和 Oh My Zsh
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "检查 Zsh 和 Oh My Zsh 配置"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$CHECK_ZSH_OMZ_SCRIPT" ] && [ -x "$CHECK_ZSH_OMZ_SCRIPT" ]; then
    log_info "运行 Zsh/OMZ 检查脚本..."
    CHECK_OUTPUT=$("$CHECK_ZSH_OMZ_SCRIPT" 2>&1)
    CHECK_EXIT_CODE=$?
    echo "$CHECK_OUTPUT"

    # 如果检查发现问题，自动运行修复脚本
    NEEDS_FIX=false

    # 检查插件是否缺失
    if echo "$CHECK_OUTPUT" | grep -q "未安装.*插件\|已安装插件数量: 0/"; then
        log_warning "发现插件缺失问题"
        NEEDS_FIX=true
    fi

    # 检查 .zshrc 配置是否不完整
    if echo "$CHECK_OUTPUT" | grep -q "以下插件未在配置中\|plugins=(git)"; then
        log_warning "发现 .zshrc 配置不完整"
        NEEDS_FIX=true
    fi

    # 检查 run_once 脚本是否未执行
    if echo "$CHECK_OUTPUT" | grep -q "脚本未执行"; then
        log_warning "发现 run_once 脚本未执行"
        NEEDS_FIX=true
    fi

    if [ "$NEEDS_FIX" = true ]; then
        log_warning "检查发现问题，自动运行修复脚本..."

        # 优先使用完整修复脚本
        if [ -f "$FIX_ZSH_OMZ_COMPLETE_SCRIPT" ] && [ -x "$FIX_ZSH_OMZ_COMPLETE_SCRIPT" ]; then
            log_info "使用完整修复脚本..."
            "$FIX_ZSH_OMZ_COMPLETE_SCRIPT" || log_warning "完整修复脚本执行失败"
        elif [ -f "$FIX_ZSH_OMZ_SCRIPT" ] && [ -x "$FIX_ZSH_OMZ_SCRIPT" ]; then
            log_info "使用标准修复脚本..."
            "$FIX_ZSH_OMZ_SCRIPT" || log_warning "修复脚本执行失败"
        else
            log_warning "修复脚本不可用"
        fi

        # 修复后再次检查
        log_info "修复后再次检查..."
        "$CHECK_ZSH_OMZ_SCRIPT" 2>&1 | tail -20
    else
        log_success "Zsh 和 Oh My Zsh 配置正常"
    fi
else
    log_warning "Zsh/OMZ 检查脚本不可用，跳过检查"
fi

# ============================================
# 验证与报告（字体、默认 Shell、环境变量、开机启动声明）
# ============================================
VERIFY_SCRIPT="${SCRIPT_DIR}/scripts/chezmoi/verify_installation.sh"
if [ -f "$VERIFY_SCRIPT" ] && [ -x "$VERIFY_SCRIPT" ]; then
    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "验证与确认（安装状态报告）"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if bash "$VERIFY_SCRIPT"; then
        log_success "验证完成，报告已写入（见上方路径）"
    else
        log_warning "验证脚本执行完毕，请查看上方报告摘要"
    fi
fi

log_info ""
log_info "提示："
log_info "  - 如果修改了 Shell 配置（如 ~/.zshrc），运行: source ~/.zshrc"
log_info "  - 切换到 zsh: chsh -s \$(which zsh) 然后重新打开终端"
log_info "  - 查看配置状态: ./scripts/manage_dotfiles.sh status"
log_info "  - 查看配置差异: ./scripts/manage_dotfiles.sh diff"
log_info "  - 检查 Zsh/OMZ: ./scripts/common/utils/check_zsh_omz.sh"

end_script

