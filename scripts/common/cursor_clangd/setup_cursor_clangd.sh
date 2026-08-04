#!/usr/bin/env bash
# ============================================
# 组合安装：clangd 二进制 +（若有 cursor CLI）clangd 扩展
# 永不安装 Cursor 本体；无 GUI 场景安全
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { printf "[setup-cursor-clangd] [INFO] %s\n" "$*"; }

log_info "Step 1/2: install clangd binary"
bash "${SCRIPT_DIR}/install_clangd.sh"

log_info "Step 2/2: install Cursor clangd extension (skipped if no cursor CLI)"
bash "${SCRIPT_DIR}/install_cursor_clangd_extension.sh"

log_info "Verify"
bash "${SCRIPT_DIR}/verify_clangd.sh"

log_info "Done. Project compile_commands: see docs/CURSOR_CLANGD.md"
