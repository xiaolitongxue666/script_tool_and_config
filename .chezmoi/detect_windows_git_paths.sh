#!/usr/bin/env bash
# chezmoi [data] helper：检测 Git for Windows 路径（C:/ 或 D:/）
# 用法: detect_windows_git_paths.sh bash|icon|connect
set -euo pipefail

_mode="${1:-bash}"

_posix_to_chezmoi_win() {
    local p="$1"
    local drive
    drive="$(echo "${p:1:1}" | tr '[:lower:]' '[:upper:]')"
    printf '%s:%s' "${drive}" "${p:2}"
}

_detect_executable() {
    local p
    for p in "$@"; do
        if [[ -x "$p" ]]; then
            _posix_to_chezmoi_win "$p"
            return 0
        fi
    done
    return 1
}

_detect_file() {
    local p
    for p in "$@"; do
        if [[ -f "$p" ]]; then
            _posix_to_chezmoi_win "$p"
            return 0
        fi
    done
    return 1
}

case "$_mode" in
    bash)
        if _detect_executable \
            "/d/Program Files/Git/bin/bash.exe" \
            "/c/Program Files/Git/bin/bash.exe" \
            "/d/Program Files (x86)/Git/bin/bash.exe" \
            "/c/Program Files (x86)/Git/bin/bash.exe"; then
            exit 0
        fi
        printf 'D:/Program Files/Git/bin/bash.exe'
        ;;
    icon)
        if _detect_file \
            "/d/Program Files/Git/mingw64/share/git/git-for-windows.ico" \
            "/c/Program Files/Git/mingw64/share/git/git-for-windows.ico"; then
            exit 0
        fi
        printf 'D:/Program Files/Git/mingw64/share/git/git-for-windows.ico'
        ;;
    connect)
        if _detect_executable \
            "/d/Program Files/Git/mingw64/bin/connect.exe" \
            "/c/Program Files/Git/mingw64/bin/connect.exe"; then
            exit 0
        fi
        printf 'D:/Program Files/Git/mingw64/bin/connect.exe'
        ;;
    *)
        echo "[ERROR] unknown mode: $_mode" >&2
        exit 1
        ;;
esac
