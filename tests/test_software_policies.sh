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

# 非 Arch：过滤 configure-pacman/arch-base/aur-helper/dwm；WSL 另过滤 i3wm/alacritty
# Layer 4 无 run_once_92（CodeWhale 已移除）后基线为 14 / WSL 12
min_linux_count=14
if type _helpers_is_wsl &>/dev/null && _helpers_is_wsl; then
    min_linux_count=12
fi
if [[ "$count_linux" -ge "$min_linux_count" ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] linux script count >= ${min_linux_count} ($count_linux)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] linux script count too low ($count_linux, need >= ${min_linux_count})"
fi

# Arch 专用脚本在非 Arch 上应被过滤
arch_only_in_list=0
while IFS= read -r s; do
    [[ "$s" == *"configure-pacman"* || "$s" == *"arch-base-packages"* || "$s" == *"aur-helper"* || "$s" == *"install-dwm"* ]] && arch_only_in_list=1
done < <(list_applicable_run_once_scripts "$CHEZMOI_DIR" linux)
if type is_arch_linux &>/dev/null && is_arch_linux; then
    PASSED=$((PASSED + 1))
    echo "[PASS] on Arch: arch-only scripts may appear in linux list (skipped assert)"
elif [[ "$arch_only_in_list" -eq 0 ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] non-Arch host filters arch-only run_once from linux list"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] non-Arch host still lists arch-only run_once scripts"
fi

# Debian/Ubuntu 二进制别名：batcat / fdfind 视为已安装
_tmpdir="${PROJECT_ROOT}/logs/test_common_tool_cmd_$$"
mkdir -p "$_tmpdir"
printf '#!/bin/sh\nexit 0\n' > "${_tmpdir}/batcat"
printf '#!/bin/sh\nexit 0\n' > "${_tmpdir}/fdfind"
chmod +x "${_tmpdir}/batcat" "${_tmpdir}/fdfind"
_old_path="$PATH"
PATH="${_tmpdir}:${PATH}"
hash -r 2>/dev/null || true
if common_tool_command_present bat && common_tool_command_present fd; then
    PASSED=$((PASSED + 1))
    echo "[PASS] common_tool_command_present accepts batcat/fdfind"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] common_tool_command_present should accept batcat/fdfind"
fi
PATH="$_old_path"
hash -r 2>/dev/null || true
rm -rf "$_tmpdir"

name="$(extract_software_name_from_script "${CHEZMOI_DIR}/run_on_linux/run_once_configure-pacman.sh.tmpl")"
assert_eq "configure-pacman name" "configure-pacman" "$name"

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

# [4/6] ensure 补装：当前平台无包（packages.conf 为 "-"）时应跳过，不误报 WARNING
if grep -q '当前平台无此包' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] upgrade_common_tools_packages skips missing-pkg items (Windows trash/btop)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] upgrade_common_tools_packages missing pkg-empty skip guard"
fi

# uv 经包管理器安装（choco/brew 等）时 self-update 不可用：应提示 INFO 而非 WARNING
if grep -q '\*chocolatey\*\|\*choco\*' "${PROJECT_ROOT}/scripts/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] ensure_uv_latest recognizes package-manager uv (choco/brew)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] ensure_uv_latest missing package-manager path detection"
fi

echo "Summary: $PASSED passed, $FAILED failed"
[[ "$FAILED" -eq 0 ]]
