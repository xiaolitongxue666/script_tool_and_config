#!/usr/bin/env bash
# ============================================
# software_policies 策略与脚本发现测试
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/chezmoi/install_helpers.sh"

PASSED=0
FAILED=0

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

assert_eq "neovim policy" "minimum:0.11.0" "$(get_software_policy neovim)"
assert_eq "rmux policy" "pinned:0.5.0" "$(get_software_policy install-rmux)"
assert_eq "nerd-fonts policy" "skip" "$(get_software_policy nerd-fonts)"
assert_eq "claude policy" "latest" "$(get_software_policy 90-install-claude-code)"

CHEZMOI_DIR="${PROJECT_ROOT}/.chezmoi"
count_linux=0
while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    count_linux=$((count_linux + 1))
done < <(list_applicable_run_once_scripts "$CHEZMOI_DIR" linux)

if [[ "$count_linux" -ge 19 ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] linux script count >= 19 ($count_linux)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] linux script count too low ($count_linux)"
fi

has_layer4=0
while IFS= read -r s; do
    [[ "$s" == *"90-install-claude-code"* ]] && has_layer4=1
done < <(list_applicable_run_once_scripts "$CHEZMOI_DIR" linux)

if [[ "$has_layer4" -eq 1 ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Layer 4 claude script included for linux"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Layer 4 claude script missing from linux list"
fi

pkg="$(get_common_tool_package bat linux pacman)"
assert_eq "bat pacman" "bat" "$pkg"

pkg="$(get_common_tool_package fd linux apt)"
assert_eq "fd apt" "fd-find" "$pkg"

pkg="$(get_common_tool_package gh linux pacman)"
assert_eq "gh pacman" "github-cli" "$pkg"

pkg="$(get_common_tool_package bat windows winget)"
assert_eq "bat winget" "sharkdp.bat" "$pkg"

pkg="$(get_common_tool_package trash windows winget)"
assert_eq "trash winget skip" "" "$pkg"

cmds="$(get_common_tool_commands)"
assert_eq "common tools include bat" "bat eza fd rg fzf lazygit delta gh trash btop fastfetch" "$cmds"

pkg="$(get_common_tool_package rg windows winget)"
assert_eq "rg winget id" "BurntSushi.ripgrep.MSVC" "$pkg"

pkg="$(get_common_tool_package delta windows winget)"
assert_eq "delta winget id" "dandavison.delta" "$pkg"

# install.sh 使用 set -e；已安装项若用 return 1 会在 $() 中触发退出
status_code="$(get_software_report_status "${CHEZMOI_DIR}/run_once_install-git.sh.tmpl" 0)"
if [[ "$status_code" =~ ^[012]$ ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] get_software_report_status safe under command substitution (git -> $status_code)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] get_software_report_status returned invalid status: $status_code"
fi

# winget 须固定 --source winget（避开 msstore / 0x8a15005e）
if grep -q 'winget install.*--source winget' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh" \
    && grep -q 'winget upgrade.*--source winget' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] winget install/upgrade use --source winget"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] winget install/upgrade missing --source winget"
fi

if grep -q 'install_github_release_zip_exe' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh" \
    && grep -q 'install_rg_from_github' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh" \
    && grep -q 'install_delta_from_github' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] GitHub release fallback helpers present"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] GitHub release fallback helpers missing"
fi

# [5/6] 专项检测函数存在
if type check_neovim_binary_installed &>/dev/null \
    && type check_windows_terminal_installed &>/dev/null \
    && type check_nerd_fonts_firamono_installed &>/dev/null; then
    PASSED=$((PASSED + 1))
    echo "[PASS] report detect helpers defined"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] report detect helpers missing"
fi

echo "Summary: $PASSED passed, $FAILED failed"
[[ "$FAILED" -eq 0 ]]
