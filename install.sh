#!/bin/bash

# ============================================
# 一键安装脚本
# 自动检测系统、安装 chezmoi、应用所有配置
# 核心功能：智能软件检查、配置差异检测和应用
# ============================================

set -e

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

# ============================================
# 临时文件管理
# ============================================
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT INT TERM

start_script "一键安装脚本"

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
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --proxy, -p <地址>    指定代理地址（例如: http://192.168.1.76:7890）"
            echo "  --test-remote         执行远程测试（测试远端 tmux 配置）"
            echo "  --commit              测试成功后自动提交并推送到 Git"
            echo "  --help, -h            显示此帮助信息"
            echo ""
            echo "环境变量:"
            echo "  PROXY                 代理地址（例如: http://192.168.1.76:7890）"
            echo "  http_proxy            代理地址（例如: http://192.168.1.76:7890）"
            echo ""
            echo "示例:"
            echo "  $0 --proxy http://192.168.1.76:7890"
            echo "  $0 --test-remote"
            echo "  $0 --test-remote --commit"
            echo "  PROXY=http://192.168.1.76:7890 $0"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            log_info "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# ============================================
# 检测操作系统
# ============================================
OS="$(uname -s)"
log_info "检测到操作系统: $OS"

if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    PLATFORM="windows"
else
    error_exit "不支持的操作系统: $OS"
fi

log_success "平台: $PLATFORM"

# ============================================
# 代理配置（可选）
# ============================================
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
    log_info "使用代理: $PROXY"
else
    log_info "未设置代理，使用直连"
fi

# ============================================
# 安装 chezmoi
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[1/4] 检查并安装 chezmoi"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "检查 chezmoi 安装状态..."
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
        error_exit "chezmoi 安装后仍不可用，请检查安装过程或手动安装"
    fi

    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 安装成功: $CHEZMOI_VERSION"
else
    CHEZMOI_VERSION=$(chezmoi --version | head -n 1)
    log_success "chezmoi 已安装: $CHEZMOI_VERSION"
fi

# ============================================
# 初始化 chezmoi 仓库
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[2/4] 初始化 chezmoi 环境"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 创建必要的目录
# 1. ~/.local/bin 目录（用于官方安装脚本安装的工具）
if [ ! -d "$HOME/.local/bin" ]; then
    log_info "创建目录: $HOME/.local/bin"
    mkdir -p "$HOME/.local/bin"
else
    log_info "目录已存在: $HOME/.local/bin"
fi

# 2. chezmoi 状态目录（chezmoi 需要此目录存储状态信息）
CHEZMOI_STATE_DIR="$HOME/.local/share/chezmoi"
if [ ! -d "$CHEZMOI_STATE_DIR" ]; then
    log_info "创建 chezmoi 状态目录: $CHEZMOI_STATE_DIR"
    mkdir -p "$CHEZMOI_STATE_DIR"
else
    log_info "chezmoi 状态目录已存在: $CHEZMOI_STATE_DIR"
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

log_success "chezmoi 环境初始化完成"

# ============================================
# 配置差异检测和应用（chezmoi 核心流程）
# ============================================
# 再次确认 chezmoi 可用
if ! command -v chezmoi &> /dev/null; then
    error_exit "chezmoi 命令不可用，无法继续应用配置"
fi

log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[3/4] 检查配置状态和差异"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "$CHEZMOI_DIR" ] || [ -z "$(ls -A $CHEZMOI_DIR 2>/dev/null)" ]; then
    log_warning "chezmoi 源状态目录为空"
    log_info "请先运行迁移脚本: ./scripts/migration/migrate_to_chezmoi.sh"
    log_info "或手动添加配置: chezmoi add ~/.zshrc"
    exit 0
fi

# 设置源状态目录和环境变量
export CHEZMOI_SOURCE_DIR="$CHEZMOI_DIR"
export PAGER=cat  # 避免 chezmoi 进入交互模式

# 步骤 1: 检查配置状态
log_info "[1/3] 检查配置状态 (chezmoi status)..."
STATUS_OUTPUT=$(chezmoi status 2>&1 || true)
if [ -z "$STATUS_OUTPUT" ]; then
    log_success "所有配置都是最新的"
    HAS_STATUS_DIFF=false
else
    # 统计不同类型的变更
    modified=$(echo "$STATUS_OUTPUT" | grep -c "^M" || echo "0")
    added=$(echo "$STATUS_OUTPUT" | grep -c "^A" || echo "0")
    deleted=$(echo "$STATUS_OUTPUT" | grep -c "^D" || echo "0")
    run=$(echo "$STATUS_OUTPUT" | grep -c "^R" || echo "0")
    log_info "发现未同步配置: M=$modified, A=$added, D=$deleted, R=$run"
    HAS_STATUS_DIFF=true
    # 显示详细状态
    echo "$STATUS_OUTPUT" | head -10 | while IFS= read -r line; do
        log_info "  $line"
    done
fi

# 步骤 2: 检查配置差异
log_info "[2/3] 检查配置差异 (chezmoi diff)..."
DIFF_OUTPUT=$(chezmoi diff 2>&1 || true)
if [ -z "$DIFF_OUTPUT" ]; then
    log_success "模板配置与本地配置一致"
    HAS_DIFF=false
else
    # 统计差异文件数量
    file_count=$(echo "$DIFF_OUTPUT" | grep -c "^diff --git" || echo "0")
    log_info "发现 $file_count 个文件存在差异"
    HAS_DIFF=true
    # 显示差异摘要
    echo "$DIFF_OUTPUT" | head -20 | while IFS= read -r line; do
        log_info "  $line"
    done
    diff_lines=$(echo "$DIFF_OUTPUT" | wc -l | tr -d ' ')
    if [ "$diff_lines" -gt 20 ]; then
        log_info "  ... (还有更多差异，共 $diff_lines 行)"
    fi
fi

# 步骤 3: 应用配置（如果有差异）
log_info "[3/3] 应用配置 (chezmoi apply)..."
if [ "$HAS_STATUS_DIFF" = false ] && [ "$HAS_DIFF" = false ]; then
    log_success "所有配置都是最新的，无需应用"
else
    log_info "发现配置差异，开始应用配置..."
    log_info "执行: chezmoi apply -v --force"
    echo ""

    if chezmoi apply -v --force; then
        log_success "配置应用成功！"

        # 验证应用结果
        log_info "验证配置应用结果..."
        VERIFY_STATUS=$(chezmoi status 2>&1 || true)
        VERIFY_DIFF=$(chezmoi diff 2>&1 || true)
        if [ -z "$VERIFY_STATUS" ] && [ -z "$VERIFY_DIFF" ]; then
            log_success "配置已完全同步"
        else
            log_warning "配置应用后仍有差异，请检查"
        fi
    else
        log_error "配置应用失败，请检查错误信息"
        exit 1
    fi
fi

# ============================================
# 软件安装检查（通过 chezmoi run_once 脚本）
# ============================================
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[4/4] 检查软件安装状态"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检测操作系统和包管理器（用于软件检查）
if [ -f "$COMMON_INSTALL_SH" ]; then
    detect_os_and_package_manager || {
        log_warning "无法检测操作系统和包管理器，跳过详细软件检查"
        PLATFORM=""
        PACKAGE_MANAGER=""
    }
else
    log_warning "未找到 common_install.sh，跳过详细软件检查"
    PLATFORM=""
    PACKAGE_MANAGER=""
fi

# 扫描并检查安装脚本
if [ -d "$CHEZMOI_DIR" ]; then
    log_info "扫描安装脚本..."
    INSTALL_SCRIPTS=$(find "$CHEZMOI_DIR" -name "run_once_install-*.sh.tmpl" -type f 2>/dev/null || true)

    if [ -n "$INSTALL_SCRIPTS" ]; then
        script_count=$(echo "$INSTALL_SCRIPTS" | wc -l | tr -d ' ')
        log_info "找到 $script_count 个安装脚本"

        # 如果有包管理器信息，进行详细检查
        if [ -n "$PACKAGE_MANAGER" ]; then
            log_info "检查软件安装状态..."
            installed_list=""
            not_installed_list=""
            installed_count=0
            not_installed_count=0

            echo "$INSTALL_SCRIPTS" | while IFS= read -r script; do
                software_name=$(extract_software_name_from_script "$script")

                if check_script_software_installed "$script"; then
                    installed_list="${installed_list}${installed_list:+ }$software_name"
                    installed_count=$((installed_count + 1))
                    log_info "  ✓ $software_name (已安装)"
                else
                    not_installed_list="${not_installed_list}${not_installed_list:+ }$software_name"
                    not_installed_count=$((not_installed_count + 1))
                    log_info "  ✗ $software_name (未安装，将通过 chezmoi apply 安装)"
                fi
            done

            if [ "$installed_count" -gt 0 ]; then
                log_success "已安装软件: $installed_count 个"
            fi
            if [ "$not_installed_count" -gt 0 ]; then
                log_info "待安装软件: $not_installed_count 个（将通过 chezmoi apply 自动安装）"
            fi
        else
            log_info "注意: 软件安装将通过 chezmoi apply 自动执行 run_once_ 脚本"
            log_info "已安装的软件会被跳过，未安装的软件会自动安装"
        fi
    else
        log_info "未找到安装脚本"
    fi
else
    log_warning "chezmoi 源状态目录不存在，跳过软件检查"
fi

log_success "软件检查完成"

# ============================================
# 远程测试（如果指定）
# ============================================
REMOTE_TEST_PASSED=true

if [ "$TEST_REMOTE" = true ]; then
    log_info ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "执行远程测试"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    TEST_SCRIPT="${SCRIPT_DIR}/scripts/common/utils/test_tmux_remote.sh"

    if [ ! -f "$TEST_SCRIPT" ]; then
        log_error "远程测试脚本不存在: $TEST_SCRIPT"
        REMOTE_TEST_PASSED=false
    elif [ ! -x "$TEST_SCRIPT" ]; then
        log_warning "远程测试脚本没有执行权限，正在设置..."
        chmod +x "$TEST_SCRIPT"
    fi

    if [ -f "$TEST_SCRIPT" ] && [ -x "$TEST_SCRIPT" ]; then
        log_info "运行远程测试脚本..."
        if bash "$TEST_SCRIPT"; then
            log_success "远程测试通过"
            REMOTE_TEST_PASSED=true
        else
            log_error "远程测试失败"
            REMOTE_TEST_PASSED=false
        fi
    fi
fi

# ============================================
# 自动提交和推送（如果指定且测试通过）
# ============================================
if [ "$AUTO_COMMIT" = true ]; then
    if [ "$REMOTE_TEST_PASSED" != true ]; then
        log_warning "远程测试未通过，跳过自动提交"
    else
        log_info ""
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "自动提交和推送"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # 检查是否在 Git 仓库中
        if [ ! -d "${SCRIPT_DIR}/.git" ]; then
            log_warning "当前目录不是 Git 仓库，跳过提交"
        else
            cd "$SCRIPT_DIR"

            # 检查是否有更改
            if [ -z "$(git status --porcelain)" ]; then
                log_info "没有更改需要提交"
            else
                # 添加所有更改
                log_info "添加更改到 Git..."
                git add -A

                # 生成提交信息
                COMMIT_MSG="feat: 添加 Catppuccin Tmux 主题配置 (Mocha)"
                if [ "$TEST_REMOTE" = true ]; then
                    COMMIT_MSG="${COMMIT_MSG} - 远程测试通过"
                fi

                # 提交
                log_info "提交更改: $COMMIT_MSG"
                if git commit -m "$COMMIT_MSG"; then
                    log_success "提交成功"

                    # 推送到远程
                    log_info "推送到远程仓库..."
                    if git push; then
                        log_success "推送成功"
                    else
                        log_warning "推送失败，请手动推送"
                    fi
                else
                    log_warning "提交失败，可能没有需要提交的更改"
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

log_success "安装完成！"
echo ""
log_info "后续操作："
log_info "  快速部署: ./deploy.sh"
log_info "  查看状态: ./scripts/manage_dotfiles.sh status"
log_info "  查看差异: ./scripts/manage_dotfiles.sh diff"
log_info "  编辑配置: ./scripts/manage_dotfiles.sh edit ~/.zshrc"
echo ""
log_info "使用帮助: ./scripts/manage_dotfiles.sh help"
log_info "部署指南: scripts/common/utils/DEPLOYMENT_GUIDE.md"
