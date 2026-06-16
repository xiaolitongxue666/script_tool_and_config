#!/usr/bin/env bash
# ============================================
# semver 比较单元测试
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_INSTALL="${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

source "$COMMON_INSTALL"

PASSED=0
FAILED=0

assert_compare() {
    local a="$1" op="$2" b="$3"
    if compare_semver "$a" "$op" "$b"; then
        PASSED=$((PASSED + 1))
        echo "[PASS] compare_semver $a $op $b"
    else
        FAILED=$((FAILED + 1))
        echo "[FAIL] compare_semver $a $op $b"
    fi
}

assert_not_compare() {
    local a="$1" op="$2" b="$3"
    if compare_semver "$a" "$op" "$b"; then
        FAILED=$((FAILED + 1))
        echo "[FAIL] expected false: compare_semver $a $op $b"
    else
        PASSED=$((PASSED + 1))
        echo "[PASS] not compare_semver $a $op $b"
    fi
}

assert_compare "1.2.3" "lt" "2.0.0"
assert_compare "0.11.0" "ge" "0.11.0"
assert_compare "0.10.9" "lt" "0.11.0"
assert_not_compare "1.0.0" "lt" "0.9.0"
assert_compare "NVIM v0.11.5" "ge" "0.11.0"

read -r m n p <<< "$(parse_semver "v1.2.3-beta")"
if [[ "$m" == "1" && "$n" == "2" && "$p" == "3" ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] parse_semver v1.2.3-beta"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] parse_semver got $m.$n.$p"
fi

echo "Summary: $PASSED passed, $FAILED failed"
[[ "$FAILED" -eq 0 ]]
