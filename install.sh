#!/usr/bin/env bash

# ============================================
# 一键安装脚本
# 自动检测系统、安装 chezmoi、应用所有配置
# 核心功能：智能软件检查、配置差异检测和应用
# ============================================

set -e

# 在 Windows (Git Bash/MSYS2) 下强制 UTF-8，避免 tee 写入的安装日志出现乱码
# 显式导出 USERPROFILE 避免 chezmoi.exe (Go 二进制) 在新 bash 进程中找不到该变量
if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    if [[ -z "${USERPROFILE:-}" ]]; then
        # 尝试从 HOME 推导: /home/Administrator → C:/Users/Administrator
        _up_user="${HOME##*/}"
        if [[ -n "$_up_user" && "$_up_user" != "$HOME" ]]; then
            USERPROFILE="C:/Users/${_up_user}"
        else
            USERPROFILE="C:/Users/${USERNAME:-$USER}"
        fi
        export USERPROFILE
    fi

    # 统一 Windows Git Bash 下的 HOME，避免子 shell 回落到 /home/<user>
    # 目标：优先使用 USERPROFILE 对应的 /c/Users/<user>
    if command -v cygpath &>/dev/null; then
        _normalized_home="$(cygpath -u "${USERPROFILE}")"
    else
        _normalized_home="/c/Users/${USERNAME:-$USER}"
    fi
    if [[ -n "${_normalized_home}" ]]; then
        export HOME="${_normalized_home}"
    fi
    unset _normalized_home

    # chezmoi.exe、MSYS 子进程依赖 USERNAME/USER；从 USERPROFILE 补全避免未定义
    if [[ -z "${USERNAME:-}" ]]; then
        if [[ -n "${USERPROFILE:-}" ]]; then
            USERNAME="${USERPROFILE##*[/\\]}"
        else
            USERNAME="${USER:-$(whoami 2>/dev/null || echo '')}"
        fi
        export USERNAME
    fi
    if [[ -z "${USER:-}" ]]; then
        export USER="${USERNAME:-$(whoami 2>/dev/null || echo Administrator)}"
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR}/scripts/common.sh"
INSTALL_HELPERS_SH="${SCRIPT_DIR}/scripts/chezmoi/install_helpers.sh"
COMMON_INSTALL_SH="${SCRIPT_DIR}/scripts/chezmoi/common_install.sh"

# 加载通用函数库
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

# 加载安装辅助函数库
if [ -f "$INSTALL_HELPERS_SH" ]; then
    source "$INSTALL_HELPERS_SH"
fi

# 加载通用安装函数库（用于检测操作系统和包管理器）
if [ -f "$COMMON_INSTALL_SH" ]; then
    source "$COMMON_INSTALL_SH"
fi

# 加载 chezmoi 核心操作封装
CHEZMOI_CORE_SH="${SCRIPT_DIR}/scripts/chezmoi/chezmoi_core.sh"
if [ -f "$CHEZMOI_CORE_SH" ]; then
    source "$CHEZMOI_CORE_SH"
fi

# ============================================
# 临时文件管理
# ============================================
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT INT TERM

# ============================================
# 日志：统一 logs/install.log，覆盖写入（仅最近一次）
# ============================================
log_setup "install"

start_script "One-click Install"

# ============================================
# 解析命令行参数
# ============================================
TEST_REMOTE=false
AUTO_COMMIT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --proxy|-p)
            PROXY="$2"
            shift 2
            ;;
        --test-remote)
            TEST_REMOTE=true
            shift
            ;;
        --commit)
            AUTO_COMMIT=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --proxy, -p <url>     Proxy URL (e.g. http://192.168.1.76:7890)"
            echo "  --test-remote         Run remote tests (test tmux on remote host)"
            echo "  --commit              Auto-commit and push after successful test"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  PROXY                 Proxy URL (e.g. http://192.168.1.76:7890)"
            echo "  http_proxy            Proxy URL (e.g. http://192.168.1.76:7890)"
            echo ""
            echo "Examples:"
            echo "  $0 --proxy http://192.168.1.76:7890"
            echo "  $0 --test-remote"
            echo "  $0 --test-remote --commit"
            echo "  PROXY=http://192.168.1.76:7890 $0"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            log_info "Use --help to see available options"
            exit 1
            ;;
    esac
done

# ============================================
# 检测操作系统
# ============================================
if [ -f "$COMMON_INSTALL_SH" ] && type detect_platform &> /dev/null; then
    detect_platform || error_exit "Unsupported operating system"
else
    OS="$(uname -s)"
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="darwin"
        PLATFORM_NAME="macOS"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        PLATFORM_NAME="Linux"
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        PLATFORM_NAME="Windows"
    else
        error_exit "Unsupported operating system: $OS"
    fi
fi

log_success "Platform: $PLATFORM_NAME ($PLATFORM)"

# ============================================
# 代理配置（可选）
# ============================================
# Linux 下区分 WSL2 与原生：WSL2 中 127.0.0.1 无法访问宿主机代理，使用 /etc/resolv.conf 的 nameserver 作为宿主机 IP
if [ -z "${PROXY:-}" ] && [ -z "${http_proxy:-}" ] && [ "$PLATFORM" = "linux" ]; then
    if grep -qEi "Microsoft|WSL" /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
        _hostip=$(awk '/^nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null)
        if [ -n "$_hostip" ]; then
            PROXY="http://${_hostip}:7890"
            log_info "WSL detected, using host proxy: $PROXY"
        fi
    fi
fi
# 如果代理地址没有 http:// 或 https:// 前缀，自动添加
if [ -n "${PROXY:-}" ]; then
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
elif [ -n "${http_proxy:-}" ]; then
    PROXY="$http_proxy"
    if [[ ! "$PROXY" =~ ^https?:// ]]; then
        PROXY="http://$PROXY"
    fi
fi

# 设置代理环境变量
if [ -n "${PROXY:-}" ]; then
    export PROXY="$PROXY"
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"
    log_info "Using proxy: $PROXY"
    # 解析 host:port 供 chezmoi 模板使用（如 dot_ssh/config.tmpl 的 PROXY_HOST/PROXY_PORT，WSL 下 SSH 走宿主机代理）
    _proxy_stripped="${PROXY#*://}"
    _proxy_host="${_proxy_stripped%%:*}"
    _proxy_port="${_proxy_stripped#*:}"
    _proxy_port="${_proxy_port%%/*}"
    if [ -z "$_proxy_port" ] || [ "$_proxy_port" = "$_proxy_host" ]; then
        _proxy_port="7890"
    fi
    export PROXY_HOST="$_proxy_host"
    export PROXY_PORT="$_proxy_port"
else
    log_info "未设置代理，使用直连"
fi

# ============================================
# 安装 chezmoi
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[1/5] Check and install chezmoi"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "Checking chezmoi installation status..."
if ! command -v chezmoi &> /dev/null; then
    log_info "chezmoi 未安装，开始安装..."
    bash "${SCRIPT_DIR}/scripts/chezmoi/install_chezmoi.sh"

    # 安装后再次验证
    hash -r 2>/dev/null || true

    # 如果使用官方安装脚本，确保 PATH 已更新
    if [ -f "$HOME/.local/bin/chezmoi" ] && ! command -v chezmoi &> /dev/null; then
        export PATH="$HOME/.local/bin:$PATH"
        log_info "已将 ~/.local/bin 添加到当前会话的 PATH"
    fi

    # 最终验证
    if ! command -v chezmoi &> /dev/null; then
        error_exit "chezmoi still not available after install, please check"
    fi

    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi installed: $CHEZMOI_VERSION"
else
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi already installed: $CHEZMOI_VERSION"
fi

# ============================================
# 初始化 chezmoi 仓库
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[2/5] Initialize chezmoi environment"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 创建必要的目录
# 1. ~/.local/bin 目录（用于官方安装脚本安装的工具）
if [ ! -d "$HOME/.local/bin" ]; then
    log_info "Creating directory: $HOME/.local/bin"
    mkdir -p "$HOME/.local/bin"
else
    log_info "Directory exists: $HOME/.local/bin"
fi

# 2. chezmoi 状态目录（chezmoi 需要此目录存储状态信息）
CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
if [ ! -d "$CHEZMOI_STATE_DIR" ]; then
    log_info "Creating chezmoi state dir: $CHEZMOI_STATE_DIR"
    mkdir -p "$CHEZMOI_STATE_DIR"
else
    log_info "chezmoi state dir exists: $CHEZMOI_STATE_DIR"
fi

# 源状态目录（项目内的 .chezmoi 目录）
CHEZMOI_DIR="${SCRIPT_DIR}/.chezmoi"

if [ ! -d "$CHEZMOI_DIR" ]; then
    log_info "创建 chezmoi 源状态目录..."
    mkdir -p "$CHEZMOI_DIR"

    # 初始化 Git 仓库
    if [ ! -d "${CHEZMOI_DIR}/.git" ]; then
        log_info "初始化 Git 仓库..."
        cd "$CHEZMOI_DIR"
        git init
        cd - > /dev/null
    fi
else
    log_info "chezmoi 源状态目录已存在: $CHEZMOI_DIR"
fi

# 3. 确保 chezmoi 使用项目源：写入 ~/.config/chezmoi/chezmoi.toml 的 sourceDir
#    （chezmoi 不尊重 CHEZMOI_SOURCE_DIR 环境变量，必须通过 config 指定）
#    run_once 脚本内通过 env http_proxy 使用代理，与 install.sh 导出的环境变量一致
#    Windows 下写入 sourceDir（正斜杠路径）与 [interpreters.sh]（bash），以便 apply 时 run_once_*.sh 由 bash 执行
CHEZMOI_CONFIG_DIR="$HOME/.config/chezmoi"
CHEZMOI_CONFIG_FILE="${CHEZMOI_CONFIG_DIR}/chezmoi.toml"
SOURCE_DIR_ABS="$(cd "$SCRIPT_DIR" && pwd)/.chezmoi"
if [ "$PLATFORM" = "windows" ]; then
    # MINGW/MSYS/Git Bash 中 pwd 为 /e/Code/...，写入 config 后 chezmoi.exe 会解析成 E:/e/Code/... 导致路径错误
    # 转为 Windows 风格路径；TOML 中反斜杠为转义符会破坏路径，故统一用正斜杠（Windows API 接受）
    if command -v cygpath &>/dev/null; then
        _win_path="$(cygpath -w "$(cd "$SCRIPT_DIR" && pwd)/.chezmoi")"
        SOURCE_DIR_ABS="${_win_path//\\//}"
    else
        _unix_path="$(cd "$SCRIPT_DIR" && pwd)/.chezmoi"
        if [[ "$_unix_path" =~ ^/([a-zA-Z])/(.*) ]]; then
            SOURCE_DIR_ABS="${BASH_REMATCH[1]^^}:/${BASH_REMATCH[2]}"
        fi
        unset _unix_path
    fi
    unset _win_path 2>/dev/null || true
fi
mkdir -p "$CHEZMOI_CONFIG_DIR"
NEED_WRITE=false
if [ ! -f "$CHEZMOI_CONFIG_FILE" ]; then
    NEED_WRITE=true
elif ! grep -qF "sourceDir = \"${SOURCE_DIR_ABS}\"" "$CHEZMOI_CONFIG_FILE" 2>/dev/null; then
    if grep -q "^sourceDir = " "$CHEZMOI_CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^sourceDir = .*|sourceDir = \"${SOURCE_DIR_ABS}\"|" "$CHEZMOI_CONFIG_FILE"
        log_info "已更新 chezmoi 源目录配置: $SOURCE_DIR_ABS"
    else
        NEED_WRITE=true
    fi
fi
if [ "$NEED_WRITE" = true ]; then
    if [ -f "$CHEZMOI_CONFIG_FILE" ]; then
        printf 'sourceDir = "%s"\n\n' "$SOURCE_DIR_ABS" > "${CHEZMOI_CONFIG_FILE}.new"
        cat "$CHEZMOI_CONFIG_FILE" >> "${CHEZMOI_CONFIG_FILE}.new"
        mv "${CHEZMOI_CONFIG_FILE}.new" "$CHEZMOI_CONFIG_FILE"
        log_info "已添加 chezmoi 源目录配置: $SOURCE_DIR_ABS"
    else
        printf 'sourceDir = "%s"\n\n[git]\n    autoCommit = false\n    autoPush = false\n' "$SOURCE_DIR_ABS" > "$CHEZMOI_CONFIG_FILE"
        log_info "Written chezmoi config: $CHEZMOI_CONFIG_FILE"
    fi
fi
# Windows 下 .sh 需通过 bash 执行，否则会报「不是有效的 Win32 应用程序」
if [ "$PLATFORM" = "windows" ]; then
    BASH_CMD="bash"
    if command -v bash &>/dev/null; then
        if command -v cygpath &>/dev/null; then
            _b="$(cygpath -w "$(command -v bash)" 2>/dev/null)"
            [ -n "$_b" ] && BASH_CMD="${_b//\\//}"  # 正斜杠避免 TOML 转义
            unset _b
        fi
    fi
    if ! grep -q "\[interpreters\.sh\]" "$CHEZMOI_CONFIG_FILE" 2>/dev/null; then
        printf '\n[interpreters.sh]\n    command = "%s"\n' "$BASH_CMD" >> "$CHEZMOI_CONFIG_FILE"
        log_info "Added chezmoi script interpreter: [interpreters.sh] command = $BASH_CMD"
    fi
fi

log_success "chezmoi environment initialized"

# ============================================
# 配置差异检测和应用（chezmoi 核心流程）
# ============================================
chezmoi_ensure_unlocked 30

if ! chezmoi_is_installed; then
    error_exit "chezmoi not available, cannot apply config"
fi

log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[3/5] Check config status and diff"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "$CHEZMOI_DIR" ] || [ -z "$(ls -A "$CHEZMOI_DIR" 2>/dev/null)" ]; then
    log_warning "chezmoi source dir is empty"
    log_info "Add config manually: chezmoi add ~/.zshrc"
    exit 0
fi

# 设置源状态目录和环境变量
export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
export CHEZMOI_PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
chezmoi_export_apply_env

# apply 前确保 SSH ProxyCommand 依赖就绪（connect/connect.exe）
ENSURE_SSH_PREREQS="${SCRIPT_DIR}/scripts/chezmoi/ensure_ssh_prereqs.sh"
if [[ -f "$ENSURE_SSH_PREREQS" ]]; then
    log_info "Ensuring SSH prerequisites..."
    bash "$ENSURE_SSH_PREREQS" || true
fi

# 检查配置状态和差异
STATUS_OUTPUT=$(chezmoi_run_status)
HAS_STATUS_DIFF=false
if [[ -n "$STATUS_OUTPUT" ]] && [[ "$STATUS_OUTPUT" != *"All configs are up-to-date"* ]]; then
    HAS_STATUS_DIFF=true
    modified=$(echo "$STATUS_OUTPUT" | grep -c "^M" || echo "0")
    added=$(echo "$STATUS_OUTPUT" | grep -c "^A" || echo "0")
    deleted=$(echo "$STATUS_OUTPUT" | grep -c "^D" || echo "0")
    run=$(echo "$STATUS_OUTPUT" | grep -c "^R" || echo "0")
    log_info "Config changes: M=$modified, A=$added, D=$deleted, R=$run"
fi

DIFF_OUTPUT=$(chezmoi_run_diff)
HAS_DIFF=false
if [[ -n "$DIFF_OUTPUT" ]] && [[ "$DIFF_OUTPUT" != *"template and local config match"* ]]; then
    HAS_DIFF=true
    file_count=$(echo "$DIFF_OUTPUT" | grep -c "^diff --git" || echo "0")
    log_info "$file_count file(s) have differences"
fi

# 应用配置
if [ "$HAS_STATUS_DIFF" = false ] && [ "$HAS_DIFF" = false ]; then
    log_success "All configs are up-to-date, no apply needed"
else
    log_info "Config differences found, applying..."
    if chezmoi_run_apply "-v --force"; then
        log_success "Config applied successfully!"
        # 验证
        chezmoi_verify_sync "$(uname -s)" && log_success "Config fully synced" || log_warning "Config still has differences after apply"
    else
        error_exit "Config apply failed, check error messages"
    fi
fi

# ============================================
# 软件安装检查（通过 chezmoi run_once 脚本）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[4/5] Check software installation status"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检测操作系统和包管理器（用于软件检查）
if [ -f "$COMMON_INSTALL_SH" ]; then
    detect_os_and_package_manager || {
        log_warning "Cannot detect OS/package manager, skipping software check"
        PLATFORM=""
        PACKAGE_MANAGER=""
    }
else
    log_warning "common_install.sh not found, skipping software check"
    PLATFORM=""
    PACKAGE_MANAGER=""
fi

# 按 docs/SOFTWARE_LIST.md 的 OS/WSL 分类打印安装状态（仅显示当前平台适用项）
if [ -d "$CHEZMOI_DIR" ]; then
    if [ -n "$PLATFORM" ]; then
        report_install_status_by_platform "$CHEZMOI_DIR" "$PLATFORM" "$PACKAGE_MANAGER"
    else
        log_info "Platform not detected, skipping software status check"
        log_info "Software will be installed via chezmoi apply (run_once_ scripts)"
    fi
else
    log_warning "chezmoi source dir not found, skipping software check"
fi

log_success "Software check completed"

# ============================================
# [5/5] 验证与确认（字体、默认 Shell、环境变量、开机启动声明）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[5/5] Verification and confirmation"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VERIFY_SCRIPT="${SCRIPT_DIR}/scripts/chezmoi/verify_installation.sh"
if [ -f "$VERIFY_SCRIPT" ] && [ -x "$VERIFY_SCRIPT" ]; then
    if bash "$VERIFY_SCRIPT"; then
        log_success "Verification completed, report written"
    else
        log_warning "Verification script finished, check report above"
    fi
else
    if [ -f "$VERIFY_SCRIPT" ]; then
        chmod +x "$VERIFY_SCRIPT" 2>/dev/null || true
        bash "$VERIFY_SCRIPT" || true
    else
        log_warning "Verify script not found: $VERIFY_SCRIPT, skipping"
    fi
fi

# ============================================
# 远程测试（如果指定）
# ============================================
REMOTE_TEST_PASSED=true

if [ "$TEST_REMOTE" = true ]; then
    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Running remote tests"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    TEST_SCRIPT="${SCRIPT_DIR}/scripts/common/deploy_utils/test_tmux_remote.sh"

    if [ ! -f "$TEST_SCRIPT" ]; then
        log_error "Remote test script not found: $TEST_SCRIPT"
        REMOTE_TEST_PASSED=false
    elif [ ! -x "$TEST_SCRIPT" ]; then
        log_warning "Remote test script not executable, setting permissions..."
        chmod +x "$TEST_SCRIPT"
    fi

    if [ -f "$TEST_SCRIPT" ] && [ -x "$TEST_SCRIPT" ]; then
        log_info "Running remote test script..."
        if bash "$TEST_SCRIPT"; then
            log_success "Remote test passed"
            REMOTE_TEST_PASSED=true
        else
            log_error "Remote test failed"
            REMOTE_TEST_PASSED=false
        fi
    fi
fi

# ============================================
# 自动提交和推送（如果指定且测试通过）
# ============================================
if [ "$AUTO_COMMIT" = true ]; then
    if [ "$REMOTE_TEST_PASSED" != true ]; then
        log_warning "Remote test did not pass, skipping auto-commit"
    else
        log_info ""
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "Auto-commit and push"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # 检查是否在 Git 仓库中
        if [ ! -d "${SCRIPT_DIR}/.git" ]; then
            log_warning "Not a git repository, skipping commit"
        else
            cd "$SCRIPT_DIR"

            # 检查是否有更改
            if [ -z "$(git status --porcelain)" ]; then
                log_info "No changes to commit"
            else
                # 添加所有更改
                log_info "Adding changes to git..."
                git add -A

                # 生成提交信息
                COMMIT_MSG="chore: auto-apply configuration changes"
                if [ "$TEST_REMOTE" = true ]; then
                    COMMIT_MSG="${COMMIT_MSG} - remote test passed"
                fi

                # 提交
                log_info "Committing: $COMMIT_MSG"
                if git commit -m "$COMMIT_MSG"; then
                    log_success "Commit succeeded"

                    # 推送到远程
                    log_info "Pushing to remote..."
                    if git push; then
                        log_success "Push succeeded"
                    else
                        log_warning "Push failed, please push manually"
                    fi
                else
                    log_warning "Commit failed, possibly nothing to commit"
                fi
            fi

            cd - > /dev/null
        fi
    fi
fi

# ============================================
# 完成
# ============================================
end_script

log_success "Installation complete!"
log_info ""
log_info "Next steps:"
log_info "  Quick deploy:         ./deploy.sh"
log_info "  Check status:         ./scripts/manage_dotfiles.sh status"
log_info "  View diff:            ./scripts/manage_dotfiles.sh diff"
log_info "  Edit config:          ./scripts/manage_dotfiles.sh edit ~/.zshrc"
log_info ""
log_info "  Help:                 ./scripts/manage_dotfiles.sh help"
log_info "  Deployment guide:     scripts/common/deploy_utils/DEPLOYMENT_GUIDE.md"