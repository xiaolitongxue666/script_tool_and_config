#!/bin/bash

# ============================================
# 生成 log4c 配置文件
# 功能：生成 log4c 日志配置文件，包含多个日志目录和滚动策略
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
用法: $(basename "$0") [日志数量]

参数:
    日志数量     要创建的日志目录数量（默认: 112）

功能:
    生成 log4c 配置文件，创建指定数量的日志目录和滚动策略

示例:
    $(basename "$0")
    $(basename "$0") 50
EOF
    exit 1
}

# 主函数
main() {
    start_script "生成 log4c 配置文件"

    # 默认日志数量
    local sub_log_number="${1:-112}"

    # 验证参数
    if ! [[ "$sub_log_number" =~ ^[0-9]+$ ]] || [[ "$sub_log_number" -le 0 ]]; then
        error_exit "日志数量必须是正整数"
    fi

    log_info "日志数量: $sub_log_number"

    # 删除旧的日志目录
    if [[ -d "./logs" ]]; then
        log_warning "删除旧的日志目录"
        rm -rf ./logs/
    fi

    # 创建日志目录
    ensure_directory "./logs"
    cd ./logs/ || error_exit "无法进入 logs 目录"

    # 创建子日志目录
    log_info "正在创建 $sub_log_number 个子日志目录..."
    for ((i = 0; i < sub_log_number; i++)); do
        index=$(printf "%03d" $i)
        sub_log_dir_name="log_$index"
        ensure_directory "$sub_log_dir_name"
    done

    cd .. || error_exit "无法返回上级目录"

    # 删除旧的配置文件
    if [[ -f "./log4crc" ]]; then
        log_warning "删除旧的配置文件"
        rm -f ./log4crc
    fi

    # 创建配置文件
    touch ./log4crc
    chmod 644 ./log4crc

    # 写入配置文件头部
    cat << EOF > ./log4crc
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE log4c SYSTEM "">

<log4c version="1.2.4">

	<config>
		<bufsize>0</bufsize>
		<debug level="2"/>
		<nocleanup>0</nocleanup>
		<reread>1</reread>
	</config>

EOF

    # 添加日志配置
    log_info "正在生成日志配置..."
    for ((i = 0; i < sub_log_number; i++)); do
        index=$(printf "%03d" $i)
        cat << EOF >> ./log4crc
    <category name="netint_$index" priority="trace" appender="rolling_file_appender_$index"/>
    <appender name="rolling_file_appender_$index" type="rollingfile" logdir="./logs/log_$index" prefix="netint_$index" layout="dated" rollingpolicy="rolling_policy_$index"/>
    <rollingpolicy name="rolling_policy_$index" type="sizewin" maxsize="102400" maxnum="1"/>

EOF
    done

    # 写入配置文件尾部
    cat << EOF >> ./log4crc
</log4c>
EOF

    log_success "已生成 log4c 配置文件: ./log4crc"
    log_info "配置文件信息:"
    ls -lh ./log4crc

    end_script
}

main "$@"

