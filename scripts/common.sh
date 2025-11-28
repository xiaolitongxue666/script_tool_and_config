#!/bin/bash

# ============================================
# 通用脚本函数库
# 提供颜色输出、日志记录、错误处理等功能
# ============================================

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0) 2>/dev/null || cd "$(dirname "$0")" && pwd)
readonly ARGS="$@"

# ============================================
# 颜色定义
# ============================================
# 黑色        0;30     深灰色       1;30
# 红色        0;31     浅红色       1;31
# 绿色        0;32     浅绿色       1;32
# 棕色/橙色   0;33     黄色         1;33
# 蓝色        0;34     浅蓝色       1;34
# 紫色        0;35     浅紫色       1;35
# 青色        0;36     浅青色       1;36
# 浅灰色      0;37     白色         1;37

readonly BLACK='\e[0;30m'
readonly RED='\e[0;31m'
readonly GREEN='\e[0;32m'
readonly ORANGE='\e[0;33m'
readonly BLUE='\e[0;34m'
readonly PURPLE='\e[0;35m'
readonly CYAN='\e[0;36m'
readonly LIGHT_GRAY='\e[0;37m'

readonly DARK_GRAY='\e[1;30m'
readonly LIGHT_RED='\e[1;31m'
readonly LIGHT_GREEN='\e[1;32m'
readonly YELLOW='\e[1;33m'
readonly LIGHT_BLUE='\e[1;34m'
readonly LIGHT_PURPLE='\e[1;35m'
readonly LIGHT_CYAN='\e[1;36m'
readonly WHITE='\e[1;37m'
readonly NO_COLOR='\e[0m'

# ============================================
# 日志输出函数
# ============================================

# 输出带颜色的消息
function echo_color_message() {
    echo -e "${1}${2}${NO_COLOR}"
}

# 信息日志（蓝色）
function log_info() {
    echo_color_message "${BLUE}" "[INFO] $*"
}

# 成功日志（绿色）
function log_success() {
    echo_color_message "${GREEN}" "[SUCCESS] $*"
}

# 警告日志（黄色）
function log_warning() {
    echo_color_message "${YELLOW}" "[WARNING] $*"
}

# 错误日志（红色）
function log_error() {
    echo_color_message "${RED}" "[ERROR] $*" >&2
}

# 调试日志（青色）
function log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo_color_message "${CYAN}" "[DEBUG] $*"
    fi
}

# ============================================
# 脚本生命周期函数
# ============================================

# 脚本开始
function start_script() {
    echo ""
    echo_color_message "${CYAN}" "=========================================="
    echo_color_message "${CYAN}" "Starting: $1"
    echo_color_message "${CYAN}" "=========================================="
    echo ""
}

# 脚本结束
function end_script() {
    echo ""
    echo_color_message "${CYAN}" "=========================================="
    echo_color_message "${CYAN}" "Script execution completed"
    echo_color_message "${CYAN}" "=========================================="
    echo ""
    trap - EXIT
    exit 0
}

# 脚本错误退出
function error_exit() {
    local error_msg="${1:-Unknown error}"
    local exit_code="${2:-1}"
    log_error "$error_msg"
    exit "$exit_code"
}

# ============================================
# 错误处理
# ============================================

# 检查命令是否存在
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        error_exit "Command '$1' not found, please install it first"
    fi
}

# 检查文件是否存在
function check_file() {
    if [[ ! -f "$1" ]]; then
        error_exit "File does not exist: $1"
    fi
}

# 检查目录是否存在
function check_directory() {
    if [[ ! -d "$1" ]]; then
        error_exit "Directory does not exist: $1"
    fi
}

# 检查是否为 root 用户
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script requires root privileges, please run with sudo"
    fi
}

# ============================================
# 工具函数
# ============================================

# 确认操作
function confirm() {
    local prompt="${1:-Continue?}"
    read -p "$(echo_color_message "${YELLOW}" "$prompt (y/n): ")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

# 创建目录（如果不存在）
function ensure_directory() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        log_info "Directory created: $1"
    fi
}

# 备份文件
function backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "File backed up: $backup"
        echo "$backup"
    fi
}
