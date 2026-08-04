#!/usr/bin/env bash
# ============================================
# 安装 clangd 二进制（不安装 Cursor）
# 支持：Linux / WSL / macOS / Windows(Git Bash+winget 或 MSYS2)
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_INSTALL="${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

log_info()  { printf "[install-clangd] [INFO] %s\n" "$*"; }
log_ok()    { printf "[install-clangd] [OK] %s\n" "$*"; }
log_warn()  { printf "[install-clangd] [WARN] %s\n" "$*" >&2; }
log_error() { printf "[install-clangd] [ERROR] %s\n" "$*" >&2; }

if [[ -f "$COMMON_INSTALL" ]]; then
    # shellcheck disable=SC1090
    source "$COMMON_INSTALL"
    setup_proxy "${PROXY:-${http_proxy:-${HTTP_PROXY:-}}}" || true
    detect_os_and_package_manager || true
fi

PLATFORM="${PLATFORM:-}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-}"
if [[ -z "$PLATFORM" ]]; then
    case "$(uname -s 2>/dev/null)" in
        Darwin) PLATFORM="darwin"; PACKAGE_MANAGER="${PACKAGE_MANAGER:-brew}" ;;
        Linux)  PLATFORM="linux"
            if command -v pacman >/dev/null 2>&1; then PACKAGE_MANAGER="${PACKAGE_MANAGER:-pacman}"
            elif command -v apt-get >/dev/null 2>&1; then PACKAGE_MANAGER="${PACKAGE_MANAGER:-apt}"
            elif command -v dnf >/dev/null 2>&1; then PACKAGE_MANAGER="${PACKAGE_MANAGER:-dnf}"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) PLATFORM="windows"
            if command -v winget >/dev/null 2>&1; then PACKAGE_MANAGER="${PACKAGE_MANAGER:-winget}"
            elif command -v pacman >/dev/null 2>&1; then PACKAGE_MANAGER="${PACKAGE_MANAGER:-pacman}"
            fi
            ;;
        *) PLATFORM="unknown" ;;
    esac
fi

clangd_available() {
    command -v clangd >/dev/null 2>&1
}

print_clangd_version() {
    clangd --version 2>/dev/null | head -n 1 || true
}

# macOS：Homebrew llvm 的 clangd 常不在默认 PATH
ensure_brew_llvm_on_path() {
    if [[ "$PLATFORM" != "darwin" ]] && [[ "$PLATFORM" != "macos" ]]; then
        return 0
    fi
    if clangd_available; then
        return 0
    fi
    local prefix=""
    if command -v brew >/dev/null 2>&1; then
        prefix="$(brew --prefix llvm 2>/dev/null || true)"
    fi
    if [[ -n "$prefix" && -x "${prefix}/bin/clangd" ]]; then
        export PATH="${prefix}/bin:${PATH}"
        log_info "Added brew llvm to PATH for this session: ${prefix}/bin"
    fi
}

install_linux() {
    case "$PACKAGE_MANAGER" in
        apt)
            if command -v sudo >/dev/null 2>&1; then
                sudo apt-get update -qq
                sudo apt-get install -y clangd
            else
                apt-get update -qq
                apt-get install -y clangd
            fi
            ;;
        pacman)
            if command -v sudo >/dev/null 2>&1; then
                sudo pacman -S --noconfirm --needed clang
            else
                pacman -S --noconfirm --needed clang
            fi
            ;;
        dnf)
            if command -v sudo >/dev/null 2>&1; then
                sudo dnf install -y clang-tools-extra
            else
                dnf install -y clang-tools-extra
            fi
            ;;
        *)
            log_error "Unsupported Linux package manager: ${PACKAGE_MANAGER:-none}"
            log_error "Install manually: apt install clangd | pacman -S clang | dnf install clang-tools-extra"
            return 1
            ;;
    esac
}

install_darwin() {
    if [[ -x /usr/bin/clangd ]]; then
        log_ok "Xcode CLT clangd present: /usr/bin/clangd"
        return 0
    fi
    if command -v brew >/dev/null 2>&1; then
        if brew list llvm >/dev/null 2>&1; then
            log_ok "brew llvm already installed"
        else
            brew install llvm
        fi
        ensure_brew_llvm_on_path
        return 0
    fi
    log_warn "brew not found; try: xcode-select --install"
    if xcode-select -p >/dev/null 2>&1; then
        log_info "xcode-select already configured; clangd may appear after CLT install"
    else
        xcode-select --install 2>/dev/null || true
    fi
    return 0
}

install_windows() {
    case "$PACKAGE_MANAGER" in
        winget)
            winget install -e --id LLVM.LLVM --source winget \
                --accept-source-agreements --accept-package-agreements || return 1
            ;;
        pacman)
            # MSYS2 MinGW
            pacman -S --noconfirm --needed mingw-w64-x86_64-clang-tools-extra || return 1
            ;;
        *)
            log_error "Windows: need winget or MSYS2 pacman"
            log_error "  winget install -e --id LLVM.LLVM --source winget"
            log_error "  pacman -S mingw-w64-x86_64-clang-tools-extra"
            return 1
            ;;
    esac
}

if clangd_available; then
    log_ok "clangd already available: $(command -v clangd) ($(print_clangd_version))"
    exit 0
fi

ensure_brew_llvm_on_path
if clangd_available; then
    log_ok "clangd available after PATH fix: $(command -v clangd) ($(print_clangd_version))"
    exit 0
fi

log_info "PLATFORM=${PLATFORM} PACKAGE_MANAGER=${PACKAGE_MANAGER}"
log_info "Installing clangd..."

case "$PLATFORM" in
    linux) install_linux ;;
    darwin|macos) install_darwin ;;
    windows) install_windows ;;
    *)
        log_error "Unsupported PLATFORM=$PLATFORM"
        exit 1
        ;;
esac

ensure_brew_llvm_on_path

if clangd_available; then
    log_ok "clangd installed: $(command -v clangd) ($(print_clangd_version))"
    exit 0
fi

log_error "clangd still not in PATH after install"
log_error "macOS brew llvm: export PATH=\"\$(brew --prefix llvm)/bin:\$PATH\""
log_error "Windows: add LLVM bin to User PATH, then reopen shell"
exit 1
