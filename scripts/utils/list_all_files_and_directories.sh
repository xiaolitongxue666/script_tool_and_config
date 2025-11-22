#!/bin/bash

# ============================================
# 列出所有文件和目录
# 功能：递归列出指定目录下的所有文件和子目录
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 递归获取文件和目录列表
get_files_and_dirs() {
    local root_dir="$1"
    
    for element in "$root_dir"/*; do
        if [[ -e "$element" ]]; then
            echo "$element"
            if [[ -d "$element" ]]; then
                get_files_and_dirs "$element"
            fi
        fi
    done
}

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") <根目录>

功能:
    递归列出指定目录下的所有文件和子目录

示例:
    $(basename "$0") ./application
EOF
    exit 1
}

# 主函数
main() {
    # 检查参数
    if [[ $# -lt 1 ]]; then
        log_error "参数不足"
        usage
    fi

    local root_dir="$1"

    # 检查目录是否存在
    if [[ ! -d "$root_dir" ]]; then
        error_exit "目录不存在: $root_dir"
    fi

    # 列出所有文件和目录
    get_files_and_dirs "$root_dir"
}

main "$@"

