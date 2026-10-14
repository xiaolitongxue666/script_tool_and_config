#!/usr/bin/env bash
# ============================================
# software_policies 策略与脚本发现测试
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/lib/chezmoi/install_helpers.sh"

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
# 含 run_once_install-clangd 后基线为 15 / WSL 13（无 run_once_92 CodeWhale）
min_linux_count=15
if type _helpers_is_wsl &>/dev/null && _helpers_is_wsl; then
    min_linux_count=13
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

name="$(extract_software_name_from_script "${CHEZMOI_DIR}/run_once_linux-configure-pacman.sh.tmpl")"
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
if grep -q 'winget install.*--source winget' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q 'winget upgrade.*--source winget' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] winget install/upgrade use --source winget"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] winget install/upgrade missing --source winget"
fi

if grep -q 'install_github_release_zip_exe' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q 'install_rg_from_github' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q 'install_delta_from_github' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
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
if grep -q '当前平台无此包' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] upgrade_common_tools_packages skips missing-pkg items (Windows trash/btop)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] upgrade_common_tools_packages missing pkg-empty skip guard"
fi

# uv 经包管理器安装（choco/brew 等）时 self-update 不可用：应提示 INFO 而非 WARNING
if grep -q '\*chocolatey\*\|\*choco\*' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] ensure_uv_latest recognizes package-manager uv (choco/brew)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] ensure_uv_latest missing package-manager path detection"
fi

# macOS Intel：有 bottle 才 brew upgrade；要源码编译则停在已装版本。clangd 无 formula，不模糊搜索
if grep -q 'brew upgrade "$name"' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q 'macOS Intel: brew upgrade' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q 'last Intel binary stays' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel brew-upgrades only when a bottle is available"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel bottle-only upgrade path missing"
fi

if grep -q '_brew_should_skip_installed_upgrade' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    || grep -q '_brew_should_skip_installed_upgrade' "${PROJECT_ROOT}/scripts/lib/chezmoi/brew_macos_network.sh"; then
    FAILED=$((FAILED + 1))
    echo "[FAIL] leftover Intel skip-upgrade helper"
else
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel skip-upgrade helper removed"
fi

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/lib/chezmoi/brew_macos_network.sh"
_fastfetch_dryrun=$(cat <<'EOF'
==> Would install 2 dependencies:
vulkan-headers  1.4.357.0
vulkan-loader   1.4.357.0
==> Would upgrade 3 dependencies:
libheif      1.23.3    -> 1.23.4
imagemagick  7.1.2-8_1 -> 7.1.2-31
lua          5.4.8     -> 5.5.1
==> Would upgrade 1 requested outdated package
fastfetch 2.67.1 -> 2.68.1
EOF
)
_bat_dryrun=$(cat <<'EOF'
==> Would upgrade 1 requested outdated package
bat 0.26.1 -> 0.26.2
EOF
)
_lua_dep_dryrun=$(cat <<'EOF'
==> Would upgrade 1 dependencies:
lua          5.4.8     -> 5.5.1
==> Would upgrade 1 requested outdated package
fastfetch 2.67.1 -> 2.68.1
EOF
)
_openssl_dep_dryrun=$(cat <<'EOF'
==> Would install 1 dependency:
openssl@4  4.0.3
==> Would upgrade 1 requested outdated package
tmux 3.7c -> 3.8
EOF
)
_source_build_dryrun=$(cat <<'EOF'
==> Would upgrade 1 requested outdated package
tmux 3.7c -> 3.8
==> 1 homebrew/core formula that would build from source
tmux
EOF
)
if _brew_intel_dryrun_mentions_heavy_dep "$_fastfetch_dryrun"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel dry-run parser skips fastfetch when imagemagick is a dep"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel dry-run parser missed imagemagick dep"
fi
if ! _brew_intel_dryrun_mentions_heavy_dep "$_bat_dryrun"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel dry-run parser does not skip requested formula itself"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel dry-run parser treated requested package as heavy dep"
fi
if ! _brew_intel_dryrun_mentions_heavy_dep "$_lua_dep_dryrun"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel dry-run parser allows non-heavy deps (lua)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel dry-run parser treated lua as heavy dep"
fi
if _brew_intel_dryrun_lacks_bottle "$_openssl_dep_dryrun"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel dry-run keeps installed formula when openssl@4 is a dependency"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel dry-run did not treat openssl@4 dependency as no-bottle"
fi
if _brew_intel_dryrun_lacks_bottle "$_source_build_dryrun"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel dry-run keeps installed formula when it would build from source"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel dry-run missed would-build-from-source"
fi
if ! _brew_intel_dryrun_lacks_bottle "$_bat_dryrun"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel dry-run still upgrades when only a bottle is needed"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel dry-run skipped a bottle-only upgrade"
fi
if grep -q '_brew_intel_run_with_heartbeat' "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q '_brew_intel_dryrun_lacks_bottle' \
        "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q 'upgrade_brew_package "$package_name"' \
        "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh" \
    && grep -q '_brew_link_existing_keg' \
        "${PROJECT_ROOT}/scripts/lib/chezmoi/brew_macos_network.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Intel brew upgrade uses heartbeat, bottle check, install_package reuse, keg relink"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Intel brew upgrade missing heartbeat, bottle check, install_package reuse, or keg relink"
fi

if grep -q 'clangd already present, skip brew formula search' \
    "${PROJECT_ROOT}/scripts/chezmoi/ensure_platform_software.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] clangd ensure skips nonexistent brew formula search"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] clangd still searches brew for clangd/clang/clang-tools-extra"
fi

if grep -q 'HOMEBREW_NO_ENV_HINTS=1' "${PROJECT_ROOT}/scripts/lib/chezmoi/brew_macos_network.sh" \
    && grep -q 'HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1' \
        "${PROJECT_ROOT}/scripts/lib/chezmoi/brew_macos_network.sh" \
    && grep -q 'HOMEBREW_NO_INSTALL_CLEANUP=1' \
        "${PROJECT_ROOT}/scripts/lib/chezmoi/brew_macos_network.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] brew env suppresses hints, Intel dependents check, and periodic cleanup"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] brew_macos_network.sh missing Intel brew env flags"
fi

if ! grep -q 'upgrade_brew_package' "${PROJECT_ROOT}/scripts/chezmoi/ensure_platform_software.sh" \
    || ! grep -A6 '93-install-cursor' "${PROJECT_ROOT}/scripts/chezmoi/ensure_platform_software.sh" \
        | grep -q 'upgrade_brew_package'; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Cursor brew cask does not fall back to formula install"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Cursor brew target still calls upgrade_brew_package"
fi

if grep -q 'Cursor.app already present; skip brew cask' \
    "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] existing Cursor.app skips brew cask download"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] upgrade_brew_cask still downloads over an existing Cursor.app"
fi

if grep -q 'ensure_rc' "${PROJECT_ROOT}/install.sh" \
    && grep -q '130' "${PROJECT_ROOT}/install.sh"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] install.sh exits when ensure is interrupted"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] install.sh does not treat ensure exit 130 as fatal"
fi

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"
_gh_json='{"browser_download_url":"https://github.com/Schniz/fnm/releases/download/v1.39.0/fnm-macos.zip"}'
_gh_url="$(github_release_json_first_asset_url "$_gh_json" "fnm-macos.zip" || true)"
if [[ "$_gh_url" == *fnm-macos.zip ]]; then
    PASSED=$((PASSED + 1))
    echo "[PASS] GitHub release JSON finds Intel/universal fnm asset"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] GitHub release JSON missed fnm-macos.zip"
fi
if ! github_release_json_first_asset_url "$_gh_json" "fnm-macos-arm64.zip" >/dev/null; then
    PASSED=$((PASSED + 1))
    echo "[PASS] GitHub release JSON rejects a missing Intel asset"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] GitHub release JSON returned a URL for a missing asset"
fi

# Layer 4 npm：超时、已最新跳过、WSL 不走 Windows interop
_pkg_install="${PROJECT_ROOT}/scripts/lib/chezmoi/package_install.sh"
if grep -q '_is_windows_interop_path' "$_pkg_install" \
    && grep -q '_wsl_prepend_npm_global_bin' "$_pkg_install" \
    && grep -q '_run_with_timeout' "$_pkg_install" \
    && grep -q 'already up-to-date' "$_pkg_install" \
    && grep -q -- '--no-fund --no-audit' "$_pkg_install" \
    && grep -q '始终置顶' "$_pkg_install" \
    && ! grep -q ':"${npm_prefix}/bin":*) return 0' "$_pkg_install"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] ensure_npm_global_latest has timeout, skip-if-latest, WSL always-prepend"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] ensure_npm_global_latest missing timeout/interop/skip-if-latest/always-prepend"
fi

if grep -q '_npm_apply_china_mirror' "$_pkg_install" \
    && grep -q 'registry.npmmirror.com' "$_pkg_install" \
    && grep -q 'npm_config_registry' "$_pkg_install"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] package_install.sh uses npmmirror for npm view/install"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] package_install.sh missing npmmirror registry helper"
fi

if grep -q '_command_exists_local_not_interop' \
    "${PROJECT_ROOT}/scripts/lib/chezmoi/install_helpers.sh" \
    && grep -A8 '93-install-cursor|cursor)' \
        "${PROJECT_ROOT}/scripts/lib/chezmoi/install_helpers.sh" \
        | grep -q '_command_exists_local_not_interop "cursor"'; then
    PASSED=$((PASSED + 1))
    echo "[PASS] claude/codex/cursor installed-check ignores Windows interop paths"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] install_helpers missing interop-aware claude/codex/cursor check"
fi

if grep -q 'cursor.com/api/download?platform=linux-x64' \
    "${PROJECT_ROOT}/.chezmoi/run_once_93-install-cursor.sh.tmpl" \
    && ! grep -q 'downloader.cursor.sh/linux/appImage' \
        "${PROJECT_ROOT}/.chezmoi/run_once_93-install-cursor.sh.tmpl"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] Cursor AppImage uses cursor.com download API"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] Cursor AppImage still uses downloader.cursor.sh"
fi

if grep -q 'ensure_npm_global_latest "@anthropic-ai/claude-code"' \
    "${PROJECT_ROOT}/.chezmoi/run_once_90-install-claude-code.sh.tmpl" \
    && grep -q 'ensure_npm_global_latest "@openai/codex"' \
        "${PROJECT_ROOT}/.chezmoi/run_once_91-install-codex.sh.tmpl" \
    && ! grep -qE '^[[:space:]]*npm install -g' \
        "${PROJECT_ROOT}/.chezmoi/run_once_90-install-claude-code.sh.tmpl" \
    && ! grep -qE '^[[:space:]]*npm install -g' \
        "${PROJECT_ROOT}/.chezmoi/run_once_91-install-codex.sh.tmpl"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] run_once 90/91 call ensure_npm_global_latest (no bare npm install -g)"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] run_once 90/91 still use bare npm install -g"
fi

if _is_windows_interop_path "/mnt/c/Users/x/AppData/Roaming/npm/claude" \
    && _is_windows_interop_path "/mnt/d/Program Files/nodejs/npm" \
    && _is_windows_interop_path "/mnt/host/c/Users/x/AppData/Roaming/npm/claude" \
    && ! _is_windows_interop_path "/mnt/host/wslg/runtime-dir/fnm_multishells/1/bin/npm" \
    && ! _is_windows_interop_path "/mnt/wslg/runtime-dir/fnm_multishells/1/bin/npm" \
    && ! _is_windows_interop_path "/usr/local/bin/claude" \
    && ! _is_windows_interop_path "${HOME}/.local/share/fnm/aliases/default/bin/claude"; then
    PASSED=$((PASSED + 1))
    echo "[PASS] _is_windows_interop_path: Windows drives only; WSLg fnm is local"
else
    FAILED=$((FAILED + 1))
    echo "[FAIL] _is_windows_interop_path misclassifies WSL vs Windows paths"
fi

echo "Summary: $PASSED passed, $FAILED failed"
[[ "$FAILED" -eq 0 ]]
