#!/bin/bash

# ============================================
# WSL2 专用 Docker 容器启动脚本
# 在 WSL2 环境中使用 Docker，自动配置 SSH Agent 转发
# ============================================

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# 加载通用函数库
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

# ============================================
# WSL2 环境检测
# ============================================

# 检查是否在 WSL 中运行
if ! grep -qE "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    log_error "此脚本专为 WSL2 设计"
    log_info "Windows 环境下 SSH Agent Forwarding 无法工作，必须使用 WSL2"
    log_info "请安装 WSL2: wsl --install"
    log_info "然后在 WSL2 中运行此脚本"
    exit 1
fi

log_info "检测到 WSL2 环境"

# 检查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    log_error "Docker 命令未找到"
    log_info "请确保："
    log_info "1. Docker Desktop 已安装"
    log_info "2. 已在 Docker Desktop 设置中启用 WSL2 集成"
    log_info "3. 当前 WSL2 发行版已启用 Docker 集成"
    exit 1
fi

# 验证 Docker 是否正常工作
if ! docker info >/dev/null 2>&1; then
    log_error "Docker 无法正常工作"
    log_info "请检查："
    log_info "1. Docker Desktop 是否正在运行"
    log_info "2. WSL2 集成是否已启用"
    log_info "3. 当前用户是否有 Docker 权限"
    exit 1
fi

log_success "Docker 可用"

# ============================================
# SSH Agent 配置函数
# ============================================

# 自动配置 Windows SSH Agent 转发
setup_wsl_ssh_agent() {
    log_info "配置 WSL2 SSH Agent 转发"
    
    # 方法1: 使用 wsl-ssh-agent（推荐）
    if command -v wsl-ssh-agent &> /dev/null; then
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
        if ! ss -a 2>/dev/null | grep -q "$SSH_AUTH_SOCK"; then
            # 如果 socket 不存在或未运行，启动 wsl-ssh-agent
            rm -f "$SSH_AUTH_SOCK"
            if wsl-ssh-agent -socket "$SSH_AUTH_SOCK" >/dev/null 2>&1; then
                log_success "使用 wsl-ssh-agent"
                return 0
            else
                log_warning "wsl-ssh-agent 启动失败"
            fi
        else
            log_success "使用现有的 wsl-ssh-agent socket"
            return 0
        fi
    fi
    
    # 方法2: 使用 Windows 的 ssh-agent（通过 npiperelay）
    local npiperelay_socket="$HOME/.ssh/agent.sock"
    if [[ -S "$npiperelay_socket" ]]; then
        export SSH_AUTH_SOCK="$npiperelay_socket"
        log_success "使用现有的 npiperelay socket"
        return 0
    fi
    
    # 方法3: 检查 Windows SSH Agent 转发
    if command -v powershell.exe &> /dev/null && command -v wslpath &> /dev/null; then
        local win_ssh_agent_sock
        win_ssh_agent_sock="$(powershell.exe -c 'Write-Output $Env:SSH_AUTH_SOCK 2> $null' 2>/dev/null | tr -d '\r')"
        if [[ -n "$win_ssh_agent_sock" ]]; then
            # 转换 Windows 路径到 WSL 路径
            local wsl_ssh_agent_sock
            wsl_ssh_agent_sock="$(wslpath -u "$win_ssh_agent_sock" 2>/dev/null || echo "")"
            if [[ -n "$wsl_ssh_agent_sock" && -S "$wsl_ssh_agent_sock" ]]; then
                export SSH_AUTH_SOCK="$wsl_ssh_agent_sock"
                log_success "使用 Windows SSH Agent: $wsl_ssh_agent_sock"
                return 0
            fi
        fi
    fi
    
    # 方法4: 尝试启动 WSL 内置 ssh-agent
    log_warning "未找到 SSH Agent，尝试启动 WSL 内置 ssh-agent"
    if command -v ssh-agent &> /dev/null; then
        if eval "$(ssh-agent -s)" 2>/dev/null; then
            # 尝试加载默认密钥
            if [[ -f "$HOME/.ssh/id_rsa" ]]; then
                ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true
            fi
            if [[ -n "$SSH_AUTH_SOCK" ]]; then
                log_success "使用 WSL 内置 ssh-agent"
                return 0
            fi
        fi
    fi
    
    log_warning "SSH Agent 配置失败，容器中将无法使用 SSH 密钥"
    log_info "建议安装 wsl-ssh-agent 或配置 npiperelay 来使用 Windows SSH Agent"
    return 1
}

# 配置 SSH Agent
setup_wsl_ssh_agent || log_warning "SSH Agent 配置失败，将继续启动容器"

# ============================================
# Windows 路径转换支持
# ============================================

# 转换 Windows 路径到 WSL 路径（如果需要）
if [[ -n "${1:-}" && "$1" == "--windows-path" ]]; then
    if [[ -z "${2:-}" ]]; then
        log_error "--windows-path 需要指定路径参数"
        exit 1
    fi
    WIN_PATH="$2"
    if command -v wslpath &> /dev/null; then
        WSL_PATH="$(wslpath -u "$WIN_PATH" 2>/dev/null || echo "$WIN_PATH")"
        if [[ -d "$WSL_PATH" ]]; then
            cd "$WSL_PATH" || {
                log_warning "无法切换到目录: $WSL_PATH"
            }
            log_info "已切换到 WSL 路径: $WSL_PATH"
            shift 2
        else
            log_warning "路径不存在: $WSL_PATH"
            shift 2
        fi
    else
        log_warning "wslpath 命令不可用，无法转换路径"
        shift 2
    fi
fi

# ============================================
# 调用主脚本
# ============================================

log_info "调用主启动脚本: run.sh"
bash "$SCRIPT_DIR/run.sh" "$@"
