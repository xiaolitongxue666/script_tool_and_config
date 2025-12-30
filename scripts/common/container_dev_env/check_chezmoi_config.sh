#!/bin/bash

# ============================================
# 检查容器中 chezmoi 配置是否生效
# ============================================

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认值
CONTAINER_NAME="archlinux-dev-env"
IMAGE_NAME="archlinux-dev-env"
IMAGE_TAG="latest"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --container-name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --container-name=*)
            CONTAINER_NAME="${1#*=}"
            shift
            ;;
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --image-name=*)
            IMAGE_NAME="${1#*=}"
            shift
            ;;
        --image-tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --image-tag=*)
            IMAGE_TAG="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --container-name NAME     容器名称（默认: archlinux-dev-env）"
            echo "  --image-name NAME         镜像名称（默认: archlinux-dev-env）"
            echo "  --image-tag TAG           镜像标签（默认: latest）"
            echo "  -h, --help                显示帮助信息"
            exit 0
            ;;
        *)
            echo "错误: 未知参数 $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# 日志函数
log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[✓] $*"
}

log_warning() {
    echo "[⚠] $*"
}

log_error() {
    echo "[✗] $*" >&2
}

# 检查容器或镜像是否存在
check_container_or_image() {
    if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
        if [ "$CONTAINER_STATUS" = "running" ]; then
            log_info "使用运行中的容器: $CONTAINER_NAME"
            USE_CONTAINER=true
            return 0
        else
            log_info "发现已停止的容器: $CONTAINER_NAME，启动它..."
            docker start "$CONTAINER_NAME" >/dev/null 2>&1
            sleep 2
            USE_CONTAINER=true
            return 0
        fi
    elif docker image inspect "$FULL_IMAGE_NAME" >/dev/null 2>&1; then
        log_info "使用镜像创建临时容器: $FULL_IMAGE_NAME"
        USE_CONTAINER=false
        return 0
    else
        log_error "容器 $CONTAINER_NAME 和镜像 $FULL_IMAGE_NAME 都不存在"
        return 1
    fi
}

# 在容器中执行命令
exec_in_container() {
    local cmd="$1"
    if [ "$USE_CONTAINER" = true ]; then
        docker exec "$CONTAINER_NAME" /bin/bash -c "$cmd"
    else
        docker run --rm "$FULL_IMAGE_NAME" /bin/bash -c "$cmd"
    fi
}

# 检查配置文件
check_config_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    local min_size="${2:-1000}"

    log_info "检查配置文件: $file_path"

    # 检查文件是否存在
    if exec_in_container "test -f $file_path" >/dev/null 2>&1; then
        log_success "  文件存在: $file_path"

        # 检查文件大小
        local file_size=$(exec_in_container "stat -c%s $file_path 2>/dev/null || stat -f%z $file_path 2>/dev/null || echo 0")
        if [ "$file_size" -ge "$min_size" ]; then
            log_success "  文件大小正常: $file_size 字节"

            # 显示文件前几行（关键配置）
            log_info "  文件内容预览:"
            exec_in_container "head -20 $file_path" | sed 's/^/    /' || true

            return 0
        else
            log_warning "  文件太小: $file_size 字节（期望至少 $min_size 字节）"
            log_info "  文件内容:"
            exec_in_container "cat $file_path" | sed 's/^/    /' || true
            return 1
        fi
    else
        log_error "  文件不存在: $file_path"
        return 1
    fi
}

# 检查 chezmoi 状态
check_chezmoi_status() {
    log_info "检查 chezmoi 安装和配置..."

    # 检查 chezmoi 是否安装
    if exec_in_container "command -v chezmoi" >/dev/null 2>&1; then
        local version=$(exec_in_container "chezmoi --version 2>&1 | head -1")
        log_success "chezmoi 已安装: $version"
    else
        log_error "chezmoi 未安装"
        return 1
    fi

    # 检查 chezmoi 源目录
    log_info "检查 chezmoi 源目录配置..."
    local source_dir=$(exec_in_container "echo \${CHEZMOI_SOURCE_DIR:-未设置}")
    if [ "$source_dir" != "未设置" ] && [ -n "$source_dir" ]; then
        log_success "CHEZMOI_SOURCE_DIR: $source_dir"
        if exec_in_container "test -d $source_dir" >/dev/null 2>&1; then
            log_success "  源目录存在"
            local file_count=$(exec_in_container "find $source_dir -type f | wc -l")
            log_info "  源目录文件数: $file_count"
        else
            log_warning "  源目录不存在: $source_dir"
        fi
    else
        log_warning "CHEZMOI_SOURCE_DIR 未设置"
    fi

    # 检查 chezmoi 状态目录
    local state_dir="/root/.local/share/chezmoi"
    if exec_in_container "test -d $state_dir" >/dev/null 2>&1; then
        log_success "chezmoi 状态目录存在: $state_dir"
    else
        log_warning "chezmoi 状态目录不存在: $state_dir"
    fi
}

# 检查 Oh My Zsh 配置
check_oh_my_zsh() {
    log_info "检查 Oh My Zsh 配置..."

    local omz_dir="/root/.oh-my-zsh"
    if exec_in_container "test -d $omz_dir" >/dev/null 2>&1; then
        log_success "Oh My Zsh 已安装: $omz_dir"

        # 检查插件
        local plugins_dir="$omz_dir/custom/plugins"
        log_info "检查自定义插件..."
        local plugins=(
            "zsh-autosuggestions"
            "zsh-syntax-highlighting"
            "zsh-history-substring-search"
        )
        for plugin in "${plugins[@]}"; do
            if exec_in_container "test -d $plugins_dir/$plugin" >/dev/null 2>&1; then
                log_success "  插件已安装: $plugin"
            else
                log_warning "  插件未安装: $plugin"
            fi
        done
    else
        log_warning "Oh My Zsh 未安装: $omz_dir"
    fi
}

# 主检查函数
main() {
    echo "============================================"
    echo "检查容器中 chezmoi 配置"
    echo "============================================"
    echo ""

    # 检查容器或镜像
    if ! check_container_or_image; then
        exit 1
    fi

    echo ""

    # 检查 chezmoi 状态
    check_chezmoi_status
    echo ""

    # 检查关键配置文件
    log_info "检查关键配置文件..."
    echo ""

    local config_files=(
        "/root/.zshrc:2000"
        "/root/.bashrc:500"
        "/root/.tmux.conf:500"
    )

    local success_count=0
    local total_count=${#config_files[@]}

    for config_spec in "${config_files[@]}"; do
        IFS=':' read -r file_path min_size <<< "$config_spec"
        if check_config_file "$file_path" "$min_size"; then
            success_count=$((success_count + 1))
        fi
        echo ""
    done

    # 检查 Oh My Zsh
    check_oh_my_zsh
    echo ""

    # 总结
    echo "============================================"
    echo "检查结果总结"
    echo "============================================"
    echo "配置文件检查: $success_count/$total_count 通过"
    echo ""

    if [ $success_count -eq $total_count ]; then
        log_success "所有配置文件检查通过！chezmoi 配置已正确应用。"
        return 0
    else
        log_warning "部分配置文件检查未通过，chezmoi 配置可能未完全生效。"
        return 1
    fi
}

# 执行主函数
main "$@"

