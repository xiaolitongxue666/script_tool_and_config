#!/bin/bash
set -e

# 脚本所在目录（Dockerfile 所在目录）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 项目根目录
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "=========================================="
echo "开始构建 Docker 镜像"
echo "=========================================="

PROXY="${1:-192.168.1.76:7890}"

echo "使用代理: $PROXY"
echo "项目根目录: $PROJECT_ROOT"
echo "Dockerfile 目录: $SCRIPT_DIR"
echo ""

# 构建镜像
cd "$PROJECT_ROOT"

# 强制使用 docker build（不使用 buildx）
docker build \
    --build-arg PROXY="$PROXY" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    -t archlinux-dev-env:latest \
    .

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "构建成功！"
    echo "=========================================="
    docker images | grep archlinux-dev-env
    exit 0
else
    echo ""
    echo "=========================================="
    echo "构建失败，退出码: $BUILD_EXIT_CODE"
    echo "=========================================="
    exit $BUILD_EXIT_CODE
fi

