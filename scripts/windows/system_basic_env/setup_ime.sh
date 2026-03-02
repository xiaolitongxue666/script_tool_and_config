#!/usr/bin/env bash
# Windows 10 输入法配置：仅保留微软拼音、禁用全角/半角快捷键、默认半角
# 需在 Git Bash 中运行；修改系统输入法建议以管理员身份运行 Git Bash。
# 用法: bash setup_ime.sh [--rollback]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

# 备份文件放在当前工作目录，便于用户查找
readonly BACKUP_DIR="${BACKUP_DIR:-$(pwd)}"
readonly BACKUP_KEYBOARD="${BACKUP_DIR}/ime_backup.reg"
readonly BACKUP_PROFILE="${BACKUP_DIR}/ime_profile_backup.reg"
readonly HOTKEY_PATH="HKEY_CURRENT_USER\\Control Panel\\Input Method\\Hot Keys\\00000011"
readonly CHS_SETTINGS_PATH="HKEY_CURRENT_USER\\Software\\Microsoft\\InputMethod\\Settings\\CHS"

# ============================================
# 检查运行环境
# ============================================
check_windows_env() {
    if ! command -v reg.exe &>/dev/null; then
        error_exit "未找到 reg.exe，请在 Windows 的 Git Bash 中运行此脚本"
    fi
    if ! command -v powershell.exe &>/dev/null; then
        error_exit "未找到 powershell.exe"
    fi
}

# ============================================
# 备份当前输入法相关注册表
# ============================================
backup_registry() {
    log_info "正在备份当前输入法注册表到 ${BACKUP_DIR}"
    ensure_directory "${BACKUP_DIR}"
    local backup_ok=0
    if reg.exe export "HKEY_CURRENT_USER\\Keyboard Layout" "${BACKUP_KEYBOARD}" /y 2>/dev/null; then
        backup_ok=1
    else
        log_warning "备份 Keyboard Layout 失败（可能键不存在或权限不足，建议以管理员身份运行）"
    fi
    if reg.exe export "HKEY_CURRENT_USER\\Control Panel\\International\\User Profile" "${BACKUP_PROFILE}" /y 2>/dev/null; then
        backup_ok=1
    else
        log_warning "备份 User Profile 失败"
    fi
    if [[ $backup_ok -eq 1 ]]; then
        log_success "备份完成: ${BACKUP_KEYBOARD} ${BACKUP_PROFILE}"
    else
        log_warning "未生成任何备份文件，回滚时将无法恢复注册表；建议以管理员身份重新运行以生成备份"
    fi
}

# ============================================
# 应用配置：仅微软拼音、禁用全角/半角热键、默认半角
# ============================================
apply_ime_config() {
    log_info "正在重置语言列表：仅保留微软拼音 (zh-Hans-CN)"
    if ! powershell.exe -NoProfile -Command "Set-WinUserLanguageList -LanguageList (New-WinUserLanguageList -Language 'zh-Hans-CN') -Force" 2>/dev/null; then
        error_exit "Set-WinUserLanguageList 执行失败，请尝试以管理员身份运行 Git Bash"
    fi
    log_success "语言列表已设为仅微软拼音"

    log_info "正在禁用全角/半角切换快捷键 (Shift+Space)"
    if ! powershell.exe -NoProfile -Command "if (!(Test-Path 'HKCU:\\Control Panel\\Input Method\\Hot Keys\\00000011')) { New-Item -Path 'HKCU:\\Control Panel\\Input Method\\Hot Keys\\00000011' -Force | Out-Null }; Set-ItemProperty -Path 'HKCU:\\Control Panel\\Input Method\\Hot Keys\\00000011' -Name 'Target IME' -Value ([byte[]](0x00,0x00,0x00,0x00)) -Force" 2>/dev/null; then
        log_warning "禁用全角/半角热键可能未完全生效，请检查注册表路径"
    else
        log_success "全角/半角快捷键已禁用"
    fi

    # 微软拼音 CHS 下 "Default Mode"=0 表示半角，1 表示全角（实测键名为 "Default Mode"）
    log_info "正在设置微软拼音默认为半角（永远使用半角）"
    local half_width_ok=0
    if powershell.exe -NoProfile -Command "if (Test-Path 'HKCU:\\Software\\Microsoft\\InputMethod\\Settings\\CHS') { Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\InputMethod\\Settings\\CHS' -Name 'Default Mode' -Value 0 -Type DWord -Force; exit 0 } else { exit 1 }" 2>/dev/null; then
        half_width_ok=1
    fi
    if [[ $half_width_ok -eq 0 ]] && reg.exe add "${CHS_SETTINGS_PATH}" /v "Default Mode" /t REG_DWORD /d 0 /f 2>/dev/null; then
        half_width_ok=1
    fi
    if [[ $half_width_ok -eq 0 ]] && reg.exe add "${CHS_SETTINGS_PATH}" /v "Default Full/Half Width Mode" /t REG_DWORD /d 0 /f 2>/dev/null; then
        half_width_ok=1
    fi
    if [[ $half_width_ok -eq 1 ]]; then
        log_success "微软拼音已设为默认半角"
    else
        log_warning "设置默认半角未生效，请检查 HKCU:\\Software\\Microsoft\\InputMethod\\Settings\\CHS 是否存在"
    fi
}

# ============================================
# 回滚：导入备份的注册表
# ============================================
rollback_ime() {
    log_info "正在回滚输入法设置"
    if [[ -f "${BACKUP_KEYBOARD}" ]]; then
        if reg.exe import "${BACKUP_KEYBOARD}" 2>/dev/null; then
            log_success "已导入 ${BACKUP_KEYBOARD}"
        else
            log_error "导入失败: ${BACKUP_KEYBOARD}"
        fi
    else
        log_warning "备份文件不存在: ${BACKUP_KEYBOARD}"
    fi
    if [[ -f "${BACKUP_PROFILE}" ]]; then
        if reg.exe import "${BACKUP_PROFILE}" 2>/dev/null; then
            log_success "已导入 ${BACKUP_PROFILE}"
        else
            log_error "导入失败: ${BACKUP_PROFILE}"
        fi
    else
        log_warning "备份文件不存在: ${BACKUP_PROFILE}"
    fi
    log_info "回滚完成。建议注销或重启以使语言列表完全恢复；或在 设置 -> 时间和语言 -> 语言 中手动添加英语(美国)。"
}

# ============================================
# 验证当前配置
# ============================================
verify_config() {
    log_info "验证当前语言列表"
    powershell.exe -NoProfile -Command "Get-WinUserLanguageList | Format-Table -AutoSize"
    local chs_val
    chs_val=$(reg.exe query "${CHS_SETTINGS_PATH}" /v "Default Mode" 2>/dev/null | grep "Default Mode" || true)
    if [[ -n "${chs_val}" ]]; then
        log_info "微软拼音 Default Mode: ${chs_val} (0=半角 1=全角)"
    fi
}

# ============================================
# 主流程
# ============================================
main() {
    local do_rollback=false
    if [[ "${1:-}" == "--rollback" ]]; then
        do_rollback=true
    fi

    start_script "Windows 输入法配置 (setup_ime)"

    check_windows_env

    if [[ "$do_rollback" == true ]]; then
        rollback_ime
        verify_config
        end_script
    fi

    backup_registry
    apply_ime_config
    verify_config

    log_info "为使设置完全生效，建议 注销并重新登录 或 重启计算机。"
    log_info "回滚命令: bash $(basename "${BASH_SOURCE[0]}") --rollback （需在备份文件所在目录运行，或设置 BACKUP_DIR）"
    end_script
}

main "$@"
