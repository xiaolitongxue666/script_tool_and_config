#!/bin/bash

# ============================================
# Docker 镜像构建脚本
# 支持代理配置
# ============================================

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录（向上三级：container_dev_env -> common -> scripts -> root）
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# 默认值
PROXY=""
IMAGE_NAME="archlinux-dev-env"
IMAGE_TAG="latest"

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
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --proxy ADDRESS           设置代理地址（例如: 192.168.1.76:7890）"
            echo "  --image-name NAME         镜像名称（默认: archlinux-dev-env）"
            echo "  --image-tag TAG           镜像标签（默认: latest）"
            echo "  -h, --help                 显示帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROXY                     代理地址（如果未通过参数指定）"
            echo ""
            echo "示例:"
            echo "  $0 --proxy 192.168.1.76:7890"
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

# 构建参数
BUILD_ARGS=()

# 如果设置了代理，添加到构建参数
if [ -n "$PROXY" ]; then
    # 如果代理地址不包含协议，添加 http://
    if [[ ! "$PROXY" =~ ^http:// ]] && [[ ! "$PROXY" =~ ^https:// ]]; then
        PROXY="http://$PROXY"
    fi
    # 提取主机和端口（移除 http:// 或 https://）
    PROXY_HOST_PORT="${PROXY#http://}"
    PROXY_HOST_PORT="${PROXY_HOST_PORT#https://}"
    BUILD_ARGS+=(--build-arg "PROXY=$PROXY_HOST_PORT")
    echo "[INFO] 使用代理: $PROXY_HOST_PORT"
else
    echo "[INFO] 未设置代理，将使用中国镜像源"
fi

# 完整镜像名称
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "[INFO] 开始构建 Docker 镜像: $FULL_IMAGE_NAME"
echo "[INFO] 项目根目录: $PROJECT_ROOT"
echo "[INFO] Dockerfile 位置: $SCRIPT_DIR/Dockerfile"

# 构建镜像
# 注意：构建上下文是项目根目录，Dockerfile 在 container_dev_env 目录
cd "$PROJECT_ROOT"

# 构建镜像（移除 --progress=plain，兼容旧版本 docker）
docker buildx build \
    "${BUILD_ARGS[@]}" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    -t "$FULL_IMAGE_NAME" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "[SUCCESS] 镜像构建完成: $FULL_IMAGE_NAME"
    echo ""
    echo "使用以下命令启动容器:"
    echo "  cd $SCRIPT_DIR"
    if [ -n "$PROXY_HOST_PORT" ]; then
        echo "  ./run.sh --proxy $PROXY_HOST_PORT"
    else
        echo "  ./run.sh"
    fi
else
    echo "[ERROR] 镜像构建失败"
    exit 1
fi

