#!/bin/bash

# ============================================
# 同步脚本 - 将项目同步到远端 Arch Linux
# 使用 rsync 进行高效同步
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

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

start_script "同步项目到远端 Arch Linux"

# ============================================
# 检测操作系统
# ============================================
OS="$(uname -s)"
if [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    IS_WINDOWS=true
    PLATFORM="windows"
else
    IS_WINDOWS=false
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="macos"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
    else
        PLATFORM="unknown"
    fi
fi

# ============================================
# 配置参数
# ============================================
REMOTE_HOST="${REMOTE_HOST:-192.168.1.109}"
REMOTE_USER="${REMOTE_USER:-leonli}"
REMOTE_PATH="${REMOTE_PATH:-/home/leonli/Code/DotfilesAndScript/script_tool_and_config}"

# ============================================
# 检查 rsync 是否安装
# ============================================
USE_RSYNC=false
if command -v rsync &> /dev/null; then
    USE_RSYNC=true
    log_success "检测到 rsync，将使用 rsync 同步"
elif [ "$IS_WINDOWS" = true ]; then
    log_warning "Windows 环境下未检测到 rsync"
    log_info "Windows 上安装 rsync 的方法："
    log_info "  1. 使用 MSYS2: pacman -S rsync"
    log_info "  2. 使用 Git Bash 自带的 scp/sftp（功能有限）"
    log_info "  3. 推荐使用 VS Code SFTP 扩展进行同步"
    echo ""
    log_info "当前将使用 scp 进行同步（功能有限，建议使用 VS Code SFTP 扩展）"
    read -p "是否继续使用 scp 同步？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "建议使用以下方法之一："
        log_info "  1. 安装 rsync: 在 MSYS2 中运行 pacman -S rsync"
        log_info "  2. 使用 VS Code SFTP 扩展: Ctrl+Shift+P -> SFTP: Upload Project"
        error_exit "用户取消操作"
    fi
    if ! command -v scp &> /dev/null; then
        error_exit "scp 未找到，请确保 Git Bash 已正确安装"
    fi
else
    log_info "正在检查 rsync 安装方法..."
    if [[ "$PLATFORM" == "macos" ]]; then
        log_info "macOS 上安装 rsync: brew install rsync"
    elif [[ "$PLATFORM" == "linux" ]]; then
        if command -v pacman &> /dev/null; then
            log_info "Arch Linux 上安装 rsync: sudo pacman -S rsync"
        elif command -v apt-get &> /dev/null; then
            log_info "Ubuntu/Debian 上安装 rsync: sudo apt-get install rsync"
        fi
    fi
    error_exit "rsync 未安装，请先安装 rsync"
fi

# ============================================
# 检查 SSH 连接
# ============================================
log_info "检查 SSH 连接..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" "echo 'SSH连接成功'" &> /dev/null; then
    log_warning "SSH 连接测试失败，可能需要手动输入密码或配置 SSH 密钥"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error_exit "用户取消操作"
    fi
fi

# ============================================
# 确认同步
# ============================================
log_info "同步配置："
log_info "  远端主机: ${REMOTE_USER}@${REMOTE_HOST}"
log_info "  远端路径: ${REMOTE_PATH}"
log_info "  本地路径: ${PROJECT_ROOT}"
echo ""
read -p "确认开始同步？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "用户取消操作"
    end_script
    exit 0
fi

# ============================================
# 执行同步
# ============================================
log_info "开始同步..."

if [ "$USE_RSYNC" = true ]; then
    # 使用 rsync 同步（推荐）
    rsync -avz --progress \
      --delete \
      --exclude='.git' \
      --exclude='.gitignore' \
      --exclude='.gitmodules' \
      --exclude='.gitattributes' \
      --exclude='.vscode' \
      --exclude='.claude' \
      --exclude='.idea' \
      --exclude='*.tmp' \
      --exclude='*.temp' \
      --exclude='*.log' \
      --exclude='*.bak' \
      --exclude='*.backup' \
      --exclude='*.old' \
      --exclude='*.orig' \
      --exclude='*.swp' \
      --exclude='*.swo' \
      --exclude='*.swn' \
      --exclude='*~' \
      --exclude='.DS_Store' \
      --exclude='.AppleDouble' \
      --exclude='.LSOverride' \
      --exclude='._*' \
      --exclude='Thumbs.db' \
      --exclude='ehthumbs.db' \
      --exclude='Desktop.ini' \
      --exclude='$RECYCLE.BIN/' \
      --exclude='.directory' \
      --exclude='.chezmoistate' \
      --exclude='.chezmoi.*.tmp' \
      --exclude='logs/' \
      --exclude='scripts/**/log' \
      --exclude='scripts/**/*.log' \
      --exclude='scripts/**/logs/' \
      --exclude='scripts/linux/system_basic_env/log' \
      --exclude='scripts/windows/system_basic_env/log' \
      --exclude='scripts/windows/system_basic_env/*.log' \
      --exclude='scripts/windows/system_basic_env/path.bak' \
      --exclude='scripts/windows/system_basic_env/InstallationLog.txt' \
      --exclude='scripts/windows/system_basic_env/*.backup' \
      --exclude='scripts/common/project_tools/cpp_project_generator/src/' \
      --exclude='scripts/common/project_tools/cpp_project_generator/build/' \
      --exclude='scripts/common/project_tools/cpp_project_generator/CMakeLists.txt' \
      --exclude='scripts/common/project_tools/cpp_project_generator/.gitignore' \
      --exclude='scripts/linux/patch_examples/*.bak' \
      --exclude='scripts/common/auto_edit_redis_config/redis.conf.bak' \
      --exclude='scripts/**/test_*.sh' \
      --exclude='scripts/**/TEST_*.md' \
      --exclude='scripts/**/*_test.sh' \
      --exclude='scripts/**/*_test_*.sh' \
      --exclude='.cache/' \
      --exclude='.tmp/' \
      --exclude='tmp/' \
      --exclude='temp/' \
      --exclude='build/' \
      --exclude='dist/' \
      --exclude='bin/' \
      --exclude='lib/' \
      --exclude='obj/' \
      --exclude='out/' \
      --exclude='cmake-build-*/' \
      --exclude='CMakeCache.txt' \
      --exclude='CMakeFiles/' \
      --exclude='cmake_install.cmake' \
      --exclude='Makefile' \
      --exclude='*.cmake' \
      --exclude='*.o' \
      --exclude='*.obj' \
      --exclude='*.exe' \
      --exclude='*.out' \
      --exclude='*.a' \
      --exclude='*.so' \
      --exclude='*.dylib' \
      --exclude='*.dll' \
      --exclude='*.sh.x' \
      --exclude='*.sh.x.c' \
      --exclude='*.pyc' \
      --exclude='*.pyo' \
      --exclude='__pycache__/' \
      --exclude='env/' \
      --exclude='venv/' \
      --exclude='ENV/' \
      --exclude='.venv' \
      --exclude='.env' \
      --exclude='.env.local' \
      --exclude='.env.*.local' \
      --exclude='*.key' \
      --exclude='*.pem' \
      --exclude='*.cert' \
      --exclude='*.crt' \
      --exclude='*.p12' \
      --exclude='*.pfx' \
      --exclude='node_modules/' \
      "${PROJECT_ROOT}/" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

    SYNC_RESULT=$?
else
    # 使用 scp 同步（Windows 备用方案，功能有限）
    log_warning "使用 scp 同步，功能有限，建议使用 VS Code SFTP 扩展"
    log_info "scp 不支持排除文件，将同步所有文件（包括临时文件）"
    log_info "建议在远端手动清理不需要的文件"
    echo ""

    # 创建临时排除文件列表（用于 tar）
    EXCLUDE_FILE=$(mktemp)
    cat > "$EXCLUDE_FILE" << 'EOF'
.git
.gitignore
.gitmodules
.gitattributes
.vscode
.claude
.idea
*.tmp
*.temp
*.log
*.bak
*.backup
*.old
*.orig
*.swp
*.swo
*.swn
*~
.DS_Store
.AppleDouble
.LSOverride
._*
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
.directory
.chezmoistate
.chezmoi.*.tmp
logs/
scripts/**/log
scripts/**/*.log
scripts/**/logs/
scripts/linux/system_basic_env/log
scripts/windows/system_basic_env/log
scripts/windows/system_basic_env/*.log
scripts/windows/system_basic_env/path.bak
scripts/windows/system_basic_env/InstallationLog.txt
scripts/windows/system_basic_env/*.backup
scripts/common/project_tools/cpp_project_generator/src/
scripts/common/project_tools/cpp_project_generator/build/
scripts/common/project_tools/cpp_project_generator/CMakeLists.txt
scripts/common/project_tools/cpp_project_generator/.gitignore
scripts/linux/patch_examples/*.bak
scripts/common/auto_edit_redis_config/redis.conf.bak
scripts/**/test_*.sh
scripts/**/TEST_*.md
scripts/**/*_test.sh
scripts/**/*_test_*.sh
.cache/
.tmp/
tmp/
temp/
build/
dist/
bin/
lib/
obj/
out/
cmake-build-*/
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile
*.cmake
*.o
*.obj
*.exe
*.out
*.a
*.so
*.dylib
*.dll
*.sh.x
*.sh.x.c
*.pyc
*.pyo
__pycache__/
env/
venv/
ENV/
.venv
.env
.env.local
.env.*.local
*.key
*.pem
*.cert
*.crt
*.p12
*.pfx
node_modules/
EOF

    # 使用 tar + ssh 进行同步（支持排除文件）
    log_info "使用 tar 打包并同步..."
    cd "$PROJECT_ROOT"
    tar --exclude-from="$EXCLUDE_FILE" -czf - . | \
      ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_PATH} && cd ${REMOTE_PATH} && tar -xzf -"

    SYNC_RESULT=$?
    rm -f "$EXCLUDE_FILE"
fi

if [ $SYNC_RESULT -eq 0 ]; then
    log_success "同步完成！"
    log_info "远端路径: ${REMOTE_PATH}"
    log_info "下一步：在远端运行 ./install.sh 初始化项目"
    if [ "$IS_WINDOWS" = true ] && [ "$USE_RSYNC" = false ]; then
        echo ""
        log_warning "Windows 环境建议："
        log_info "  1. 安装 rsync: 在 MSYS2 中运行 pacman -S rsync"
        log_info "  2. 使用 VS Code SFTP 扩展: Ctrl+Shift+P -> SFTP: Upload Project"
        log_info "  3. VS Code SFTP 扩展支持自动排除文件，功能更强大"
    fi
else
    error_exit "同步失败"
fi

end_script

