#!/bin/bash

# ============================================
# chezmoi 安装脚本
# 支持 Linux、macOS、Windows 多平台安装
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

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

start_script "chezmoi 安装脚本"

# ============================================
# 检测操作系统
# ============================================
OS="$(uname -s)"
log_info "检测到操作系统: $OS"

if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
else
    error_exit "不支持的操作系统: $OS"
fi

log_success "平台: $PLATFORM"

# ============================================
# 创建必要的目录
# ============================================
# 创建 ~/.local/bin 目录（用于官方安装脚本）
if [ ! -d "$HOME/.local/bin" ]; then
    log_info "创建目录: $HOME/.local/bin"
    mkdir -p "$HOME/.local/bin"
else
    log_info "目录已存在: $HOME/.local/bin"
fi

# ============================================
# 检查 chezmoi 是否已安装
# ============================================
if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
    read -p "是否重新安装？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "跳过安装"
        end_script
    fi
fi

# ============================================
# 代理配置
# ============================================
# 从环境变量获取代理，如果没有则使用默认值
if [ -n "${PROXY:-}" ]; then
    # 如果代理地址没有 http:// 或 https:// 前缀，自动添加
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
elif [ -n "${http_proxy:-}" ]; then
    PROXY="$http_proxy"
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
else
    PROXY="http://127.0.0.1:7890"
fi

# 设置代理环境变量
export PROXY="$PROXY"
export http_proxy="$PROXY"
export https_proxy="$PROXY"
export HTTP_PROXY="$PROXY"
export HTTPS_PROXY="$PROXY"
log_info "使用代理: $PROXY"

# ============================================
# 安装 chezmoi
# ============================================
log_info "开始安装 chezmoi..."

# 临时禁用 set -e 以便更好地处理错误
set +e

case "$PLATFORM" in
    macos)
        # macOS: 使用 Homebrew（推荐）或官方安装脚本
        if command -v brew &> /dev/null; then
            log_info "使用 Homebrew 安装 chezmoi..."
            brew install chezmoi
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
            else
                log_warning "Homebrew 安装失败，尝试使用官方安装脚本..."
                sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            fi
        else
            log_info "使用官方安装脚本安装 chezmoi..."
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
                # 添加到 PATH
                if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bash_profile" 2>/dev/null || \
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
                    log_info "已将 ~/.local/bin 添加到 PATH"
                fi
            else
                error_exit "chezmoi 安装失败"
            fi
        fi
        ;;
    linux)
        # Linux: 优先使用包管理器，否则使用官方安装脚本
        if command -v pacman &> /dev/null; then
            log_info "使用 pacman 安装 chezmoi..."
            # 检查包是否存在
            if pacman -Ss chezmoi | grep -q "^community/chezmoi"; then
                log_info "chezmoi 包在仓库中找到"
            else
                log_warning "chezmoi 包可能不在仓库中，尝试同步数据库..."
                sudo pacman -Sy || log_warning "数据库同步失败，继续尝试安装..."
            fi

            # 尝试安装
            log_info "执行: sudo pacman -S --noconfirm chezmoi"
            PACMAN_OUTPUT=$(sudo pacman -S --noconfirm chezmoi 2>&1)
            PACMAN_EXIT_CODE=$?

            if [ $PACMAN_EXIT_CODE -eq 0 ]; then
                log_success "pacman 安装 chezmoi 成功"
                # 刷新 PATH（pacman 安装到系统路径，通常不需要）
                hash -r 2>/dev/null || true
            else
                log_error "pacman 安装 chezmoi 失败 (退出码: $PACMAN_EXIT_CODE)"
                log_info "pacman 输出:"
                echo "$PACMAN_OUTPUT" | while IFS= read -r line; do
                    log_info "  $line"
                done
                log_info "可能的原因："
                log_info "  - 需要同步数据库: sudo pacman -Sy"
                log_info "  - 包不存在或名称错误"
                log_info "  - 权限问题"
                log_info "  - 网络连接问题"
                log_info "尝试使用官方安装脚本..."

                # 创建目录
                mkdir -p "$HOME/.local/bin"

                # 测试网络连接
                log_info "测试网络连接..."
                if curl -fsLS --max-time 5 --proxy "$PROXY" https://www.chezmoi.io > /dev/null 2>&1; then
                    log_success "可以访问 chezmoi 官网"
                else
                    log_warning "无法访问 chezmoi 官网，可能代理有问题"
                    log_info "尝试不使用代理..."
                    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
                fi

                # 使用官方安装脚本
                log_info "下载并安装 chezmoi..."
                log_info "执行: curl -fsLS get.chezmoi.io | sh -s -- -b $HOME/.local/bin"
                INSTALL_OUTPUT=$(sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" 2>&1)
                INSTALL_EXIT_CODE=$?

                if [ $INSTALL_EXIT_CODE -eq 0 ] && [ -f "$HOME/.local/bin/chezmoi" ]; then
                    log_success "官方安装脚本安装成功"
                    chmod +x "$HOME/.local/bin/chezmoi" 2>/dev/null || true
                    # 添加到 PATH
                    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || \
                        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
                        log_info "已将 ~/.local/bin 添加到 PATH"
                    fi
                    # 立即生效
                    export PATH="$HOME/.local/bin:$PATH"
                else
                    log_error "官方安装脚本执行失败 (退出码: $INSTALL_EXIT_CODE)"
                    log_info "安装脚本输出:"
                    echo "$INSTALL_OUTPUT" | while IFS= read -r line; do
                        log_info "  $line"
                    done
                    if [ ! -f "$HOME/.local/bin/chezmoi" ]; then
                        log_error "chezmoi 可执行文件不存在: $HOME/.local/bin/chezmoi"
                    fi
                    error_exit "chezmoi 安装失败，请手动安装: sudo pacman -S chezmoi 或访问 https://www.chezmoi.io/install/"
                fi
            fi
        elif command -v apt-get &> /dev/null; then
            log_info "使用 apt-get 安装 chezmoi..."
            if sudo apt-get update && sudo apt-get install -y chezmoi; then
                log_success "apt-get 安装 chezmoi 成功"
                hash -r 2>/dev/null || true
            else
                error_exit "apt-get 安装 chezmoi 失败"
            fi
        elif command -v dnf &> /dev/null; then
            log_info "使用 dnf 安装 chezmoi..."
            if sudo dnf install -y chezmoi; then
                log_success "dnf 安装 chezmoi 成功"
                hash -r 2>/dev/null || true
            else
                error_exit "dnf 安装 chezmoi 失败"
            fi
        elif command -v yum &> /dev/null; then
            log_info "使用 yum 安装 chezmoi..."
            if sudo yum install -y chezmoi; then
                log_success "yum 安装 chezmoi 成功"
                hash -r 2>/dev/null || true
            else
                error_exit "yum 安装 chezmoi 失败"
            fi
        else
            log_info "使用官方安装脚本安装 chezmoi..."
            # 创建目录
            mkdir -p "$HOME/.local/bin"
            if sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"; then
                log_success "chezmoi 安装成功"
                # 添加到 PATH
                if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || \
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
                    log_info "已将 ~/.local/bin 添加到 PATH"
                fi
                # 立即生效
                export PATH="$HOME/.local/bin:$PATH"
            else
                error_exit "chezmoi 安装失败"
            fi
        fi
        ;;
    windows)
        # Windows: 使用 winget 或官方安装脚本
        if command -v winget &> /dev/null; then
            log_info "使用 winget 安装 chezmoi..."
            winget install --id=twpayne.chezmoi -e --accept-source-agreements --accept-package-agreements
        else
            log_info "使用官方安装脚本安装 chezmoi..."
            # Windows Git Bash 环境
            sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
            if [ $? -eq 0 ]; then
                log_success "chezmoi 安装成功"
                # 添加到 PATH
                if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bash_profile" 2>/dev/null || true
                    log_info "已将 ~/.local/bin 添加到 PATH"
                fi
            else
                error_exit "chezmoi 安装失败，请手动安装: https://www.chezmoi.io/install/"
            fi
        fi
        ;;
esac

# 重新启用 set -e
set -e

# ============================================
# 验证安装
# ============================================
# 刷新命令缓存
hash -r 2>/dev/null || true

# 如果使用官方安装脚本，确保 PATH 已更新
if [ -f "$HOME/.local/bin/chezmoi" ] && ! command -v chezmoi &> /dev/null; then
    export PATH="$HOME/.local/bin:$PATH"
    log_info "已将 ~/.local/bin 添加到当前会话的 PATH"
fi

# 再次检查
if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 安装成功: $CHEZMOI_VERSION"
    log_info "安装路径: $(which chezmoi)"
else
    # 检查是否真的安装了
    log_warning "chezmoi 命令不可用，检查安装状态..."

    if [ -f "$HOME/.local/bin/chezmoi" ]; then
        log_error "chezmoi 已安装到 ~/.local/bin/chezmoi，但不在 PATH 中"
        log_info "文件信息:"
        ls -lh "$HOME/.local/bin/chezmoi" | while IFS= read -r line; do
            log_info "  $line"
        done
        log_info "解决方案："
        log_info "  1. 运行: export PATH=\"\$HOME/.local/bin:\$PATH\""
        log_info "  2. 或重新打开终端"
        log_info "  3. 或添加到 ~/.bashrc: echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        error_exit "chezmoi 未在 PATH 中，无法继续"
    elif command -v pacman &> /dev/null && pacman -Q chezmoi &> /dev/null 2>&1; then
        log_error "chezmoi 已通过 pacman 安装，但命令不可用"
        log_info "pacman 安装信息:"
        pacman -Q chezmoi | while IFS= read -r line; do
            log_info "  $line"
        done
        log_info "检查系统路径:"
        if [ -f "/usr/bin/chezmoi" ]; then
            log_info "  找到: /usr/bin/chezmoi"
            ls -lh /usr/bin/chezmoi | while IFS= read -r line; do
                log_info "    $line"
            done
        else
            log_warning "  未找到: /usr/bin/chezmoi"
        fi
        log_info "当前 PATH: $PATH"
        log_info "解决方案："
        log_info "  1. 检查 PATH 环境变量"
        log_info "  2. 运行: hash -r"
        log_info "  3. 或重新打开终端"
        error_exit "chezmoi 命令不可用，无法继续"
    else
        log_error "chezmoi 安装失败或未正确安装"
        log_info "诊断信息:"
        log_info "  - 检查 ~/.local/bin/chezmoi: $([ -f "$HOME/.local/bin/chezmoi" ] && echo "存在" || echo "不存在")"
        if command -v pacman &> /dev/null; then
            log_info "  - 检查 pacman 安装: $([ -n "$(pacman -Q chezmoi 2>/dev/null)" ] && echo "已安装" || echo "未安装")"
        fi
        log_info "建议手动安装:"
        if command -v pacman &> /dev/null; then
            log_info "  sudo pacman -Sy && sudo pacman -S chezmoi"
        fi
        log_info "  或使用官方安装脚本:"
        log_info "  mkdir -p ~/.local/bin"
        log_info "  sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \"\$HOME/.local/bin\""
        log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        error_exit "chezmoi 安装失败，请手动安装"
    fi
fi

# ============================================
# 完成
# ============================================
end_script
