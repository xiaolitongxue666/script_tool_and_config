#!/bin/bash

# ============================================
# 列出所有目录
# 功能：递归列出指定目录下的所有子目录
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 递归获取目录列表
get_dirs() {
    local root_dir="$1"
    
    for element in "$root_dir"/*; do
        if [[ -d "$element" ]]; then
            echo "$element"
            get_dirs "$element"
        fi
    done
}

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") <根目录>

功能:
    递归列出指定目录下的所有子目录

示例:
    $(basename "$0") ./application
    
    # 在每行前添加前缀
    $(basename "$0") ./application | awk '{print "INCLUDES\t+= -I$(MK_ROOT)/" \$0 }'
    
    # 输出到剪贴板（需要安装 xclip）
    $(basename "$0") ./component | awk '{print "INCLUDES\t+= -I$(MK_ROOT)/" \$0 }' | xclip
    
    # 输出到 CMake 格式
    $(basename "$0") . | awk '{print "include_directories(" \$0 ")" }' > include_directories.cmake
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

    # 列出所有目录
    get_dirs "$root_dir"
}

main "$@"

