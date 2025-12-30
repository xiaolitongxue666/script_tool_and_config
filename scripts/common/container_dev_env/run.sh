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

# Windows 环境下，将 Git Bash 路径转换为 Windows 路径（如果需要）
# Docker Desktop for Windows 可以直接使用 Git Bash 路径格式
# 但如果遇到路径问题，可以尝试转换
if [[ "$OSTYPE" == "msys" ]] || [[ "${MSYSTEM:-}" == "MINGW"* ]]; then
    # Git Bash 路径格式（如 /e/Code/...）在 Docker Desktop 中通常可以直接使用
    # 但如果 Docker 报错，可能需要转换为 Windows 路径
    # 这里先保持原样，如果遇到问题再转换
    :
fi

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
CONTAINER_EXISTS=false
CONTAINER_RUNNING=false

# 检查容器是否存在（包括已停止的）
# 使用 docker inspect 更可靠
if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    CONTAINER_EXISTS=true
    # 检查容器是否正在运行
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
    if [ "$CONTAINER_STATUS" = "running" ]; then
        CONTAINER_RUNNING=true
    fi
fi

# 处理已存在的容器
if [ "$CONTAINER_EXISTS" = true ]; then
    if [ "$CONTAINER_RUNNING" = true ]; then
        echo "[WARNING] 容器正在运行: $CONTAINER_NAME"
        echo "[INFO] 选项："
        echo "  y - 停止并删除现有容器，然后启动新容器"
        echo "  n - 使用现有运行中的容器（执行命令或进入 shell）"
        echo "  q - 退出"
        # 检查是否是交互式终端
        if [ -t 0 ]; then
            read -p "请选择 (y/n/q): " -n 1 -r
            echo
        else
            # 非交互模式，默认删除并重新创建
            echo "[INFO] 非交互模式，自动选择: y (停止并删除现有容器)"
            REPLY="y"
        fi
        case $REPLY in
            [Yy]*)
                echo "[INFO] 停止并删除现有容器..."
                docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
                docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
                echo "[SUCCESS] 容器已删除"
                ;;
            [Nn]*)
                echo "[INFO] 使用现有运行中的容器..."
                if [ -n "$COMMAND" ]; then
                    echo "[INFO] 执行命令: $COMMAND"
                    docker exec -it "$CONTAINER_NAME" /bin/zsh -c "cd ${WORK_DIR} && $COMMAND"
                else
                    echo "[INFO] 进入交互式 shell"
                    docker exec -it "$CONTAINER_NAME" /bin/zsh -c "cd ${WORK_DIR} && exec /bin/zsh"
                fi
                exit 0
                ;;
            [Qq]*)
                echo "[INFO] 已取消"
                exit 0
                ;;
            *)
                echo "[INFO] 无效选择，已取消"
                exit 0
                ;;
        esac
    else
        # 容器存在但未运行
        echo "[INFO] 发现已停止的容器: $CONTAINER_NAME"
        echo "[INFO] 选项："
        echo "  y - 删除现有容器并创建新容器"
        echo "  n - 启动现有容器"
        echo "  q - 退出"
        # 检查是否是交互式终端
        if [ -t 0 ]; then
            read -p "请选择 (y/n/q): " -n 1 -r
            echo
        else
            # 非交互模式，默认删除并重新创建
            echo "[INFO] 非交互模式，自动选择: y (删除现有容器)"
            REPLY="y"
        fi
        case $REPLY in
            [Yy]*)
                echo "[INFO] 删除现有容器..."
                docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
                echo "[SUCCESS] 容器已删除"
                ;;
            [Nn]*)
                echo "[INFO] 启动现有容器..."
                docker start "$CONTAINER_NAME" >/dev/null 2>&1
                if [ -n "$COMMAND" ]; then
                    echo "[INFO] 执行命令: $COMMAND"
                    docker exec -it "$CONTAINER_NAME" /bin/zsh -c "cd ${WORK_DIR} && $COMMAND"
                else
                    echo "[INFO] 进入交互式 shell"
                    docker exec -it "$CONTAINER_NAME" /bin/zsh -c "cd ${WORK_DIR} && exec /bin/zsh"
                fi
                exit 0
                ;;
            [Qq]*)
                echo "[INFO] 已取消"
                exit 0
                ;;
            *)
                echo "[INFO] 无效选择，已取消"
                exit 0
                ;;
        esac
    fi
fi

# 检测是否支持 TTY（Windows Git Bash 需要特殊处理）
USE_TTY=""
if [ -t 0 ] && [ -t 1 ]; then
    # 检查是否是 Windows Git Bash (mintty)
    if [[ "${MSYSTEM:-}" == "MINGW"* ]] || [[ "$OSTYPE" == "msys" ]] || command -v winpty >/dev/null 2>&1; then
        # Windows 环境下，如果 winpty 可用，使用它；否则不使用 -it
        if command -v winpty >/dev/null 2>&1; then
            USE_TTY="-it"
        else
            USE_TTY=""
        fi
    else
        USE_TTY="-it"
    fi
else
    USE_TTY=""
fi

# 准备 Docker 运行参数
# 注意：Windows 环境下，-w 参数可能导致路径问题，我们在容器内切换目录
DOCKER_RUN_ARGS=(
    $USE_TTY
    --name "$CONTAINER_NAME"
    --hostname archlinux-dev
    -v "${PROJECT_ROOT}:${WORK_DIR}"
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

# 确定 zsh 路径（避免 Windows Git Bash 路径转换问题）
ZSH_CMD="/bin/zsh"
# 在 Windows Git Bash 中，直接使用命令名而不是路径
if [[ "${MSYSTEM:-}" == "MINGW"* ]] || [[ "$OSTYPE" == "msys" ]]; then
    ZSH_CMD="zsh"
fi

# 启动容器
if [ -n "$COMMAND" ]; then
    echo "[INFO] 执行命令: $COMMAND"
    # 在命令前添加 cd 到工作目录
    docker run "${DOCKER_RUN_ARGS[@]}" --rm "$FULL_IMAGE_NAME" $ZSH_CMD -c "cd ${WORK_DIR} && $COMMAND"
else
    echo "[INFO] 启动交互式 shell"
    # 交互式模式：覆盖默认的 sleep infinity，启动 zsh
    # Windows Git Bash 环境下，如果 winpty 可用，使用它包装命令
    if [[ "${MSYSTEM:-}" == "MINGW"* ]] || [[ "$OSTYPE" == "msys" ]]; then
        if command -v winpty >/dev/null 2>&1; then
            winpty docker run "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" $ZSH_CMD -c "cd ${WORK_DIR} && exec $ZSH_CMD"
        else
            # 不使用 -it，直接运行
            docker run "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" $ZSH_CMD -c "cd ${WORK_DIR} && exec $ZSH_CMD"
        fi
    else
        docker run "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" $ZSH_CMD -c "cd ${WORK_DIR} && exec $ZSH_CMD"
    fi
fi

