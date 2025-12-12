#!/bin/bash

# ============================================
# chezmoi 辅助函数库
# 提供常用的辅助函数
# ============================================

# 获取项目根目录
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "${script_dir}/../.." && pwd)"
}

# 获取通用函数库路径
get_common_sh_path() {
    local project_root="$(get_project_root)"
    echo "${project_root}/scripts/common.sh"
}

# 加载通用函数库
load_common_sh() {
    local common_sh="$(get_common_sh_path)"
    if [ -f "$common_sh" ]; then
        source "$common_sh"
        return 0
    else
        echo "[WARNING] 未找到 common.sh: $common_sh"
        return 1
    fi
}

# 检查 chezmoi 是否已安装
check_chezmoi_installed() {
    if command -v chezmoi &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 获取 chezmoi 源状态目录
get_chezmoi_source_dir() {
    local project_root="$(get_project_root)"
    echo "${project_root}/.chezmoi"
}

# 检查 chezmoi 是否已初始化
check_chezmoi_initialized() {
    local source_dir="$(get_chezmoi_source_dir)"
    if [ -d "$source_dir" ] && [ -f "${source_dir}/.git/config" ] 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 初始化 chezmoi 仓库
init_chezmoi_repo() {
    local source_dir="$(get_chezmoi_source_dir)"

    if [ -d "$source_dir" ]; then
        echo "[INFO] chezmoi 源状态目录已存在: $source_dir"
        if [ ! -d "${source_dir}/.git" ]; then
            echo "[INFO] 初始化 Git 仓库..."
            cd "$source_dir"
            git init
            git add .
            git commit -m "Initial commit" || true
            cd - > /dev/null
        fi
    else
        echo "[INFO] 创建 chezmoi 源状态目录: $source_dir"
        mkdir -p "$source_dir"
        cd "$source_dir"
        git init
        cd - > /dev/null
    fi
}
