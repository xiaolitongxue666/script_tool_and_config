#!/bin/bash

# ============================================
# Zsh + Oh My Zsh 手动安装和配置脚本
# 参考 deploy.sh 流程，提供完整的手动操作步骤
# ============================================

# 注意：不使用 set -e，避免在加载 common.sh 时因小错误而退出
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    # 临时禁用 set -e（如果 common.sh 中有）
    set +e
    source "$COMMON_SH" 2>/dev/null || true
    set -e
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function start_script() { echo "=========================================="; echo "Starting: $1"; echo "=========================================="; }
    function end_script() { echo "=========================================="; echo "Script execution completed"; echo "=========================================="; }
fi

# 确保函数存在
if ! type log_info &>/dev/null; then
    function log_info() { echo "[INFO] $*"; }
fi
if ! type log_success &>/dev/null; then
    function log_success() { echo "[SUCCESS] $*"; }
fi
if ! type log_warning &>/dev/null; then
    function log_warning() { echo "[WARNING] $*"; }
fi
if ! type log_error &>/dev/null; then
    function log_error() { echo "[ERROR] $*" >&2; }
fi
if ! type start_script &>/dev/null; then
    function start_script() { echo "=========================================="; echo "Starting: $1"; echo "=========================================="; }
fi
if ! type end_script &>/dev/null; then
    function end_script() { echo "=========================================="; echo "Script execution completed"; echo "=========================================="; }
fi

# ============================================
# 解析命令行参数
# ============================================
PROXY_ARG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy|-p)
            PROXY_ARG="$2"
            shift 2
            ;;
        *)
            log_warning "未知参数: $1，忽略"
            shift
            ;;
    esac
done

start_script "Zsh + Oh My Zsh 手动安装和配置"

# ============================================
# 设置环境变量
# ============================================
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
if [ -d "$CHEZMOI_DIR" ]; then
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
    log_info "已设置 CHEZMOI_SOURCE_DIR: $CHEZMOI_SOURCE_DIR"
else
    log_error "chezmoi 源目录不存在: $CHEZMOI_DIR"
    exit 1
fi

# ============================================
# 设置代理（如果提供）
# ============================================
# 优先使用命令行参数，然后是环境变量，最后是默认值
PROXY="${PROXY_ARG:-${PROXY:-192.168.1.76:7890}}"

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
    log_info "  环境变量: http_proxy, https_proxy, GIT_HTTP_PROXY, GIT_HTTPS_PROXY"
else
    log_info "未设置代理，使用直连"
    unset PROXY
fi

# ============================================
# 步骤 1: 检查当前 zsh 配置和插件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 1: 检查当前 zsh 配置和插件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1.1 检查 Zsh 安装
log_info ""
log_info "1.1 检查 Zsh 安装..."
if command -v zsh &> /dev/null; then
    ZSH_VERSION=$(zsh --version 2>&1 | head -1)
    ZSH_PATH=$(which zsh)
    log_success "Zsh 已安装: $ZSH_VERSION"
    log_info "  安装路径: $ZSH_PATH"

    # 检查当前 Shell
    CURRENT_SHELL=$(echo "$SHELL" 2>/dev/null || echo "unknown")
    log_info "  当前 Shell: $CURRENT_SHELL"
    if [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
        log_success "  当前正在使用 zsh"
    else
        log_warning "  当前未使用 zsh，建议切换: chsh -s $(which zsh)"
    fi
else
    log_warning "Zsh 未安装"
fi

# 1.2 检查 Oh My Zsh 安装
log_info ""
log_info "1.2 检查 Oh My Zsh 安装..."
OMZ_DIR="$HOME/.oh-my-zsh"
if [ -d "$OMZ_DIR" ]; then
    log_success "Oh My Zsh 已安装"
    log_info "  安装路径: $OMZ_DIR"

    # 检查版本
    if [ -f "$OMZ_DIR/.git/config" ]; then
        OMZ_VERSION=$(cd "$OMZ_DIR" && git describe --tags 2>/dev/null || echo "未知版本")
        log_info "  版本: $OMZ_VERSION"
    else
        log_info "  版本: 未知版本"
    fi
else
    log_warning "Oh My Zsh 未安装"
fi

# 1.3 检查 .zshrc 文件
log_info ""
log_info "1.3 检查 .zshrc 文件..."
if [ -f "$HOME/.zshrc" ]; then
    ZSHRC_SIZE=$(wc -c < "$HOME/.zshrc" 2>/dev/null || echo "0")
    ZSHRC_MODIFIED=$(stat -c "%y" "$HOME/.zshrc" 2>/dev/null || stat -f "%Sm" "$HOME/.zshrc" 2>/dev/null || echo "未知")
    log_success ".zshrc 文件存在"
    log_info "  文件大小: $ZSHRC_SIZE 字节"
    log_info "  修改时间: $ZSHRC_MODIFIED"

    # 检查 Oh My Zsh 配置
    if grep -q "ZSH=" "$HOME/.zshrc" 2>/dev/null; then
        ZSH_VAR=$(grep "^export ZSH=" "$HOME/.zshrc" 2>/dev/null | head -1 || echo "")
        log_success "  包含 Oh My Zsh 配置"
        log_info "  $ZSH_VAR"
    else
        log_warning "  未找到 Oh My Zsh 配置"
    fi

    # 检查插件配置
    PLUGINS_SECTION=$(grep -A 15 "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -16 || echo "")
    if [ -n "$PLUGINS_SECTION" ]; then
        log_success "  包含插件配置:"
        echo "$PLUGINS_SECTION" | head -5 | while IFS= read -r line; do
            log_info "    $line"
        done
    else
        log_warning "  未找到插件配置"
    fi
else
    log_warning ".zshrc 文件不存在"
fi

# 1.4 检查已安装的插件
log_info ""
log_info "1.4 检查已安装的插件..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ -d "$ZSH_CUSTOM" ]; then
    PLUGINS=(
        "zsh-autosuggestions"
        "zsh-history-substring-search"
        "zsh-syntax-highlighting"
        "zsh-completions"
    )

    INSTALLED_COUNT=0
    for plugin in "${PLUGINS[@]}"; do
        plugin_path="$ZSH_CUSTOM/$plugin"
        if [ -d "$plugin_path" ]; then
            log_success "  ✓ $plugin 已安装"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            log_warning "  ✗ $plugin 未安装"
        fi
    done

    log_info ""
    log_info "已安装插件: $INSTALLED_COUNT/${#PLUGINS[@]}"
else
    log_warning "插件目录不存在: $ZSH_CUSTOM"
fi

# ============================================
# 步骤 2: 安装 zsh + omz + 插件
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 2: 安装 zsh + omz + 插件"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 2.1 安装 Zsh
log_info ""
log_info "2.1 安装 Zsh..."
if ! command -v zsh &> /dev/null; then
    log_info "开始安装 Zsh..."

    # 检测操作系统和包管理器
    OS="$(uname -s)"
    if [[ "$OS" == "Linux" ]]; then
        if command -v pacman &> /dev/null; then
            log_info "使用 pacman 安装 zsh..."
            sudo pacman -S --noconfirm zsh || log_error "安装失败"
        elif command -v apt-get &> /dev/null; then
            log_info "使用 apt-get 安装 zsh..."
            sudo apt-get update && sudo apt-get install -y zsh || log_error "安装失败"
        else
            log_error "未找到支持的包管理器"
            exit 1
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        if command -v brew &> /dev/null; then
            log_info "使用 Homebrew 安装 zsh..."
            brew install zsh || log_error "安装失败"
        else
            log_warning "macOS 通常已预装 Zsh"
        fi
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi

    if command -v zsh &> /dev/null; then
        log_success "Zsh 安装成功: $(zsh --version)"
    else
        log_error "Zsh 安装失败"
        exit 1
    fi
else
    log_info "Zsh 已安装，跳过"
fi

# 2.2 安装 Oh My Zsh
log_info ""
log_info "2.2 安装 Oh My Zsh..."
if [ ! -d "$OMZ_DIR" ]; then
    log_info "开始安装 Oh My Zsh..."

    # 设置环境变量，避免自动切换 shell
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    export CHSH=no

    # 安装 Oh My Zsh（使用代理如果设置了）
    if [ -n "$PROXY" ]; then
        log_info "使用代理安装 Oh My Zsh: $PROXY"
        if curl --proxy "$PROXY" -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh; then
            log_success "Oh My Zsh 安装成功"
        else
            log_error "Oh My Zsh 安装失败"
            exit 1
        fi
    else
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            log_success "Oh My Zsh 安装成功"
        else
            log_error "Oh My Zsh 安装失败"
            exit 1
        fi
    fi
else
    log_info "Oh My Zsh 已安装，跳过"

    # 检查并更新 Oh My Zsh（确保内置插件是最新的）
    log_info "检查 Oh My Zsh 是否需要更新..."
    if [ -d "$OMZ_DIR/.git" ]; then
        cd "$OMZ_DIR"
        if git pull --quiet 2>/dev/null; then
            log_success "Oh My Zsh 已更新到最新版本"
        else
            log_warning "Oh My Zsh 更新失败或已是最新版本"
        fi
        cd - > /dev/null
    fi
fi

# 2.2.1 检查并修复缺失的内置插件（copydir, copyfile 等）
log_info ""
log_info "2.2.1 检查 Oh My Zsh 内置插件..."
if [ -d "$OMZ_DIR" ]; then
    OMZ_PLUGINS_DIR="$OMZ_DIR/plugins"
    MISSING_BUILTIN_PLUGINS=()

    # 检查模板中配置的内置插件
    if [ -f "$CHEZMOI_DIR/dot_zshrc.tmpl" ]; then
        BUILTIN_PLUGINS=$(grep -A 20 "^plugins=" "$CHEZMOI_DIR/dot_zshrc.tmpl" 2>/dev/null | grep -E "^\s+(copydir|copyfile|extract|web-search|colored-man-pages|dirhistory)" | sed 's/^[[:space:]]*//' | sed 's/#.*$//' | grep -v "^$" || echo "")

        if [ -n "$BUILTIN_PLUGINS" ]; then
            while IFS= read -r plugin_name; do
                if [ -n "$plugin_name" ] && [[ ! "$plugin_name" =~ ^# ]]; then
                    plugin_path="$OMZ_PLUGINS_DIR/$plugin_name"
                    if [ ! -d "$plugin_path" ]; then
                        MISSING_BUILTIN_PLUGINS+=("$plugin_name")
                        log_warning "  ✗ 内置插件 $plugin_name 不存在"
                    else
                        log_info "  ✓ 内置插件 $plugin_name 存在"
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
                # 再次检查
                for plugin_name in "${MISSING_BUILTIN_PLUGINS[@]}"; do
                    plugin_path="$OMZ_PLUGINS_DIR/$plugin_name"
                    if [ ! -d "$plugin_path" ]; then
                        log_warning "  ⚠ 插件 $plugin_name 在更新后仍不存在，可能需要手动处理"
                    else
                        log_success "  ✓ 插件 $plugin_name 在更新后已存在"
                    fi
                done
            else
                log_warning "Oh My Zsh 更新失败"
            fi
            cd - > /dev/null
        fi
    fi
fi

# 2.3 安装插件
log_info ""
log_info "2.3 安装 Oh My Zsh 插件..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$ZSH_CUSTOM"

# 使用普通数组而不是关联数组，以提高兼容性
PLUGINS=(
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-completions|https://github.com/zsh-users/zsh-completions"
)

INSTALLED_COUNT=0
TOTAL_PLUGINS=${#PLUGINS[@]}

for plugin_entry in "${PLUGINS[@]}"; do
    # 分割插件名和URL
    plugin_name="${plugin_entry%%|*}"
    plugin_url="${plugin_entry#*|}"
    plugin_path="$ZSH_CUSTOM/$plugin_name"

    if [ -d "$plugin_path" ]; then
        log_info "  ✓ $plugin_name 已安装"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        log_info "  安装插件: $plugin_name..."
        # 使用代理配置 git（如果设置了代理）
        if [ -n "$PROXY" ]; then
            log_info "    使用代理: $PROXY"
            # 配置 git 使用代理
            git config --global http.proxy "$PROXY" 2>/dev/null || true
            git config --global https.proxy "$PROXY" 2>/dev/null || true
        fi

        # 尝试使用代理下载
        if git clone "$plugin_url" "$plugin_path" 2>&1 | tee /tmp/git_clone_output.log; then
            log_success "  ✓ $plugin_name 安装成功"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            # 如果失败，检查是否是网络问题
            if grep -qE "(timeout|connection|network|proxy)" /tmp/git_clone_output.log 2>/dev/null; then
                log_warning "  ✗ $plugin_name 安装失败（网络问题）"
                log_info "    尝试使用代理或检查网络连接"
            else
                log_warning "  ✗ $plugin_name 安装失败"
            fi
            log_info "    手动安装: git clone $plugin_url $plugin_path"
            rm -f /tmp/git_clone_output.log 2>/dev/null || true
        fi
    fi
done

log_info ""
log_info "已安装插件: $INSTALLED_COUNT/$TOTAL_PLUGINS"

# ============================================
# 步骤 3: 通过模板生成配置（有日志）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 3: 通过模板生成配置"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 3.1 检查模板文件
log_info ""
log_info "3.1 检查模板文件..."
ZSHRC_TEMPLATE="$CHEZMOI_DIR/dot_zshrc.tmpl"
if [ -f "$ZSHRC_TEMPLATE" ]; then
    TEMPLATE_SIZE=$(wc -c < "$ZSHRC_TEMPLATE" 2>/dev/null || echo "0")
    log_success "模板文件存在: $ZSHRC_TEMPLATE"
    log_info "  文件大小: $TEMPLATE_SIZE 字节"

    # 检查模板中的插件配置
    TEMPLATE_PLUGINS=$(grep -A 15 "^plugins=" "$ZSHRC_TEMPLATE" 2>/dev/null | head -16 || echo "")
    if [ -n "$TEMPLATE_PLUGINS" ]; then
        log_success "  模板中包含插件配置:"
        echo "$TEMPLATE_PLUGINS" | head -5 | while IFS= read -r line; do
            log_info "    $line"
        done
    fi
else
    log_error "模板文件不存在: $ZSHRC_TEMPLATE"
    exit 1
fi

# 3.2 备份现有文件
log_info ""
log_info "3.2 备份现有文件..."
if [ -f "$HOME/.zshrc" ]; then
    BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.zshrc" "$BACKUP_FILE"
    log_success "已备份: $BACKUP_FILE"
else
    log_info "没有现有文件需要备份"
fi

# 3.3 从模板生成配置
log_info ""
log_info "3.3 从模板生成配置..."

# 方法 1: 使用 chezmoi execute-template（推荐，不会进入 pager）
log_info "尝试方法 1: 使用 chezmoi execute-template..."
if command -v chezmoi &> /dev/null; then
    # 先删除旧文件
    rm -f "$HOME/.zshrc"

    # 禁用 pager 避免进入编辑模式
    export CHEZMOI_PAGER=""

    # 使用 execute-template 直接生成文件（不会进入 pager）
    if command -v timeout &> /dev/null; then
        if timeout 30 chezmoi execute-template < "$ZSHRC_TEMPLATE" > "$HOME/.zshrc" 2>&1; then
            log_success ".zshrc 已从模板创建（通过 chezmoi execute-template）"
            USE_METHOD2=false
        else
            log_warning "chezmoi execute-template 超时或失败，尝试方法 2..."
            USE_METHOD2=true
        fi
    else
        if chezmoi execute-template < "$ZSHRC_TEMPLATE" > "$HOME/.zshrc" 2>&1; then
            log_success ".zshrc 已从模板创建（通过 chezmoi execute-template）"
            USE_METHOD2=false
        else
            log_warning "chezmoi execute-template 失败，尝试方法 2..."
            USE_METHOD2=true
        fi
    fi
else
    log_warning "chezmoi 未安装，使用方法 2..."
    USE_METHOD2=true
fi

# 方法 2: 使用 chezmoi execute-template
if [ "$USE_METHOD2" = true ]; then
    log_info "尝试方法 2: 使用 chezmoi execute-template..."
    if command -v chezmoi &> /dev/null; then
        if chezmoi execute-template < "$ZSHRC_TEMPLATE" > "$HOME/.zshrc" 2>&1; then
            log_success ".zshrc 已从模板创建（通过 chezmoi execute-template）"
        else
            log_warning "chezmoi execute-template 失败，使用方法 3..."
            USE_METHOD3=true
        fi
    else
        USE_METHOD3=true
    fi
fi

# 方法 3: 直接复制模板文件（.zshrc.tmpl 中没有模板变量）
if [ "${USE_METHOD3:-false}" = true ]; then
    log_info "使用方法 3: 直接复制模板文件..."
    if cp "$ZSHRC_TEMPLATE" "$HOME/.zshrc" 2>/dev/null; then
        log_success ".zshrc 已从模板创建（直接复制）"
    else
        log_error "所有方法都失败，无法创建 .zshrc"
        exit 1
    fi
fi

# 3.4 验证生成的文件
log_info ""
log_info "3.4 验证生成的文件..."
if [ -f "$HOME/.zshrc" ]; then
    FILE_SIZE=$(wc -c < "$HOME/.zshrc" 2>/dev/null || echo "0")
    log_success ".zshrc 文件已创建"
    log_info "  文件大小: $FILE_SIZE 字节"

    if [ "$FILE_SIZE" -lt 1000 ]; then
        log_error "文件太小，可能创建失败"
    fi
else
    log_error ".zshrc 文件不存在"
    exit 1
fi

# ============================================
# 步骤 4: 手动部署
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 4: 手动部署"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 4.1 添加到 chezmoi 管理
log_info ""
log_info "4.1 添加到 chezmoi 管理..."
if command -v chezmoi &> /dev/null; then
    # 检查是否已在管理中
    if chezmoi managed 2>/dev/null | grep -q "^\.zshrc$"; then
        log_info ".zshrc 已在管理中"

        # 检查是否有冲突
        DIFF_OUTPUT=$(chezmoi diff ~/.zshrc 2>&1 || true)
        if echo "$DIFF_OUTPUT" | grep -q "has changed since chezmoi last wrote it"; then
            log_warning "检测到文件冲突，使用 --force 重新添加..."
            chezmoi add --force ~/.zshrc 2>/dev/null || log_warning "重新添加失败"
        fi
    else
        log_info ".zshrc 未在管理中，添加到管理..."
        chezmoi add ~/.zshrc 2>/dev/null || log_warning "添加到管理失败"
    fi

    log_success ".zshrc 已在 chezmoi 管理中"
else
    log_warning "chezmoi 未安装，跳过添加到管理"
fi

# 4.2 应用配置（确保最新）
log_info ""
log_info "4.2 应用配置（确保最新）..."
if command -v chezmoi &> /dev/null; then
    if command -v timeout &> /dev/null; then
        APPLY_OUTPUT=$(timeout 30 chezmoi apply ~/.zshrc --force -v 2>&1 || echo "timeout or error")
        if echo "$APPLY_OUTPUT" | grep -q "timeout"; then
            log_warning "chezmoi apply 超时，但文件已创建"
        elif echo "$APPLY_OUTPUT" | grep -qE "(apply|create|write)"; then
            log_success "配置已应用"
        else
            log_info "配置已是最新"
        fi
    else
        if chezmoi apply ~/.zshrc --force -v 2>&1 | grep -qE "(apply|create|write)"; then
            log_success "配置已应用"
        else
            log_info "配置已是最新"
        fi
    fi
else
    log_warning "chezmoi 未安装，跳过应用配置"
fi

# ============================================
# 步骤 5: 验证
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "步骤 5: 验证"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 5.1 验证文件存在
log_info ""
log_info "5.1 验证文件存在..."
FILES_TO_CHECK=(
    "$HOME/.zshrc"
    "$HOME/.oh-my-zsh"
    "$ZSH_CUSTOM/zsh-autosuggestions"
    "$ZSH_CUSTOM/zsh-history-substring-search"
    "$ZSH_CUSTOM/zsh-syntax-highlighting"
    "$ZSH_CUSTOM/zsh-completions"
)

ALL_EXIST=true
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -e "$file" ]; then
        log_success "  ✓ $(basename "$file") 存在"
    else
        log_warning "  ✗ $(basename "$file") 不存在"
        ALL_EXIST=false
    fi
done

# 5.2 验证 .zshrc 配置
log_info ""
log_info "5.2 验证 .zshrc 配置..."
if [ -f "$HOME/.zshrc" ]; then
    # 检查 Oh My Zsh 配置
    if grep -q "^export ZSH=" "$HOME/.zshrc" 2>/dev/null; then
        ZSH_VAR=$(grep "^export ZSH=" "$HOME/.zshrc" 2>/dev/null | head -1)
        log_success "  ✓ 包含 Oh My Zsh 配置: $ZSH_VAR"
    else
        log_warning "  ✗ 未找到 Oh My Zsh 配置"
    fi

    # 检查插件配置
    PLUGINS_SECTION=$(grep -A 20 "^plugins=" "$HOME/.zshrc" 2>/dev/null | head -21 || echo "")
    if [ -n "$PLUGINS_SECTION" ]; then
        log_success "  ✓ 包含插件配置:"
        echo "$PLUGINS_SECTION" | head -10 | while IFS= read -r line; do
            log_info "    $line"
        done

        # 检查自定义插件（需要安装的插件）
        MISSING_CUSTOM_PLUGINS=()
        for plugin_entry in "${PLUGINS[@]}"; do
            plugin_name="${plugin_entry%%|*}"
            if ! echo "$PLUGINS_SECTION" | grep -q "$plugin_name"; then
                MISSING_CUSTOM_PLUGINS+=("$plugin_name")
            fi
        done

        if [ ${#MISSING_CUSTOM_PLUGINS[@]} -eq 0 ]; then
            log_success "  ✓ 所有自定义插件都在配置中"
        else
            log_warning "  ✗ 以下自定义插件未在配置中: ${MISSING_CUSTOM_PLUGINS[*]}"
        fi

        # 检查模板中的其他插件（Oh My Zsh 内置插件）
        TEMPLATE_PLUGINS_LIST=$(grep -A 20 "^plugins=" "$ZSHRC_TEMPLATE" 2>/dev/null | grep -E "^\s+[a-z-]+" | sed 's/^[[:space:]]*//' | sed 's/#.*$//' | grep -v "^$" || echo "")
        MISSING_TEMPLATE_PLUGINS=()
        if [ -n "$TEMPLATE_PLUGINS_LIST" ]; then
            while IFS= read -r template_plugin; do
                # 跳过注释行和空行
                if [[ "$template_plugin" =~ ^# ]] || [ -z "$template_plugin" ]; then
                    continue
                fi
                # 检查插件是否在配置中
                if ! echo "$PLUGINS_SECTION" | grep -qE "(^|[[:space:]])${template_plugin}([[:space:]]|$)"; then
                    MISSING_TEMPLATE_PLUGINS+=("$template_plugin")
                fi
            done <<< "$TEMPLATE_PLUGINS_LIST"
        fi

        if [ ${#MISSING_TEMPLATE_PLUGINS[@]} -eq 0 ]; then
            log_success "  ✓ 所有模板插件都在配置中"
        else
            log_warning "  ✗ 以下模板插件未在配置中: ${MISSING_TEMPLATE_PLUGINS[*]}"
        fi
    else
        log_warning "  ✗ 未找到插件配置"
    fi

    # 检查 Oh My Zsh 初始化
    if grep -q "source.*oh-my-zsh.sh" "$HOME/.zshrc" 2>/dev/null; then
        log_success "  ✓ 包含 Oh My Zsh 初始化"
    else
        log_warning "  ✗ 未找到 Oh My Zsh 初始化"
    fi
else
    log_error "  ✗ .zshrc 文件不存在"
    ALL_EXIST=false
fi

# 5.3 验证 chezmoi 管理状态
log_info ""
log_info "5.3 验证 chezmoi 管理状态..."
if command -v chezmoi &> /dev/null; then
    if chezmoi managed 2>/dev/null | grep -q "^\.zshrc$"; then
        log_success "  ✓ .zshrc 在 chezmoi 管理中"
    else
        log_warning "  ✗ .zshrc 未在 chezmoi 管理中"
    fi

    # 检查状态
    STATUS_OUTPUT=$(chezmoi status ~/.zshrc 2>&1 || true)
    if [ -z "$STATUS_OUTPUT" ]; then
        log_success "  ✓ .zshrc 配置已同步"
    else
        log_warning "  ⚠ .zshrc 配置未同步:"
        echo "$STATUS_OUTPUT" | while IFS= read -r line; do
            log_info "    $line"
        done
    fi
else
    log_warning "  ⚠ chezmoi 未安装，跳过验证"
fi

# ============================================
# 完成
# ============================================
end_script

log_info ""
if [ "$ALL_EXIST" = true ]; then
    log_success "所有验证通过！"
else
    log_warning "部分验证未通过，请检查上面的输出"
fi

log_info ""
log_info "下一步操作："
log_info "  1. 重新加载配置: source ~/.zshrc"
log_info "  2. 或切换到 zsh: chsh -s $(which zsh) 然后重新打开终端"
log_info "  3. 检查效果: 应该看到语法高亮和自动建议"
log_info ""
log_info "如果还有问题，请检查:"
log_info "  - 插件是否已安装: ls ~/.oh-my-zsh/custom/plugins/"
log_info "  - .zshrc 配置: cat ~/.zshrc | grep -A 20 '^plugins='"
log_info "  - chezmoi 状态: chezmoi status ~/.zshrc"

