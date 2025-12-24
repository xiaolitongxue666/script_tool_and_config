#!/bin/bash

# ============================================
# chezmoi 安装诊断脚本
# 帮助诊断 chezmoi 安装问题
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

echo "============================================"
echo "chezmoi 安装诊断"
echo "============================================"
echo ""

# 1. 检查 chezmoi 是否已安装
log_info "1. 检查 chezmoi 是否已安装..."
if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
    log_info "安装路径: $(which chezmoi)"
else
    log_warning "chezmoi 命令不可用"
fi
echo ""

# 2. 检查 pacman 安装
log_info "2. 检查 pacman 安装..."
if command -v pacman &> /dev/null; then
    if pacman -Q chezmoi &> /dev/null 2>&1; then
        log_success "chezmoi 已通过 pacman 安装"
        pacman -Q chezmoi
    else
        log_warning "chezmoi 未通过 pacman 安装"
    fi
else
    log_info "pacman 不可用（非 Arch Linux 系统）"
fi
echo ""

# 3. 检查官方安装脚本安装
log_info "3. 检查官方安装脚本安装..."
if [ -f "$HOME/.local/bin/chezmoi" ]; then
    log_success "chezmoi 文件存在于 ~/.local/bin/chezmoi"
    ls -lh "$HOME/.local/bin/chezmoi"
    if [ -x "$HOME/.local/bin/chezmoi" ]; then
        log_success "文件可执行"
    else
        log_warning "文件不可执行，尝试添加执行权限..."
        chmod +x "$HOME/.local/bin/chezmoi" && log_success "已添加执行权限" || log_error "无法添加执行权限"
    fi
else
    log_warning "~/.local/bin/chezmoi 不存在"
fi
echo ""

# 4. 检查 PATH
log_info "4. 检查 PATH 环境变量..."
echo "当前 PATH: $PATH"
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    log_success "~/.local/bin 在 PATH 中"
else
    log_warning "~/.local/bin 不在 PATH 中"
    log_info "建议添加到 ~/.bashrc 或 ~/.zshrc:"
    log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
echo ""

# 5. 检查网络连接（用于官方安装脚本）
log_info "5. 检查网络连接..."
if curl -fsLS https://www.chezmoi.io > /dev/null 2>&1; then
    log_success "可以访问 chezmoi 官网"
else
    log_warning "无法访问 chezmoi 官网，可能网络有问题"
fi
echo ""

# 6. 检查代理设置
log_info "6. 检查代理设置..."
if [ -n "${http_proxy:-}" ] || [ -n "${HTTP_PROXY:-}" ]; then
    log_info "HTTP 代理: ${http_proxy:-${HTTP_PROXY:-未设置}}"
    log_info "HTTPS 代理: ${https_proxy:-${HTTPS_PROXY:-未设置}}"
else
    log_info "未设置代理"
fi
echo ""

# 7. 建议
log_info "7. 建议的解决方案："
echo ""

if command -v chezmoi &> /dev/null; then
    log_success "chezmoi 已可用，无需操作"
elif pacman -Q chezmoi &> /dev/null 2>&1; then
    log_info "chezmoi 已通过 pacman 安装，但命令不可用"
    log_info "建议：重新打开终端或运行: hash -r"
elif [ -f "$HOME/.local/bin/chezmoi" ]; then
    log_info "chezmoi 文件存在，但不在 PATH 中"
    log_info "建议运行："
    log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    log_info "  chezmoi --version"
elif command -v pacman &> /dev/null; then
    log_info "建议使用 pacman 安装："
    log_info "  sudo pacman -Sy"
    log_info "  sudo pacman -S chezmoi"
else
    log_info "建议使用官方安装脚本："
    log_info "  mkdir -p ~/.local/bin"
    log_info "  sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \"\$HOME/.local/bin\""
    log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
log_info "诊断完成"

