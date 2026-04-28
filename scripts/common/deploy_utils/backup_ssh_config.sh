#!/usr/bin/env bash

# ============================================
# SSH 配置文件备份脚本
# 功能：备份 ~/.ssh/config 文件
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

# SSH 配置目录和文件
readonly SSH_DIR="${HOME}/.ssh"
readonly SSH_CONFIG="${SSH_DIR}/config"

# 错误处理：捕获 ERR 信号并记录错误信息
trap 'log_error "Error detected, exiting script"; exit 1' ERR

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") [选项]

选项:
    -h, --help      显示此帮助信息
    -f, --force     强制备份（即使文件不存在也创建备份目录）

功能:
    备份 ~/.ssh/config 文件到 ~/.ssh/config.backup.YYYYMMDD_HHMMSS

示例:
    $(basename "$0")              # 备份 SSH 配置
    $(basename "$0") --force      # 强制备份（创建目录）
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

    start_script "SSH 配置文件备份"

    # 检查 SSH 配置目录是否存在
    if [[ ! -d "${SSH_DIR}" ]]; then
        if [[ "${force_backup}" == "true" ]]; then
            log_info "创建 SSH 目录: ${SSH_DIR}"
            mkdir -p "${SSH_DIR}"
            chmod 700 "${SSH_DIR}"
        else
            log_warning "SSH 目录不存在: ${SSH_DIR}"
            log_info "如果文件不存在，请使用 --force 选项创建目录"
            exit 0
        fi
    fi

    # 检查 SSH 配置文件是否存在
    if [[ ! -f "${SSH_CONFIG}" ]]; then
        if [[ "${force_backup}" == "true" ]]; then
            log_warning "SSH 配置文件不存在: ${SSH_CONFIG}"
            log_info "将创建空文件作为备份"
            touch "${SSH_CONFIG}"
            chmod 600 "${SSH_CONFIG}"
        else
            log_warning "SSH 配置文件不存在: ${SSH_CONFIG}"
            log_info "如果文件不存在，请使用 --force 选项"
            exit 0
        fi
    fi

    # 生成备份文件名（带时间戳）
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${SSH_CONFIG}.backup.${timestamp}"

    # 执行备份
    log_info "备份 SSH 配置文件..."
    log_info "源文件: ${SSH_CONFIG}"
    log_info "备份文件: ${backup_file}"

    cp "${SSH_CONFIG}" "${backup_file}"
    chmod 600 "${backup_file}"

    if [[ -f "${backup_file}" ]]; then
        log_success "备份完成: ${backup_file}"

        # 显示备份文件信息
        local file_size
        file_size=$(du -h "${backup_file}" | cut -f1)
        log_info "备份文件大小: ${file_size}"

        # 列出所有备份文件
        local backup_count
        backup_count=$(find "${SSH_DIR}" -name "config.backup.*" -type f 2>/dev/null | wc -l | tr -d ' ')
        log_info "当前备份文件数量: ${backup_count}"

        if [[ ${backup_count} -gt 5 ]]; then
            log_warning "备份文件数量较多（${backup_count} 个），建议清理旧备份"
            log_info "可以使用以下命令查看备份文件:"
            log_info "  ls -lh ${SSH_DIR}/config.backup.*"
        fi
    else
        error_exit "备份失败"
    fi

    end_script
}

# 执行主函数
main "$@"

