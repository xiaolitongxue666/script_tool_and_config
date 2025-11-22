#!/bin/bash

# ============================================
# 替换文件中的文本
# 功能：在指定文件中替换匹配的文本
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
用法: $(basename "$0") <文件路径> <旧文本> <新文本>

示例:
    $(basename "$0") ./test.txt "old_text" "new_text"
EOF
    exit 1
}

# 替换文件中的文本
replace_text_in_files() {
    local file_path="$1"
    local old_text="$2"
    local new_text="$3"

    # 检查文件是否存在
    check_file "$file_path"

    # 备份文件
    backup_file "$file_path" > /dev/null

    # 执行替换（跨平台兼容）
    if [[ "$(uname -s)" == "Darwin" ]]; then
        sed -i.bak "s|$old_text|$new_text|g" "$file_path"
        rm -f "${file_path}.bak" 2>/dev/null
    else
        sed -i "s|$old_text|$new_text|g" "$file_path"
    fi

    if [[ $? -eq 0 ]]; then
        log_success "已替换文件中的文本: $file_path"
    else
        error_exit "替换文本失败"
    fi
}

# 主函数
main() {
    start_script "替换文件中的文本"

    # 检查参数
    if [[ $# -lt 3 ]]; then
        log_error "参数不足"
        usage
    fi

    local file_path="$1"
    local old_text="$2"
    local new_text="$3"

    log_info "文件: $file_path"
    log_info "旧文本: $old_text"
    log_info "新文本: $new_text"

    replace_text_in_files "$file_path" "$old_text" "$new_text"

    end_script
}

main "$@"

