#!/usr/bin/env bash

# ============================================
# install.sh 辅助函数库
# 提供软件检查、配置对比等功能
# ============================================

_INSTALL_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_SOFTWARE_POLICIES_SH="${_INSTALL_HELPERS_DIR}/software_policies.sh"
_CHEZMOI_CORE_SH="${_INSTALL_HELPERS_DIR}/chezmoi_core.sh"
if [[ -f "$_SOFTWARE_POLICIES_SH" ]]; then
    # shellcheck disable=SC1090
    source "$_SOFTWARE_POLICIES_SH"
fi
if [[ -f "$_CHEZMOI_CORE_SH" ]] && ! type chezmoi_capture_status &>/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source "$_CHEZMOI_CORE_SH"
fi

# 统一 chezmoi status/diff 查询（Windows 下含 override-data）
_chezmoi_query_output() {
    local subcmd="$1"
    if type chezmoi_export_apply_env &>/dev/null; then
        chezmoi_export_apply_env
    fi
    if [[ "$subcmd" == "status" ]] && type chezmoi_capture_status &>/dev/null; then
        chezmoi_capture_status
        return 0
    fi
    if [[ "$subcmd" == "diff" ]] && type chezmoi_capture_diff &>/dev/null; then
        chezmoi_capture_diff
        return 0
    fi
    PAGER=cat chezmoi "$subcmd" 2>&1 || true
}

# ============================================
# 软件安装检查函数
# ============================================

# 检查命令是否存在
# 参数: command_name
check_command_exists() {
    local command_name="$1"
    if command -v "$command_name" &> /dev/null; then
        return 0
    fi
    return 1
}

# 检查包管理器中的安装状态
# 参数: package_name
check_package_installed() {
    local package_name="$1"

    if [ -z "$PACKAGE_MANAGER" ]; then
        return 1
    fi

    case "$PACKAGE_MANAGER" in
        brew)
            brew list "$package_name" &> /dev/null
            ;;
        pacman)
            if [[ "$PLATFORM" == "windows" ]]; then
                pacman.exe -Q "$package_name" &> /dev/null
            else
                pacman -Q "$package_name" &> /dev/null
            fi
            ;;
        apt)
            dpkg -l | grep -q "^ii.*$package_name " &> /dev/null
            ;;
        dnf|yum)
            rpm -q "$package_name" &> /dev/null
            ;;
        winget)
            winget list --id "$package_name" --source winget &> /dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# 综合检查软件是否已安装（命令 + 包管理器）
# 参数: command_name [package_name]
check_software_installed() {
    local command_name="$1"
    local package_name="${2:-$command_name}"

    # 检查命令是否存在
    if check_command_exists "$command_name"; then
        return 0
    fi

    # 检查包管理器中的安装状态
    if check_package_installed "$package_name"; then
        return 0
    fi

    return 1
}

# ============================================
# chezmoi 配置检查函数
# ============================================

# 检查配置状态（使用 chezmoi status）
# 返回: 0=无差异, 1=有差异
check_chezmoi_status() {
    local status_output
    # 设置 PAGER=cat 避免进入交互模式
    status_output=$(_chezmoi_query_output status)

    # 如果输出包含错误信息，认为有差异
    if echo "$status_output" | grep -qi "error\|failed"; then
        return 1
    fi

    if [ -z "$status_output" ]; then
        return 0  # 无差异
    fi

    return 1  # 有差异
}

# 检查配置差异（使用 chezmoi diff）
# 返回: 0=无差异, 1=有差异
check_chezmoi_diff() {
    local diff_output
    # 设置 PAGER=cat 避免进入交互模式
    diff_output=$(_chezmoi_query_output diff)

    # 如果输出包含错误信息，认为有差异
    if echo "$diff_output" | grep -qi "error\|failed"; then
        return 1
    fi

    if [ -z "$diff_output" ]; then
        return 0  # 无差异
    fi

    return 1  # 有差异
}

# 检查配置是否最新
# 返回: 0=最新, 1=不是最新
check_config_up_to_date() {
    # 同时检查 status 和 diff
    if check_chezmoi_status && check_chezmoi_diff; then
        return 0  # 最新
    fi

    return 1  # 不是最新
}

# 获取配置状态摘要
get_chezmoi_status_summary() {
    local status_output
    # 设置 PAGER=cat 避免进入交互模式
    status_output=$(_chezmoi_query_output status)

    # 检查是否出错
    if echo "$status_output" | grep -qi "error\|failed"; then
        echo "检查配置状态时出错"
        return 1
    fi

    if [ -z "$status_output" ]; then
        echo "所有配置都是最新的"
        return 0
    fi

    # 统计不同类型的变更
    local modified=$(echo "$status_output" | grep -c "^M" || echo "0")
    local added=$(echo "$status_output" | grep -c "^A" || echo "0")
    local deleted=$(echo "$status_output" | grep -c "^D" || echo "0")
    local run=$(echo "$status_output" | grep -c "^R" || echo "0")

    echo "发现未同步配置: M=$modified, A=$added, D=$deleted, R=$run"
    return 1
}

# 获取配置差异摘要
get_chezmoi_diff_summary() {
    local diff_output
    # 设置 PAGER=cat 避免进入交互模式
    diff_output=$(_chezmoi_query_output diff)

    # 检查是否出错
    if echo "$diff_output" | grep -qi "error\|failed"; then
        echo "检查配置差异时出错"
        return 1
    fi

    if [ -z "$diff_output" ]; then
        echo "模板配置与本地配置一致"
        return 0
    fi

    # 统计差异文件数量
    local file_count=$(echo "$diff_output" | grep -c "^diff --git" || echo "0")
    echo "发现 $file_count 个文件存在差异"
    return 1
}

# ============================================
# 软件安装脚本分析函数
# ============================================

# 从安装脚本文件名提取软件名
# 参数: script_path
# 返回: software_name（与 SOFTWARE_LIST.md 中 run_once 索引一致）
extract_software_name_from_script() {
    local script_path="$1"
    [[ -z "$script_path" ]] && { echo ''; return 0; }
    local basename=$(basename "$script_path")
    local base

    # 支持 run_once_00-*、run_once_9x-*（Layer 4 AI）、run_once_install-*、run_once_configure-*
    if [[ "$basename" == run_once_00-* ]]; then
        base="${basename#run_once_}"
        base="${base%.sh.tmpl}"
        base="${base%.sh}"
    elif [[ "$basename" == run_once_install-* ]]; then
        base="${basename#run_once_install-}"
        base="${base%.sh.tmpl}"
        base="${base%.sh}"
    elif [[ "$basename" == run_once_configure-* ]]; then
        base="${basename#run_once_}"
        base="${base%.sh.tmpl}"
        base="${base%.sh}"
    elif [[ "$basename" == run_once_[0-9]* ]]; then
        base="${basename#run_once_}"
        base="${base%.sh.tmpl}"
        base="${base%.sh}"
    else
        base="${basename%.sh.tmpl}"
        base="${base%.sh}"
        # 兜底：仍带 run_once_ 前缀时去掉（如未覆盖的命名）
        if [[ "$base" == run_once_* ]]; then
            base="${base#run_once_}"
        fi
    fi
    echo "$base"
}

# 返回软件所属分类（与 SOFTWARE_LIST.md 按 OS 汇总一致，用于 [4/5] 分栏打印）
# 参数: software_name
# 返回: 分类名
get_software_category() {
    local name="$1"
    case "$name" in
        00-install-version-managers)  echo "版本管理" ;;
        common-tools)                 echo "文件/搜索与通用" ;;
        starship|tmux|zsh|fish|alacritty|oh-my-posh|windows-terminal)  echo "终端/Shell" ;;
        ghostty|connect)              echo "macOS 专属" ;;
        git|neovim|neovim-config|lazyssh)  echo "开发" ;;
        nerd-fonts)                   echo "字体" ;;
        system-basic-env)             echo "系统基础" ;;
        yabai|skhd|maccy)             echo "macOS 专属" ;;
        i3wm|dwm|arch-base-packages|aur-helper|configure-pacman)  echo "Linux 专属" ;;
        90-install-claude-code|91-install-codex|93-install-cursor)  echo "AI 工具" ;;
        *)                            echo "其他" ;;
    esac
}

# 返回当前平台显示名（含 WSL 区分，与 SOFTWARE_LIST.md 一致）
# 参数: platform, package_manager
# 返回: 如 "Windows" / "macOS" / "Linux (WSL, apt)" / "Linux (原生, pacman)"
get_platform_display_name() {
    local platform="$1"
    local pkg="${2:-}"
    case "$platform" in
        windows)  echo "Windows" ;;
        darwin|macos)    echo "macOS" ;;
        linux)
            if grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
                echo "Linux (WSL, ${pkg:-apt})"
            else
                echo "Linux (原生, ${pkg:-})"
            fi
            ;;
        *)        echo "${platform:-未知}" ;;
    esac
}

# 内部：当前环境是否 WSL（供 script_applicable_to_platform 使用）
_helpers_is_wsl() {
    if type chezmoi_is_wsl &>/dev/null; then
        chezmoi_is_wsl
        return $?
    fi
    if type is_wsl &>/dev/null; then
        is_wsl
        return $?
    fi
    [[ "$(uname -s 2>/dev/null || true)" == "Linux" ]] \
        && { grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; }
}

# 内部：当前环境是否 Arch Linux
_helpers_is_arch() {
    if type is_arch_linux &>/dev/null; then
        is_arch_linux
        return $?
    fi
    [[ "$(uname -s 2>/dev/null || true)" == "Linux" ]] || return 1
    [[ -f /etc/os-release ]] || return 1
    local id
    id="$(awk -F= '/^ID=/{gsub(/"/,""); print $2; exit}' /etc/os-release 2>/dev/null)"
    [[ "$id" == "arch" || "$id" == "archarm" ]]
}

# 判断安装脚本是否适用于当前平台（用于安装状态检查时过滤）
# 参数: script_path, platform (linux|macos|windows)
# 返回: 0=适用于当前平台应检查, 1=不适用应跳过
script_applicable_to_platform() {
    local script_path="$1"
    local platform="$2"
    script_path="${script_path//\\/\/}"
    if [[ -z "$platform" ]]; then
        return 0
    fi
    # 统一 darwin/macos 为 darwin
    local plat="$platform"
    [[ "$plat" == "macos" ]] && plat="darwin"
    if [[ "$script_path" == *"/run_on_linux/"* ]]; then
        [[ "$plat" != "linux" ]] && return 1
    elif [[ "$script_path" == *"/run_on_darwin/"* ]]; then
        [[ "$plat" != "darwin" ]] && return 1
        return 0
    elif [[ "$script_path" == *"/run_on_windows/"* ]]; then
        [[ "$plat" != "windows" ]] && return 1
        return 0
    fi
    local software_name
    software_name="$(extract_software_name_from_script "$script_path")"
    case "$software_name" in
        # 仅 Arch Linux（Ubuntu/Debian/WSL 不适用，不列入 Missing）
        configure-pacman|arch-base-packages|aur-helper|dwm)
            [[ "$plat" != "linux" ]] && return 1
            _helpers_is_arch || return 1
            ;;
        # 原生 Linux GUI：WSL 上跳过（用 Windows 终端 / 无本地 WM）
        i3wm|alacritty)
            [[ "$plat" != "linux" ]] && return 1
            _helpers_is_wsl && return 1
            ;;
        # 仅 Linux（含 WSL）
        lazyssh)
            [[ "$plat" != "linux" ]] && return 1
            ;;
        # 仅 Linux + macOS（不在 Windows 安装，与 SOFTWARE_LIST 一致）
        tmux|fish)
            [[ "$plat" != "linux" && "$plat" != "darwin" ]] && return 1
            ;;
        # 仅 macOS
        maccy|skhd|yabai)
            [[ "$plat" != "darwin" ]] && return 1
            ;;
        # 仅 Windows
        oh-my-posh)
            [[ "$plat" != "windows" ]] && return 1
            ;;
    esac
    return 0
}

# 检查安装脚本对应的软件是否已安装
# 参数: script_path
# 返回: 0=已安装, 1=未安装
check_script_software_installed() {
    local script_path="$1"
    local software_name=$(extract_software_name_from_script "$script_path")

    # 常见软件名到命令名的映射
    local command_name="$software_name"
    case "$software_name" in
        00-install-version-managers)
            if check_command_exists "fnm" || check_command_exists "uv" || check_command_exists "rustup"; then
                return 0
            fi
            return 1
            ;;
        common-tools)
            check_common_tools_installed_status
            return $?
            ;;
        version-managers)
            # 检查版本管理器
            if check_command_exists "fnm" || check_command_exists "uv" || check_command_exists "rustup"; then
                return 0
            fi
            return 1
            ;;
        system-basic-env)
            # 系统基础环境，通常已安装
            return 0
            ;;
        90-install-claude-code|claude-code)
            if check_command_exists "claude"; then
                return 0
            fi
            return 1
            ;;
        91-install-codex|codex)
            if check_command_exists "codex"; then
                return 0
            fi
            return 1
            ;;
        neovim|install-neovim)
            # 仅检测二进制 nvim（>=0.11）；配置归属 ~/.config/nvim 独立仓库，缺失不算未安装
            check_neovim_binary_installed
            return $?
            ;;
        windows-terminal|install-windows-terminal)
            check_windows_terminal_installed
            return $?
            ;;
        nerd-fonts|install-nerd-fonts)
            check_nerd_fonts_firamono_installed
            return $?
            ;;
        *)
            # 默认使用软件名作为命令名
            check_software_installed "$command_name"
            ;;
    esac
}

# Neovim：command -v nvim + 版本 >= 0.11；不要求 ~/.config/nvim
check_neovim_binary_installed() {
    if ! check_command_exists "nvim"; then
        return 1
    fi
    if type is_nvim_version_ge_0_11 &>/dev/null; then
        if ! is_nvim_version_ge_0_11; then
            return 1
        fi
    else
        local first_line major minor
        first_line="$(nvim --version 2>/dev/null | head -n 1)" || return 1
        major="$(echo "$first_line" | sed -n 's/.*[vV]\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1/p')"
        minor="$(echo "$first_line" | sed -n 's/.*[vV]\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\2/p')"
        [[ -z "$major" || -z "$minor" ]] && return 1
        if [[ "$major" -eq 0 && "$minor" -lt 11 ]]; then
            return 1
        fi
    fi
    if [[ ! -d "${HOME}/.config/nvim" ]]; then
        echo "[INFO] nvim binary OK; config managed separately (~/.config/nvim)" >&2
    fi
    return 0
}

# Windows Terminal：wt 或 LocalState 旁的 WindowsApps\wt.exe
check_windows_terminal_installed() {
    if check_command_exists "wt"; then
        return 0
    fi
    local wt_path=""
    if [[ -n "${LOCALAPPDATA:-}" ]]; then
        if command -v cygpath &>/dev/null; then
            wt_path="$(cygpath -u "${LOCALAPPDATA}/Microsoft/WindowsApps/wt.exe" 2>/dev/null || true)"
        else
            wt_path="${LOCALAPPDATA}/Microsoft/WindowsApps/wt.exe"
            wt_path="${wt_path//\\//}"
        fi
        if [[ -n "$wt_path" && -f "$wt_path" ]]; then
            return 0
        fi
    fi
    if [[ -f "/c/Users/${USER:-}/AppData/Local/Microsoft/WindowsApps/wt.exe" ]]; then
        return 0
    fi
    return 1
}

# FiraMono Nerd Font（与 verify_installation.sh 路径探测对齐）
check_nerd_fonts_firamono_installed() {
    local os_name
    os_name="$(uname -s 2>/dev/null || echo unknown)"
    case "$os_name" in
        Linux)
            local font_dir="/usr/local/share/fonts/FiraMono-NerdFont"
            if [[ -d "$font_dir" ]] && find "$font_dir" -name "*.ttf" -o -name "*.otf" 2>/dev/null | grep -q .; then
                return 0
            fi
            if command -v fc-list &>/dev/null && fc-list 2>/dev/null | grep -qi FiraMono; then
                return 0
            fi
            return 1
            ;;
        Darwin)
            local dir
            for dir in "/Library/Fonts" "${HOME}/Library/Fonts"; do
                if [[ -d "$dir" ]] && find "$dir" -name "*FiraMono*" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | grep -q .; then
                    return 0
                fi
            done
            return 1
            ;;
        MINGW*|MSYS*|CYGWIN*)
            local fonts_dir="/c/Windows/Fonts"
            if [[ -d "${fonts_dir}" ]] && find "${fonts_dir}" -name "*FiraMono*" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | grep -q .; then
                return 0
            fi
            # Win11 无管理员时常装到用户字体目录
            local user_fonts=""
            if [[ -n "${LOCALAPPDATA:-}" ]] && command -v cygpath &>/dev/null; then
                user_fonts="$(cygpath -u "${LOCALAPPDATA}/Microsoft/Windows/Fonts" 2>/dev/null || true)"
            fi
            if [[ -n "$user_fonts" && -d "$user_fonts" ]] \
                && find "$user_fonts" -name "*FiraMono*" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | grep -q .; then
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# common-tools 安装状态：0=全部已装, 1=全部缺失, 2=部分已装
# 供 check_script_software_installed 与报告使用
check_common_tools_installed_status() {
    local cmd total=0 present=0
    if ! type get_common_tool_commands &>/dev/null; then
        if type common_tool_command_present &>/dev/null; then
            if common_tool_command_present "bat" || check_command_exists "eza" || common_tool_command_present "fd"; then
                return 0
            fi
        elif check_command_exists "bat" || check_command_exists "eza" || check_command_exists "fd" \
            || command -v batcat &>/dev/null || command -v fdfind &>/dev/null; then
            return 0
        fi
        return 1
    fi
    for cmd in $(get_common_tool_commands); do
        # 当前平台无包（packages.conf 为 "-"）则不计入（如 Windows 的 trash/btop）
        if type get_common_tool_package &>/dev/null; then
            local _pkg
            _pkg="$(get_common_tool_package "$cmd" "${PLATFORM:-}" "${PACKAGE_MANAGER:-}")"
            if [[ -z "$_pkg" ]]; then
                continue
            fi
        elif [[ "$cmd" == "btop" || "$cmd" == "fastfetch" || "$cmd" == "trash" ]]; then
            if [[ "${PLATFORM:-}" == "windows" ]]; then
                continue
            fi
        fi
        total=$((total + 1))
        if type common_tool_command_present &>/dev/null; then
            if common_tool_command_present "$cmd"; then
                present=$((present + 1))
            fi
            continue
        fi
        if [[ "$cmd" == "trash" ]]; then
            if command -v trash &>/dev/null || command -v trash-cli &>/dev/null; then
                present=$((present + 1))
            fi
            continue
        fi
        if [[ "$cmd" == "bat" ]]; then
            if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
                present=$((present + 1))
            fi
            continue
        fi
        if [[ "$cmd" == "fd" ]]; then
            if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
                present=$((present + 1))
            fi
            continue
        fi
        if command -v "$cmd" &>/dev/null; then
            present=$((present + 1))
        fi
    done
    [[ "$total" -eq 0 ]] && return 1
    [[ "$present" -eq 0 ]] && return 1
    [[ "$present" -eq "$total" ]] && return 0
    return 2
}

# 返回软件报告状态码（stdout）：0=未安装, 1=已安装/符合策略, 2=部分安装或跳过升级
# 参数: script_path, upgrade_skipped(0|1)
# 注意：状态经 stdout 输出，函数始终 return 0，避免 install.sh 的 set -e 在 $() 中误判失败
get_software_report_status() {
    local script_path="$1"
    local upgrade_skipped="${2:-0}"
    local software_name status_code=1
    software_name="$(extract_software_name_from_script "$script_path")"

    if [[ "$software_name" == "common-tools" ]]; then
        check_common_tools_installed_status
        case $? in
            0) status_code=1 ;;
            2) status_code=2 ;;
            *) status_code=0 ;;
        esac
    elif ! check_script_software_installed "$script_path"; then
        status_code=0
    elif [[ "$upgrade_skipped" -eq 1 ]]; then
        local policy=""
        if type get_software_policy &>/dev/null; then
            policy="$(get_software_policy "$software_name")"
        fi
        if [[ "$policy" == "latest" ]]; then
            status_code=2
        fi
    fi
    echo "$status_code"
}

# 统一发现 run_once 模板（含 Layer 4）
find_all_run_once_scripts() {
    local chezmoi_dir="$1"
    local platform="${2:-}"
    if type list_applicable_run_once_scripts &>/dev/null && [[ -n "$platform" ]]; then
        list_applicable_run_once_scripts "$chezmoi_dir" "$platform"
        return 0
    fi
    find "$chezmoi_dir" -name 'run_once_*.sh.tmpl' -type f 2>/dev/null | sort -u
}

# 扫描并检查所有安装脚本
# 参数: chezmoi_dir
# 输出: 已安装和未安装的软件列表
scan_and_check_install_scripts() {
    local chezmoi_dir="$1"
    local installed_count=0
    local not_installed_count=0

    if [ ! -d "$chezmoi_dir" ]; then
        return 1
    fi

    # 查找所有安装脚本
    local install_scripts=$(find "$chezmoi_dir" -name "run_once_install-*.sh.tmpl" -type f 2>/dev/null || true)

    if [ -z "$install_scripts" ]; then
        return 1
    fi

    # 检查每个脚本
    echo "$install_scripts" | while IFS= read -r script; do
        local software_name=$(extract_software_name_from_script "$script")

        if check_script_software_installed "$script"; then
            echo "INSTALLED:$software_name"
            installed_count=$((installed_count + 1))
        else
            echo "NOT_INSTALLED:$software_name"
            not_installed_count=$((not_installed_count + 1))
        fi
    done

    # 返回统计信息（通过全局变量或文件）
    echo "STATS:$installed_count:$not_installed_count"
}

# 按 SOFTWARE_LIST.md 的 OS/WSL 分类打印安装状态（[4/5] 检查软件安装状态）
# 参数: chezmoi_dir, platform, package_manager
# 依赖: log_info, log_success 等（由 install.sh 提供）
report_install_status_by_platform() {
    local chezmoi_dir="$1"
    local platform="$2"
    local pkg="$3"
    [[ -z "$platform" ]] && return 0
    [[ ! -d "$chezmoi_dir" ]] && return 1

    local display_name
    display_name="$(get_platform_display_name "$platform" "$pkg")"
    log_info '当前: '"$display_name"'（依据 docs/SOFTWARE_LIST.md 按 OS 汇总）'

    local upgrade_skipped=0
    if [[ "${SKIP_SOFTWARE_UPGRADE:-0}" == "1" ]]; then
        upgrade_skipped=1
    fi

    local all_scripts
    all_scripts="$(find_all_run_once_scripts "$chezmoi_dir" "$platform")"
    [[ -z "$all_scripts" ]] && return 0

    local tmp_list
    tmp_list=$(mktemp)
    trap "rm -f '$tmp_list'" RETURN EXIT

    while IFS= read -r script; do
        [[ -z "$script" ]] && continue
        script_applicable_to_platform "$script" "$platform" || continue
        local name
        name="$(extract_software_name_from_script "$script")"
        [[ -z "$name" ]] && continue
        local cat
        cat="$(get_software_category "$name")"
        local status_code
        status_code="$(get_software_report_status "$script" "$upgrade_skipped")"
        printf '%s\t%s\t%s\n' "$cat" "$name" "$status_code" >> "$tmp_list"
    done <<< "$all_scripts"

    [[ ! -s "$tmp_list" ]] && { log_info "无适用于当前平台的 run_once 安装项"; return 0; }

    local category_order="版本管理 终端/Shell 文件/搜索与通用 开发 字体 系统基础 macOS 专属 Linux 专属 Windows 专属 AI 工具 其他"
    local total_installed=0
    local total_not=0
    local total_partial=0

    for cat in $category_order; do
        local lines=""
        while IFS= read -r line; do
            line="${line//$'\r'/}"
            [[ -z "$line" ]] && continue
            local first_field="${line%%$'\t'*}"
            [[ "$first_field" == "$cat" ]] && lines+="$line"$'\n'
        done < "$tmp_list"
        [[ -z "$lines" ]] && continue
        # ${cat} 必须花括号：macOS UTF-8 locale 下 "$cat" 后紧跟 】 会把其首字节并入变量名 → set -u unbound
        log_info "【${cat}】"
        while IFS= read -r line; do
            line="${line//$'\r'/}"
            [[ -z "$line" ]] && continue
            name_installed=$(echo "$line" | cut -f2-)
            name="${name_installed%$'\t'*}"
            inst="${name_installed##*$'\t'}"
            inst="${inst//$'\r'/}"
            case "$inst" in
                1)
                    total_installed=$((total_installed + 1))
                    log_info "  ✓ ${name} installed (OK)"
                    ;;
                2)
                    total_partial=$((total_partial + 1))
                    if [[ "$upgrade_skipped" -eq 1 ]]; then
                        log_info "  ~ ${name} installed (upgrade skipped, remove --no-upgrade to update)"
                    else
                        log_info "  ~ ${name} partially installed"
                    fi
                    ;;
                *)
                    total_not=$((total_not + 1))
                    log_info "  ✗ ${name} not installed"
                    ;;
            esac
        done <<< "$lines"
    done

    if [[ $total_installed -gt 0 ]]; then
        log_success "Installed (OK): ${total_installed}"
    fi
    if [[ $total_partial -gt 0 ]]; then
        log_info "Partial / upgrade skipped: ${total_partial}"
    fi
    if [[ $total_not -gt 0 ]]; then
        log_info "Missing: ${total_not} (re-run install.sh or ensure_platform_software.sh)"
    fi
}

