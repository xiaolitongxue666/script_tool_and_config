#!/bin/bash

# ============================================
# install.sh 辅助函数库
# 提供软件检查、配置对比等功能
# ============================================

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
            winget list --id "$package_name" &> /dev/null 2>&1
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
    status_output=$(PAGER=cat chezmoi status 2>&1 || true)

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
    diff_output=$(PAGER=cat chezmoi diff 2>&1 || true)

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
    status_output=$(PAGER=cat chezmoi status 2>&1 || true)

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
    diff_output=$(PAGER=cat chezmoi diff 2>&1 || true)

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

    # 支持 run_once_00-install-* 与 run_once_install-*
    if [[ "$basename" == run_once_00-* ]]; then
        base="${basename#run_once_}"
        base="${base%.sh.tmpl}"
        base="${base%.sh}"
    else
        base="${basename#run_once_install-}"
        base="${base%.sh.tmpl}"
        base="${base%.sh}"
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
        starship|tmux|zsh|fish|alacritty|oh-my-posh)  echo "终端/Shell" ;;
        ghostty|connect)              echo "macOS 专属" ;;
        git|neovim|neovim-config|lazyssh)  echo "开发" ;;
        nerd-fonts)                   echo "字体" ;;
        system-basic-env)             echo "系统基础" ;;
        yabai|skhd|maccy)             echo "macOS 专属" ;;
        i3wm|dwm|arch-base-packages|aur-helper|configure-pacman)  echo "Linux 专属" ;;
        opencode|opencode-omo)        echo "OpenCode" ;;
        *)                            echo "其他" ;;
    esac
}

# 返回当前平台显示名（含 WSL 区分，与 SOFTWARE_LIST.md / INSTALL_STATUS 一致）
# 参数: platform, package_manager
# 返回: 如 "Windows" / "macOS" / "Linux (WSL, apt)" / "Linux (原生, pacman)"
get_platform_display_name() {
    local platform="$1"
    local pkg="${2:-}"
    case "$platform" in
        windows)  echo "Windows" ;;
        macos)    echo "macOS" ;;
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
    if [[ "$script_path" == *"/run_on_linux/"* ]]; then
        [[ "$platform" != "linux" ]] && return 1
        return 0
    fi
    if [[ "$script_path" == *"/run_on_darwin/"* ]]; then
        [[ "$platform" != "macos" ]] && return 1
        return 0
    fi
    if [[ "$script_path" == *"/run_on_windows/"* ]]; then
        [[ "$platform" != "windows" ]] && return 1
        return 0
    fi
    local software_name
    software_name="$(extract_software_name_from_script "$script_path")"
    case "$software_name" in
        # 仅 Linux（含 WSL 原生环境）
        i3wm|alacritty|dwm|lazyssh)
            [[ "$platform" != "linux" ]] && return 1
            ;;
        # 仅 Linux + macOS（不在 Windows 安装，与 SOFTWARE_LIST 一致）
        tmux|fish)
            [[ "$platform" != "linux" && "$platform" != "macos" ]] && return 1
            ;;
        # 仅 macOS
        maccy|skhd|yabai)
            [[ "$platform" != "macos" ]] && return 1
            ;;
        # 仅 Windows
        oh-my-posh)
            [[ "$platform" != "windows" ]] && return 1
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
            # 检查几个主要工具
            if check_command_exists "bat" || check_command_exists "eza" || check_command_exists "fd"; then
                return 0
            fi
            return 1
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
        opencode-omo)
            # Oh My OpenCode：检查 opencode 存在且 opencode.json 含 oh-my-opencode 插件
            if ! check_command_exists "opencode"; then
                return 1
            fi
            local oc_json="${HOME}/.config/opencode/opencode.json"
            if [[ -f "$oc_json" ]] && grep -q '"oh-my-opencode"' "$oc_json" 2>/dev/null; then
                return 0
            fi
            return 1
            ;;
        *)
            # 默认使用软件名作为命令名
            check_software_installed "$command_name"
            ;;
    esac
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

    local all_scripts
    if [[ "$platform" == "windows" ]]; then
        if [[ -x /usr/bin/find ]]; then
            all_scripts=$(/usr/bin/find "$chezmoi_dir" -name "run_once_install-*.sh.tmpl" -type f 2>/dev/null || true; /usr/bin/find "$chezmoi_dir" -name "run_once_00-*.sh.tmpl" -type f 2>/dev/null || true)
        fi
        if [[ -z "$all_scripts" ]]; then
            local _d="$chezmoi_dir"
            all_scripts=$(
                shopt -s nullglob 2>/dev/null || true
                for f in "$_d"/run_once_install-*.sh.tmpl "$_d"/run_once_00-*.sh.tmpl \
                    "$_d"/run_on_linux/run_once_*.sh.tmpl "$_d"/run_on_darwin/run_once_*.sh.tmpl "$_d"/run_on_windows/run_once_*.sh.tmpl; do
                    [[ -f "$f" ]] && echo "$f"
                done | sort -u
            )
        fi
        all_scripts=$(echo "$all_scripts" | sort -u)
    else
        all_scripts=$(find "$chezmoi_dir" -name "run_once_install-*.sh.tmpl" -type f 2>/dev/null || true; find "$chezmoi_dir" -name "run_once_00-*.sh.tmpl" -type f 2>/dev/null || true)
        all_scripts=$(echo "$all_scripts" | sort -u)
    fi
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
        if check_script_software_installed "$script"; then
            printf '%s\t%s\t1\n' "$cat" "$name" >> "$tmp_list"
        else
            printf '%s\t%s\t0\n' "$cat" "$name" >> "$tmp_list"
        fi
    done <<< "$all_scripts"

    [[ ! -s "$tmp_list" ]] && { log_info "无适用于当前平台的 run_once 安装项"; return 0; }

    local category_order="版本管理 终端/Shell 文件/搜索与通用 开发 字体 系统基础 macOS 专属 Linux 专属 Windows 专属 OpenCode 其他"
    local total_installed=0
    local total_not=0

    for cat in $category_order; do
        local lines=""
        while IFS= read -r line; do
            line="${line//$'\r'/}"
            [[ -z "$line" ]] && continue
            local first_field="${line%%$'\t'*}"
            [[ "$first_field" == "$cat" ]] && lines+="$line"$'\n'
        done < "$tmp_list"
        [[ -z "$lines" ]] && continue
        log_info "【$cat】"
        while IFS= read -r line; do
            line="${line//$'\r'/}"
            [[ -z "$line" ]] && continue
            name_installed=$(echo "$line" | cut -f2-)
            name="${name_installed%$'\t'*}"
            inst="${name_installed##*$'\t'}"
            inst="${inst//$'\r'/}"
            if [[ "$inst" == "1" ]]; then
                total_installed=$((total_installed + 1))
                log_info "  ✓ ${name} 已安装"
            else
                total_not=$((total_not + 1))
                log_info "  ✗ ${name} 未安装, 将通过 chezmoi apply 安装"
            fi
        done <<< "$lines"
    done

    if [[ $total_installed -gt 0 ]]; then
        log_success "已安装: ${total_installed} 个"
    fi
    if [[ $total_not -gt 0 ]]; then
        log_info "待安装: ${total_not} 个, 将通过 chezmoi apply 自动安装"
    fi
}

