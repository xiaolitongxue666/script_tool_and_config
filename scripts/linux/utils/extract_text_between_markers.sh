#!/bin/bash

# ============================================
# 提取标记之间的文本
# 功能：从文件中提取两个特殊标记之间的文本内容
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") <文件路径> <开始标记> <结束标记>

示例:
    $(basename "$0") ./config.txt "BEGIN" "END"
EOF
    exit 1
}

# 主函数
main() {
    start_script "提取标记之间的文本"

    # 检查参数
    if [[ $# -lt 3 ]]; then
        log_error "参数不足"
        usage
    fi

    local file_path="$1"
    local begin_marker="$2"
    local end_marker="$3"

    # 检查文件是否存在
    check_file "$file_path"

    # 提取标记之间的文本
    # 使用 sed 提取两个标记之间的内容（包含标记）
    sed -n "/$begin_marker/,/$end_marker/p" "$file_path"

    if [[ $? -eq 0 ]]; then
        log_success "已提取标记之间的文本"
    else
        error_exit "提取文本失败"
    fi

    end_script
}

main "$@"

