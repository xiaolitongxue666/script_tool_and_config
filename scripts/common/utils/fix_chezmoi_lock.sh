#!/bin/bash

# ============================================
# 修复 chezmoi 锁文件问题
# 解决 "timeout obtaining persistent state lock" 错误
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
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

log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "修复 chezmoi 锁文件问题"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================
# 1. 检查是否有其他 chezmoi 进程在运行
# ============================================
log_info ""
log_info "1. 检查 chezmoi 进程..."

CHEZMOI_PIDS=$(pgrep -f "chezmoi" 2>/dev/null || true)

if [ -n "$CHEZMOI_PIDS" ]; then
    log_warning "发现正在运行的 chezmoi 进程:"
    ps -p $CHEZMOI_PIDS -o pid,cmd || true

    read -p "是否要终止这些进程? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "终止 chezmoi 进程..."
        kill $CHEZMOI_PIDS 2>/dev/null || true
        sleep 1
        # 如果还在运行，强制终止
        CHEZMOI_PIDS=$(pgrep -f "chezmoi" 2>/dev/null || true)
        if [ -n "$CHEZMOI_PIDS" ]; then
            log_warning "强制终止进程..."
            kill -9 $CHEZMOI_PIDS 2>/dev/null || true
        fi
        log_success "进程已终止"
    else
        log_info "跳过终止进程"
    fi
else
    log_success "没有发现正在运行的 chezmoi 进程"
fi

# ============================================
# 2. 查找并清理锁文件
# ============================================
log_info ""
log_info "2. 查找并清理锁文件..."

# chezmoi 锁文件位置
CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
LOCK_FILE="$CHEZMOI_STATE_DIR/.chezmoi.lock"

if [ -f "$LOCK_FILE" ]; then
    log_warning "发现锁文件: $LOCK_FILE"

    # 检查锁文件的时间戳
    LOCK_AGE=$(find "$LOCK_FILE" -mmin +5 2>/dev/null || echo "")

    if [ -n "$LOCK_AGE" ]; then
        log_warning "锁文件已存在超过 5 分钟，可能是残留的锁文件"
        log_info "删除锁文件..."
        rm -f "$LOCK_FILE"
        log_success "锁文件已删除"
    else
        log_info "锁文件较新，可能是正在运行的进程创建的"
        log_info "等待 5 秒后检查..."
        sleep 5

        if [ -f "$LOCK_FILE" ]; then
            log_warning "锁文件仍然存在"
            read -p "是否要强制删除锁文件? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$LOCK_FILE"
                log_success "锁文件已强制删除"
            else
                log_info "保留锁文件"
            fi
        else
            log_success "锁文件已自动消失"
        fi
    fi
else
    log_success "没有发现锁文件"
fi

# ============================================
# 3. 测试 chezmoi 命令
# ============================================
log_info ""
log_info "3. 测试 chezmoi 命令..."

if command -v chezmoi &> /dev/null; then
    log_info "测试: chezmoi version"
    if chezmoi version &>/dev/null; then
        log_success "chezmoi 命令正常"
    else
        log_error "chezmoi 命令异常"
        exit 1
    fi

    log_info "测试: chezmoi status (带超时)"
    if timeout 5 chezmoi status &>/dev/null; then
        log_success "chezmoi status 正常"
    else
        log_warning "chezmoi status 超时或失败"
    fi
else
    log_error "chezmoi 未安装"
    exit 1
fi

log_info ""
log_success "修复完成！"
log_info ""
log_info "现在可以尝试运行:"
log_info "  chezmoi apply -v"
log_info "  或"
log_info "  ./deploy.sh"

