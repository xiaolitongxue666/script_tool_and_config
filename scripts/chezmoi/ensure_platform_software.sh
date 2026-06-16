#!/usr/bin/env bash

# ============================================
# 全平台软件补装与升级编排
# 由 install.sh [4/6] 调用；也可单独运行
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
if [[ -f "$COMMON_SH" ]]; then
    # shellcheck disable=SC1090
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common_install.sh"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/install_helpers.sh"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/software_policies.sh"

CHEZMOI_CORE="${SCRIPT_DIR}/chezmoi_core.sh"
if [[ -f "$CHEZMOI_CORE" ]]; then
    # shellcheck disable=SC1090
    source "$CHEZMOI_CORE"
    if type chezmoi_normalize_windows_env &>/dev/null; then
        chezmoi_normalize_windows_env
    fi
fi

NO_UPGRADE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-upgrade)
            NO_UPGRADE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--no-upgrade]"
            echo "  UPGRADE_SOFTWARE=1 (default)  Upgrade installed packages to latest stable"
            echo "  SKIP_SOFTWARE_UPGRADE=1       Same as --no-upgrade"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ "$NO_UPGRADE" == "true" ]] || [[ "${SKIP_SOFTWARE_UPGRADE:-0}" == "1" ]]; then
    UPGRADE_SOFTWARE=0
else
    UPGRADE_SOFTWARE="${UPGRADE_SOFTWARE:-1}"
fi

export CHEZMOI_PROJECT_ROOT="${CHEZMOI_PROJECT_ROOT:-$PROJECT_ROOT}"
CHEZMOI_DIR="${CHEZMOI_SOURCE_DIR:-${PROJECT_ROOT}/.chezmoi}"
export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"

ensure_proxy_for_download
detect_os_and_package_manager || {
    log_error "Cannot detect OS/package manager"
    exit 1
}

STATS_INSTALLED=0
STATS_UPGRADED=0
STATS_SKIPPED=0
STATS_FAILED=0

_detect_gui_available() {
    if [[ "${PLATFORM:-}" == "windows" || "${PLATFORM:-}" == "darwin" ]]; then
        return 0
    fi
    if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        return 0
    fi
    return 1
}

_upgrade_software_by_name() {
    local name="$1"
    local policy
    policy="$(get_software_policy "$name")"

    case "$policy" in
        skip)
            return 0
            ;;
        pinned:*)
            local pin_ver="${policy#pinned:}"
            if ensure_rmux_pinned "$pin_ver"; then
                return 0
            fi
            return 1
            ;;
        minimum:*)
            if ensure_neovim_minimum; then
                return 0
            fi
            return 1
            ;;
    esac

    case "$name" in
        00-install-version-managers)
            ensure_fnm_latest || true
            ensure_uv_latest || true
            ;;
        common-tools)
            upgrade_common_tools_packages || true
            ;;
        90-install-claude-code)
            ensure_npm_global_latest "$(get_npm_global_spec "$name")" || return 1
            ;;
        91-install-codex)
            ensure_npm_global_latest "$(get_npm_global_spec "$name")" || return 1
            ;;
        92-install-codewhale)
            ensure_npm_global_latest "$(get_npm_global_spec "$name")" || return 1
            ;;
        93-install-cursor)
            _detect_gui_available || return 0
            local target
            target="$(get_cursor_upgrade_target)"
            case "$target" in
                brew:*)
                    upgrade_brew_cask "${target#brew:}" || upgrade_brew_package "${target#brew:}" || return 1
                    ;;
                winget:*)
                    upgrade_winget_id "${target#winget:}" || return 1
                    ;;
                pacman:*)
                    upgrade_pacman_package "${target#pacman:}" || return 1
                    ;;
                *)
                    return 0
                    ;;
            esac
            ;;
        install-git|git)
            upgrade_package_by_manager "git" || true
            ;;
        install-neovim|neovim)
            ensure_neovim_minimum && return 0
            return 1
            ;;
        install-rmux|rmux)
            ensure_rmux_pinned "0.5.0" && return 0
            return 1
            ;;
        maccy)
            upgrade_brew_cask "maccy" || return 1
            ;;
        ghostty)
            if [[ -d "/Applications/Ghostty.app" ]]; then
                brew upgrade --cask ghostty 2>/dev/null || true
            fi
            ;;
        install-windows-terminal|windows-terminal)
            upgrade_winget_id "Microsoft.WindowsTerminal" || true
            ;;
        oh-my-posh|install-oh-my-posh)
            upgrade_winget_id "JanDeDobbeleer.OhMyPosh" || upgrade_package_by_manager "oh-my-posh" || true
            ;;
        *)
            local cmd="$name"
            case "$name" in
                install-*) cmd="${name#install-}" ;;
            esac
            if command -v "$cmd" &>/dev/null; then
                upgrade_package_by_manager "$cmd" || true
            fi
            ;;
    esac
    return 0
}

_process_one_script() {
    local script="$1"
    local name
    name="$(extract_software_name_from_script "$script")"
    [[ -z "$name" ]] && return 0

    if check_script_software_installed "$script"; then
        if [[ "$UPGRADE_SOFTWARE" -eq 0 ]]; then
            STATS_SKIPPED=$((STATS_SKIPPED + 1))
            log_info "Installed (upgrade skipped): $name"
            return 0
        fi
        local policy
        policy="$(get_software_policy "$name")"
        if [[ "$policy" == "skip" ]]; then
            STATS_SKIPPED=$((STATS_SKIPPED + 1))
            return 0
        fi
        log_info "Checking upgrade: $name (policy: $policy)"
        if _upgrade_software_by_name "$name"; then
            if [[ "$policy" == pinned:* ]] || [[ "$policy" == minimum:* ]]; then
                if check_script_software_installed "$script"; then
                    STATS_SKIPPED=$((STATS_SKIPPED + 1))
                else
                    log_info "Re-running install template after version check: $name"
                    if run_chezmoi_install_script "$script" "$CHEZMOI_DIR"; then
                        STATS_UPGRADED=$((STATS_UPGRADED + 1))
                    else
                        STATS_FAILED=$((STATS_FAILED + 1))
                    fi
                fi
            else
                STATS_UPGRADED=$((STATS_UPGRADED + 1))
                log_success "Upgrade attempted: $name"
            fi
        else
            log_info "Re-running install template: $name"
            if run_chezmoi_install_script "$script" "$CHEZMOI_DIR"; then
                STATS_UPGRADED=$((STATS_UPGRADED + 1))
            else
                STATS_FAILED=$((STATS_FAILED + 1))
            fi
        fi
    else
        log_info "Missing software, installing: $name"
        if run_chezmoi_install_script "$script" "$CHEZMOI_DIR"; then
            STATS_INSTALLED=$((STATS_INSTALLED + 1))
            log_success "Installed: $name"
        else
            STATS_FAILED=$((STATS_FAILED + 1))
            log_warning "Install failed: $name"
        fi
    fi
}

log_info "Ensure platform software (upgrade=${UPGRADE_SOFTWARE}, platform=${PLATFORM:-}, pkg=${PACKAGE_MANAGER:-})"

local_scripts=""
while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    local_scripts+="${s}"$'\n'
done < <(list_applicable_run_once_scripts "$CHEZMOI_DIR" "${PLATFORM:-}")

if [[ -z "$local_scripts" ]]; then
    log_warning "No applicable run_once scripts found"
    exit 0
fi

while IFS= read -r script; do
    [[ -z "$script" ]] && continue
    _process_one_script "$script" || true
done <<< "$local_scripts"

log_info "Ensure summary: installed=${STATS_INSTALLED}, upgraded=${STATS_UPGRADED}, skipped=${STATS_SKIPPED}, failed=${STATS_FAILED}"

if [[ "$STATS_FAILED" -gt 0 ]]; then
    log_warning "Some software ensure steps failed (non-fatal)"
fi

exit 0
