#!/usr/bin/env bash

# 包安装与升级函数（由 common_install.sh source）

# ============================================

# 跨平台包安装函数
# 参数: package_name
install_package() {
    local package_name="$1"
    if [ -z "$package_name" ]; then
        echo "[ERROR] 包名不能为空"
        return 1
    fi

    # 确保已检测操作系统
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_os_and_package_manager || return 1
    fi

    echo "[INFO] 安装包: $package_name"

    case "$PACKAGE_MANAGER" in
        brew)
            # 与 upgrade_brew_package 同一路径：NO_AUTO_UPDATE、Intel 重型依赖跳过、断链 keg 重 link
            if type upgrade_brew_package &>/dev/null; then
                upgrade_brew_package "$package_name" || return 1
            else
                brew install "$package_name" || return 1
            fi
            ;;
        pacman)
            if [[ "$PLATFORM" == "windows" ]]; then
                # Windows MSYS2
                pacman.exe -S --noconfirm "$package_name" || return 1
            else
                # Linux Arch
                sudo pacman -S --noconfirm "$package_name" || return 1
            fi
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y "$package_name" || return 1
            ;;
        dnf)
            sudo dnf install -y "$package_name" || return 1
            ;;
        yum)
            sudo yum install -y "$package_name" || return 1
            ;;
        winget)
            # --source winget：避开 msstore（7890 MITM 易触发 0x8a15005e）
            winget install --id="$package_name" -e --source winget --accept-source-agreements --accept-package-agreements || return 1
            ;;
        *)
            echo "[ERROR] 不支持的包管理器: $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    echo "[SUCCESS] 包安装成功: $package_name"
}

# 跨平台 Cask 包安装函数（主要用于 macOS Homebrew Cask）
# 参数: package_name
install_cask_package() {
    local package_name="$1"
    if [ -z "$package_name" ]; then
        echo "[ERROR] 包名不能为空"
        return 1
    fi

    # 确保已检测操作系统
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_os_and_package_manager || return 1
    fi

    echo "[INFO] 安装 Cask 包: $package_name"

    case "$PACKAGE_MANAGER" in
        brew)
            brew install --cask "$package_name" || return 1
            ;;
        *)
            echo "[ERROR] Cask 包仅支持 Homebrew (macOS)"
            return 1
            ;;
    esac

    echo "[SUCCESS] Cask 包安装成功: $package_name"
}

# ============================================
# 依赖安装函数
# ============================================

# 安装前置依赖
# 参数: 依赖包列表（空格分隔）
install_dependencies() {
    if [ $# -eq 0 ]; then
        echo "[WARNING] 未提供依赖列表"
        return 0
    fi

    echo "[INFO] 检查并安装前置依赖..."

    # 确保已检测操作系统
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_os_and_package_manager || return 1
    fi

    for dep in "$@"; do
        # 检查是否已安装
        if command -v "$dep" &> /dev/null; then
            echo "[INFO] 依赖已安装: $dep"
            continue
        fi

        # 尝试安装
        install_package "$dep" || echo "[WARNING] 依赖安装失败: $dep"
    done

    echo "[SUCCESS] 依赖检查完成"
}

# ============================================
# 命令检查函数
# ============================================

# 检查命令是否存在，不存在则安装
# 参数: command_name [package_name]
check_command_or_install() {
    local command_name="$1"
    local package_name="${2:-$command_name}"

    if command -v "$command_name" &> /dev/null; then
        echo "[INFO] 命令已存在: $command_name"
        return 0
    fi

    echo "[INFO] 命令不存在，尝试安装: $package_name"
    install_package "$package_name"
}

# ============================================
# 下载函数
# ============================================

# 带进度显示的下载函数（带超时和重试）
# 参数: url dest [timeout] [max_retries]
download_with_progress() {
    local url="$1"
    local dest="$2"
    local timeout="${3:-60}"
    local max_retries="${4:-3}"

    log_info "开始下载: ${url}"

    # 确保目标目录存在
    local dest_dir=$(dirname "${dest}")
    if [[ ! -d "${dest_dir}" ]]; then
        mkdir -p "${dest_dir}" || {
            log_error "无法创建目录: ${dest_dir}"
            return 1
        }
    fi

    local retry_count=0
    while [[ "${retry_count}" -lt "${max_retries}" ]]; do
        # 优先使用 curl（进度条更简洁），其次 wget，最后使用 aria2c
        if command -v curl >/dev/null 2>&1; then
            if timeout "${timeout}" curl -fL --progress-bar --max-time "${timeout}" \
                -o "${dest}" "${url}" 2>&1; then
                echo ""
                log_success "下载完成: ${dest}"
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            if timeout "${timeout}" wget --show-progress --progress=bar:force:noscroll \
                --timeout="${timeout}" -O "${dest}" "${url}" 2>&1; then
                log_success "下载完成: ${dest}"
                return 0
            fi
        elif command -v aria2c >/dev/null 2>&1; then
            local aria2_output
            aria2_output=$(aria2c --check-certificate=false \
                --max-connection-per-server=8 \
                --split=8 \
                --dir="$(dirname "${dest}")" \
                --out="$(basename "${dest}")" \
                --summary-interval=5 \
                --console-log-level=warn \
                --timeout="${timeout}" \
                --max-tries="${max_retries}" \
                --quiet=false \
                "${url}" 2>&1)

            local aria2_exit=$?
            echo "${aria2_output}" | grep -E "^\[#.*\]" | tail -n 1 | sed 's/^/\r/' >&2 || true

            if [[ ${aria2_exit} -eq 0 ]] && [[ -f "${dest}" ]]; then
                echo "" >&2
                log_success "下载完成: ${dest}"
                return 0
            fi
        else
            log_error "没有可用的下载工具 (curl, wget, 或 aria2c)"
            return 1
        fi

        retry_count=$((retry_count + 1))
        if [[ "${retry_count}" -lt "${max_retries}" ]]; then
            log_warning "下载失败，重试中 (${retry_count}/${max_retries})..."
            sleep 2
            rm -f "${dest}" 2>/dev/null || true
        fi
    done

    log_error "下载失败，已重试 ${max_retries} 次: ${url}"
    return 1
}

# ============================================
# PATH 管理函数
# ============================================

# 备份 PATH 环境变量
# 参数: backup_dir (可选，默认 ~/.local/share/system_basic_env)
backup_path() {
    local backup_dir="${1:-${HOME}/.local/share/system_basic_env}"
    mkdir -p "${backup_dir}" || return 1
    local backup_file="${backup_dir}/path_backup_$(date +%Y%m%d_%H%M%S).txt"
    printf "%s\n" "${PATH}" > "${backup_file}"
    log_info "PATH 已备份到: ${backup_file}"
}

# 添加 PATH 入口
# 参数: path_entry path_env_file (可选，默认 ~/.config/system_basic_env/path.env)
add_path_entry() {
    local path_entry="$1"
    local path_env_file="${2:-${HOME}/.config/system_basic_env/path.env}"

    if [[ -z "${path_entry}" ]]; then
        log_error "PATH 入口不能为空"
        return 1
    fi

    # 确保文件存在
    local path_env_dir=$(dirname "${path_env_file}")
    if [[ ! -d "${path_env_dir}" ]]; then
        mkdir -p "${path_env_dir}" || return 1
    fi
    touch "${path_env_file}" || return 1

    # 检查路径是否已存在，避免重复添加
    if grep -qxF "export PATH=\"${path_entry}:\$PATH\"" "${path_env_file}" 2>/dev/null; then
        log_info "PATH 入口已存在: ${path_entry}"
        return 0
    fi

    # 追加路径到文件
    echo "export PATH=\"${path_entry}:\$PATH\"" >> "${path_env_file}"
    log_info "PATH 入口已记录: ${path_entry}"
}

# 准备 PATH 管理
# 参数: backup_dir (可选)
prepare_path_management() {
    local backup_dir="${1:-${HOME}/.local/share/system_basic_env}"
    backup_path "${backup_dir}"
    add_path_entry "/usr/local/bin"
    add_path_entry "${HOME}/.local/bin"
    add_path_entry "${HOME}/.cargo/bin"
}

# ============================================
# 日志管理函数
# ============================================

# 确保必要的目录存在
# 参数: log_dir state_dir config_dir
ensure_directories() {
    local log_dir="${1:-${HOME}/.local/share/system_basic_env/logs}"
    local state_dir="${2:-${HOME}/.local/share/system_basic_env}"
    local config_dir="${3:-${HOME}/.config/system_basic_env}"

    mkdir -p "${log_dir}" "${state_dir}" "${config_dir}" || {
        log_error "无法创建必要的目录"
        return 1
    }
    log_info "目录已创建: ${log_dir}, ${state_dir}, ${config_dir}"
}

# ============================================
# 权限检查函数
# ============================================

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限，请使用 sudo 运行"
        return 1
    fi
    return 0
}

# 检测安装用户（用于 AUR 构建）
# 返回: INSTALL_USER 变量
detect_install_user() {
    if [[ -n "${SUDO_USER:-}" ]] && [[ "${SUDO_USER}" != "root" ]]; then
        INSTALL_USER="${SUDO_USER}"
    elif [[ -n "${PKEXEC_UID:-}" ]]; then
        INSTALL_USER="$(id -un "${PKEXEC_UID}")"
    else
        log_error "请使用 sudo 运行此脚本，以便使用非特权用户进行 AUR 构建任务"
        return 1
    fi
    log_info "非特权用户: ${INSTALL_USER}"
    return 0
}

# ============================================
# 语义版本比较（bash 3.2 / MSYS2 兼容）
# ============================================

# 从 --version 输出解析 semver，stdout: major minor patch
parse_semver() {
    local text="$1"
    local major minor patch digits
    digits=$(printf '%s' "$text" | tr -cd '0-9.')
    major=$(printf '%s' "$digits" | cut -d. -f1)
    minor=$(printf '%s' "$digits" | cut -d. -f2)
    patch=$(printf '%s' "$digits" | cut -d. -f3)
    [[ -z "$major" ]] && major="0"
    [[ -z "$minor" ]] && minor="0"
    [[ -z "$patch" ]] && patch="0"
    echo "$major $minor $patch"
}

# 比较两个 semver 字符串；op: lt|le|eq|ge|gt
# 返回 0 表示关系成立
compare_semver() {
    local ver_a="$1"
    local op="$2"
    local ver_b="$3"
    local a_m a_n a_p b_m b_n b_p
    read -r a_m a_n a_p <<< "$(parse_semver "$ver_a")"
    read -r b_m b_n b_p <<< "$(parse_semver "$ver_b")"

    local cmp=0
    if [[ "$a_m" -lt "$b_m" ]]; then cmp=-1
    elif [[ "$a_m" -gt "$b_m" ]]; then cmp=1
    elif [[ "$a_n" -lt "$b_n" ]]; then cmp=-1
    elif [[ "$a_n" -gt "$b_n" ]]; then cmp=1
    elif [[ "$a_p" -lt "$b_p" ]]; then cmp=-1
    elif [[ "$a_p" -gt "$b_p" ]]; then cmp=1
    fi

    case "$op" in
        lt) [[ "$cmp" -lt 0 ]] ;;
        le) [[ "$cmp" -le 0 ]] ;;
        eq) [[ "$cmp" -eq 0 ]] ;;
        ge) [[ "$cmp" -ge 0 ]] ;;
        gt) [[ "$cmp" -gt 0 ]] ;;
        *) return 1 ;;
    esac
}

# ============================================
# 代理与 chezmoi 模板执行
# ============================================

ensure_proxy_for_download() {
    if type chezmoi_setup_proxy &>/dev/null; then
        chezmoi_setup_proxy "${PROXY:-}"
    else
        setup_proxy "${PROXY:-${http_proxy:-http://127.0.0.1:7890}}"
    fi
}

# 渲染并执行 chezmoi run_once 模板（补装缺失项）
# 参数: template_abs_path, chezmoi_source_dir
run_chezmoi_install_script() {
    local template_path="$1"
    local source_dir="${2:-${CHEZMOI_SOURCE_DIR:-}}"
    local config_file="${HOME}/.config/chezmoi/chezmoi.toml"

    if [[ ! -f "$template_path" ]]; then
        echo "[ERROR] Template not found: $template_path" >&2
        return 1
    fi
    if ! command -v chezmoi &>/dev/null; then
        echo "[ERROR] chezmoi not found, cannot execute template" >&2
        return 1
    fi

    ensure_proxy_for_download

    local rel_path="${template_path#"${source_dir}/"}"
    rel_path="${rel_path#./}"
    if [[ "$rel_path" == "$template_path" ]]; then
        rel_path="$(basename "$template_path")"
    fi

    echo "[INFO] Running install template: $rel_path" >&2
    # 须 --file + 绝对路径；否则 chezmoi 把路径当模板字面量，bash 会报 command not found
    local chezmoi_args=(execute-template --file)
    if [[ -f "$config_file" ]]; then
        chezmoi_args+=(--config "$config_file")
    fi
    if [[ -n "$source_dir" && -d "$source_dir" ]]; then
        chezmoi_args+=(--source "$source_dir")
    fi
    chezmoi_args+=("$template_path")

    if ! chezmoi "${chezmoi_args[@]}" 2>&1 | bash; then
        echo "[WARNING] Install template failed: $rel_path" >&2
        return 1
    fi
    return 0
}

# ============================================
# 包管理器升级
# ============================================

upgrade_brew_package() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    if ! command -v brew &>/dev/null; then
        echo "[WARNING] brew not found, skip upgrade: $name" >&2
        return 1
    fi
    echo "[INFO] Upgrading via brew: $name" >&2
    # macOS：有代理则保留（实测 7890→GitHub 稳于卸代理直连清华 git 易卡）；
    # 始终 HOMEBREW_NO_AUTO_UPDATE=1，避免 upgrade 隐式 brew update 卡住
    _brew_macos_prepare_env
    local ret=0
    if brew list "$name" &>/dev/null; then
        if type _brew_is_intel_macos &>/dev/null && _brew_is_intel_macos; then
            echo "[INFO] macOS Intel: brew upgrade $name (no bottles; may compile from source for several minutes)" >&2
            # HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK 不拦 formula 自己的 outdated 依赖；
            # fastfetch 会拖 imagemagick 源码编译，Xcode 警告后长时间无输出（易被当成卡死）
            if type _brew_intel_should_skip_heavy_dep_upgrade &>/dev/null \
                && _brew_intel_should_skip_heavy_dep_upgrade "$name"; then
                echo "[INFO] Skip brew upgrade $name: would rebuild heavy deps from source (imagemagick/llvm/...). Keep installed version." >&2
                if type _brew_link_existing_keg &>/dev/null; then
                    _brew_link_existing_keg "$name"
                fi
                _brew_macos_restore_env
                return 0
            fi
            if type _brew_intel_run_with_heartbeat &>/dev/null; then
                _brew_intel_run_with_heartbeat "$name" brew upgrade "$name" || ret=1
            else
                brew upgrade "$name" || ret=1
            fi
        else
            brew upgrade "$name" || ret=1
        fi
    else
        if type _brew_is_intel_macos &>/dev/null && _brew_is_intel_macos; then
            echo "[INFO] macOS Intel: brew install $name (no bottles; may compile from source for several minutes)" >&2
            if type _brew_intel_run_with_heartbeat &>/dev/null; then
                _brew_intel_run_with_heartbeat "$name" brew install "$name" || ret=1
            else
                brew install "$name" || ret=1
            fi
        else
            brew install "$name" || ret=1
        fi
    fi
    if type _brew_link_existing_keg &>/dev/null; then
        _brew_link_existing_keg "$name"
    fi
    _brew_macos_restore_env
    return $ret
}

upgrade_brew_cask() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    if ! command -v brew &>/dev/null; then
        return 1
    fi
    echo "[INFO] Upgrading cask via brew: $name" >&2
    _brew_macos_prepare_env
    local ret=0
    if brew list --cask "$name" &>/dev/null; then
        brew upgrade --cask "$name" || ret=1
    else
        brew install --cask "$name" || ret=1
    fi
    _brew_macos_restore_env
    return $ret
}

upgrade_pacman_package() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    echo "[INFO] Upgrading via pacman: $name" >&2
    if [[ "${PLATFORM:-}" == "windows" ]]; then
        pacman.exe -Sy --noconfirm 2>/dev/null || true
        pacman.exe -S --noconfirm "$name" 2>/dev/null || return 1
    else
        sudo pacman -Sy --noconfirm 2>/dev/null || true
        sudo pacman -S --noconfirm "$name" 2>/dev/null || return 1
    fi
    return 0
}

upgrade_apt_package() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    echo "[INFO] Upgrading via apt: $name" >&2
    sudo apt-get update -qq 2>/dev/null || true
    if dpkg -l "$name" 2>/dev/null | grep -q '^ii'; then
        sudo apt-get install --only-upgrade -y "$name" 2>/dev/null || return 1
    else
        sudo apt-get install -y "$name" 2>/dev/null || return 1
    fi
    return 0
}

# winget 升级失败是否应走 MSIX 用户级 sideload（InstallService 禁用 / 安装技术不一致）
# 参数: output [exit_code]
# 返回: 0=应 sideload, 1=否
winget_output_needs_msix_sideload() {
    local output="$1"
    local rc="${2:-1}"

    if [[ "$rc" -eq 0 ]]; then
        return 1
    fi
    # 已最新：中文 winget 也常返回 43，不能单凭 exit code 判断
    if printf '%s' "$output" | grep -qiE \
        'No applicable update|No available upgrade|No newer package versions|找不到可用的升级|没有可用的升级|没有可用的较新|已是最新'; then
        return 1
    fi
    if printf '%s' "$output" | grep -qiE \
        '0x80070422|InstallService|无法启动服务|安装技术|installer technology'; then
        return 0
    fi
    return 1
}

# 从 winget download 目录选出主包（排除 UI.Xaml / VCLibs 等依赖）
# 参数: dir
# stdout: 主包路径
find_primary_msix_in_dir() {
    local dir="$1"
    local f base
    [[ -n "$dir" && -d "$dir" ]] || return 1

    while IFS= read -r f; do
        [[ -z "$f" || ! -f "$f" ]] && continue
        echo "$f"
        return 0
    done < <(find "$dir" -type f \( \
        -iname '*WindowsTerminal*.msix' -o \
        -iname '*WindowsTerminal*.msixbundle' -o \
        -iname '*WindowsTerminal*.appxbundle' -o \
        -iname 'install-x64.msix' -o \
        -iname 'install-arm64.msix' -o \
        -iname '*OhMyPosh*.msix' -o \
        -iname '*OhMyPosh*.msixbundle' -o \
        -iname '*Oh My Posh*.msix' -o \
        -iname '*posh*.msix' \
        \) 2>/dev/null | LC_ALL=C sort)

    while IFS= read -r f; do
        [[ -z "$f" || ! -f "$f" ]] && continue
        base="${f##*/}"
        case "$base" in
            *UI.Xaml*|*VCLibs*|*NET.Native*|*DesktopAppInstaller*) continue ;;
        esac
        echo "$f"
        return 0
    done < <(find "$dir" -type f \( \
        -iname '*.msix' -o -iname '*.msixbundle' -o -iname '*.appxbundle' \
        \) 2>/dev/null | LC_ALL=C sort)
    return 1
}

# 列出目录中的 MSIX 依赖包（须先于主包 Add-AppxPackage）
# 参数: dir
# stdout: 每行一个路径
find_msix_dependency_files() {
    local dir="$1"
    [[ -n "$dir" && -d "$dir" ]] || return 1
    find "$dir" -type f \( \
        -iname '*UI.Xaml*.msix' -o -iname '*UI.Xaml*.appx' -o \
        -iname '*VCLibs*.msix' -o -iname '*VCLibs*.appx' -o \
        -iname '*NET.Native*.msix' -o -iname '*NET.Native*.appx' \
        \) 2>/dev/null | LC_ALL=C sort
}

_windows_process_running() {
    local name="$1"
    [[ -n "$name" ]] || return 1
    powershell.exe -NoProfile -Command \
        "if (Get-Process -Name '${name}' -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" \
        >/dev/null 2>&1
}

_win_path_for_powershell() {
    local path="$1"
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$path"
    else
        printf '%s\n' "$path"
    fi
}

# 用户级 Add-AppxPackage（无需管理员，仅需 AppXSvc）
# 参数: windows_path
_add_appx_package() {
    local win_path="$1"
    local ps_path
    ps_path="${win_path//\'/\'\'}"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
        "Add-AppxPackage -Path '${ps_path}'"
}

# 对目录内依赖 + 主包执行 Add-AppxPackage
# 参数: dir
_add_appx_packages_from_dir() {
    local dir="$1"
    local dep primary dep_win primary_win
    [[ -n "$dir" && -d "$dir" ]] || return 1

    primary="$(find_primary_msix_in_dir "$dir" || true)"
    if [[ -z "$primary" || ! -f "$primary" ]]; then
        echo "[WARNING] No primary MSIX package found in ${dir}" >&2
        return 1
    fi

    while IFS= read -r dep; do
        [[ -z "$dep" || ! -f "$dep" ]] && continue
        dep_win="$(_win_path_for_powershell "$dep")"
        echo "[INFO] Adding AppX dependency: ${dep##*/}" >&2
        _add_appx_package "$dep_win" >/dev/null 2>&1 || true
    done < <(find_msix_dependency_files "$dir" || true)

    primary_win="$(_win_path_for_powershell "$primary")"
    echo "[INFO] Adding AppX package: ${primary##*/}" >&2
    if _add_appx_package "$primary_win"; then
        echo "[SUCCESS] MSIX sideload installed: ${primary##*/}" >&2
        return 0
    fi
    echo "[WARNING] Add-AppxPackage failed for ${primary##*/}" >&2
    return 1
}

# winget download + Add-AppxPackage，绕过 InstallService / 安装技术不一致
# 参数: winget_id
upgrade_winget_msix_sideload() {
    local id="$1"
    local dest
    [[ -n "$id" ]] || return 1
    if ! command -v winget &>/dev/null; then
        echo "[WARNING] winget not found, skip MSIX sideload: $id" >&2
        return 1
    fi

    if [[ "$id" == "Microsoft.WindowsTerminal" ]] && _windows_process_running WindowsTerminal; then
        echo "[WARNING] Windows Terminal is running; skip MSIX sideload to avoid 0x80073D02. Close WT and retry." >&2
        return 1
    fi

    dest="${HOME}/Downloads/${id}_winget_msix"
    mkdir -p "$dest" || return 1
    ensure_proxy_for_download

    echo "[INFO] Downloading MSIX via winget: $id -> ${dest}" >&2
    if ! winget download --id "$id" --source winget --download-directory "$dest" \
        --accept-source-agreements --accept-package-agreements; then
        echo "[WARNING] winget download failed: $id" >&2
        return 1
    fi

    _add_appx_packages_from_dir "$dest"
}

upgrade_winget_id() {
    local id="$1"
    local output=""
    local rc=0
    [[ -z "$id" ]] && return 1
    if ! command -v winget &>/dev/null; then
        echo "[WARNING] winget not found, skip upgrade: $id" >&2
        return 1
    fi
    echo "[INFO] Upgrading via winget: $id" >&2
    # --source winget：避开 msstore（7890 MITM 易触发 0x8a15005e）
    if winget list --id "$id" --source winget &>/dev/null 2>&1; then
        output="$(winget upgrade --id "$id" -e --source winget --accept-source-agreements --accept-package-agreements 2>&1)" || rc=$?
    else
        output="$(winget install --id "$id" -e --source winget --accept-source-agreements --accept-package-agreements 2>&1)" || rc=$?
    fi
    if [[ -n "$output" ]]; then
        printf '%s\n' "$output" >&2
    fi
    if [[ "$rc" -eq 0 ]]; then
        return 0
    fi
    if winget_output_needs_msix_sideload "$output" "$rc"; then
        echo "[INFO] winget upgrade failed (rc=${rc}), trying MSIX sideload: $id" >&2
        upgrade_winget_msix_sideload "$id" && return 0
    fi
    return 1
}

upgrade_package_by_manager() {
    local pkg="$1"
    [[ -z "$pkg" ]] && return 1
    if [[ -z "${PACKAGE_MANAGER:-}" ]]; then
        detect_os_and_package_manager || return 1
    fi
    case "$PACKAGE_MANAGER" in
        brew)   upgrade_brew_package "$pkg" ;;
        pacman) upgrade_pacman_package "$pkg" ;;
        apt)    upgrade_apt_package "$pkg" ;;
        dnf)    sudo dnf upgrade -y "$pkg" 2>/dev/null || sudo dnf install -y "$pkg" ;;
        yum)    sudo yum update -y "$pkg" 2>/dev/null || sudo yum install -y "$pkg" ;;
        winget) upgrade_winget_id "$pkg" ;;
        *)      echo "[WARNING] Unsupported package manager for upgrade: $PACKAGE_MANAGER" >&2; return 1 ;;
    esac
}

# ============================================
# fnm / uv / npm 升级
# ============================================

_ensure_fnm_env() {
    if command -v fnm &>/dev/null; then
        eval "$(fnm env 2>/dev/null)" || true
        hash -r 2>/dev/null || true
    fi
}

# WSL 与 Windows 宿主机独立：只有 Windows 盘符上的路径才算 interop
# /mnt/c、/mnt/d：Windows 盘；/mnt/host/c：少见的盘符暴露
# /mnt/host/wslg/.../fnm_multishells、/mnt/wslg/...：WSL 本机（WSLg），不是 Windows npm
# Git Bash 的 /c/Users/... 不是 interop（本就在 Windows 里）
_is_windows_interop_path() {
    local cmd_path="${1:-}"
    [[ -z "$cmd_path" ]] && return 1
    case "$cmd_path" in
        /mnt/[a-z]/*|/mnt/[A-Z]/*)
            return 0
            ;;
        /mnt/host/[a-z]/*|/mnt/host/[A-Z]/*)
            return 0
            ;;
    esac
    if type chezmoi_is_wsl &>/dev/null && chezmoi_is_wsl; then
        :
    elif type is_wsl &>/dev/null && is_wsl; then
        :
    else
        return 1
    fi
    case "$cmd_path" in
        *AppData/Roaming/npm*|[A-Za-z]:[\\/]*)
            return 0
            ;;
    esac
    return 1
}

# WSL：把本地 fnm npm global bin 前置；当前 npm 已是 interop 则拒绝
_wsl_prepend_npm_global_bin() {
    local npm_prefix npm_path
    if type chezmoi_is_wsl &>/dev/null; then
        chezmoi_is_wsl || return 0
    elif type is_wsl &>/dev/null; then
        is_wsl || return 0
    else
        return 0
    fi

    command -v npm >/dev/null 2>&1 || return 0
    npm_path="$(command -v npm 2>/dev/null || true)"
    if _is_windows_interop_path "$npm_path"; then
        echo "[WARNING] npm resolves via Windows interop (${npm_path}); skip Windows npm prefix" >&2
        return 1
    fi

    npm_prefix="$(npm prefix -g 2>/dev/null || true)"
    [[ -n "$npm_prefix" && -d "${npm_prefix}/bin" ]] || return 0
    if _is_windows_interop_path "$npm_prefix"; then
        return 1
    fi
    # 始终置顶：路径可能已在 PATH 后面，Windows AppData npm 会抢先
    export PATH="${npm_prefix}/bin:${PATH}"
    hash -r 2>/dev/null || true
}

# 便携超时（macOS 无 GNU timeout；Git Bash / Linux 通用）
# 参数: seconds command [args...]
# 超时或命令失败返回非 0
_run_with_timeout() {
    local secs="$1"
    shift
    local cmd_pid watchdog_pid rc=0
    "$@" </dev/null &
    cmd_pid=$!
    (
        sleep "$secs"
        if kill -0 "$cmd_pid" 2>/dev/null; then
            echo "[WARNING] Command timed out after ${secs}s" >&2
            kill "$cmd_pid" 2>/dev/null || true
            sleep 3
            kill -0 "$cmd_pid" 2>/dev/null && kill -9 "$cmd_pid" 2>/dev/null || true
        fi
    ) &
    watchdog_pid=$!
    wait "$cmd_pid" || rc=$?
    kill "$watchdog_pid" 2>/dev/null || true
    wait "$watchdog_pid" 2>/dev/null || true
    return "$rc"
}

# 会话内走国内 npm 镜像（不写 ~/.npmrc）。官方 Cloudflare 经 7890 约 1 Mbps；
# npmmirror 在 FIClash Domestic/DIRECT。覆盖：NPM_REGISTRY=https://registry.npmjs.org
_npm_apply_china_mirror() {
    export npm_config_registry="${NPM_REGISTRY:-https://registry.npmmirror.com}"
    local hosts="registry.npmmirror.com,cdn.npmmirror.com,npmmirror.com"
    local current="${NO_PROXY:-${no_proxy:-}}"
    local host
    if [[ "$npm_config_registry" != *npmmirror.com* ]]; then
        return 0
    fi
    local IFS=','
    for host in $hosts; do
        [[ -n "$host" ]] || continue
        case ",${current}," in
            *",${host},"*) ;;
            *)
                if [[ -n "$current" ]]; then
                    current="${current},${host}"
                else
                    current="$host"
                fi
                ;;
        esac
    done
    export NO_PROXY="$current"
    export no_proxy="$current"
}

_npm_global_installed_version() {
    local pkg="$1"
    local line
    line="$(npm list -g --depth=0 "$pkg" 2>/dev/null | tr -d '\r')"
    printf '%s\n' "$line" | awk -v p="$pkg" '
        index($0, p "@") {
            sub(".*" p "@", "", $0)
            gsub(/[[:space:]]+/, "", $0)
            print $0
            exit
        }'
}

_npm_latest_version() {
    local pkg="$1"
    local line
    local timeout_secs="${NPM_VIEW_TIMEOUT_SECS:-30}"
    _npm_apply_china_mirror
    line="$(_run_with_timeout "$timeout_secs" npm view "$pkg" version || true)"
    line="$(printf '%s' "$line" | tr -d '\r' | awk 'NF { line=$0 } END { gsub(/[[:space:]]+/, "", line); print line }')"
    printf '%s' "$line"
}

# fnm 升级（多 OS/WSL 兼容）
# 注意：新版 fnm（>=1.36）已移除 self-update 子命令（1.38.1 实测 unrecognized subcommand），
# 升级路径：包管理器（brew/winget/pacman）→ 官方安装脚本（Linux/WSL/Git Bash）
# 返回: 0=已最新或升级完成, 1=升级失败（非关键，调用方勿阻断）
ensure_fnm_latest() {
    if ! command -v fnm &>/dev/null; then
        return 1
    fi

    local before after
    before="$(fnm --version 2>/dev/null | head -n1 || true)"

    # 兼容旧版 fnm：仍有 self-update 子命令的安装直接用它
    if fnm self-update 2>/dev/null; then
        return 0
    fi

    ensure_proxy_for_download
    echo "[INFO] Updating fnm (current: ${before:-unknown})..." >&2

    # 1) 包管理器优先：brew（macOS）/ winget（Windows）/ pacman（Arch）
    case "${PACKAGE_MANAGER:-}" in
        brew)
            upgrade_brew_package "fnm" 2>/dev/null && _fnm_verify_upgrade "$before" && return 0
            ;;
        winget)
            upgrade_winget_id "Schniz.fnm" 2>/dev/null && _fnm_verify_upgrade "$before" && return 0
            ;;
        pacman)
            upgrade_pacman_package "fnm" 2>/dev/null && _fnm_verify_upgrade "$before" && return 0
            ;;
    esac

    # 2) 官方安装脚本回退（Linux/WSL 下载 release 二进制；Git Bash 下载 fnm-windows.zip）
    #    macOS 官方脚本默认走 Homebrew，已在上方尝试，跳过避免重复
    if [[ "${PLATFORM:-}" != "darwin" ]]; then
        # --skip-shell：不修改 shell rc；脚本自动检测现有安装目录（$HOME/.fnm 等）
        if curl -fsSL --max-time 120 "https://fnm.vercel.app/install" 2>/dev/null \
            | bash -s -- --skip-shell >/dev/null 2>&1; then
            if _fnm_verify_upgrade "$before"; then
                return 0
            fi
        fi
    fi

    # 3) 最终版本核对：未变化视为已最新（不刷 WARNING）；变化则成功
    hash -r 2>/dev/null || true
    after="$(fnm --version 2>/dev/null | head -n1 || true)"
    if [[ -n "$after" && -n "$before" && "$after" != "$before" ]]; then
        echo "[SUCCESS] fnm upgraded: ${after}" >&2
        return 0
    fi
    if [[ -n "$before" ]]; then
        echo "[INFO] fnm is up to date: ${before} (manual upgrade: https://github.com/Schniz/fnm/releases)" >&2
        return 0
    fi
    echo "[WARNING] fnm upgrade failed; manual: https://github.com/Schniz/fnm/releases" >&2
    return 1
}

# 升级后核对 fnm 版本是否变化（变化即升级成功）
# 返回: 0=版本已变化
_fnm_verify_upgrade() {
    local before="$1"
    local after
    hash -r 2>/dev/null || true
    after="$(fnm --version 2>/dev/null | head -n1 || true)"
    [[ -n "$after" && -n "$before" && "$after" != "$before" ]]
}

ensure_uv_latest() {
    if ! command -v uv &>/dev/null; then
        return 1
    fi

    local before after uv_path
    before="$(uv --version 2>/dev/null | head -n1 || true)"
    uv_path="$(command -v uv || true)"

    echo "[INFO] Updating uv (current: ${before:-unknown})..." >&2

    # standalone 安装（官方安装脚本）支持 self-update
    if uv self update 2>/dev/null; then
        hash -r 2>/dev/null || true
        after="$(uv --version 2>/dev/null | head -n1 || true)"
        if [[ -n "$after" && -n "$before" && "$after" != "$before" ]]; then
            echo "[SUCCESS] uv upgraded: ${after}" >&2
        else
            echo "[INFO] uv is up to date: ${before:-unknown}" >&2
        fi
        return 0
    fi

    # 包管理器安装（choco/brew/winget 等）：uv self-update 仅对 standalone 安装可用
    # 按路径特征识别（避免每次 install 刷 WARNING）
    case "$uv_path" in
        *chocolatey*|*choco*|*brew*|*Cellar*|*WinGet*|*winget*|*/usr/bin/*|*/usr/local/bin/*)
            echo "[INFO] uv installed via package manager (${uv_path}); upgrade via package manager if needed (current: ${before:-unknown})" >&2
            return 0
            ;;
    esac

    echo "[WARNING] uv self update failed; manual: https://docs.astral.sh/uv/getting-started/installation/ (current: ${before:-unknown})" >&2
    return 1
}

ensure_npm_global_latest() {
    local spec="$1"
    [[ -z "$spec" ]] && return 1
    _ensure_fnm_env
    _wsl_prepend_npm_global_bin || true
    if ! command -v npm &>/dev/null; then
        echo "[WARNING] npm not found, skip: $spec" >&2
        return 1
    fi

    local npm_path
    npm_path="$(command -v npm 2>/dev/null || true)"
    if _is_windows_interop_path "$npm_path"; then
        echo "[WARNING] npm resolves via Windows interop (${npm_path}); skip $spec (use WSL fnm npm)" >&2
        return 1
    fi

    ensure_proxy_for_download
    _npm_apply_china_mirror
    local npm_target="$spec"
    if [[ "$spec" != *"@"* ]] || [[ "$spec" == @* ]]; then
        npm_target="${spec}@latest"
    fi

    local installed latest
    installed="$(_npm_global_installed_version "$spec" || true)"
    if [[ -n "$installed" ]]; then
        latest="$(_npm_latest_version "$spec" || true)"
        if [[ -z "$latest" ]]; then
            echo "[WARNING] Failed to resolve latest version for $spec; skip reinstall" >&2
            return 0
        fi
        if compare_semver "$installed" eq "$latest" || compare_semver "$installed" ge "$latest"; then
            echo "[INFO] $spec already up-to-date (${installed})" >&2
            return 0
        fi
        echo "[INFO] Updating npm global: $spec (${installed} -> ${latest})" >&2
        npm_target="${spec}@${latest}"
    else
        echo "[INFO] Installing/upgrading npm global: $npm_target" >&2
    fi

    local timeout_secs="${NPM_GLOBAL_INSTALL_TIMEOUT_SECS:-180}"
    local rc=0
    _run_with_timeout "$timeout_secs" npm install -g --no-fund --no-audit "$npm_target" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "[WARNING] npm install -g ${npm_target} failed or timed out (${timeout_secs}s)" >&2
        return 1
    fi
    return 0
}

ensure_neovim_minimum() {
    if is_nvim_version_ge_0_11; then
        return 0
    fi
    echo "[INFO] Neovim below 0.11.0, triggering install/upgrade..." >&2
    return 1
}

ensure_rmux_pinned() {
    local pinned="${1:-0.5.0}"
    if command -v rmux &>/dev/null; then
        local ver_line
        ver_line="$(rmux -V 2>/dev/null | head -n1 || true)"
        if [[ "$ver_line" == *"${pinned}"* ]]; then
            return 0
        fi
    fi
    echo "[INFO] rmux missing or wrong version (want ${pinned}), reinstall needed..." >&2
    return 1
}

# Windows MSVC triple（GitHub Releases asset 名）
_windows_github_msvc_triple() {
    case "$(uname -m 2>/dev/null || echo x86_64)" in
        aarch64|arm64|ARM64) echo "aarch64-pc-windows-msvc" ;;
        *) echo "x86_64-pc-windows-msvc" ;;
    esac
}

# 从 GitHub Releases zip 安装单个 exe 到 ~/.local/bin（仅 Windows，无管理员）
# 参数: owner repo exe_basename（不含 .exe，如 rg / delta）
install_github_release_zip_exe() {
    local owner="$1"
    local repo="$2"
    local exe_base="$3"
    local dest_dir="${HOME}/.local/bin"
    local triple zip_path extract_dir api_json asset_url asset_name tmp_dir found_exe

    if [[ "${PLATFORM:-}" != "windows" ]]; then
        echo "[WARNING] GitHub release zip install is Windows-only" >&2
        return 1
    fi
    if [[ -z "$owner" || -z "$repo" || -z "$exe_base" ]]; then
        echo "[ERROR] install_github_release_zip_exe: owner repo exe required" >&2
        return 1
    fi

    mkdir -p "$dest_dir" || return 1
    ensure_proxy_for_download
    triple="$(_windows_github_msvc_triple)"
    tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t ghrel)" || return 1
    extract_dir="${tmp_dir}/extract"
    mkdir -p "$extract_dir"

    echo "[INFO] Installing ${exe_base} from GitHub ${owner}/${repo} (${triple})..." >&2

    if command -v gh &>/dev/null; then
        if ! gh release download -R "${owner}/${repo}" -p "*${triple}.zip" -D "$tmp_dir" --clobber 2>/dev/null; then
            if [[ "$triple" != "x86_64-pc-windows-msvc" ]]; then
                triple="x86_64-pc-windows-msvc"
                echo "[INFO] Retrying with ${triple}..." >&2
                gh release download -R "${owner}/${repo}" -p "*${triple}.zip" -D "$tmp_dir" --clobber 2>/dev/null || {
                    rm -rf "$tmp_dir"
                    return 1
                }
            else
                rm -rf "$tmp_dir"
                return 1
            fi
        fi
        zip_path="$(find "$tmp_dir" -maxdepth 1 -name "*.zip" -type f 2>/dev/null | head -n 1)"
    else
        api_json="$(curl -fsSL "https://api.github.com/repos/${owner}/${repo}/releases/latest" 2>/dev/null || true)"
        if [[ -z "$api_json" ]]; then
            echo "[WARNING] Failed to query GitHub API for ${owner}/${repo}" >&2
            rm -rf "$tmp_dir"
            return 1
        fi
        asset_url="$(printf '%s\n' "$api_json" | grep -oE "https://[^\"]*${triple}\\.zip" | head -n 1 || true)"
        if [[ -z "$asset_url" && "$triple" != "x86_64-pc-windows-msvc" ]]; then
            triple="x86_64-pc-windows-msvc"
            asset_url="$(printf '%s\n' "$api_json" | grep -oE "https://[^\"]*${triple}\\.zip" | head -n 1 || true)"
        fi
        if [[ -z "$asset_url" ]]; then
            echo "[WARNING] No Windows zip asset found for ${owner}/${repo}" >&2
            rm -rf "$tmp_dir"
            return 1
        fi
        asset_name="${asset_url##*/}"
        zip_path="${tmp_dir}/${asset_name}"
        if ! download_with_progress "$asset_url" "$zip_path" 120 3; then
            rm -rf "$tmp_dir"
            return 1
        fi
    fi

    if [[ -z "${zip_path:-}" || ! -f "$zip_path" ]]; then
        echo "[WARNING] Zip not found after download" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    if command -v unzip &>/dev/null; then
        unzip -qo "$zip_path" -d "$extract_dir" || {
            rm -rf "$tmp_dir"
            return 1
        }
    else
        echo "[WARNING] unzip not found; cannot extract ${zip_path}" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    found_exe="$(find "$extract_dir" -type f \( -name "${exe_base}.exe" -o -name "${exe_base}" \) 2>/dev/null | head -n 1)"
    if [[ -z "$found_exe" || ! -f "$found_exe" ]]; then
        echo "[WARNING] ${exe_base}.exe not found in release zip" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    cp -f "$found_exe" "${dest_dir}/${exe_base}.exe" || {
        rm -rf "$tmp_dir"
        return 1
    }
    chmod +x "${dest_dir}/${exe_base}.exe" 2>/dev/null || true
    # 当前会话优先使用 ~/.local/bin
    export PATH="${dest_dir}:${PATH}"
    hash -r 2>/dev/null || true
    rm -rf "$tmp_dir"

    if command -v "$exe_base" &>/dev/null; then
        echo "[SUCCESS] ${exe_base} installed to ${dest_dir}" >&2
        return 0
    fi
    echo "[WARNING] ${exe_base} copied to ${dest_dir} but not on PATH yet" >&2
    return 0
}

# Oh My Posh Windows GitHub asset（非 zip，官方 posh-windows-*.exe）
oh_my_posh_windows_github_asset() {
    case "$(uname -m 2>/dev/null || echo x86_64)" in
        aarch64|arm64|ARM64) echo "posh-windows-arm64.exe" ;;
        *) echo "posh-windows-amd64.exe" ;;
    esac
}

# 从 MSIX 抽出 oh-my-posh.exe 到 dest
# 参数: msix_path dest_exe
_extract_oh_my_posh_exe_from_msix() {
    local msix="$1"
    local dest_exe="$2"
    local tmp found dest_dir
    [[ -f "$msix" ]] || return 1
    command -v unzip >/dev/null 2>&1 || return 1
    dest_dir="$(dirname "$dest_exe")"
    mkdir -p "$dest_dir" || return 1
    # 勿用 Git Bash /tmp：unzip 报成功但文件会被清掉
    tmp="${dest_exe}.extract.$$"
    rm -rf "$tmp"
    mkdir -p "$tmp" || return 1
    if ! unzip -qo "$msix" "oh-my-posh.exe" -d "$tmp" 2>/dev/null; then
        unzip -qo "$msix" -d "$tmp" 2>/dev/null || {
            rm -rf "$tmp"
            return 1
        }
    fi
    found="$(find "$tmp" -type f -name 'oh-my-posh.exe' 2>/dev/null | head -n 1)"
    if [[ -z "$found" || ! -f "$found" ]]; then
        rm -rf "$tmp"
        return 1
    fi
    cp -f "$found" "$dest_exe" || {
        rm -rf "$tmp"
        return 1
    }
    rm -rf "$tmp"
    return 0
}

# 将 Oh My Posh 装到 ~/.local/bin（无管理员；绕过 EXE→MSIX 安装技术不一致）
# 优先 winget download + 从 MSIX 抽 exe（本机代理下比 GitHub 直连稳）
# 返回: 0=已写入, 1=失败
install_oh_my_posh_from_github() {
    local dest_dir="${HOME}/.local/bin"
    local dest download_dir primary asset url tmp_dir api_json

    if [[ "${PLATFORM:-}" != "windows" ]]; then
        local _uname
        _uname="$(uname -s 2>/dev/null || true)"
        if [[ ! "$_uname" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
            echo "[WARNING] Oh My Posh GitHub exe install is Windows-only" >&2
            return 1
        fi
    fi

    mkdir -p "$dest_dir" || return 1
    ensure_proxy_for_download
    dest="${dest_dir}/oh-my-posh.exe"

    if command -v winget >/dev/null 2>&1; then
        download_dir="${HOME}/Downloads/JanDeDobbeleer.OhMyPosh_winget_msix"
        mkdir -p "$download_dir" || return 1
        echo "[INFO] Downloading Oh My Posh MSIX via winget..." >&2
        if winget download --id JanDeDobbeleer.OhMyPosh --source winget \
            --download-directory "$download_dir" \
            --accept-source-agreements --accept-package-agreements; then
            primary="$(find_primary_msix_in_dir "$download_dir" || true)"
            if [[ -n "$primary" && -f "$primary" ]] && _extract_oh_my_posh_exe_from_msix "$primary" "$dest"; then
                chmod +x "$dest" 2>/dev/null || true
                export PATH="${dest_dir}:${PATH}"
                hash -r 2>/dev/null || true
                _add_appx_packages_from_dir "$download_dir" >/dev/null 2>&1 || true
                echo "[SUCCESS] oh-my-posh installed to ${dest} ($("$dest" --version 2>/dev/null || echo ok))" >&2
                return 0
            fi
            echo "[WARNING] Failed to extract oh-my-posh.exe from MSIX, trying GitHub..." >&2
        fi
    fi

    asset="$(oh_my_posh_windows_github_asset)"
    tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t ompgh)" || return 1
    echo "[INFO] Installing oh-my-posh from GitHub (${asset})..." >&2
    api_json="$(curl -fsSL "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest" 2>/dev/null || true)"
    url="$(printf '%s\n' "$api_json" | grep -oE "https://[^\"]*/${asset}" | head -n 1 || true)"
    if [[ -z "$url" ]]; then
        url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/${asset}"
    fi
    if ! download_with_progress "$url" "${tmp_dir}/${asset}" 180 3; then
        rm -rf "$tmp_dir"
        return 1
    fi
    cp -f "${tmp_dir}/${asset}" "$dest" || {
        rm -rf "$tmp_dir"
        return 1
    }
    chmod +x "$dest" 2>/dev/null || true
    export PATH="${dest_dir}:${PATH}"
    hash -r 2>/dev/null || true
    rm -rf "$tmp_dir"

    if command -v oh-my-posh &>/dev/null; then
        echo "[SUCCESS] oh-my-posh installed to ${dest} ($("$dest" --version 2>/dev/null || echo ok))" >&2
        return 0
    fi
    echo "[WARNING] oh-my-posh copied to ${dest} but not on PATH yet" >&2
    return 0
}

install_rg_from_github() {
    install_github_release_zip_exe "BurntSushi" "ripgrep" "rg"
}

install_delta_from_github() {
    install_github_release_zip_exe "dandavison" "delta" "delta"
}

# Windows：winget 失败或不在 PATH 时，对 rg/delta 走 GitHub Releases
# 参数: tool_cmd（rg|delta）
try_windows_github_fallback_for_tool() {
    local tool="$1"
    [[ "${PLATFORM:-}" == "windows" ]] || return 1
    case "$tool" in
        rg) install_rg_from_github ;;
        delta) install_delta_from_github ;;
        *) return 1 ;;
    esac
}

# 安装 common-tools 单项：包管理器 →（Windows rg/delta）GitHub 回退
# 参数: tool_cmd package_id
install_common_tool_with_fallback() {
    local tool="$1"
    local pkg="$2"

    if [[ -n "$pkg" ]] && install_package "$pkg"; then
        hash -r 2>/dev/null || true
        if type common_tool_command_present &>/dev/null && common_tool_command_present "$tool"; then
            return 0
        fi
        if command -v "$tool" &>/dev/null; then
            return 0
        fi
        echo "[WARNING] $tool package install reported success but command not found" >&2
    fi

    if try_windows_github_fallback_for_tool "$tool"; then
        hash -r 2>/dev/null || true
        if type common_tool_command_present &>/dev/null && common_tool_command_present "$tool"; then
            return 0
        fi
        if command -v "$tool" &>/dev/null; then
            return 0
        fi
    fi

    return 1
}

upgrade_common_tools_packages() {
    local cmd pkg
    if type get_common_tool_commands &>/dev/null; then
        for cmd in $(get_common_tool_commands); do
            if type common_tool_command_present &>/dev/null && common_tool_command_present "$cmd"; then
                pkg="$(get_common_tool_package "$cmd" "${PLATFORM:-}" "${PACKAGE_MANAGER:-}")"
                [[ -z "$pkg" ]] && continue
                if ! upgrade_package_by_manager "$pkg"; then
                    # 已通过别的途径安装（如 ~/.local/bin），apt 无包时不算失败
                    echo "[INFO] $cmd present; skip upgrade via ${PACKAGE_MANAGER:-pkg} (package unavailable or already newest)" >&2
                fi
                continue
            fi
            if ! command -v "$cmd" &>/dev/null; then
                pkg="$(get_common_tool_package "$cmd" "${PLATFORM:-}" "${PACKAGE_MANAGER:-}")"
                if [[ -z "$pkg" ]]; then
                    # 当前平台无此包（packages.conf 为 "-"），跳过（与 [5/6] 检测一致）
                    continue
                fi
                if ! upgrade_package_by_manager "$pkg"; then
                    echo "[WARNING] Failed to install missing tool via package manager: $cmd" >&2
                fi
                hash -r 2>/dev/null || true
                if type common_tool_command_present &>/dev/null; then
                    if common_tool_command_present "$cmd"; then
                        continue
                    fi
                elif command -v "$cmd" &>/dev/null; then
                    continue
                fi
                try_windows_github_fallback_for_tool "$cmd" || true
                if type common_tool_command_present &>/dev/null; then
                    common_tool_command_present "$cmd" && continue
                fi
                if ! command -v "$cmd" &>/dev/null; then
                    echo "[WARNING] Failed to install missing tool: $cmd" >&2
                fi
                continue
            fi
            pkg="$(get_common_tool_package "$cmd" "${PLATFORM:-}" "${PACKAGE_MANAGER:-}")"
            [[ -z "$pkg" ]] && continue
            if ! upgrade_package_by_manager "$pkg"; then
                echo "[INFO] $cmd present; skip upgrade via ${PACKAGE_MANAGER:-pkg} (package unavailable or already newest)" >&2
            fi
        done
    fi
    return 0
}

# ============================================
# 日志函数（如果 common.sh 不可用）
# ============================================

if ! type log_info &> /dev/null; then
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
fi

# ============================================
# run_once 脚本上下文加载器
# 减少 run_once_* 脚本顶部 ~50 行重复 boilerplate
# 用法：在 run_once 脚本顶部调用：
#   load_run_once_context "$(dirname "${BASH_SOURCE[0]}")" "脚本名称"
