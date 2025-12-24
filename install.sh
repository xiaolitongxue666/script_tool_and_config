#!/bin/bash

# ============================================
# 一键安装脚本
# 自动检测系统、安装 chezmoi、应用所有配置
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

start_script "一键安装脚本"

# ============================================
# 解析命令行参数
# ============================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy|-p)
            PROXY="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --proxy, -p <地址>    指定代理地址（例如: http://192.168.1.76:7890）"
            echo "  --help, -h            显示此帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROXY                 代理地址（例如: http://192.168.1.76:7890）"
            echo "  http_proxy            代理地址（例如: http://192.168.1.76:7890）"
            echo ""
            echo "示例:"
            echo "  $0 --proxy http://192.168.1.76:7890"
            echo "  PROXY=http://192.168.1.76:7890 $0"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            log_info "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

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
# 代理配置（可选）
# ============================================
# 如果代理地址没有 http:// 或 https:// 前缀，自动添加
if [ -n "${PROXY:-}" ]; then
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
elif [ -n "${http_proxy:-}" ]; then
    PROXY="$http_proxy"
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
fi

# 设置代理环境变量
if [ -n "${PROXY:-}" ]; then
    export PROXY="$PROXY"
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    log_info "使用代理: $PROXY"
else
    log_info "未设置代理，使用直连"
fi

# ============================================
# 安装 chezmoi
# ============================================
log_info "检查 chezmoi 安装状态..."
if ! command -v chezmoi &> /dev/null; then
    log_info "chezmoi 未安装，开始安装..."
    bash "${SCRIPT_DIR}/scripts/chezmoi/install_chezmoi.sh"

    # 安装后再次验证
    hash -r 2>/dev/null || true

    # 如果使用官方安装脚本，确保 PATH 已更新
    if [ -f "$HOME/.local/bin/chezmoi" ] && ! command -v chezmoi &> /dev/null; then
        export PATH="$HOME/.local/bin:$PATH"
        log_info "已将 ~/.local/bin 添加到当前会话的 PATH"
    fi

    # 最终验证
    if ! command -v chezmoi &> /dev/null; then
        error_exit "chezmoi 安装后仍不可用，请检查安装过程或手动安装"
    fi

    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 安装成功: $CHEZMOI_VERSION"
else
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
fi

# ============================================
# 初始化 chezmoi 仓库
# ============================================
# 创建必要的目录
# 1. ~/.local/bin 目录（用于官方安装脚本安装的工具）
if [ ! -d "$HOME/.local/bin" ]; then
    log_info "创建目录: $HOME/.local/bin"
    mkdir -p "$HOME/.local/bin"
fi

# 2. chezmoi 状态目录（chezmoi 需要此目录存储状态信息）
CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
if [ ! -d "$CHEZMOI_STATE_DIR" ]; then
    log_info "创建 chezmoi 状态目录: $CHEZMOI_STATE_DIR"
    mkdir -p "$CHEZMOI_STATE_DIR"
else
    log_info "chezmoi 状态目录已存在: $CHEZMOI_STATE_DIR"
fi

# 源状态目录（项目内的 .chezmoi 目录）
CHEZMOI_DIR="${SCRIPT_DIR}/.chezmoi"

if [ ! -d "$CHEZMOI_DIR" ]; then
    log_info "创建 chezmoi 源状态目录..."
    mkdir -p "$CHEZMOI_DIR"

    # 初始化 Git 仓库
    if [ ! -d "${CHEZMOI_DIR}/.git" ]; then
        log_info "初始化 Git 仓库..."
        cd "$CHEZMOI_DIR"
        git init
        cd - > /dev/null
    fi
else
    log_info "chezmoi 源状态目录已存在: $CHEZMOI_DIR"
fi

# ============================================
# 应用配置
# ============================================
# 再次确认 chezmoi 可用
if ! command -v chezmoi &> /dev/null; then
    error_exit "chezmoi 命令不可用，无法继续应用配置"
fi

log_info "应用所有配置..."
if [ -d "$CHEZMOI_DIR" ] && [ "$(ls -A $CHEZMOI_DIR 2>/dev/null)" ]; then
    # 设置源状态目录
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

    # 应用配置
    log_info "运行: chezmoi apply -v"
    chezmoi apply -v

    log_success "配置应用完成！"
else
    log_warning "chezmoi 源状态目录为空"
    log_info "请先运行迁移脚本: ./scripts/migration/migrate_to_chezmoi.sh"
    log_info "或手动添加配置: chezmoi add ~/.zshrc"
fi

# ============================================
# 完成
# ============================================
end_script

log_success "安装完成！"
echo ""
log_info "后续操作："
log_info "  快速部署: ./deploy.sh"
log_info "  查看状态: ./scripts/manage_dotfiles.sh status"
log_info "  查看差异: ./scripts/manage_dotfiles.sh diff"
log_info "  编辑配置: ./scripts/manage_dotfiles.sh edit ~/.zshrc"
echo ""
log_info "使用帮助: ./scripts/manage_dotfiles.sh help"
log_info "部署指南: scripts/common/utils/DEPLOYMENT_GUIDE.md"
