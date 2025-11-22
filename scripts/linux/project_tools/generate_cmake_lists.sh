#!/bin/bash

# ============================================
# 生成 CMakeLists.txt
# 功能：自动生成 CMakeLists.txt 文件，包含项目配置、包含目录和源文件
# 注意：在 CLion 中按 Ctrl + Shift + A，然后输入 "Reload CMake Project" 重新加载
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 递归列出目录的函数
list_dirs_recursively() {
    local dir="$1"
    find "$dir" -type d 2>/dev/null
}

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") [项目名称]

功能:
    自动生成 CMakeLists.txt 文件
    - 自动检测当前目录作为项目名称
    - 递归查找 src 目录下的所有子目录作为包含目录
    - 自动添加所有 .c 和 .h 文件作为源文件

注意:
    在 CLion 中按 Ctrl + Shift + A，然后输入 "Reload CMake Project" 重新加载

示例:
    $(basename "$0")
    $(basename "$0") my_project
EOF
    exit 1
}

# 主函数
main() {
    start_script "生成 CMakeLists.txt"

    # 项目名称使用当前目录名
    local project_path=$(pwd)
    local project_name="${1:-${project_path##*/}}"
    
    log_info "项目路径: $project_path"
    log_info "项目名称: $project_name"

    # CMakeLists.txt 文件路径
    local cmake_list_file_path="./CMakeLists.txt"
    local include_dirs_file="./include_directories.cmake"

    # 检查 src 目录是否存在
    if [[ ! -d "./src" ]]; then
        log_warning "src 目录不存在，将创建基本配置"
    fi

    # 备份现有文件
    if [[ -f "$cmake_list_file_path" ]]; then
        backup_file "$cmake_list_file_path" > /dev/null
    fi

    # 重新创建 CMakeLists.txt
    rm -f "$cmake_list_file_path"
    touch "$cmake_list_file_path"

    # 写入 CMake 基本配置
    {
        echo "cmake_minimum_required(VERSION 3.9)"
        echo "project($project_name)"
        echo "set(CMAKE_CXX_STANDARD 11)"
        echo ""
    } >> "$cmake_list_file_path"

    # 包含目录
    if [[ -d "./src" ]]; then
        log_info "正在生成包含目录配置..."
        rm -f "$include_dirs_file"
        list_dirs_recursively "./src" | awk '{print "include_directories("$0")" }' >> "$include_dirs_file"
        echo "include(./include_directories.cmake)" >> "$cmake_list_file_path"
        echo "" >> "$cmake_list_file_path"
    fi

    # 源文件
    log_info "正在生成源文件配置..."
    {
        echo "file(GLOB_RECURSE SOURCES"
        # 查找所有 .c 和 .h 文件
        find . -type f \( -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" \) 2>/dev/null | \
            awk '{print "    "$0}' | head -20
        echo ")"
        echo ""
    } >> "$cmake_list_file_path"

    # 最终可执行文件
    echo "add_executable($project_name \${SOURCES})" >> "$cmake_list_file_path"

    log_success "已生成 CMakeLists.txt: $cmake_list_file_path"
    log_info "提示: 在 CLion 中按 Ctrl + Shift + A，然后输入 'Reload CMake Project' 重新加载"

    end_script
}

main "$@"

