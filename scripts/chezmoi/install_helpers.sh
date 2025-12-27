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
# 返回: software_name
extract_software_name_from_script() {
    local script_path="$1"
    local basename=$(basename "$script_path")

    # 移除 run_once_install- 前缀
    local software_name="${basename#run_once_install-}"
    # 移除 .sh.tmpl 或 .sh 后缀
    software_name="${software_name%.sh.tmpl}"
    software_name="${software_name%.sh}"

    echo "$software_name"
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

