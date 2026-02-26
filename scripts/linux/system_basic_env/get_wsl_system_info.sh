#!/usr/bin/env bash

# ============================================
# 获取 WSL / Linux 详细版本与环境信息
# 只读脚本，不修改任何系统配置
# 用于排查与文档记录
# ============================================

set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_LIB}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

# ============================================
# 节 1: 内核与架构 (uname)
# ============================================
print_section() {
    local title="$1"
    echo ""
    echo "=============================================="
    echo "${title}"
    echo "=============================================="
}

print_section "1. 内核与架构 (uname)"
uname -a
echo ""
echo "解析: 内核 $(uname -r), 架构 $(uname -m), 系统 $(uname -s)"

# ============================================
# 节 2: 发行版信息 (/etc/os-release)
# ============================================
print_section "2. 发行版信息 (/etc/os-release)"
if [[ -r /etc/os-release ]]; then
    cat /etc/os-release
else
    log_warning "/etc/os-release 不可读或不存在"
fi

# ============================================
# 节 3: 内核版本字符串与 WSL 检测 (/proc/version)
# ============================================
print_section "3. 内核版本字符串与 WSL 检测 (/proc/version)"
if [[ -r /proc/version ]]; then
    cat /proc/version
    if grep -qE "(Microsoft|WSL)" /proc/version 2>/dev/null; then
        echo ""
        log_success "当前运行在 WSL 环境中"
    else
        echo ""
        log_info "未检测到 WSL（非 Microsoft 内核）"
    fi
else
    log_warning "/proc/version 不可读或不存在"
fi

# ============================================
# 节 4: WSL 版本说明（需在 Windows 端查看）
# ============================================
print_section "4. WSL 版本（Windows 端）"
log_info "WSL 版本请在 Windows PowerShell 或 CMD 中执行: wsl --version"
if command -v wsl.exe &>/dev/null; then
    log_info "尝试调用 wsl.exe --version:"
    wsl.exe --version 2>/dev/null || log_warning "wsl.exe --version 执行失败或不可用"
else
    log_info "当前环境未找到 wsl.exe（在 WSL 内为正常情况）"
fi

# ============================================
# 节 5: 检测到的包管理器
# ============================================
print_section "5. 包管理器检测"
detected_pkg=""
if command -v pacman &>/dev/null; then
    detected_pkg="pacman (Arch)"
elif command -v apt-get &>/dev/null; then
    detected_pkg="apt (Debian/Ubuntu)"
elif command -v dnf &>/dev/null; then
    detected_pkg="dnf (Fedora/RHEL)"
elif command -v yum &>/dev/null; then
    detected_pkg="yum (CentOS/RHEL)"
else
    detected_pkg="未检测到支持的包管理器"
fi
log_info "当前检测到: ${detected_pkg}"

echo ""
log_success "系统信息输出完成"
