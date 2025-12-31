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

# 加载通用函数库
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

# 默认值
# 默认使用宿主机 7890 端口作为代理
PROXY="${PROXY:-127.0.0.1:7890}"
IMAGE_NAME="archlinux-dev-env"
IMAGE_TAG="latest"
NO_CACHE=false

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
            echo "                            默认: 127.0.0.1:7890（macOS/Windows 自动转换为 host.docker.internal:7890）"
            echo "  --no-proxy                不使用代理（使用中国镜像源）"
            echo "  --no-cache                不使用缓存构建（强制重新构建所有层）"
            echo "  --image-name NAME         镜像名称（默认: archlinux-dev-env）"
            echo "  --image-tag TAG           镜像标签（默认: latest）"
            echo "  -h, --help                 显示帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROXY                     代理地址（如果未通过参数指定，默认: 127.0.0.1:7890）"
            echo ""
            echo "示例:"
            echo "  $0                        使用默认代理 127.0.0.1:7890"
            echo "  $0 --proxy 192.168.1.76:7890"
            echo "  $0 --no-proxy             不使用代理"
            echo "  $0 --no-cache             不使用缓存构建"
            echo "  $0 --no-cache --proxy 192.168.1.76:7890  不使用缓存并使用指定代理"
            echo "  PROXY=192.168.1.76:7890 $0"
            exit 0
            ;;
        --no-proxy)
            PROXY=""
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        *)
            log_error "未知参数: $1"
            log_info "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 如果未通过参数指定，使用默认值（已在变量定义中设置）
# 如果用户明确设置了 --no-proxy，PROXY 会被设置为空字符串

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

    # 保存原始代理地址（用于 Docker daemon）
    PROXY_FOR_DAEMON="$PROXY_HOST_PORT"

    # 检测操作系统，如果是 macOS/Windows 且代理地址是 127.0.0.1，转换为 host.docker.internal
    # 这样容器内可以访问宿主机的代理服务
    # 注意：这个转换只用于容器内的代理，Docker daemon 需要使用原始地址
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$MSYSTEM" == "MINGW"* ]]; then
        if [[ "$PROXY_HOST_PORT" =~ ^127\.0\.0\.1: ]]; then
            PROXY_HOST_PORT="${PROXY_HOST_PORT/127.0.0.1:/host.docker.internal:}"
            log_info "检测到 macOS/Windows，容器内代理地址转换为: $PROXY_HOST_PORT"
        fi
    fi

    BUILD_ARGS+=(--build-arg "PROXY=$PROXY_HOST_PORT")
    log_info "容器内使用代理: $PROXY_HOST_PORT"

    # 设置环境变量，让 Docker daemon 也能使用代理（用于拉取基础镜像）
    # Docker daemon 在宿主机上运行，需要使用原始地址（127.0.0.1:7890），而不是 host.docker.internal
    export http_proxy="http://$PROXY_FOR_DAEMON"
    export https_proxy="http://$PROXY_FOR_DAEMON"
    export HTTP_PROXY="http://$PROXY_FOR_DAEMON"
    export HTTPS_PROXY="http://$PROXY_FOR_DAEMON"
    log_info "Docker daemon 使用代理: $PROXY_FOR_DAEMON"
else
    log_info "未设置代理，将使用中国镜像源"
fi

# 完整镜像名称
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

log_info "开始构建 Docker 镜像: $FULL_IMAGE_NAME"
log_info "项目根目录: $PROJECT_ROOT"
log_info "Dockerfile 位置: $SCRIPT_DIR/Dockerfile"

# 构建镜像
# 注意：构建上下文是项目根目录，Dockerfile 在 container_dev_env 目录
cd "$PROJECT_ROOT"

# 如果设置了 --no-cache，添加到构建参数
if [ "$NO_CACHE" = true ]; then
    BUILD_ARGS+=(--no-cache)
    log_info "使用 --no-cache 选项（不使用缓存）"
fi

# 构建镜像
# 优先使用 docker buildx，如果失败则回退到 docker build
BUILD_EXIT_CODE=1
if docker buildx version >/dev/null 2>&1; then
    log_info "使用 docker buildx 构建"
    if [ ${#BUILD_ARGS[@]} -gt 0 ]; then
        docker buildx build \
            "${BUILD_ARGS[@]}" \
            -f "${SCRIPT_DIR}/Dockerfile" \
            -t "$FULL_IMAGE_NAME" \
            .
    else
        docker buildx build \
            -f "${SCRIPT_DIR}/Dockerfile" \
            -t "$FULL_IMAGE_NAME" \
            .
    fi
    BUILD_EXIT_CODE=$?
else
    log_info "使用 docker build 构建（buildx 不可用）"
    if [ ${#BUILD_ARGS[@]} -gt 0 ]; then
        docker build \
            "${BUILD_ARGS[@]}" \
            -f "${SCRIPT_DIR}/Dockerfile" \
            -t "$FULL_IMAGE_NAME" \
            .
    else
        docker build \
            -f "${SCRIPT_DIR}/Dockerfile" \
            -t "$FULL_IMAGE_NAME" \
            .
    fi
    BUILD_EXIT_CODE=$?
fi

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    log_success "镜像构建完成: $FULL_IMAGE_NAME"
    echo ""
    log_info "使用以下命令启动容器:"
    echo "  cd $SCRIPT_DIR"
    if [ -n "${PROXY_HOST_PORT:-}" ]; then
        echo "  ./run.sh --proxy $PROXY_HOST_PORT"
    else
        echo "  ./run.sh"
    fi
else
    log_error "镜像构建失败，退出码: $BUILD_EXIT_CODE"
    exit $BUILD_EXIT_CODE
fi

