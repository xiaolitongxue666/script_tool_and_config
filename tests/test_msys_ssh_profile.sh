#!/usr/bin/env bash
# ============================================
# windows-link-msys-ssh：USERPROFILE 缺失时仍能定位用户目录
# chezmoi 拉起的 Git Bash 不一定继承父进程的 USERPROFILE
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TMPL="${PROJECT_ROOT}/.chezmoi/run_once_windows-link-msys-ssh.sh.tmpl"
WORK_DIR="${PROJECT_ROOT}/logs/msys-ssh-profile-test"
RENDERED="${WORK_DIR}/link.sh"

PASSED=0
FAILED=0

ok() { PASSED=$((PASSED + 1)); echo "[PASS] $1"; }
bad() { FAILED=$((FAILED + 1)); echo "[FAIL] $1"; }

if [[ -x "D:/Program Files/Git/bin/bash.exe" ]]; then
    BASH_BIN="D:/Program Files/Git/bin/bash.exe"
else
    BASH_BIN="bash"
fi

mkdir -p "$WORK_DIR"
sed -e '1d' -e '$d' -e 's/^link_msys_ssh$/# skipped/' "$TMPL" > "$RENDERED"

echo "=========================================="
echo "MSYS ssh profile resolution - $(date)"
echo "=========================================="

if "$BASH_BIN" --noprofile --norc -n "$RENDERED"; then
    ok "rendered script syntax"
else
    bad "rendered script syntax"
fi

profile_out="$(env -u userprofile USERPROFILE='C:/Users/ProfileTest' "$BASH_BIN" --noprofile --norc -c 'source "$1"; resolve_windows_profile' _ "$RENDERED" || true)"
case "$profile_out" in
    /c/Users/ProfileTest|C:/Users/ProfileTest)
        ok "USERPROFILE is used when set"
        ;;
    *)
        bad "USERPROFILE is used when set (got: ${profile_out:-<empty>})"
        ;;
esac

lower_out="$(env -u USERPROFILE userprofile='D:/Users/LowerTest' "$BASH_BIN" --noprofile --norc -c 'source "$1"; resolve_windows_profile' _ "$RENDERED" || true)"
case "$lower_out" in
    /d/Users/LowerTest|D:/Users/LowerTest)
        ok "lowercase userprofile is accepted"
        ;;
    *)
        bad "lowercase userprofile is accepted (got: ${lower_out:-<empty>})"
        ;;
esac

if "$BASH_BIN" --noprofile --norc -c 'unset USERPROFILE userprofile HOME USERNAME; export USER=nosuchprofileuser; source "$1"; resolve_windows_profile' _ "$RENDERED"; then
    bad "missing profile variables should fail"
else
    ok "missing profile variables should fail"
fi

if [[ -d /c/Users/Administrator ]] && command -v cygpath >/dev/null 2>&1; then
    home_out="$("$BASH_BIN" --noprofile --norc -c 'unset USERPROFILE userprofile; export HOME=/c/Users/Administrator; source "$1"; resolve_windows_profile' _ "$RENDERED" || true)"
    case "$home_out" in
        /c/Users/Administrator)
            ok "HOME is used when USERPROFILE is unset"
            ;;
        *)
            bad "HOME is used when USERPROFILE is unset (got: ${home_out:-<empty>})"
            ;;
    esac
else
    echo "[INFO] Skip HOME fallback: not a Windows profile layout"
fi

echo "----------------------------------------"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "----------------------------------------"

[[ "$FAILED" -eq 0 ]]
