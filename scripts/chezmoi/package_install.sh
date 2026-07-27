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
            brew install "$package_name" || return 1
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
        brew upgrade "$name" || ret=1
    else
        brew install "$name" || ret=1
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

upgrade_winget_id() {
    local id="$1"
    [[ -z "$id" ]] && return 1
    if ! command -v winget &>/dev/null; then
        echo "[WARNING] winget not found, skip upgrade: $id" >&2
        return 1
    fi
    echo "[INFO] Upgrading via winget: $id" >&2
    # --source winget：避开 msstore（7890 MITM 易触发 0x8a15005e）
    if winget list --id "$id" --source winget &>/dev/null 2>&1; then
        winget upgrade --id "$id" -e --source winget --accept-source-agreements --accept-package-agreements 2>/dev/null || return 1
    else
        winget install --id "$id" -e --source winget --accept-source-agreements --accept-package-agreements 2>/dev/null || return 1
    fi
    return 0
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

ensure_fnm_latest() {
    if ! command -v fnm &>/dev/null; then
        return 1
    fi
    echo "[INFO] Updating fnm..." >&2
    if fnm self-update 2>/dev/null; then
        return 0
    fi
    echo "[WARNING] fnm self-update not available or failed" >&2
    return 1
}

ensure_uv_latest() {
    if ! command -v uv &>/dev/null; then
        return 1
    fi
    echo "[INFO] Updating uv..." >&2
    if uv self update 2>/dev/null; then
        return 0
    fi
    echo "[WARNING] uv self update failed" >&2
    return 1
}

ensure_npm_global_latest() {
    local spec="$1"
    [[ -z "$spec" ]] && return 1
    _ensure_fnm_env
    if ! command -v npm &>/dev/null; then
        echo "[WARNING] npm not found, skip: $spec" >&2
        return 1
    fi
    ensure_proxy_for_download
    local npm_target="$spec"
    if [[ "$spec" != *"@"* ]] || [[ "$spec" == @* ]]; then
        npm_target="${spec}@latest"
    fi
    echo "[INFO] Installing/upgrading npm global: $npm_target" >&2
    npm install -g "$npm_target" 2>/dev/null || return 1
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
        if command -v "$tool" &>/dev/null; then
            return 0
        fi
        echo "[WARNING] $tool package install reported success but command not found" >&2
    fi

    if try_windows_github_fallback_for_tool "$tool"; then
        hash -r 2>/dev/null || true
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
            [[ "$cmd" == "trash" ]] && { command -v trash &>/dev/null || command -v trash-cli &>/dev/null; } && continue
            if ! command -v "$cmd" &>/dev/null; then
                pkg="$(get_common_tool_package "$cmd" "${PLATFORM:-}" "${PACKAGE_MANAGER:-}")"
                if [[ -n "$pkg" ]]; then
                    if ! upgrade_package_by_manager "$pkg"; then
                        echo "[WARNING] Failed to install missing tool via package manager: $cmd" >&2
                    fi
                    hash -r 2>/dev/null || true
                fi
                if ! command -v "$cmd" &>/dev/null; then
                    try_windows_github_fallback_for_tool "$cmd" || true
                fi
                if ! command -v "$cmd" &>/dev/null; then
                    echo "[WARNING] Failed to install missing tool: $cmd" >&2
                fi
                continue
            fi
            pkg="$(get_common_tool_package "$cmd" "${PLATFORM:-}" "${PACKAGE_MANAGER:-}")"
            [[ -z "$pkg" ]] && continue
            upgrade_package_by_manager "$pkg" || echo "[WARNING] Failed to upgrade tool: $cmd" >&2
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
