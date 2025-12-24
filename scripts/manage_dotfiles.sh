#!/bin/bash

# ============================================
# 统一 dotfiles 管理脚本
# 封装 chezmoi 命令，提供友好的中文提示
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
HELPERS_SH="${SCRIPT_DIR}/chezmoi/helpers.sh"

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

# 加载 chezmoi 辅助函数库
if [ -f "$HELPERS_SH" ]; then
    source "$HELPERS_SH"
fi

# ============================================
# 检查 chezmoi 是否已安装
# ============================================
check_chezmoi() {
    if ! command -v chezmoi &> /dev/null; then
        log_error "chezmoi 未安装"
        log_info "请先运行: ./scripts/chezmoi/install_chezmoi.sh"
        exit 1
    fi
}

# ============================================
# 设置 chezmoi 源状态目录
# 使用 helpers.sh 中的函数
# ============================================
setup_chezmoi_source() {
    if command -v setup_chezmoi_source_dir &> /dev/null; then
        # 使用 helpers.sh 中的函数
        setup_chezmoi_source_dir
    else
        # 回退到本地实现
        init_chezmoi_env
        local source_dir="${PROJECT_ROOT}/.chezmoi"
        if [ -d "$source_dir" ]; then
            export CHEZMOI_SOURCE_DIR="$source_dir"
            log_info "使用源状态目录: $source_dir"
        else
            log_warning "源状态目录不存在: $source_dir"
            log_info "将使用默认源状态目录"
        fi
    fi
}

# ============================================
# 命令处理
# ============================================

cmd_install() {
    log_info "安装 chezmoi..."
    bash "${SCRIPT_DIR}/chezmoi/install_chezmoi.sh"

    # 安装后验证
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

    log_info "初始化 chezmoi 仓库..."
    setup_chezmoi_source

    # 使用 helpers.sh 中的函数初始化仓库
    if command -v init_chezmoi_repo &> /dev/null; then
        init_chezmoi_repo
    elif [ -n "$CHEZMOI_SOURCE_DIR" ] && [ ! -d "${CHEZMOI_SOURCE_DIR}/.git" ]; then
        log_info "初始化 Git 仓库..."
        cd "$CHEZMOI_SOURCE_DIR"
        git init
        git add .
        git commit -m "Initial commit" || true
        cd - > /dev/null
    fi
}

cmd_apply() {
    check_chezmoi
    setup_chezmoi_source
    log_info "应用所有配置..."
    chezmoi apply -v
}

cmd_update() {
    check_chezmoi
    setup_chezmoi_source
    log_info "更新配置..."
    chezmoi update -v
}

cmd_diff() {
    check_chezmoi
    setup_chezmoi_source
    log_info "查看配置差异..."
    chezmoi diff
}

cmd_status() {
    check_chezmoi
    setup_chezmoi_source
    log_info "查看配置状态..."
    chezmoi status
}

cmd_edit() {
    check_chezmoi
    setup_chezmoi_source
    if [ -z "$1" ]; then
        error_exit "请指定要编辑的文件，例如: $0 edit ~/.zshrc"
    fi
    log_info "编辑配置文件: $1"
    chezmoi edit "$1"
}

cmd_list() {
    check_chezmoi
    setup_chezmoi_source
    log_info "列出所有受管理的文件..."
    chezmoi managed
}

cmd_cd() {
    check_chezmoi
    setup_chezmoi_source
    log_info "进入 chezmoi 源状态目录..."
    chezmoi cd
}

cmd_help() {
    cat << EOF
用法: $0 <command> [options]

命令:
  install         安装 chezmoi 并初始化仓库
  apply           应用所有配置到系统
  update          更新配置（拉取仓库后使用）
  diff            查看配置差异
  status          查看配置状态
  edit <file>     编辑配置文件
  list            列出所有受管理的文件
  cd              进入 chezmoi 源状态目录
  help            显示此帮助信息

示例:
  $0 install              # 安装并初始化
  $0 apply                # 应用所有配置
  $0 edit ~/.zshrc        # 编辑 zsh 配置
  $0 diff                 # 查看差异
EOF
}

# ============================================
# 主函数
# ============================================
main() {
    local cmd="${1:-help}"

    case "$cmd" in
        install)
            cmd_install
            ;;
        apply)
            cmd_apply
            ;;
        update)
            cmd_update
            ;;
        diff)
            cmd_diff
            ;;
        status)
            cmd_status
            ;;
        edit)
            cmd_edit "$2"
            ;;
        list)
            cmd_list
            ;;
        cd)
            cmd_cd
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "未知命令: $cmd"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
