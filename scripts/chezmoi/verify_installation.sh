#!/usr/bin/env bash
# ============================================
# 安装验证与报告脚本
# 检查：字体、默认 Shell、环境变量/PATH、开机启动声明
# 输出：终端摘要 + 报告文件
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"

if [[ -f "${COMMON_SH}" ]]; then
    # shellcheck source=../common.sh
    source "${COMMON_SH}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

# 报告文件路径（可由调用方传入）
REPORT_FILE="${VERIFY_REPORT_FILE:-}"
REPORT_DATE="$(date +%Y%m%d_%H%M%S)"
if [[ -z "$REPORT_FILE" ]]; then
    # Windows（Git Bash）下优先使用 USERPROFILE，避免报告写到 /home/... 导致用户找不到
    if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]] && [[ -n "${USERPROFILE:-}" ]]; then
        REPORT_DIR="$(cygpath -u "$USERPROFILE" 2>/dev/null || echo "$USERPROFILE")"
        REPORT_FILE="${REPORT_DIR}/install_verification_report_${REPORT_DATE}.txt"
    else
        REPORT_FILE="${HOME}/install_verification_report_${REPORT_DATE}.txt"
    fi
fi

# 报告内容缓存（先写入变量，最后统一写文件并打印摘要）
REPORT_LINES=()
SUMMARY_PASS=0
SUMMARY_WARN=0
SUMMARY_FAIL=0

report_append() {
    REPORT_LINES+=("$*")
}

# 检测操作系统
detect_os() {
    local os
    os="$(uname -s)"
    if [[ "$os" == "Darwin" ]]; then
        echo "darwin"
    elif [[ "$os" == "Linux" ]]; then
        echo "linux"
    elif [[ "$os" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# 1. 字体检查
check_font() {
    report_append "========== 1. 字体（Nerd Font） =========="
    local os="$1"
    local ok=false

    if [[ "$os" == "linux" ]]; then
        local font_dir="/usr/local/share/fonts/FiraMono-NerdFont"
        if [[ -d "$font_dir" ]]; then
            local count
            count=$(find "$font_dir" -name "*.ttf" -o -name "*.otf" 2>/dev/null | wc -l)
            if [[ "${count:-0}" -gt 0 ]]; then
                report_append "  状态: 通过"
                report_append "  路径: ${font_dir} (${count} 个字体文件)"
                ok=true
            fi
        fi
        if [[ "$ok" != true ]] && command -v fc-list &>/dev/null; then
            if fc-list 2>/dev/null | grep -qi FiraMono; then
                report_append "  状态: 通过 (fc-list 检测到 FiraMono)"
                ok=true
            fi
        fi
        if [[ "$ok" != true ]]; then
            report_append "  状态: 未安装或未检测到"
            report_append "  说明: 可由 run_once_install-nerd-fonts.sh 安装"
            ((SUMMARY_WARN++)) || true
        else
            ((SUMMARY_PASS++)) || true
        fi
    elif [[ "$os" == "darwin" ]]; then
        local found=""
        for dir in "/Library/Fonts" "${HOME}/Library/Fonts"; do
            if [[ -d "$dir" ]] && find "$dir" -name "*FiraMono*" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | grep -q .; then
                found="$dir"
                break
            fi
        done
        if [[ -n "$found" ]]; then
            report_append "  状态: 通过"
            report_append "  路径: 检测到 FiraMono 字体"
            ((SUMMARY_PASS++)) || true
        else
            report_append "  状态: 未安装或未检测到"
            report_append "  说明: 可由 run_once_install-nerd-fonts.sh 安装"
            ((SUMMARY_WARN++)) || true
        fi
    else
        report_append "  状态: 跳过 (Windows/其他平台请手动确认字体)"
        report_append "  说明: 本项目安装 FiraMono Nerd Font，终端可选用 Nerd Font 以显示图标"
    fi
    report_append ""
}

# 2. 默认 Shell 检查
check_default_shell() {
    report_append "========== 2. 默认 Shell =========="
    local os="$1"

    if [[ "$os" == "linux" || "$os" == "darwin" ]]; then
        local current_shell=""
        if [[ "$os" == "darwin" ]]; then
            current_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')"
        fi
        if [[ -z "$current_shell" ]] && command -v getent &>/dev/null; then
            current_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
        fi
        if [[ -z "$current_shell" ]] && [[ -f /etc/passwd ]]; then
            current_shell="$(awk -F: -v u="$(id -un)" '$1==u {print $7}' /etc/passwd)"
        fi
        if [[ -n "$current_shell" ]]; then
            report_append "  当前登录/默认 Shell: ${current_shell}"
            if [[ "$current_shell" == *zsh* ]]; then
                report_append "  状态: 通过 (项目期望 Linux/macOS 默认 zsh)"
                ((SUMMARY_PASS++)) || true
            else
                report_append "  状态: 建议 (项目期望 zsh，可执行 chsh -s \$(command -v zsh) 后重新登录)"
                ((SUMMARY_WARN++)) || true
            fi
        else
            report_append "  状态: 无法获取"
            ((SUMMARY_WARN++)) || true
        fi
    else
        report_append "  状态: Windows 无系统默认 shell 概念"
        report_append "  说明: Git Bash 下可通过 dot_bash_profile 自动启动 zsh"
    fi
    report_append ""
}

# 3. 环境变量 / PATH 检查
check_path_and_commands() {
    report_append "========== 3. 环境变量与 PATH =========="
    local path_ok=true
    local path_content="${PATH:-}"

    if [[ "$path_content" == *".local/bin"* ]] || [[ "$path_content" == *"$HOME/.local/bin"* ]]; then
        report_append "  ~/.local/bin: 在 PATH 中"
    else
        report_append "  ~/.local/bin: 不在 PATH 中（当前会话）"
        path_ok=false
    fi

    if [[ "$path_content" == *"fnm"* ]] || [[ "$path_content" == *".local/share/fnm"* ]]; then
        report_append "  fnm 路径: 在 PATH 中"
    else
        report_append "  fnm 路径: 未检测（新终端或 .zprofile 加载后会加入）"
    fi

    report_append "  关键命令:"
    local cmd_ok=0
    for cmd in chezmoi git fnm uv; do
        if command -v "$cmd" &>/dev/null; then
            report_append "    $cmd: $(command -v "$cmd")"
            ((cmd_ok++)) || true
        else
            report_append "    $cmd: 未找到"
        fi
    done
    if [[ $cmd_ok -ge 3 ]]; then
        report_append "  状态: 通过 (关键命令可用)"
        ((SUMMARY_PASS++)) || true
    else
        report_append "  状态: 警告 (部分命令不可用，请确认已 source ~/.zprofile 或 ~/.bashrc)"
        ((SUMMARY_WARN++)) || true
    fi
    report_append ""
}

# 4. 通用工具（btop、fastfetch 等，Linux/macOS 由 run_once_install-common-tools 安装）
check_common_tools() {
    local os="$1"
    if [[ "$os" != "linux" && "$os" != "darwin" ]]; then
        report_append "========== 4. 通用工具（btop/fastfetch） =========="
        report_append "  状态: 跳过 (仅 Linux/macOS 检查)"
        report_append ""
        return 0
    fi
    report_append "========== 4. 通用工具（btop/fastfetch） =========="
    local tools_ok=0
    for cmd in btop fastfetch; do
        if command -v "$cmd" &>/dev/null; then
            report_append "  $cmd: $(command -v "$cmd")"
            ((tools_ok++)) || true
        else
            report_append "  $cmd: 未找到"
        fi
    done
    if [[ $tools_ok -eq 2 ]]; then
        report_append "  状态: 通过 (btop、fastfetch 已安装)"
        ((SUMMARY_PASS++)) || true
    elif [[ $tools_ok -eq 1 ]]; then
        report_append "  状态: 警告 (其一未安装，可由 run_once_install-common-tools 安装)"
        ((SUMMARY_WARN++)) || true
    else
        report_append "  状态: 警告 (未安装，可由 run_once_install-common-tools 安装)"
        ((SUMMARY_WARN++)) || true
    fi
    report_append ""
}

# 5. OpenCode / Oh My OpenCode
check_opencode() {
    report_append "========== 5. OpenCode / Oh My OpenCode =========="
    if ! command -v opencode &>/dev/null; then
        report_append "  opencode: 未在 PATH 中"
        report_append "  说明: 可由 run_once_install-opencode.sh 安装"
        ((SUMMARY_WARN++)) || true
    else
        report_append "  opencode: $(command -v opencode)"
        local ver
        ver="$(opencode --version 2>/dev/null | head -n1)"
        report_append "  版本: ${ver:-未知}"
        local oc_json="${HOME}/.config/opencode/opencode.json"
        if [[ -f "$oc_json" ]] && grep -q '"oh-my-opencode"' "$oc_json" 2>/dev/null; then
            report_append "  Oh My OpenCode: 已配置"
            ((SUMMARY_PASS++)) || true
        else
            report_append "  Oh My OpenCode: 未配置或未找到 plugin"
            report_append "  说明: 可由 run_once_install-opencode-omo.sh 安装；或手动运行: bunx oh-my-opencode install"
            ((SUMMARY_WARN++)) || true
        fi
    fi
    report_append ""
}

# 6. 开机启动声明
check_startup_declaration() {
    report_append "========== 6. 开机启动服务 =========="
    report_append "  本项目未配置 systemd 用户服务、~/.config/autostart 等图形自启动。"
    report_append "  环境变量与 PATH 由 shell 配置文件（如 .zprofile、.bashrc）在登录时加载。"
    report_append "  状态: 已确认（无需检测服务列表）"
    report_append ""
}

# 7. SSH 与 connect（ProxyCommand 依赖，供 GitHub 等经代理走 443）
check_ssh_and_connect() {
    local os="$1"
    report_append "========== 7. SSH 与 connect =========="

    if [[ -f "${HOME}/.ssh/config" ]]; then
        report_append "  ~/.ssh/config: 存在"
    else
        report_append "  ~/.ssh/config: 不存在（chezmoi apply 后会生成）"
    fi

    if [[ "$os" == "linux" || "$os" == "darwin" ]]; then
        local connect_path=""
        if command -v connect &>/dev/null; then
            connect_path="$(command -v connect)"
        elif [[ -x /opt/homebrew/bin/connect ]]; then
            connect_path="/opt/homebrew/bin/connect"
        elif [[ -x /usr/local/bin/connect ]]; then
            connect_path="/usr/local/bin/connect"
        fi
        if [[ -n "$connect_path" ]]; then
            report_append "  connect: ${connect_path}"
            report_append "  状态: 通过 (SSH ProxyCommand 可用)"
            ((SUMMARY_PASS++)) || true
        else
            report_append "  connect: 未找到"
            report_append "  说明: Linux 可 sudo apt install connect-proxy 或 sudo pacman -S connect；macOS 可 brew install connect"
            ((SUMMARY_WARN++)) || true
        fi
    else
        report_append "  connect.exe: Windows 下随 Git for Windows 提供，请确认已安装 Git for Windows"
        report_append "  说明: 若 Git 安装在其他盘符，可在 .chezmoi.toml.local 中设置 windows_git_connect_path"
    fi
    report_append "  建议: 安装后手动执行 ssh -T git@github.com 验证；WSL/Linux 可运行 scripts/linux/system_basic_env/verify_wsl_ssh.sh"
    report_append ""
}

# 写报告文件并打印摘要
write_report_and_summary() {
    local report_dir
    report_dir="$(dirname "$REPORT_FILE")"
    if [[ ! -d "$report_dir" ]]; then
        mkdir -p "$report_dir"
    fi
    {
        echo "安装验证报告 - ${REPORT_DATE}"
        echo "项目: script_tool_and_config"
        echo "主机: $(hostname 2>/dev/null || echo 'unknown')"
        echo "操作系统: $(detect_os)"
        echo ""
        for line in "${REPORT_LINES[@]}"; do
            echo "$line"
        done
        echo "========== 报告结束 =========="
    } > "$REPORT_FILE"

    log_info "验证报告已写入: ${REPORT_FILE}"
    echo ""
    log_info "验证摘要: 通过 ${SUMMARY_PASS} 项, 警告 ${SUMMARY_WARN} 项, 失败 ${SUMMARY_FAIL} 项"
    for line in "${REPORT_LINES[@]}"; do
        echo "$line"
    done
}

# 主流程（不调用 start_script/end_script，便于被 install.sh 内嵌时风格一致）
main() {
    local os
    os="$(detect_os)"
    report_append "平台: ${os}"
    report_append ""

    check_font "$os"
    check_default_shell "$os"
    check_path_and_commands
    check_common_tools "$os"
    check_opencode
    check_ssh_and_connect "$os"
    check_startup_declaration
    write_report_and_summary
    return 0
}

# 支持单独运行或 source 后调用 main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
