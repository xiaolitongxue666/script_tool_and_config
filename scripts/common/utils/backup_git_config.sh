#!/usr/bin/env bash

# ============================================
# Git 全局配置文件备份脚本
# 功能：备份 ~/.gitconfig 文件
# ============================================

set -euo pipefail

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取项目根目录的绝对路径
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# 通用脚本库路径
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

# 检查通用脚本库是否存在
if [[ ! -f "${COMMON_LIB}" ]]; then
    echo "[ERROR] Common script library not found: ${COMMON_LIB}" >&2
    exit 1
fi

# 引入通用日志/错误处理函数
# shellcheck disable=SC1090
source "${COMMON_LIB}"

# Git 全局配置文件路径
readonly GITCONFIG="${HOME}/.gitconfig"

# 错误处理：捕获 ERR 信号并记录错误信息
trap 'log_error "Error detected, exiting script"; exit 1' ERR

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") [选项]

选项:
    -h, --help      显示此帮助信息
    -f, --force     强制模式（文件不存在时也输出提示并退出）

功能:
    备份 ~/.gitconfig 文件到 ~/.gitconfig.backup.YYYYMMDD_HHMMSS

示例:
    $(basename "$0")              # 备份 Git 全局配置
    $(basename "$0") --force      # 强制模式（文件不存在时仍执行并提示）
EOF
    exit 0
}

# 主函数
main() {
    local force_backup=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -f|--force)
                force_backup=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                usage
                ;;
        esac
    done

    start_script "Git 全局配置文件备份"

    # 检查 Git 配置文件是否存在
    if [[ ! -f "${GITCONFIG}" ]]; then
        log_warning "Git 配置文件不存在: ${GITCONFIG}"
        if [[ "${force_backup}" == "true" ]]; then
            log_info "使用 --force 时若文件不存在则跳过备份"
        else
            log_info "若文件不存在，请使用 --force 选项以确认跳过"
        fi
        exit 0
    fi

    # 生成备份文件名（带时间戳）
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${GITCONFIG}.backup.${timestamp}"

    # 执行备份
    log_info "备份 Git 全局配置文件..."
    log_info "源文件: ${GITCONFIG}"
    log_info "备份文件: ${backup_file}"

    cp "${GITCONFIG}" "${backup_file}"
    chmod 600 "${backup_file}"

    if [[ -f "${backup_file}" ]]; then
        log_success "备份完成: ${backup_file}"

        # 显示备份文件信息
        local file_size
        file_size=$(du -h "${backup_file}" | cut -f1)
        log_info "备份文件大小: ${file_size}"

        # 列出当前用户主目录下所有 gitconfig 备份数量
        local backup_count
        backup_count=$(find "${HOME}" -maxdepth 1 -name ".gitconfig.backup.*" -type f 2>/dev/null | wc -l | tr -d ' ')
        log_info "当前备份文件数量: ${backup_count}"

        if [[ ${backup_count} -gt 5 ]]; then
            log_warning "备份文件数量较多（${backup_count} 个），建议清理旧备份"
            log_info "可以使用以下命令查看备份文件:"
            log_info "  ls -lh ${HOME}/.gitconfig.backup.*"
        fi
    else
        error_exit "备份失败"
    fi

    end_script
}

# 执行主函数
main "$@"
