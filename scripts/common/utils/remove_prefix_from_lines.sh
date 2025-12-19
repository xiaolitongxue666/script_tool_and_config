#!/bin/bash

# ============================================
# 删除每行前缀字符
# 功能：删除文件中每行的前 N 个字符
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") <文件路径> [字符数量]

参数:
    文件路径     要处理的文件路径
    字符数量     要删除的字符数量（默认: 3）

示例:
    $(basename "$0") ./test.txt
    $(basename "$0") ./test.txt 5
EOF
    exit 1
}

# 主函数
main() {
    start_script "删除每行前缀字符"

    # 检查参数
    if [[ $# -lt 1 ]]; then
        log_error "参数不足"
        usage
    fi

    local file_path="$1"
    local char_count="${2:-3}"

    # 检查文件是否存在
    check_file "$file_path"

    # 验证字符数量
    if ! [[ "$char_count" =~ ^[0-9]+$ ]] || [[ "$char_count" -le 0 ]]; then
        error_exit "字符数量必须是正整数"
    fi

    # 备份文件
    backup_file "$file_path" > /dev/null

    # 删除每行前 N 个字符
    # {n} 表示匹配确定的 n 次
    if [[ "$(uname -s)" == "Darwin" ]]; then
        sed -i.bak "s/^.\{$char_count\}//" "$file_path"
        rm -f "${file_path}.bak" 2>/dev/null
    else
        sed -i "s/^.\{$char_count\}//" "$file_path"
    fi

    if [[ $? -eq 0 ]]; then
        log_success "已删除每行前 $char_count 个字符: $file_path"
    else
        error_exit "删除前缀字符失败"
    fi

    end_script
}

main "$@"

