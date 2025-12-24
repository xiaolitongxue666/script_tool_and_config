#!/bin/bash

# ============================================
# Windows 新系统完整安装脚本（chezmoi 流程）
# 自动执行：安装 chezmoi -> 安装软件 -> 配置软件 -> 纳入管理
# ============================================

set -e

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
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

start_script "Windows 新系统完整安装脚本（chezmoi 流程）"

# ============================================
# 检测操作系统
# ============================================
OS="$(uname -s)"
if [[ ! "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    error_exit "此脚本仅支持 Windows 系统（Git Bash/MSYS2）"
fi

log_success "检测到 Windows 系统"

# ============================================
# 检查项目目录
# ============================================
if [ ! -d "$PROJECT_ROOT/.chezmoi" ]; then
    log_warning ".chezmoi 目录不存在，将创建"
    mkdir -p "$PROJECT_ROOT/.chezmoi"
fi

# ============================================
# 步骤 1：安装 chezmoi
# ============================================
log_info "============================================"
log_info "步骤 1/5: 安装 chezmoi"
log_info "============================================"

if command -v chezmoi &> /dev/null; then
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
else
    log_info "开始安装 chezmoi..."
    bash "${PROJECT_ROOT}/scripts/chezmoi/install_chezmoi.sh"

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
fi

# ============================================
# 步骤 2：初始化 chezmoi 仓库
# ============================================
log_info "============================================"
log_info "步骤 2/5: 初始化 chezmoi 仓库"
log_info "============================================"

# 创建必要的目录（Windows 需要）
CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
if [ ! -d "$CHEZMOI_STATE_DIR" ]; then
    log_info "创建 chezmoi 状态目录: $CHEZMOI_STATE_DIR"
    mkdir -p "$CHEZMOI_STATE_DIR"
fi

# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$PROJECT_ROOT/.chezmoi"
log_success "源状态目录: $CHEZMOI_SOURCE_DIR"

# 初始化 Git 仓库（如果不存在）
if [ ! -d "${CHEZMOI_SOURCE_DIR}/.git" ]; then
    log_info "初始化 Git 仓库..."
    cd "$CHEZMOI_SOURCE_DIR"
    git init || true
    cd - > /dev/null
fi

# ============================================
# 步骤 3：安装所需软件
# ============================================
log_info "============================================"
log_info "步骤 3/5: 安装所需软件"
log_info "============================================"

log_info "chezmoi 会在应用配置时自动执行安装脚本"
log_info "也可以使用 PowerShell 脚本安装（功能更强大）"
log_info ""
read -p "是否使用 PowerShell 脚本安装软件？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "使用 PowerShell 脚本安装软件..."
    log_info "请以管理员身份运行 PowerShell，然后执行："
    log_info "  cd ${PROJECT_ROOT}/scripts/windows/system_basic_env"
    log_info "  .\\install_common_tools.ps1"
    log_info ""
    read -p "按 Enter 继续（假设已安装完成）..."
else
    log_info "跳过 PowerShell 脚本，将使用 chezmoi 安装脚本"
fi

# ============================================
# 步骤 4：配置所需软件
# ============================================
log_info "============================================"
log_info "步骤 4/5: 配置所需软件"
log_info "============================================"

log_info "应用所有配置（会自动执行安装脚本）..."
log_info "运行: chezmoi apply -v"
log_info ""

# 检查是否有配置文件
if [ ! "$(ls -A $CHEZMOI_SOURCE_DIR 2>/dev/null)" ]; then
    log_warning ".chezmoi 目录为空"
    log_info "请先添加配置文件，例如："
    log_info "  chezmoi add ~/.bash_profile"
    log_info "  chezmoi add ~/.bashrc"
else
    log_info "开始应用配置..."
    chezmoi apply -v || {
        log_warning "配置应用过程中出现错误，但继续执行..."
    }
    log_success "配置应用完成"
fi

# ============================================
# 步骤 5：纳入 chezmoi 管理
# ============================================
log_info "============================================"
log_info "步骤 5/5: 纳入 chezmoi 管理"
log_info "============================================"

log_info "检查现有配置文件..."

# 检查常见的配置文件
CONFIG_FILES=(
    "$HOME/.bash_profile"
    "$HOME/.bashrc"
    "$HOME/.config/alacritty/alacritty.toml"
    "$HOME/.config/starship/starship.toml"
)

FOUND_FILES=()
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        FOUND_FILES+=("$file")
    fi
done

if [ ${#FOUND_FILES[@]} -gt 0 ]; then
    log_info "发现以下现有配置文件："
    for file in "${FOUND_FILES[@]}"; do
        log_info "  - $file"
    done
    log_info ""
    read -p "是否将这些文件添加到 chezmoi 管理？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for file in "${FOUND_FILES[@]}"; do
            log_info "添加: $file"
            chezmoi add "$file" || log_warning "添加失败: $file"
        done
        log_success "配置文件已添加到 chezmoi 管理"
    else
        log_info "跳过添加现有配置文件"
    fi
else
    log_info "未发现现有配置文件"
fi

# ============================================
# 完成
# ============================================
end_script

log_success "============================================"
log_success "安装完成！"
log_success "============================================"
log_info ""
log_info "下一步操作："
log_info "  1. 查看配置状态: chezmoi status"
log_info "  2. 查看配置差异: chezmoi diff"
log_info "  3. 编辑配置: chezmoi edit ~/.bash_profile"
log_info "  4. 提交到 Git:"
log_info "     git add .chezmoi"
log_info "     git commit -m 'Add Windows config'"
log_info "     git push"
log_info ""
log_info "使用帮助: ./scripts/manage_dotfiles.sh help"
log_info "详细文档: WINDOWS_INSTALL_GUIDE.md"
log_info ""

