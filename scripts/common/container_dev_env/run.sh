#!/bin/bash

# ============================================
# Docker 容器启动脚本
# 支持代理配置和项目目录挂载
# ============================================

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# 默认值
PROXY=""
IMAGE_NAME="archlinux-dev-env"
IMAGE_TAG="latest"
CONTAINER_NAME="archlinux-dev-env"
COMMAND=""
WORK_DIR="/workspace"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy)
            PROXY="$2"
            shift 2
            ;;
        --proxy=*)
            PROXY="${1#*=}"
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
        --container-name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --container-name=*)
            CONTAINER_NAME="${1#*=}"
            shift
            ;;
        --command|-c)
            COMMAND="$2"
            shift 2
            ;;
        --command=*|-c=*)
            COMMAND="${1#*=}"
            shift
            ;;
        --work-dir)
            WORK_DIR="$2"
            shift 2
            ;;
        --work-dir=*)
            WORK_DIR="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --proxy ADDRESS           设置代理地址（例如: 192.168.1.76:7890）"
            echo "  --image-name NAME         镜像名称（默认: archlinux-dev-env）"
            echo "  --image-tag TAG           镜像标签（默认: latest）"
            echo "  --container-name NAME     容器名称（默认: archlinux-dev-env）"
            echo "  --command COMMAND         要执行的命令（默认: 交互式 shell）"
            echo "  -c COMMAND                同 --command"
            echo "  --work-dir DIR            工作目录（默认: /workspace）"
            echo "  -h, --help                显示帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROXY                     代理地址（如果未通过参数指定）"
            echo ""
            echo "示例:"
            echo "  $0 --proxy 192.168.1.76:7890"
            echo "  $0 --proxy 192.168.1.76:7890 --command 'nvim'"
            echo "  PROXY=192.168.1.76:7890 $0"
            exit 0
            ;;
        *)
            echo "错误: 未知参数 $1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 如果未通过参数指定，尝试从环境变量获取
if [ -z "$PROXY" ]; then
    PROXY="${PROXY:-}"
fi

# 完整镜像名称
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# 检查镜像是否存在
if ! docker image inspect "$FULL_IMAGE_NAME" >/dev/null 2>&1; then
    echo "[ERROR] 镜像不存在: $FULL_IMAGE_NAME"
    echo "[INFO] 请先运行构建脚本: ./build.sh"
    exit 1
fi

# 检查容器是否已存在
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[INFO] 容器已存在: $CONTAINER_NAME"
    read -p "是否删除现有容器并创建新容器? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[INFO] 删除现有容器..."
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    else
        echo "[INFO] 启动现有容器..."
        docker start "$CONTAINER_NAME" >/dev/null 2>&1
        if [ -n "$COMMAND" ]; then
            docker exec -it "$CONTAINER_NAME" /bin/zsh -c "$COMMAND"
        else
            docker exec -it "$CONTAINER_NAME" /bin/zsh
        fi
        exit 0
    fi
fi

# 准备 Docker 运行参数
DOCKER_RUN_ARGS=(
    -it
    --name "$CONTAINER_NAME"
    --hostname archlinux-dev
    -v "${PROJECT_ROOT}:${WORK_DIR}"
    -w "$WORK_DIR"
)

# 如果设置了代理，添加到环境变量
if [ -n "$PROXY" ]; then
    # 如果代理地址不包含协议，添加 http://
    if [[ ! "$PROXY" =~ ^http:// ]] && [[ ! "$PROXY" =~ ^https:// ]]; then
        PROXY="http://$PROXY"
    fi
    DOCKER_RUN_ARGS+=(
        -e "http_proxy=$PROXY"
        -e "https_proxy=$PROXY"
        -e "HTTP_PROXY=$PROXY"
        -e "HTTPS_PROXY=$PROXY"
    )
    echo "[INFO] 使用代理: $PROXY"
fi

echo "[INFO] 启动容器: $CONTAINER_NAME"
echo "[INFO] 镜像: $FULL_IMAGE_NAME"
echo "[INFO] 项目目录: $PROJECT_ROOT -> $WORK_DIR"

# 启动容器
if [ -n "$COMMAND" ]; then
    echo "[INFO] 执行命令: $COMMAND"
    docker run "${DOCKER_RUN_ARGS[@]}" --rm "$FULL_IMAGE_NAME" /bin/zsh -c "$COMMAND"
else
    echo "[INFO] 启动交互式 shell"
    docker run "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME"
fi

