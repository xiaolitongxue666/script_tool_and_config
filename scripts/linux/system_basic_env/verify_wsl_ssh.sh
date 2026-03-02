#!/usr/bin/env bash

# ============================================
# WSL SSH 自检脚本（只读，不修改任何配置）
# 依次执行 ssh-add -l、ssh -T git@github.com 并打印结果
# 用于确认子模块与 run_once 克隆所需的 SSH 是否可用
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

echo ""
log_info "WSL SSH 自检（子模块与 git clone 依赖 SSH 或 HTTPS+代理回退）"
echo ""

# 1. 列出已加载的密钥
log_info "1. ssh-add -l（已加载的密钥）"
echo "----------------------------------------"
if ssh-add -l 2>&1; then
    log_success "已加载至少一个密钥"
else
    log_warning "未加载密钥或 agent 未就绪（Could not open a connection to your authentication agent）"
    log_info "宿主机密钥：确保 ~/.ssh 软链接与 /etc/wsl.conf [automount] options = \"metadata\"，并 chmod 600 ~/.ssh/id_rsa"
    log_info "npiperelay：确保 .bashrc/.zprofile 中建立 SSH_AUTH_SOCK 的 socat 在登录时执行"
fi
echo ""

# 1.5 WSL 下软链接与 ProxyCommand 127.0.0.1 提示（只读检测）
if grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    _ssh_dir="$(readlink -f ~/.ssh 2>/dev/null || true)"
    if [[ -n "$_ssh_dir" ]] && [[ "$_ssh_dir" == /mnt/* ]]; then
        log_info "当前 ~/.ssh 指向宿主机目录，使用的为宿主机 config；若 ProxyCommand 使用 127.0.0.1，在 WSL 中无法连到宿主机代理，建议在 WSL 内使用独立 config 并设置宿主机 IP，见 docs/INSTALL_GUIDE.md。"
    elif [[ -f ~/.ssh/config ]]; then
        if grep -A10 "Host github.com" ~/.ssh/config 2>/dev/null | grep -q "127\.0\.0\.1"; then
            log_warning "~/.ssh/config 中 github.com 的 ProxyCommand 使用 127.0.0.1，WSL 中应改为宿主机 IP（export PROXY_HOST=\$(awk '/^nameserver / {print \$2; exit}' /etc/resolv.conf) 后重新 chezmoi apply）。"
        fi
    fi
fi
echo ""

# 2. GitHub SSH 认证测试（成功时 GitHub 返回 exit 1，需单独判断）
log_info "2. ssh -T git@github.com（GitHub 认证）"
echo "----------------------------------------"
set +e
ssh_output="$(ssh -T git@github.com 2>&1)"
ssh_exit=$?
set -e
echo "$ssh_output"
if [[ $ssh_exit -eq 1 ]] && echo "$ssh_output" | grep -q "successfully authenticated"; then
    log_success "GitHub SSH 认证成功"
elif [[ $ssh_exit -ne 0 ]]; then
    log_warning "GitHub SSH 认证失败或未连接，exit code: $ssh_exit"
fi
echo ""

log_info "自检结束。若上述两项正常，子模块与 run_once 的 SSH 克隆应可成功；否则脚本会回退 HTTPS+代理。"
