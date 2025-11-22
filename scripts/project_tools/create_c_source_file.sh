#!/bin/bash

# ============================================
# 创建 C 源文件
# 功能：创建新的 C/C++ 源文件或头文件，包含标准模板
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") <文件名>

功能:
    创建新的 C/C++ 源文件或头文件，包含标准模板

示例:
    $(basename "$0") main.c
    $(basename "$0") utils.h
EOF
    exit 1
}

# 主函数
main() {
    start_script "创建 C 源文件"

    # 检查参数
    if [[ $# -lt 1 ]]; then
        log_error "参数不足"
        usage
    fi

    local file_path="$1"
    local filename="${file_path%.*}"
    local suffix="${file_path##*.}"

    log_info "文件名: $filename"
    log_info "扩展名: $suffix"

    # 创建文件
    touch "$file_path"

    # 添加文件头注释
    {
        echo "/* File: $file_path */"
        echo "/* Author: $(whoami) */"
        echo "/* Date: $(date) */"
    } > "$file_path"

    # 如果是头文件，添加头文件保护
    if [[ "$suffix" == "h" ]] || [[ "$suffix" == "hpp" ]]; then
        local header_guard=$(echo "$filename" | tr '[:lower:]' '[:upper:]' | tr -d '[:punct:]')
        {
            echo ""
            echo "#ifndef _${header_guard}_H_"
            echo "#define _${header_guard}_H_"
            echo ""
            echo "#endif /* _${header_guard}_H_ */"
        } >> "$file_path"
        log_success "已创建头文件: $file_path（包含头文件保护）"
    else
        log_success "已创建源文件: $file_path"
    fi

    end_script
}

main "$@"

