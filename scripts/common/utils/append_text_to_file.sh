#!/bin/bash

# ============================================
# 追加文本到文件
# 功能：在文件末尾追加一行文本
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="$SCRIPT_DIR/../../../common.sh"
if [[ -f "$COMMON_SH" ]]; then
    source "$COMMON_SH"
else
    echo "警告: 无法加载 common.sh，将使用基本功能"
    # 定义基本函数
    function log_info() { echo "[信息] $*"; }
    function log_success() { echo "[成功] $*"; }
    function log_warning() { echo "[警告] $*"; }
    function log_error() { echo "[错误] $*" >&2; }
    function error_exit() { echo "[错误] $1" >&2; exit "${2:-1}"; }
    function start_script() { echo ""; echo "开始执行: $1"; echo ""; }
    function end_script() { echo ""; echo "脚本执行完成"; echo ""; exit 0; }
fi

# 使用说明
usage() {
    cat << EOF
用法: $(basename "$0") <文件路径> <文本内容>

示例:
    $(basename "$0") ./test.txt "新的一行文本"
EOF
    exit 1
}

# 主函数
main() {
    start_script "追加文本到文件"

    # 检查参数
    if [[ $# -lt 2 ]]; then
        log_error "参数不足"
        usage
    fi

    local file_path="$1"
    local text_content="$2"

    # 检查文件是否存在
    if [[ ! -f "$file_path" ]]; then
        log_warning "文件不存在，将创建新文件: $file_path"
        touch "$file_path"
    fi

    # 追加文本
    echo "$text_content" >> "$file_path"
    
    if [[ $? -eq 0 ]]; then
        log_success "已追加文本到文件: $file_path"
    else
        error_exit "追加文本失败"
    fi

    end_script
}

main "$@"

