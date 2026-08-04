#!/usr/bin/env bash
# ============================================
# clangd / Cursor 扩展冒烟检查（不修改系统）
# ============================================

set -euo pipefail

EXTENSION_ID="llvm-vs-code-extensions.vscode-clangd"
errors=0

log_info()  { printf "[verify-clangd] [INFO] %s\n" "$*"; }
log_ok()    { printf "[verify-clangd] [OK] %s\n" "$*"; }
log_warn()  { printf "[verify-clangd] [WARN] %s\n" "$*" >&2; }
log_error() { printf "[verify-clangd] [ERROR] %s\n" "$*" >&2; }

if command -v clangd >/dev/null 2>&1; then
    log_ok "clangd: $(command -v clangd)"
    log_info "  $(clangd --version 2>/dev/null | head -n 1 || true)"
else
    log_error "clangd not in PATH — run: bash scripts/common/cursor_clangd/install_clangd.sh"
    errors=$((errors + 1))
    # macOS brew llvm hint
    if command -v brew >/dev/null 2>&1; then
        prefix="$(brew --prefix llvm 2>/dev/null || true)"
        if [[ -n "$prefix" && -x "${prefix}/bin/clangd" ]]; then
            log_warn "Found brew llvm clangd at ${prefix}/bin/clangd (not on PATH)"
        fi
    fi
fi

CURSOR_BIN=""
if command -v cursor >/dev/null 2>&1; then
    CURSOR_BIN="$(command -v cursor)"
elif [[ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
    CURSOR_BIN="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
fi

if [[ -n "$CURSOR_BIN" ]]; then
    log_ok "cursor CLI: $CURSOR_BIN"
    if "$CURSOR_BIN" --list-extensions 2>/dev/null | grep -qx "$EXTENSION_ID"; then
        log_ok "extension: $EXTENSION_ID"
    else
        log_warn "extension missing: $EXTENSION_ID"
        log_warn "  run: bash scripts/common/cursor_clangd/install_cursor_clangd_extension.sh"
        log_warn "  WSL Remote: Install in WSL, then Reload Window"
    fi
else
    log_info "cursor CLI absent — extension check skipped (OK on headless / no GUI)"
fi

if [[ -f compile_commands.json ]]; then
    log_ok "cwd has compile_commands.json"
elif [[ -f .clangd ]]; then
    log_info "cwd has .clangd (no compile_commands.json in cwd — may be OK)"
else
    log_info "no compile_commands.json in cwd — generate in the C/C++ project (e.g. cstl: scripts/setup-lsp.sh)"
fi

if [[ "$errors" -gt 0 ]]; then
    exit 1
fi
exit 0
