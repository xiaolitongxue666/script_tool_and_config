#!/bin/bash

# ============================================
# 获取目录名称
# 功能：获取当前脚本所在目录的名称
# ============================================

# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 主函数
main() {
    # 获取项目路径和名称
    project_path=$(cd "$(dirname "$0")" && pwd)
    project_name="${project_path##*/}"
    
    echo "项目路径: $project_path"
    echo "项目名称: $project_name"
    
    # 输出项目名称（用于脚本调用）
    echo "$project_name"
}

main "$@"

