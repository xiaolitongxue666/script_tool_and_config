#!/usr/bin/env bash
# ============================================
# 安装 Cursor 的 clangd 扩展（不安装 Cursor 本体）
# 需要当前环境已有 cursor CLI（含 WSL Remote CLI）
# ============================================

set -euo pipefail

EXTENSION_ID="llvm-vs-code-extensions.vscode-clangd"

log_info()  { printf "[cursor-clangd-ext] [INFO] %s\n" "$*"; }
log_ok()    { printf "[cursor-clangd-ext] [OK] %s\n" "$*"; }
log_warn()  { printf "[cursor-clangd-ext] [WARN] %s\n" "$*" >&2; }
log_error() { printf "[cursor-clangd-ext] [ERROR] %s\n" "$*" >&2; }

find_cursor_cli() {
    if command -v cursor >/dev/null 2>&1; then
        command -v cursor
        return 0
    fi
    # macOS .app
    if [[ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
        echo "/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
        return 0
    fi
    return 1
}

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
    grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null && return 0
    return 1
}

CURSOR_BIN=""
if ! CURSOR_BIN="$(find_cursor_cli)"; then
    log_warn "cursor CLI not found — skip extension install (does NOT install Cursor)"
    if is_wsl; then
        log_warn "WSL tip: open the folder with Cursor Remote-WSL, then re-run this script"
        log_warn "  or Extensions → clangd → Install in WSL"
    else
        log_warn "Install Cursor only on GUI hosts via run_once_93-install-cursor"
        log_warn "See docs/CURSOR_CLANGD.md"
    fi
    exit 0
fi

log_info "Using cursor CLI: $CURSOR_BIN"
if is_wsl; then
    log_info "WSL detected: extension will install into the remote (WSL) side when using Remote CLI"
fi

if "$CURSOR_BIN" --list-extensions 2>/dev/null | grep -qx "$EXTENSION_ID"; then
    log_ok "Extension already installed: $EXTENSION_ID"
    exit 0
fi

log_info "Installing extension: $EXTENSION_ID"
if "$CURSOR_BIN" --install-extension "$EXTENSION_ID"; then
    log_ok "Installed $EXTENSION_ID"
    log_info "Next: Command Palette → Developer: Reload Window"
    log_info "Then: clangd: Restart language server"
    exit 0
fi

log_error "Failed to install $EXTENSION_ID"
log_error "Manual: Extensions search 'clangd' (LLVM) → Install (in WSL if Remote)"
exit 1
