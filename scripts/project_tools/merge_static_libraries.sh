#!/bin/bash

# ============================================
# 合并多个静态库为一个
# 功能：将多个静态库文件合并为一个静态库文件
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
用法: $(basename "$0") <工作目录> <AR工具路径> <库文件列表> <目标库名>

参数:
    工作目录      包含静态库文件的目录
    AR工具路径    ar 工具路径（如: arm-hisiv200-linux-ar）
    库文件列表    要合并的库文件列表，用空格分隔
    目标库名      合并后的目标库文件名

示例:
    $(basename "$0") ./libs arm-hisiv200-linux-ar "lib1.a lib2.a" libcombined.a
EOF
    exit 1
}

# 合并静态库
ar_static_libs_to_one() {
    local work_dir="$1"
    local ar_tool="$2"
    local lib_sequence="$3"
    local target_lib="$4"

    cd "$work_dir" || error_exit "无法进入工作目录: $work_dir"

    log_info "工作目录: $work_dir"
    log_info "AR 工具: $ar_tool"
    log_info "目标库: $target_lib"

    # 检查 AR 工具
    if ! command -v "$ar_tool" &> /dev/null; then
        error_exit "AR 工具未找到: $ar_tool"
    fi

    # 清理旧的 .o 文件
    log_info "清理旧的 .o 文件..."
    rm -f ./*.o

    # 删除旧的目标库
    if [[ -f "$target_lib" ]]; then
        log_warning "删除旧的目标库: $target_lib"
        rm -f "$target_lib"
    fi

    local object_file_sq=""

    # 处理每个库文件
    for lib_file in $lib_sequence; do
        if [[ "${lib_file##*.}" == "a" ]]; then
            if [[ ! -f "$lib_file" ]]; then
                log_warning "库文件不存在，跳过: $lib_file"
                continue
            fi

            log_info "处理库文件: $lib_file"

            # 提取 .o 文件
            "$ar_tool" -x "$lib_file" || {
                log_error "提取库文件失败: $lib_file"
                continue
            }

            # 获取库中的所有对象文件
            local lib_objects=$("$ar_tool" -t "$lib_file" 2>/dev/null)
            object_file_sq+="$lib_objects "
        else
            log_warning "跳过非静态库文件: $lib_file"
        fi
    done

    # 合并所有 .o 文件到目标库
    log_info "正在合并对象文件到目标库..."
    if [[ -n "$(ls -A ./*.o 2>/dev/null)" ]]; then
        "$ar_tool" -qcs "$target_lib" ./*.o || error_exit "合并库文件失败"
        log_success "已创建合并库: $target_lib"
    else
        error_exit "没有找到对象文件"
    fi
}

# 主函数
main() {
    start_script "合并多个静态库为一个"

    # 检查参数
    if [[ $# -lt 4 ]]; then
        log_error "参数不足"
        usage
    fi

    local work_dir="$1"
    local ar_tool="$2"
    local lib_sequence="$3"
    local target_lib="$4"

    # 检查工作目录
    check_directory "$work_dir"

    # 执行合并
    ar_static_libs_to_one "$work_dir" "$ar_tool" "$lib_sequence" "$target_lib"

    end_script
}

main "$@"

