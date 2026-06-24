#!/usr/bin/env bash
# ============================================
# install [5/6] 报告逻辑测试（macOS Intel 宿主验证）
# 修复点：get_software_report_status 在 install.sh set -e 下须 stdout 输出状态码
# 代码本身跨平台；本测试仅在当前 macOS 环境执行 report 集成验证
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/common.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/chezmoi/install_helpers.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

PASSED=0
FAILED=0

pass() {
    PASSED=$((PASSED + 1))
    echo "[PASS] $1"
}

fail() {
    FAILED=$((FAILED + 1))
    echo "[FAIL] $1"
}

test_status_stdout_and_exit_zero() {
    local script_path="$1"
    local upgrade_skipped="${2:-0}"
    local code exit_code=0

    code="$(get_software_report_status "$script_path" "$upgrade_skipped")" || exit_code=$?
    if [[ "$exit_code" -ne 0 ]]; then
        fail "get_software_report_status exit $exit_code under set -e"
        return
    fi
    if [[ ! "$code" =~ ^[012]$ ]]; then
        fail "invalid status code '$code'"
        return
    fi
    pass "status stdout=$code exit=0 ($(basename "$script_path"))"
}

echo "=== install report status tests (macOS Intel, set -e) ==="
echo "Host: $(uname -s) $(uname -m)"

# mock：旧 bug — return 1 表示已安装会在 set -e + $() 中中断
if (
    check_script_software_installed() { return 0; }
    code="$(get_software_report_status "${CHEZMOI_DIR}/run_once_install-git.sh.tmpl" 0)"
    [[ "$code" == "1" ]]
); then
    pass "mock installed does not abort set -e"
else
    fail "mock installed does not abort set -e"
fi

if (
    check_script_software_installed() { return 1; }
    code="$(get_software_report_status "${CHEZMOI_DIR}/run_once_install-neovim.sh.tmpl" 0)"
    [[ "$code" == "0" ]]
); then
    pass "mock not installed -> status 0"
else
    fail "mock not installed -> status 0"
fi

if (
    check_common_tools_installed_status() { return 2; }
    code="$(get_software_report_status "${CHEZMOI_DIR}/run_once_install-common-tools.sh.tmpl" 0)"
    [[ "$code" == "2" ]]
); then
    pass "mock common-tools partial -> status 2"
else
    fail "mock common-tools partial -> status 2"
fi

for script in \
    "${CHEZMOI_DIR}/run_once_00-install-version-managers.sh.tmpl" \
    "${CHEZMOI_DIR}/run_once_install-git.sh.tmpl" \
    "${CHEZMOI_DIR}/run_once_install-common-tools.sh.tmpl" \
    "${CHEZMOI_DIR}/run_once_90-install-claude-code.sh.tmpl"
do
    [[ -f "$script" ]] && test_status_stdout_and_exit_zero "$script" 0
done

# 与 install.sh [5/6] 相同调用链（须先 detect_os_and_package_manager）
detect_os_and_package_manager
if [[ "${PLATFORM:-}" != "darwin" ]]; then
    fail "expected darwin on macOS host (got ${PLATFORM:-unset})"
else
    pass "detect_os_and_package_manager -> darwin/brew"
fi

if report_install_status_by_platform "$CHEZMOI_DIR" "$PLATFORM" "$PACKAGE_MANAGER" >/dev/null; then
    pass "report_install_status_by_platform completes (macOS)"
else
    fail "report_install_status_by_platform failed (macOS)"
fi

echo "Summary: $PASSED passed, $FAILED failed"
[[ "$FAILED" -eq 0 ]]
