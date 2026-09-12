#!/usr/bin/env bash
# ============================================
# 提示符 / TERM：Cursor 用户终端也要花式提示符
# Cursor 仅 GUI，用户终端也会注入 CURSOR_AGENT=1 + TERM=dumb，不得据此跳过
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

COMMON_SH="${PROJECT_ROOT}/scripts/lib/common.sh"
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
fi

SCRIPT_DIR="$PROJECT_ROOT"
log_setup "test_bashrc_prompt_guard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Bashrc prompt guard tests - $(date)"
echo "=========================================="

PASSED=0
FAILED=0

BASHRC_TMPL="${PROJECT_ROOT}/.chezmoi/dot_bashrc.tmpl"
ZSHRC_TMPL="${PROJECT_ROOT}/.chezmoi/dot_zshrc.tmpl"
ZPROFILE_TMPL="${PROJECT_ROOT}/.chezmoi/dot_zprofile.tmpl"

assert_ok() {
    local desc="$1"
    if eval "$2"; then
        PASSED=$((PASSED + 1))
        echo "[PASS] $desc"
    else
        FAILED=$((FAILED + 1))
        echo "[FAIL] $desc"
    fi
}

if [ ! -f "$BASHRC_TMPL" ]; then
    echo "[FAIL] missing template: $BASHRC_TMPL"
    exit 1
fi

prompt_block="$(awk '
    /Windows 提示符/ { capture=1 }
    capture { print }
    capture && /打开默认路径/ { exit }
' "$BASHRC_TMPL")"

linux_block="$(awk '
    /Linux 特定配置/ { capture=1 }
    capture { print }
    capture && /^fi$/ { if (seen_exec) exit }
    capture && /exec zsh/ { seen_exec=1 }
' "$BASHRC_TMPL")"

assert_ok "Windows prompt block exists" '[[ -n "$prompt_block" ]]'
assert_ok "prompt block inits starship" '[[ "$prompt_block" == *"starship init bash"* ]]'
assert_ok "Windows block does not skip on CURSOR_AGENT" '[[ "$prompt_block" != *"\${CURSOR_AGENT"* ]]'
assert_ok "dumb TERM falls back to xterm-256color" \
    '[[ "$prompt_block" == *"TERM=xterm-256color"* && "$prompt_block" == *"dumb"* ]]'
assert_ok "clears MSYS2_PS1 so git-prompt cannot win back" \
    '[[ "$prompt_block" == *"unset MSYS2_PS1"* ]]'

starship_line="$(printf '%s\n' "$prompt_block" | grep -n 'starship init bash' | head -n 1 | cut -d: -f1 || true)"
term_fix_line="$(printf '%s\n' "$prompt_block" | grep -n 'TERM=xterm-256color' | head -n 1 | cut -d: -f1 || true)"

assert_ok "TERM fallback precedes starship init" \
    '[[ -n "$starship_line" && -n "$term_fix_line" && "$term_fix_line" -lt "$starship_line" ]]'

assert_ok "Linux exec zsh exists" '[[ "$linux_block" == *"exec zsh"* ]]'
assert_ok "Linux exec zsh does not gate on CURSOR_AGENT" '[[ "$linux_block" != *"\${CURSOR_AGENT"* ]]'
assert_ok "Linux bash remaps dumb TERM when not exec zsh" \
    '[[ "$linux_block" == *"TERM=xterm-256color"* && "$linux_block" == *"dumb"* ]]'

assert_ok "zshrc remaps dumb/empty TERM only" \
    'grep -q "TERM:-" "$ZSHRC_TMPL" && grep -q "TERM=xterm-256color" "$ZSHRC_TMPL" && grep -q "dumb" "$ZSHRC_TMPL"'
assert_ok "zprofile remaps dumb/empty TERM only" \
    'grep -q "TERM:-" "$ZPROFILE_TMPL" && grep -q "TERM=xterm-256color" "$ZPROFILE_TMPL" && grep -q "dumb" "$ZPROFILE_TMPL"'
assert_ok "zprofile does not unconditionally overwrite TERM on Windows" \
    '! grep -n "export TERM=xterm-256color" "$ZPROFILE_TMPL" | grep -q "windows" '

echo ""
echo "=========================================="
echo "Summary: $PASSED passed, $FAILED failed"
echo "=========================================="

exit "$FAILED"
