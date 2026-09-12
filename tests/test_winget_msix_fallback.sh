#!/usr/bin/env bash
# ============================================
# Windows winget 升级失败回退：MSIX sideload 判定与主包选择
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"

PASSED=0
FAILED=0

assert_ok() {
    local desc="$1"
    shift
    if "$@"; then
        PASSED=$((PASSED + 1))
        echo "[PASS] $desc"
    else
        FAILED=$((FAILED + 1))
        echo "[FAIL] $desc"
    fi
}

assert_fail() {
    local desc="$1"
    shift
    if "$@"; then
        FAILED=$((FAILED + 1))
        echo "[FAIL] $desc (expected failure)"
    else
        PASSED=$((PASSED + 1))
        echo "[PASS] $desc"
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        PASSED=$((PASSED + 1))
        echo "[PASS] $desc"
    else
        FAILED=$((FAILED + 1))
        echo "[FAIL] $desc (expected '$expected', got '$actual')"
    fi
}

# --- winget_output_needs_msix_sideload ---
assert_ok "0x80070422 triggers sideload" \
    winget_output_needs_msix_sideload "安装程序失败，退出代码为: 0x80070422 : 无法启动服务" 1
assert_ok "installer technology mismatch triggers sideload" \
    winget_output_needs_msix_sideload "找到了较新的版本，但安装技术与当前安装的版本不同。请卸载包并安装较新的版本。" 43
assert_ok "English installer technology mismatch triggers sideload" \
    winget_output_needs_msix_sideload "A newer version was found, but the installer technology is different from the current installed version." 43
assert_fail "exit 43 alone does not trigger sideload" \
    winget_output_needs_msix_sideload "generic failure" 43
assert_fail "success rc does not trigger sideload" \
    winget_output_needs_msix_sideload "Successfully installed" 0
assert_fail "already latest does not trigger sideload" \
    winget_output_needs_msix_sideload "No available upgrade found" 1
assert_fail "Chinese already latest does not trigger sideload" \
    winget_output_needs_msix_sideload "没有可用的升级" 1
assert_fail "Chinese no-upgrade rc=43 does not trigger sideload" \
    winget_output_needs_msix_sideload "找不到可用的升级。"$'\n'"配置的源中没有可用的较新的包版本。" 43
assert_fail "unrelated winget error does not trigger sideload" \
    winget_output_needs_msix_sideload "Failed to connect to source" 1

# --- find_primary_msix_in_dir ---
_tmpdir="${PROJECT_ROOT}/logs/test_winget_msix_$$"
mkdir -p "$_tmpdir/wt" "$_tmpdir/omp" "$_tmpdir/empty" "$_tmpdir/onlydep"

touch "$_tmpdir/wt/Microsoft.UI.Xaml.2.8_8.2501.31001.0_x64__8wekyb3d8bbwe.appx"
touch "$_tmpdir/wt/Microsoft.WindowsTerminal_1.24.11911.0_8wekyb3d8bbwe.msixbundle"
touch "$_tmpdir/omp/Microsoft.UI.Xaml.2.8.msix"
touch "$_tmpdir/omp/Oh My Posh_31.1.3_X64_msix_en-US.msix"
touch "$_tmpdir/onlydep/Microsoft.UI.Xaml.2.8.msix"

wt_primary="$(find_primary_msix_in_dir "$_tmpdir/wt")"
assert_eq "WT picks WindowsTerminal bundle not UI.Xaml" \
    "$_tmpdir/wt/Microsoft.WindowsTerminal_1.24.11911.0_8wekyb3d8bbwe.msixbundle" \
    "$wt_primary"

omp_primary="$(find_primary_msix_in_dir "$_tmpdir/omp")"
assert_eq "OMP picks winget Oh My Posh msix not UI.Xaml" \
    "$_tmpdir/omp/Oh My Posh_31.1.3_X64_msix_en-US.msix" \
    "$omp_primary"

assert_fail "empty dir has no primary msix" find_primary_msix_in_dir "$_tmpdir/empty"
assert_fail "dependency-only dir has no primary msix" find_primary_msix_in_dir "$_tmpdir/onlydep"

deps="$(find_msix_dependency_files "$_tmpdir/wt" | tr '\n' '|')"
case "$deps" in
    *Microsoft.UI.Xaml.2.8_8.2501.31001.0_x64__8wekyb3d8bbwe.appx*)
        PASSED=$((PASSED + 1))
        echo "[PASS] WT dir lists UI.Xaml as dependency"
        ;;
    *)
        FAILED=$((FAILED + 1))
        echo "[FAIL] WT dir lists UI.Xaml as dependency (got '$deps')"
        ;;
esac

# --- OMP GitHub asset name ---
assert_eq "OMP windows amd64 asset name" \
    "posh-windows-amd64.exe" \
    "$(oh_my_posh_windows_github_asset)"

# Windows PATH 上可能仍是旧 oh-my-posh；成功日志必须报刚写入的 dest 版本
if grep -q 'oh-my-posh installed to ${dest} ($("$dest" --version' \
    "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] OMP success reports dest exe version"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] OMP success must use dest --version, not PATH oh-my-posh"
fi
if grep -n 'oh-my-posh installed to' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    | grep -q '$(oh-my-posh --version'; then
    FAILED=$((FAILED + 1))
    echo "[FAIL] OMP success still reports PATH oh-my-posh --version"
else
    PASSED=$((PASSED + 1))
    echo "[PASS] OMP success does not report PATH oh-my-posh --version"
fi

rm -rf "$_tmpdir"

echo "=========================================="
echo "Passed: $PASSED  Failed: $FAILED"
echo "=========================================="
[[ "$FAILED" -eq 0 ]]
