#!/usr/bin/env bash
# ============================================
# VPS / Cursor Remote SSH / Pi 诊断（只读）
# 在 VPS 交互 zsh 或 Cursor SSH 集成终端内运行
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# shellcheck disable=SC1090
if [[ -f "${PROJECT_ROOT}/scripts/common.sh" ]]; then
    source "${PROJECT_ROOT}/scripts/common.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# shellcheck disable=SC1090
if [[ -f "${PROJECT_ROOT}/scripts/chezmoi/chezmoi_core.sh" ]]; then
    source "${PROJECT_ROOT}/scripts/chezmoi/chezmoi_core.sh"
fi

_pass=0
_fail=0
_warn=0

_check() {
    local label="$1"
    local ok="$2"
    local detail="${3:-}"
    if [[ "$ok" == "pass" ]]; then
        log_success "[PASS] $label${detail:+ — $detail}"
        _pass=$((_pass + 1))
    elif [[ "$ok" == "warn" ]]; then
        log_warning "[WARN] $label${detail:+ — $detail}"
        _warn=$((_warn + 1))
    else
        log_error "[FAIL] $label${detail:+ — $detail}"
        _fail=$((_fail + 1))
    fi
}

log_info "========== VPS / SSH / Pi diagnostics =========="
log_info "Host: $(hostname 2>/dev/null || echo unknown)"
log_info "User: $(whoami 2>/dev/null || echo unknown)"
log_info "Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date)"

# --- 环境 ---
_is_wsl=0
if chezmoi_is_wsl 2>/dev/null; then _is_wsl=1; fi
_is_headless=0
if type chezmoi_is_headless_native_linux &>/dev/null && chezmoi_is_headless_native_linux; then
    _is_headless=1
fi

log_info "WSL: ${_is_wsl} | Headless native Linux: ${_is_headless}"
log_info "TERM=${TERM:-<unset>} SSH_CONNECTION=${SSH_CONNECTION:-<unset>}"
log_info "DISPLAY=${DISPLAY:-<unset>} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<unset>}"

# --- TERM（SSH 会话） ---
if [[ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]]; then
    if [[ "${TERM:-}" == "xterm-256color" ]]; then
        _check "SSH TERM" pass "xterm-256color"
    else
        _check "SSH TERM" fail "expected xterm-256color, got ${TERM:-<unset>}"
    fi
else
    _check "SSH TERM" warn "not an SSH session; TERM check skipped"
fi

# --- shell 配置 ---
for f in "${HOME}/.pi_ssh_helpers.sh" "${HOME}/.zprofile" "${HOME}/.bashrc"; do
    if [[ -f "$f" ]] && grep -qE 'pi\(\)|pi-reset|pi_ssh_helpers' "$f" 2>/dev/null; then
        _check "Pi/SSH helpers in $(basename "$f")" pass
    elif [[ "$f" == "${HOME}/.pi_ssh_helpers.sh" ]]; then
        _check "Pi/SSH helpers file" fail "~/.pi_ssh_helpers.sh missing (run Phase 1 deploy)"
    fi
done

# --- 代理 ---
if command -v ss &>/dev/null; then
    _ports="$(ss -tlnH 2>/dev/null | grep -oE ':(7890|17890)\b' | tr -d ':' | sort -u | tr '\n' ' ' || true)"
    log_info "Listening proxy ports: ${_ports:-none}"
fi

if type chezmoi_detect_proxy &>/dev/null; then
    _proxy="$(chezmoi_detect_proxy 2>/dev/null || true)"
    log_info "chezmoi_detect_proxy: ${_proxy:-<empty>}"
    if [[ "$_is_headless" == "1" ]] && [[ "${_proxy:-}" == *":17890" ]]; then
        _check "Headless proxy discovery" pass "17890"
    elif [[ "$_is_headless" == "1" ]] && ss -tlnH 2>/dev/null | grep -q ':17890'; then
        _check "Headless proxy discovery" fail "17890 listening but detect returned ${_proxy:-empty}"
    fi
fi

if command -v curl &>/dev/null; then
    for _p in 7890 17890; do
        if ss -tlnH 2>/dev/null | grep -q ":${_p}"; then
            _code="$(curl --noproxy '*' -x "http://127.0.0.1:${_p}" -s -o /dev/null -w '%{http_code}' --connect-timeout 2 https://api.github.com 2>/dev/null || echo "000")"
            log_info "curl via 127.0.0.1:${_p} → HTTP ${_code}"
        fi
    done
fi

# --- fnm / pi / cursor ---
for _cmd in fnm pi; do
    if command -v "$_cmd" &>/dev/null; then
        _check "command: $_cmd" pass "$(command -v "$_cmd")"
    else
        _check "command: $_cmd" fail "not in PATH"
    fi
done

if command -v cursor &>/dev/null; then
    if [[ "$_is_headless" == "1" ]]; then
        _check "cursor CLI on headless" fail "should not be installed on VPS"
    else
        _check "cursor CLI" pass
    fi
else
    if [[ "$_is_headless" == "1" ]]; then
        _check "cursor CLI absent (headless)" pass
    fi
fi

# --- Pi harness ---
_pi_ext="${HOME}/.pi/agent/extensions"
if [[ -d "$_pi_ext" ]]; then
    if [[ -d "${_pi_ext}/ssh-terminal" ]]; then
        _check "Pi extension ssh-terminal" pass
    else
        _check "Pi extension ssh-terminal" fail "run APPLY_TARGETS=pi bash scripts/apply-config.sh"
    fi
    if [[ -d "${_pi_ext}/peon-ping" ]]; then
        if [[ "$_is_headless" == "1" ]]; then
            _check "Pi extension peon-ping absent" fail "should be removed on headless VPS"
        fi
    elif [[ "$_is_headless" == "1" ]]; then
        _check "Pi extension peon-ping absent" pass
    fi
else
    _check "Pi harness directory" warn "~/.pi/agent/extensions not found"
fi

log_info "========== Summary: ${_pass} passed, ${_warn} warnings, ${_fail} failed =========="
if [[ "$_fail" -gt 0 ]]; then
    exit 1
fi
exit 0
