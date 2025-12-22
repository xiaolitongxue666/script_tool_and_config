#!/usr/bin/env bash

# ============================================
# SSH 配置文件部署脚本
# 功能：通过 chezmoi 部署 SSH 配置文件
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
readonly BACKUP_SCRIPT="${SCRIPT_DIR}/backup_ssh_config.sh"

# 错误处理：捕获 ERR 信号并记录错误信息
trap 'log_error "Error detected, exiting script"; exit 1' ERR

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") [选项]

选项:
    -h, --help          显示此帮助信息
    -b, --backup        在部署前备份现有配置
    -s, --skip-backup   跳过备份步骤
    -f, --force         强制应用配置（覆盖现有文件）

功能:
    通过 chezmoi 部署 SSH 配置文件到 ~/.ssh/config
    自动设置正确的文件权限（600）

示例:
    $(basename "$0")                  # 部署 SSH 配置（自动备份）
    $(basename "$0") --backup         # 明确指定备份
    $(basename "$0") --skip-backup    # 跳过备份
    $(basename "$0") --force          # 强制覆盖
EOF
    exit 0
}

# 检查 chezmoi 是否已安装
check_chezmoi() {
    if ! command -v chezmoi &> /dev/null; then
        error_exit "chezmoi 未安装，请先安装 chezmoi"
    fi
    log_info "chezmoi 已安装: $(chezmoi --version | head -n 1)"
}

# 设置 chezmoi 源状态目录
setup_chezmoi_source() {
    local source_dir="${PROJECT_ROOT}/.chezmoi"

    if [[ ! -d "${source_dir}" ]]; then
        error_exit "chezmoi 源状态目录不存在: ${source_dir}"
    fi

    export CHEZMOI_SOURCE_DIR="${source_dir}"
    log_info "使用源状态目录: ${CHEZMOI_SOURCE_DIR}"
}

# 备份现有配置
backup_existing_config() {
    if [[ -f "${SSH_CONFIG}" ]]; then
        log_info "备份现有 SSH 配置..."
        if [[ -f "${BACKUP_SCRIPT}" ]]; then
            bash "${BACKUP_SCRIPT}" --force
        else
            log_warning "备份脚本不存在: ${BACKUP_SCRIPT}"
            log_info "手动创建备份..."
            local timestamp
            timestamp=$(date +%Y%m%d_%H%M%S)
            local backup_file="${SSH_CONFIG}.backup.${timestamp}"
            cp "${SSH_CONFIG}" "${backup_file}"
            chmod 600 "${backup_file}"
            log_success "备份完成: ${backup_file}"
        fi
    else
        log_info "SSH 配置文件不存在，无需备份"
    fi
}

# 确保 SSH 目录存在并设置正确权限
ensure_ssh_directory() {
    if [[ ! -d "${SSH_DIR}" ]]; then
        log_info "创建 SSH 目录: ${SSH_DIR}"
        mkdir -p "${SSH_DIR}"
    fi

    # 设置目录权限为 700
    chmod 700 "${SSH_DIR}"
    log_info "SSH 目录权限已设置: 700"
}

# 应用 SSH 配置
apply_ssh_config() {
    local force_flag=""
    if [[ "${1:-}" == "--force" ]]; then
        force_flag="--force"
    fi

    log_info "应用 SSH 配置..."

    # 检查配置是否在 chezmoi 管理中
    if ! chezmoi managed "${SSH_CONFIG}" &> /dev/null; then
        log_warning "SSH 配置不在 chezmoi 管理中"
        log_info "请先运行: chezmoi add ${SSH_CONFIG}"
        return 1
    fi

    # 应用配置
    if chezmoi apply ${force_flag} -v "${SSH_CONFIG}"; then
        log_success "SSH 配置已应用"
    else
        error_exit "应用 SSH 配置失败"
    fi

    # 确保文件权限正确（600）
    if [[ -f "${SSH_CONFIG}" ]]; then
        chmod 600 "${SSH_CONFIG}"
        log_info "SSH 配置文件权限已设置: 600"
    fi
}

# 验证配置
verify_config() {
    if [[ -f "${SSH_CONFIG}" ]]; then
        local file_size
        file_size=$(wc -l < "${SSH_CONFIG}" | tr -d ' ')
        log_info "SSH 配置文件行数: ${file_size}"

        # 检查文件权限
        local file_perms
        file_perms=$(stat -f "%OLp" "${SSH_CONFIG}" 2>/dev/null || stat -c "%a" "${SSH_CONFIG}" 2>/dev/null || echo "unknown")
        if [[ "${file_perms}" != "600" ]] && [[ "${file_perms}" != "unknown" ]]; then
            log_warning "文件权限不正确: ${file_perms}，应该是 600"
            log_info "正在修复权限..."
            chmod 600 "${SSH_CONFIG}"
        else
            log_success "文件权限正确: ${file_perms}"
        fi
    else
        log_warning "SSH 配置文件不存在"
    fi
}

# 主函数
main() {
    local do_backup=true
    local skip_backup=false
    local force_apply=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -b|--backup)
                do_backup=true
                skip_backup=false
                shift
                ;;
            -s|--skip-backup)
                do_backup=false
                skip_backup=true
                shift
                ;;
            -f|--force)
                force_apply=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                usage
                ;;
        esac
    done

    start_script "SSH 配置文件部署"

    # 检查 chezmoi
    check_chezmoi

    # 设置源状态目录
    setup_chezmoi_source

    # 确保 SSH 目录存在
    ensure_ssh_directory

    # 备份现有配置
    if [[ "${do_backup}" == "true" ]] && [[ "${skip_backup}" == "false" ]]; then
        backup_existing_config
    elif [[ "${skip_backup}" == "true" ]]; then
        log_info "跳过备份步骤"
    fi

    # 应用配置
    if [[ "${force_apply}" == "true" ]]; then
        apply_ssh_config --force
    else
        apply_ssh_config
    fi

    # 验证配置
    verify_config

    log_success "SSH 配置部署完成"
    log_info ""
    log_info "后续操作："
    log_info "  1. 编辑配置: chezmoi edit ${SSH_CONFIG}"
    log_info "  2. 查看差异: chezmoi diff ${SSH_CONFIG}"
    log_info "  3. 同步 lazyssh 更改: chezmoi re-add ${SSH_CONFIG}"

    end_script
}

# 执行主函数
main "$@"

