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
# 默认使用 host.docker.internal:7890 作为容器内部代理
# 可以通过 --proxy 参数或 PROXY 环境变量覆盖
PROXY="${PROXY:-host.docker.internal:7890}"
IMAGE_NAME="archlinux-dev-env"
IMAGE_TAG="latest"
CONTAINER_NAME="archlinux-dev-env"
COMMAND=""
WORK_DIR="/workspace"
EXEC_ONLY=false  # 是否只进入已运行的容器，不创建新容器

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
        --exec|-e)
            EXEC_ONLY=true
            shift
            ;;
        --attach|-a)
            EXEC_ONLY=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --proxy ADDRESS           设置代理地址（例如: 192.168.1.76:7890）"
            echo "                            默认: host.docker.internal:7890"
            echo "                            使用 --proxy \"\" 禁用代理"
            echo "  --image-name NAME         镜像名称（默认: archlinux-dev-env）"
            echo "  --image-tag TAG           镜像标签（默认: latest）"
            echo "  --container-name NAME     容器名称（默认: archlinux-dev-env）"
            echo "  --command COMMAND         要执行的命令（默认: 交互式 shell）"
            echo "  -c COMMAND                同 --command"
            echo "  --work-dir DIR            工作目录（默认: /workspace）"
            echo "  --exec, -e                直接进入已运行的容器（如果容器未运行则启动）"
            echo "  --attach, -a              同 --exec"
            echo "  -h, --help                显示帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROXY                     代理地址（如果未通过参数指定）"
            echo ""
            echo "SSH 文件备份:"
            echo "  脚本会在配置 SSH Agent Forwarding 之前自动备份以下文件："
            echo "  - id_rsa (私钥)"
            echo "  - id_rsa.pub (公钥)"
            echo "  - known_hosts"
            echo "  - config"
            echo "  备份文件保存在 ~/.ssh/ssh_backup_YYYYMMDD_HHMMSS.tar.gz"
            echo ""
            echo "SSH Agent Forwarding:"
            echo "  脚本会自动检测并配置 SSH Agent Forwarding，使容器能够使用宿主机的 SSH 密钥"
            echo "  通过 SSH Agent 套接字挂载实现，无需在容器中复制密钥文件，更安全。"
            echo "  如果 SSH Agent 未运行，脚本会尝试启动（仅 Linux）。"
            echo "  如果未检测到密钥，可能需要运行: ssh-add ~/.ssh/id_rsa"
            echo ""
            echo "示例:"
            echo "  $0                                    # 使用默认代理: host.docker.internal:7890"
            echo "  $0 --proxy 192.168.1.76:7890         # 使用指定代理"
            echo "  $0 --proxy \"\"                        # 禁用代理"
            echo "  $0 --proxy 192.168.1.76:7890 --command 'nvim'"
            echo "  $0 --exec                              # 直接进入已运行的容器"
            echo "  $0 -e                                  # 同 --exec"
            echo "  PROXY=192.168.1.76:7890 $0           # 通过环境变量设置代理"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            log_info "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 如果通过 --proxy 参数指定了空值（--proxy ""），则禁用代理
# 否则使用默认值或环境变量中的值（已在默认值设置中处理）

# ============================================
# SSH 文件备份函数
# ============================================
backup_ssh_files() {
    local ssh_dir="${HOME}/.ssh"
    local files_to_backup=("id_rsa" "id_rsa.pub" "known_hosts" "config")
    local files_found=()

    # 检查 SSH 目录
    if [[ ! -d "$ssh_dir" ]]; then
        log_warning "SSH 目录不存在: $ssh_dir，跳过备份"
        return 1
    fi

    # 收集存在的文件
    for file in "${files_to_backup[@]}"; do
        local file_path="${ssh_dir}/${file}"
        if [[ -f "$file_path" ]]; then
            files_found+=("$file")
        fi
    done

    # 如果没有文件需要备份，跳过
    if [[ ${#files_found[@]} -eq 0 ]]; then
        log_warning "没有找到需要备份的 SSH 文件"
        return 1
    fi

    # 生成带时间戳的备份文件名
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${ssh_dir}/ssh_backup_${timestamp}.tar.gz"

    # 创建压缩包
    cd "$ssh_dir" || return 1
    tar -czf "$backup_file" "${files_found[@]}" 2>/dev/null || {
        log_warning "创建备份压缩包失败"
        return 1
    }

    # 设置安全权限
    chmod 600 "$backup_file"

    log_success "SSH 文件已备份到: $backup_file"
    log_info "备份的文件: ${files_found[*]}"

    return 0
}

# ============================================
# 私钥加载函数
# ============================================
ensure_ssh_key_loaded() {
    local ssh_dir="${HOME}/.ssh"
    local private_key="${ssh_dir}/id_rsa"

    # 检查私钥文件是否存在
    if [[ ! -f "$private_key" ]]; then
        log_warning "私钥文件不存在: $private_key，跳过加载"
        return 1
    fi

    # 检查 ssh-add 命令是否可用
    if ! command -v ssh-add &> /dev/null; then
        log_warning "ssh-add 命令不可用，跳过密钥加载"
        return 1
    fi

    # 检查 SSH Agent 是否运行（通过检查 SSH_AUTH_SOCK 或尝试列出密钥）
    if ! ssh-add -l &> /dev/null; then
        # SSH Agent 可能未运行，尝试启动（仅 Linux）
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if [[ -z "$SSH_AUTH_SOCK" ]]; then
                log_info "启动 SSH Agent..."
                eval $(ssh-agent) || {
                    log_warning "无法启动 SSH Agent，跳过密钥加载"
                    return 1
                }
            fi
        else
            log_warning "SSH Agent 未运行，请先启动 SSH Agent"
            return 1
        fi
    fi

    # 检查私钥是否已加载
    if ssh-add -l 2>/dev/null | grep -q "id_rsa"; then
        log_info "私钥已加载到 SSH Agent"
        return 0
    fi

    # 尝试加载私钥
    log_info "加载私钥到 SSH Agent: $private_key"
    if ssh-add "$private_key" 2>/dev/null; then
        log_success "私钥已成功加载到 SSH Agent"
        return 0
    else
        log_warning "加载私钥失败，可能需要输入密码或检查文件权限"
        return 1
    fi
}

# ============================================
# SSH Agent Forwarding 配置函数
# ============================================
setup_ssh_agent_forwarding() {
    local ssh_sock_path=""
    local ssh_auth_sock=""

    # 检测操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Docker Desktop 使用固定路径
        ssh_sock_path="/run/host-services/ssh-auth.sock"
        ssh_auth_sock="/run/host-services/ssh-auth.sock"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux: 使用环境变量中的路径
        if [[ -z "$SSH_AUTH_SOCK" ]]; then
            log_warning "SSH_AUTH_SOCK 未设置，尝试启动 ssh-agent"
            eval $(ssh-agent) || {
                log_warning "无法启动 ssh-agent，跳过 SSH Agent Forwarding"
                return 1
            }
        fi
        ssh_sock_path="$SSH_AUTH_SOCK"
        ssh_auth_sock="$SSH_AUTH_SOCK"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "${MSYSTEM:-}" == "MINGW"* ]]; then
        # Windows: Docker Desktop 使用固定路径
        ssh_sock_path="/run/host-services/ssh-auth.sock"
        ssh_auth_sock="/run/host-services/ssh-auth.sock"
    else
        log_warning "不支持的操作系统: $OSTYPE，跳过 SSH Agent Forwarding"
        return 1
    fi

    # 检查套接字文件是否存在（Linux 需要检查，macOS/Windows 由 Docker Desktop 处理）
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ ! -S "$ssh_sock_path" ]]; then
            log_warning "SSH Agent 套接字不存在: $ssh_sock_path，跳过 SSH Agent Forwarding"
            return 1
        fi
    fi

    # 检查是否有密钥已加载（可选，用于提示）
    if command -v ssh-add &> /dev/null; then
        if ssh-add -l &> /dev/null; then
            log_info "检测到已加载的 SSH 密钥"
        else
            log_warning "SSH Agent 中未检测到密钥，可能需要运行: ssh-add ~/.ssh/id_rsa"
        fi
    fi

    # 设置全局变量供后续使用
    SSH_SOCK_PATH="$ssh_sock_path"
    SSH_AUTH_SOCK_ENV="$ssh_auth_sock"

    log_success "SSH Agent Forwarding 已配置: $ssh_sock_path"
    return 0
}

# 完整镜像名称
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# 检查镜像是否存在
if ! docker image inspect "$FULL_IMAGE_NAME" >/dev/null 2>&1; then
    log_error "镜像不存在: $FULL_IMAGE_NAME"
    log_info "请先运行构建脚本: ./build.sh"
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

# 检测 Windows 环境（Git Bash）
IS_WINDOWS=false
if [[ "${MSYSTEM:-}" == "MINGW"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    IS_WINDOWS=true
fi

# Docker exec 辅助函数（处理 Windows 路径转换问题）
# 在 Windows Git Bash 环境下，Docker 会尝试将 Unix 路径转换为 Windows 路径
# 使用 MSYS_NO_PATHCONV=1 和引号包裹路径来防止转换
docker_exec_zsh() {
    local container_name="$1"
    local command="$2"

    if [ "$IS_WINDOWS" = true ]; then
        # Windows 环境：使用 MSYS_NO_PATHCONV=1 和 //bin/zsh（双斜杠）绕过路径转换
        MSYS_NO_PATHCONV=1 docker exec -it "$container_name" //bin/zsh -c "$command"
    else
        # Linux/macOS 环境：直接使用路径
        docker exec -it "$container_name" /bin/zsh -c "$command"
    fi
}

# 处理已存在的容器
if [ "$CONTAINER_EXISTS" = true ]; then
    if [ "$CONTAINER_RUNNING" = true ]; then
        # 容器已运行，直接进入（默认行为）
        log_info "进入已运行的容器: $CONTAINER_NAME"
        if [ -n "$COMMAND" ]; then
            log_info "执行命令: $COMMAND"
            docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && $COMMAND"
        else
            log_info "进入交互式 shell"
            docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && exec /bin/zsh"
        fi
        exit 0
    else
        # 容器存在但未运行
        # 如果指定了 --exec，启动容器并进入
        if [ "$EXEC_ONLY" = true ]; then
            log_info "启动已停止的容器: $CONTAINER_NAME"
            docker start "$CONTAINER_NAME" >/dev/null 2>&1
            sleep 1  # 等待容器完全启动
            if [ -n "$COMMAND" ]; then
                log_info "执行命令: $COMMAND"
                docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && $COMMAND"
            else
                log_info "进入交互式 shell"
                docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && exec /bin/zsh"
            fi
            exit 0
        fi

        log_info "发现已停止的容器: $CONTAINER_NAME"
        log_info "选项："
        echo "  y - 删除现有容器并创建新容器"
        echo "  n - 启动现有容器"
        echo "  q - 退出"
        # 检查是否是交互式终端
        if [ -t 0 ]; then
            read -p "请选择 (y/n/q): " -n 1 -r
            echo
        else
            # 非交互模式，默认启动现有容器
            log_info "非交互模式，自动选择: n (启动现有容器)"
            REPLY="n"
        fi
        case $REPLY in
            [Yy]*)
                log_info "删除现有容器..."
                docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
                log_success "容器已删除"
                ;;
            [Nn]*)
                log_info "启动现有容器..."
                docker start "$CONTAINER_NAME" >/dev/null 2>&1
                sleep 1  # 等待容器完全启动
                if [ -n "$COMMAND" ]; then
                    log_info "执行命令: $COMMAND"
                    docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && $COMMAND"
                else
                    log_info "进入交互式 shell"
                    docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && exec /bin/zsh"
                fi
                exit 0
                ;;
            [Qq]*)
                log_info "已取消"
                exit 0
                ;;
            *)
                log_info "无效选择，已取消"
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

# 备份 SSH 文件
backup_ssh_files || log_warning "SSH 文件备份失败或跳过"

# 确保私钥已加载到 SSH Agent
ensure_ssh_key_loaded || log_warning "私钥加载失败或跳过"

# 配置 SSH Agent Forwarding
if setup_ssh_agent_forwarding; then
    DOCKER_RUN_ARGS+=(
        -v "${SSH_SOCK_PATH}:${SSH_SOCK_PATH}"
        -e "SSH_AUTH_SOCK=${SSH_AUTH_SOCK_ENV}"
    )
    log_info "已启用 SSH Agent Forwarding"
fi

# 如果设置了代理，添加到环境变量
if [ -n "$PROXY" ]; then
    # 如果代理地址不包含协议，添加 http://
    if [[ ! "$PROXY" =~ ^http:// ]] && [[ ! "$PROXY" =~ ^https:// ]]; then
        PROXY_URL="http://$PROXY"
    else
        PROXY_URL="$PROXY"
    fi
    DOCKER_RUN_ARGS+=(
        -e "http_proxy=$PROXY_URL"
        -e "https_proxy=$PROXY_URL"
        -e "HTTP_PROXY=$PROXY_URL"
        -e "HTTPS_PROXY=$PROXY_URL"
    )
    log_info "使用代理: $PROXY_URL"
else
    log_info "未设置代理"
fi

log_info "启动容器: $CONTAINER_NAME"
log_info "镜像: $FULL_IMAGE_NAME"
log_info "项目目录: $PROJECT_ROOT -> $WORK_DIR"

# 容器内 zsh 路径（容器内路径不受宿主机影响，始终使用绝对路径）
ZSH_CMD="/bin/zsh"

# 启动容器
# 注意：不使用 --rm 参数，这样退出容器时不会自动删除容器
if [ -n "$COMMAND" ]; then
    log_info "执行命令: $COMMAND"
    # 在命令前添加 cd 到工作目录
    # 使用 -d 后台运行，然后 exec 执行命令，命令完成后容器继续运行
    # Windows 环境下使用 MSYS_NO_PATHCONV=1 防止路径转换
    if [ "$IS_WINDOWS" = true ]; then
        MSYS_NO_PATHCONV=1 docker run -d "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" sleep infinity >/dev/null 2>&1 || {
            # 如果容器已存在，直接使用
            CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
            if [ -n "$CONTAINER_ID" ]; then
                # 确保容器正在运行
                docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
                docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && $COMMAND"
                exit 0
            fi
        }
    else
        docker run -d "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" sleep infinity >/dev/null 2>&1 || {
            # 如果容器已存在，直接使用
            CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
            if [ -n "$CONTAINER_ID" ]; then
                # 确保容器正在运行
                docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
                docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && $COMMAND"
                exit 0
            fi
        }
    fi
    # 获取新创建的容器 ID
    CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && $COMMAND"
    fi
else
    log_info "启动交互式 shell（退出时容器将继续运行）"
    # 交互式模式：先启动容器（后台运行 sleep infinity），然后使用 exec 进入
    # 这样即使 zsh 退出，容器的 sleep infinity 进程还在运行，容器不会停止
    if [ "$IS_WINDOWS" = true ]; then
        # 先启动容器（后台运行）
        MSYS_NO_PATHCONV=1 docker run -d "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" sleep infinity >/dev/null 2>&1 || {
            # 如果容器已存在，启动它
            docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
        }
        # 等待容器完全启动
        sleep 1
        # 使用 exec 进入容器
        docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && exec //bin/zsh"
    else
        # 先启动容器（后台运行）
        docker run -d "${DOCKER_RUN_ARGS[@]}" "$FULL_IMAGE_NAME" sleep infinity >/dev/null 2>&1 || {
            # 如果容器已存在，启动它
            docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
        }
        # 等待容器完全启动
        sleep 1
        # 使用 exec 进入容器
        docker_exec_zsh "$CONTAINER_NAME" "cd ${WORK_DIR} && exec /bin/zsh"
    fi
    # 容器退出后，显示提示信息
    echo ""
    log_info "已退出容器，容器将继续运行"
    log_info "使用以下命令重新进入容器:"
    echo "  $0 --exec"
    echo "  或"
    echo "  $0"
    echo "  或"
    echo "  docker exec -it $CONTAINER_NAME /bin/zsh"
fi

