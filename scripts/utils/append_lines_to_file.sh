#!/bin/bash

# ============================================
# 追加多行文本到文件
# 功能：使用 heredoc 语法追加多行文本到文件
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
用法: $(basename "$0") <文件路径>

示例:
    $(basename "$0") ./output.txt

注意: 此脚本会使用 heredoc 语法追加多行文本到文件
EOF
    exit 1
}

# 主函数
main() {
    start_script "追加多行文本到文件"

    # 检查参数
    if [[ $# -lt 1 ]]; then
        log_error "参数不足"
        usage
    fi

    local file_path="$1"
    local kernel="${2:-2.6.39}"
    local distro="${3:-xyz}"

    # 检查文件是否存在
    if [[ ! -f "$file_path" ]]; then
        log_warning "文件不存在，将创建新文件: $file_path"
        touch "$file_path"
    fi

    # 使用 heredoc 追加多行文本
    cat >> "$file_path" << EOL
line 1, ${kernel}
line 2,
line 3, ${distro}
line ...
EOL
    
    if [[ $? -eq 0 ]]; then
        log_success "已追加多行文本到文件: $file_path"
    else
        error_exit "追加多行文本失败"
    fi

    end_script
}

main "$@"

