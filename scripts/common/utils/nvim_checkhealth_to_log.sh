#!/usr/bin/env bash
# ============================================
# 在终端通过脚本执行 Neovim checkhealth 并将结果保存为日志
# 使用 headless 模式，不打开 nvim 界面，适合 CI/脚本调用
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_LIB}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

# 默认日志路径：当前目录下的 nvim_checkhealth.log
readonly DEFAULT_LOG_NAME="nvim_checkhealth.log"

usage() {
    echo "用法: $0 [选项] [日志路径]"
    echo ""
    echo "执行 nvim :checkhealth 并将输出保存到指定日志文件。"
    echo "不指定路径时，保存到当前目录的 ${DEFAULT_LOG_NAME}。"
    echo ""
    echo "选项:"
    echo "  -h, --help    显示此帮助"
    echo ""
    echo "示例:"
    echo "  $0                          # 保存到 ./${DEFAULT_LOG_NAME}"
    echo "  $0 /tmp/nvim_health.log     # 保存到指定路径"
}

main() {
    local log_path=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "未知选项: $1"
                usage
                exit 1
                ;;
            *)
                log_path="$1"
                shift
                break
                ;;
        esac
    done

    if [[ -z "${log_path}" ]]; then
        log_path="${PWD}/${DEFAULT_LOG_NAME}"
    fi

    # 若为相对路径，转为绝对路径便于提示与写入一致
    if [[ "${log_path}" != /* ]]; then
        log_path="${PWD}/${log_path}"
    fi

    local log_dir
    log_dir="$(dirname "${log_path}")"
    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}"
        log_info "已创建目录: ${log_dir}"
    fi

    if ! command -v nvim &>/dev/null; then
        error_exit "未找到 nvim 命令，请先安装 Neovim"
    fi

    log_info "正在执行 nvim checkhealth，结果将保存到: ${log_path}"

    # --headless 下 checkhealth 会打开含结果的 buffer，用 :write! 保存到文件（redir 对 checkhealth 输出无效）
    local tmp_log="/tmp/nvim_checkhealth_$$.log"
    if nvim --headless -c "checkhealth" -c "lua vim.wait(10000)" -c "write! ${tmp_log}" -c "qa!" 2>/dev/null; then
        if [[ -f "${tmp_log}" ]]; then
            mv -f "${tmp_log}" "${log_path}"
        fi
        log_success "checkhealth 已完成，日志已写入: ${log_path}"
    else
        # headless 下 nvim 可能仍会写入了部分内容；退出码非 0 时也提示
        log_info "日志已写入: ${log_path}（请检查 nvim 或插件是否有报错）"
        exit 1
    fi
}

main "$@"
