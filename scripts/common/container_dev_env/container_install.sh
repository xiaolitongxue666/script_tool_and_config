#!/bin/bash

# ============================================
# 容器内安装脚本
# 基于 scripts/linux/system_basic_env/install_common_tools.sh
# 适配容器环境（无需 sudo，使用 root）
# ============================================

set -euo pipefail

# 代理配置（从环境变量获取）
PROXY_URL="${PROXY:-${http_proxy:-${https_proxy:-}}}"

# 日志函数
log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_warning() {
    echo "[WARNING] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

# 配置代理环境变量
setup_proxy_env() {
    if [ -n "$PROXY_URL" ]; then
        # 如果 PROXY 不包含 http://，添加它
        if [[ ! "$PROXY_URL" =~ ^http:// ]] && [[ ! "$PROXY_URL" =~ ^https:// ]]; then
            PROXY_URL="http://$PROXY_URL"
        fi
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
        log_info "代理已设置: $PROXY_URL"
    else
        log_info "未设置代理"
    fi
}

# 备份文件
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup" || true
        log_info "已备份: $file -> ${file}.backup"
    fi
}

# 配置中国镜像源（参考 Linux 脚本）
configure_mirrors() {
    backup_file "/etc/pacman.d/mirrorlist"
        cat > /etc/pacman.d/mirrorlist <<'EOF'
## Aliyun (HTTPS, primary)
Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
## USTC (HTTPS, secondary)
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
## Tencent Cloud (HTTPS, tertiary)
Server = https://mirrors.cloud.tencent.com/archlinux/$repo/os/$arch
## Huawei Cloud (HTTPS)
Server = https://mirrors.huaweicloud.com/repository/archlinux/$repo/os/$arch
## Nanjing University (HTTPS)
Server = https://mirrors.nju.edu.cn/archlinux/$repo/os/$arch
## Chongqing University (HTTPS)
Server = https://mirrors.cqu.edu.cn/archlinux/$repo/os/$arch
## Neusoft (HTTPS)
Server = https://mirrors.neusoft.edu.cn/archlinux/$repo/os/$arch
## Lanzhou University (HTTPS)
Server = https://mirror.lzu.edu.cn/archlinux/$repo/os/$arch
## Southern University of Science and Technology (HTTPS)
Server = https://mirrors.sustech.edu.cn/archlinux/$repo/os/$arch
EOF
    log_info "中国镜像源配置完成（9 个可用镜像）"
}

# 配置 pacman 代理（始终移除代理配置，pacman 使用国内源直连）
configure_pacman_proxy() {
    # 使用临时文件来安全地修改配置
    local tmp_file
    tmp_file="$(mktemp)"
    local has_xfercommand=0

    # 检查是否存在 XferCommand
    while IFS= read -r line; do
        if [[ "$line" =~ ^XferCommand ]]; then
            has_xfercommand=1
            break
        fi
    done < /etc/pacman.conf

    # 始终移除 XferCommand 配置，pacman 使用国内源直连
    if [ "$has_xfercommand" -eq 1 ]; then
        log_info "移除 XferCommand 配置，pacman 将使用直连（中国镜像源）"
        while IFS= read -r line; do
            # 跳过所有 XferCommand 行
            if [[ "$line" =~ ^XferCommand ]]; then
                continue
            fi
            echo "$line" >> "$tmp_file"
        done < /etc/pacman.conf
        mv "$tmp_file" /etc/pacman.conf
        log_info "XferCommand 已移除，pacman 将使用直连"
    else
        log_info "Pacman 已配置为使用直连（中国镜像源）"
    fi
}

# 优化 pacman 配置（参考 Linux 脚本的 tune_pacman）
tune_pacman() {
    backup_file "/etc/pacman.conf"

    # 如果配置文件中没有 [options] 部分的关键配置，则添加
        if ! grep -q "^HoldPkg" /etc/pacman.conf; then
        # 在 [options] 部分添加配置
            sed -i '/^\[options\]/a\
HoldPkg     = pacman glibc\
Architecture = auto\
CheckSpace\
SigLevel    = Required DatabaseOptional\
LocalFileSigLevel = Optional' /etc/pacman.conf
        fi

    # 确保 ParallelDownloads 已启用并设置合理值
    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        # 如果 ParallelDownloads 被注释，取消注释并设置值
        sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
        # 如果还是没有，在 [options] 部分添加
        if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
            sed -i '/^\[options\]/a\
ParallelDownloads = 5' /etc/pacman.conf
        fi
    fi
    # 确保 ParallelDownloads 有合理的值（至少为 3）
    sed -i 's/^ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]*/ParallelDownloads = 5/' /etc/pacman.conf

    # 确保 core, extra 仓库使用镜像列表（community 已合并到 extra，不再需要单独配置）
        if ! grep -q "^Include = /etc/pacman.d/mirrorlist" /etc/pacman.conf; then
            sed -i '/^\[core\]/,/^\[/ { /^\[core\]/a\
Include = /etc/pacman.d/mirrorlist
}' /etc/pacman.conf
            sed -i '/^\[extra\]/,/^\[/ { /^\[extra\]/a\
Include = /etc/pacman.d/mirrorlist
}' /etc/pacman.conf
        fi

    # 移除已废弃的 [community] 配置（如果存在）
    if grep -q "^\[community\]" /etc/pacman.conf; then
        sed -i '/^\[community\]/,/^\[/ { /^\[community\]/d; /^SigLevel/d; /^Include/d; }' /etc/pacman.conf
        log_info "已移除已废弃的 [community] 配置（已合并到 [extra]）"
    fi

    # 添加 archlinuxcn 源（8 个可用镜像）
    # 注意：archlinuxcn-keyring 要求不使用 SigLevel，使用默认设置
        if ! grep -q "archlinuxcn" /etc/pacman.conf; then
            cat >> /etc/pacman.conf <<'EOF'
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
Server = https://mirrors.aliyun.com/archlinuxcn/$arch
Server = https://mirrors.cloud.tencent.com/archlinuxcn/$arch
Server = https://mirrors.huaweicloud.com/repository/archlinuxcn/$arch
Server = https://mirrors.nju.edu.cn/archlinuxcn/$arch
Server = https://mirrors.cqu.edu.cn/archlinuxcn/$arch
Server = https://mirror.lzu.edu.cn/archlinuxcn/$arch
Server = https://mirrors.sustech.edu.cn/archlinuxcn/$arch
EOF
    else
        # 如果已存在 archlinuxcn 配置，移除 SigLevel 行（如果存在）
        if grep -q "^\[archlinuxcn\]" /etc/pacman.conf; then
            sed -i '/^\[archlinuxcn\]/,/^\[/ { /^SigLevel/d; }' /etc/pacman.conf
            log_info "已从 [archlinuxcn] 部分移除 SigLevel（archlinuxcn-keyring 要求）"
        fi
    fi

    configure_pacman_proxy
    log_info "Pacman 配置已优化"
}

# 条件配置镜像源（参考 Linux 脚本）
configure_mirrors_conditional() {
    if [ -z "$PROXY_URL" ]; then
        log_info "配置中国镜像源（无代理）"
        configure_mirrors
        tune_pacman
        log_success "中国镜像源和 pacman 配置完成"
    else
        log_info "使用代理，不修改镜像源"
        # 配置 pacman 使用代理（如果还没有配置）
        if ! grep -q "^XferCommand" /etc/pacman.conf; then
            sed -i '/^\[options\]/a\XferCommand = /usr/bin/curl -C - -f %u > %o' /etc/pacman.conf
            log_info "已配置 pacman 使用代理"
        fi
    fi
}

# 使用 chezmoi 应用配置文件
apply_config_with_chezmoi() {
    log_info "使用 chezmoi 应用配置文件..."

    PROJECT_ROOT="/tmp/project"
    CHEZMOI_SOURCE_DIR="$PROJECT_ROOT/.chezmoi"
    CHEZMOI_DEST_DIR="/root"

    # 检查 chezmoi 是否已安装
    if ! command -v chezmoi &> /dev/null; then
        log_error "chezmoi 未安装，无法应用配置"
        return 1
    fi

    # 检查源目录是否存在
    if [ ! -d "$CHEZMOI_SOURCE_DIR" ]; then
        log_error "chezmoi 源目录不存在: $CHEZMOI_SOURCE_DIR"
        return 1
    fi

    log_info "chezmoi 源目录: $CHEZMOI_SOURCE_DIR"
    log_info "chezmoi 目标目录: $CHEZMOI_DEST_DIR"

    # 创建必要的目录
    # 1. chezmoi 状态目录（chezmoi 需要此目录存储状态信息）
    CHEZMOI_STATE_DIR="$CHEZMOI_DEST_DIR/.local/share/chezmoi"
    if [ ! -d "$CHEZMOI_STATE_DIR" ]; then
        log_info "创建 chezmoi 状态目录: $CHEZMOI_STATE_DIR"
        mkdir -p "$CHEZMOI_STATE_DIR"
    else
        log_info "chezmoi 状态目录已存在: $CHEZMOI_STATE_DIR"
    fi

    # 2. 确保 .local/bin 目录存在（chezmoi 可能需要）
    if [ ! -d "$CHEZMOI_DEST_DIR/.local/bin" ]; then
        log_info "创建目录: $CHEZMOI_DEST_DIR/.local/bin"
        mkdir -p "$CHEZMOI_DEST_DIR/.local/bin"
    fi

    # 设置 chezmoi 环境变量
    # CHEZMOI_SOURCE_DIR: 指定源状态目录
    export CHEZMOI_SOURCE_DIR="$CHEZMOI_SOURCE_DIR"

    # 设置 HOME 环境变量，chezmoi 会将配置应用到 $HOME
    # 这样我们可以将配置应用到 /root 而不是默认的 $HOME
    export HOME="$CHEZMOI_DEST_DIR"

    # 禁用 chezmoi pager（避免进入交互模式）
    export CHEZMOI_PAGER=""
    export PAGER="cat"

    # 设置代理环境变量（如果提供）
    # 注意：chezmoi 模板中的 .data.proxy 会从环境变量 PROXY 或 http_proxy 读取
    if [ -n "$PROXY_URL" ]; then
        export PROXY="$PROXY_URL"
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
    fi

    # 确保 PATH 包含必要的工具路径（在多阶段构建中很重要）
    export PATH="/root/.cargo/bin:/root/.local/share/fnm:/root/.local/bin:$PATH"

    # 切换到项目目录
    cd "$PROJECT_ROOT"

    # 验证 chezmoi 配置
    log_info "验证 chezmoi 配置..."
    log_info "CHEZMOI_SOURCE_DIR: $CHEZMOI_SOURCE_DIR"
    log_info "HOME: $HOME"
    log_info "当前目录: $(pwd)"

    # 检查 chezmoi 是否能识别源目录
    if chezmoi source-path >/dev/null 2>&1; then
        CHEZMOI_SOURCE_PATH=$(chezmoi source-path)
        log_info "chezmoi 识别的源路径: $CHEZMOI_SOURCE_PATH"
        if [ "$CHEZMOI_SOURCE_PATH" != "$CHEZMOI_SOURCE_DIR" ]; then
            log_warning "chezmoi 源路径不匹配: 期望 $CHEZMOI_SOURCE_DIR，实际 $CHEZMOI_SOURCE_PATH"
        fi
    else
        log_warning "chezmoi source-path 命令失败"
    fi

    # 先检查源目录内容
    if [ -d "$CHEZMOI_SOURCE_DIR" ]; then
        log_info "chezmoi 源目录内容:"
        ls -la "$CHEZMOI_SOURCE_DIR" | head -10 || true
    fi

    # 检查源目录中的模板文件
    if [ -f "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" ]; then
        log_info "找到 .zshrc 模板文件"
        TEMPLATE_SIZE=$(stat -c%s "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" 2>/dev/null || echo "unknown")
        log_info "模板文件大小: $TEMPLATE_SIZE 字节"
    else
        log_warning "未找到 .zshrc 模板文件: $CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl"
        log_info "源目录中的文件:"
        ls -la "$CHEZMOI_SOURCE_DIR" | grep -E "zshrc|bashrc|tmux" || true
    fi

    # 关键步骤：在应用配置之前，清理可能存在的旧配置文件
    # Oh My Zsh 可能创建了小的 .zshrc 文件，需要删除以确保 chezmoi 能正确应用
    log_info "清理可能存在的旧配置文件..."
    CONFIG_FILES_TO_CLEAN=(
        "$CHEZMOI_DEST_DIR/.zshrc"
        "$CHEZMOI_DEST_DIR/.bashrc"
        "$CHEZMOI_DEST_DIR/.tmux.conf"
    )

    for config_file in "${CONFIG_FILES_TO_CLEAN[@]}"; do
        if [ -f "$config_file" ]; then
            FILE_SIZE=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
            # 如果文件太小（小于 1000 字节），可能是 Oh My Zsh 创建的占位文件，删除它
            if [ "$FILE_SIZE" -lt 1000 ]; then
                log_info "删除小的配置文件: $config_file ($FILE_SIZE 字节)"
                rm -f "$config_file"
            else
                log_info "保留现有配置文件: $config_file ($FILE_SIZE 字节)"
            fi
        fi
    done

    # 清理 chezmoi 源目录中的不一致状态
    # 如果同时存在 .toml 和 .toml.tmpl 文件，删除非模板文件以避免 "inconsistent state" 错误
    log_info "清理 chezmoi 源目录中的不一致状态..."
    if [ -d "$CHEZMOI_SOURCE_DIR/dot_config" ]; then
        find "$CHEZMOI_SOURCE_DIR/dot_config" -type f \( -name "*.toml" ! -name "*.tmpl" \) | while read -r file; do
            tmpl_file="${file}.tmpl"
            if [ -f "$tmpl_file" ]; then
                log_info "删除非模板文件以避免不一致状态: $file"
                rm -f "$file"
            fi
        done
    fi

    # 清理 chezmoi 状态目录（强制重新应用）
    # 这样可以确保 chezmoi 不会认为文件已经是最新的
    if [ -d "$CHEZMOI_STATE_DIR" ]; then
        log_info "清理 chezmoi 状态目录，强制重新应用配置..."
        rm -rf "$CHEZMOI_STATE_DIR"/*
        log_info "chezmoi 状态目录已清理"
    fi

    # 执行 chezmoi apply
    # 参考 install.sh 和 deploy.sh 的使用方式
    # 重要：需要指定 --config 参数，让 chezmoi 正确读取 .chezmoi/chezmoi.toml 中的数据配置
    CHEZMOI_CONFIG_FILE="$CHEZMOI_SOURCE_DIR/chezmoi.toml"

    log_info "执行: chezmoi apply -v --force"
    log_info "源目录: $CHEZMOI_SOURCE_DIR"
    log_info "配置文件: $CHEZMOI_CONFIG_FILE"
    log_info "目标目录: $HOME"
    log_info "当前工作目录: $(pwd)"

    # 检查配置文件是否存在
    if [ ! -f "$CHEZMOI_CONFIG_FILE" ]; then
        log_warning "chezmoi 配置文件不存在: $CHEZMOI_CONFIG_FILE"
        log_info "将使用默认配置（可能缺少数据变量）"
    else
        log_info "找到 chezmoi 配置文件: $CHEZMOI_CONFIG_FILE"
    fi

    CHEZMOI_EXIT_CODE=0
    CHEZMOI_OUTPUT=""

    # 使用 --source 和 --config 参数，确保 chezmoi 能正确读取配置和数据
    # 注意：chezmoi 需要从源目录运行，或者使用 --source 参数
    # 使用 --config 确保能读取到 .chezmoi/chezmoi.toml 中的数据配置
    if [ -f "$CHEZMOI_CONFIG_FILE" ]; then
        if CHEZMOI_OUTPUT=$(chezmoi apply --source="$CHEZMOI_SOURCE_DIR" --config="$CHEZMOI_CONFIG_FILE" -v --force 2>&1); then
            CHEZMOI_EXIT_CODE=0
            log_success "chezmoi 配置应用成功"
        else
            CHEZMOI_EXIT_CODE=$?
            log_warning "chezmoi apply 返回非零退出码: $CHEZMOI_EXIT_CODE"
            # 即使退出码非零，也可能部分成功，继续处理
        fi
    else
        # 如果没有配置文件，只使用 --source
        log_warning "未找到配置文件，使用默认配置"
        if CHEZMOI_OUTPUT=$(chezmoi apply --source="$CHEZMOI_SOURCE_DIR" -v --force 2>&1); then
            CHEZMOI_EXIT_CODE=0
            log_success "chezmoi 配置应用成功"
        else
            CHEZMOI_EXIT_CODE=$?
            log_warning "chezmoi apply 返回非零退出码: $CHEZMOI_EXIT_CODE"
        fi
    fi

    # 显示 chezmoi 输出（前 100 行）
    if [ -n "$CHEZMOI_OUTPUT" ]; then
        log_info "chezmoi 输出:"
        echo "$CHEZMOI_OUTPUT" | head -100
        if [ $(echo "$CHEZMOI_OUTPUT" | wc -l) -gt 100 ]; then
            log_info "... (还有更多输出)"
        fi
    else
        log_warning "chezmoi 没有输出（可能所有文件都是最新的或配置未正确应用）"
    fi

    # 如果失败，尝试诊断
    if [ $CHEZMOI_EXIT_CODE -ne 0 ]; then
        log_warning "chezmoi apply 失败，尝试诊断..."
        log_info "检查 chezmoi 状态:"
        chezmoi status 2>&1 | head -20 || true
        log_warning "继续执行，尝试手动应用配置文件"
    fi

    # 验证 .zshrc 文件
    if [ -f "$CHEZMOI_DEST_DIR/.zshrc" ]; then
        ZSHRC_SIZE=$(stat -f%z "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null || stat -c%s "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null || echo "0")
        log_info ".zshrc 文件大小: $ZSHRC_SIZE 字节"

        if [ "$ZSHRC_SIZE" -lt 1000 ]; then
            log_error ".zshrc 文件太小 ($ZSHRC_SIZE 字节)，配置可能未正确应用！"
            log_info ".zshrc 文件内容:"
            cat "$CHEZMOI_DEST_DIR/.zshrc" || true

            # 尝试手动应用 .zshrc
            log_warning "尝试手动应用 .zshrc 配置..."
            if [ -f "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" ]; then
                log_info "使用 chezmoi execute-template 手动解析 .zshrc 模板..."
                CHEZMOI_CONFIG_FILE="$CHEZMOI_SOURCE_DIR/chezmoi.toml"
                if [ -f "$CHEZMOI_CONFIG_FILE" ]; then
                    if chezmoi execute-template --config="$CHEZMOI_CONFIG_FILE" < "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" > "$CHEZMOI_DEST_DIR/.zshrc.new" 2>&1; then
                        NEW_SIZE=$(stat -c%s "$CHEZMOI_DEST_DIR/.zshrc.new" 2>/dev/null || stat -f%z "$CHEZMOI_DEST_DIR/.zshrc.new" 2>/dev/null || echo "0")
                        if [ "$NEW_SIZE" -gt 1000 ]; then
                            log_success "手动解析成功，新文件大小: $NEW_SIZE 字节"
                            mv "$CHEZMOI_DEST_DIR/.zshrc.new" "$CHEZMOI_DEST_DIR/.zshrc"
                            log_success "已替换 .zshrc 文件"
                        else
                            log_warning "手动解析的文件仍然太小: $NEW_SIZE 字节"
                            rm -f "$CHEZMOI_DEST_DIR/.zshrc.new"
                        fi
                    else
                        log_warning "手动解析失败，检查错误..."
                        if [ -f "$CHEZMOI_DEST_DIR/.zshrc.new" ]; then
                            log_info "部分生成的文件内容:"
                            head -10 "$CHEZMOI_DEST_DIR/.zshrc.new" || true
                            rm -f "$CHEZMOI_DEST_DIR/.zshrc.new"
                        fi
                    fi
                else
                    log_warning "chezmoi 配置文件不存在: $CHEZMOI_CONFIG_FILE"
                fi
            else
                log_warning "模板文件不存在: $CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl"
            fi
        else
            log_success ".zshrc 文件大小正常: $ZSHRC_SIZE 字节"
        fi
    else
        log_error ".zshrc 文件不存在！"
        # 尝试手动创建
        if [ -f "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" ]; then
            log_info "尝试手动创建 .zshrc..."
            CHEZMOI_CONFIG_FILE="$CHEZMOI_SOURCE_DIR/chezmoi.toml"
            if [ -f "$CHEZMOI_CONFIG_FILE" ]; then
                if chezmoi execute-template --config="$CHEZMOI_CONFIG_FILE" < "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" > "$CHEZMOI_DEST_DIR/.zshrc" 2>&1; then
                    NEW_SIZE=$(stat -c%s "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null || stat -f%z "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null || echo "0")
                    if [ "$NEW_SIZE" -gt 1000 ]; then
                        log_success "手动创建 .zshrc 成功，大小: $NEW_SIZE 字节"
                    else
                        log_warning "手动创建的 .zshrc 太小: $NEW_SIZE 字节"
                    fi
                else
                    log_error "手动创建 .zshrc 失败"
                fi
            else
                log_warning "chezmoi 配置文件不存在: $CHEZMOI_CONFIG_FILE"
            fi
        fi
    fi

    # 验证关键配置文件是否已创建，如果未创建则手动应用
    local config_files=(
        "$CHEZMOI_DEST_DIR/.zprofile:dot_zprofile.tmpl"
        "$CHEZMOI_DEST_DIR/.zshrc:dot_zshrc.tmpl"
        "$CHEZMOI_DEST_DIR/.bashrc:dot_bashrc.tmpl"
        "$CHEZMOI_DEST_DIR/.tmux.conf:dot_tmux.conf.tmpl"
    )

    local success_count=0
    for config_entry in "${config_files[@]}"; do
        IFS=':' read -r config_file template_file <<< "$config_entry"
        config_name=$(basename "$config_file")
        local file_size=0

        if [ -f "$config_file" ]; then
            file_size=$(stat -c%s "$config_file" 2>/dev/null || stat -f%z "$config_file" 2>/dev/null || echo "0")
            if [ "$file_size" -gt 100 ]; then
                log_success "配置文件已创建: $config_file ($file_size 字节)"
                success_count=$((success_count + 1))
                continue
            else
                log_warning "配置文件太小: $config_file ($file_size 字节)，尝试重新应用"
                rm -f "$config_file"
            fi
        fi

        # 如果文件不存在或太小，尝试手动应用
        if [ ! -f "$config_file" ] || [ "$file_size" -lt 100 ]; then
            log_warning "配置文件未创建或太小: $config_file"
            if [ -f "$CHEZMOI_SOURCE_DIR/$template_file" ]; then
                log_info "尝试手动应用 $config_name..."
                # 使用临时文件，成功后再移动
                TEMP_FILE="${config_file}.tmp"
                # 使用 --config 参数确保能读取数据配置
                CHEZMOI_CONFIG_FILE="$CHEZMOI_SOURCE_DIR/chezmoi.toml"
                if [ -f "$CHEZMOI_CONFIG_FILE" ]; then
                    if chezmoi execute-template --config="$CHEZMOI_CONFIG_FILE" < "$CHEZMOI_SOURCE_DIR/$template_file" > "$TEMP_FILE" 2>&1; then
                        NEW_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || stat -f%z "$TEMP_FILE" 2>/dev/null || echo "0")
                        if [ "$NEW_SIZE" -gt 100 ]; then
                            mv "$TEMP_FILE" "$config_file"
                            log_success "手动应用 $config_name 成功，大小: $NEW_SIZE 字节"
                            success_count=$((success_count + 1))
                        else
                            log_warning "手动应用的 $config_name 仍然太小: $NEW_SIZE 字节"
                            rm -f "$TEMP_FILE"
                        fi
                    else
                        log_warning "手动应用 $config_name 失败"
                        if [ -f "$TEMP_FILE" ]; then
                            log_info "错误输出:"
                            cat "$TEMP_FILE" | head -20 || true
                            rm -f "$TEMP_FILE"
                        fi
                        # 对于 .bashrc，如果模板应用失败，至少创建一个基本版本
                        if [ "$config_name" = ".bashrc" ]; then
                            log_info "为 .bashrc 创建基本配置..."
                            cat > "$config_file" <<'BASHRC_EOF'
# ~/.bashrc
# Basic bash configuration for container

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

# Load fnm
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
BASHRC_EOF
                            if [ -f "$config_file" ]; then
                                BASIC_SIZE=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
                                log_success "已创建基本 .bashrc 配置，大小: $BASIC_SIZE 字节"
                                success_count=$((success_count + 1))
                            fi
                        fi
                        # 对于 .zprofile，如果模板应用失败，创建一个基本版本（包含 fnm 初始化）
                        if [ "$config_name" = ".zprofile" ]; then
                            log_info "为 .zprofile 创建基本配置..."
                            cat > "$config_file" <<'ZPROFILE_EOF'
# ~/.zprofile
# Zsh profile configuration (loaded before .zshrc)

# PATH configuration
export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

# Initialize fnm (Fast Node Manager)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
ZPROFILE_EOF
                            if [ -f "$config_file" ]; then
                                BASIC_SIZE=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
                                log_success "已创建基本 .zprofile 配置，大小: $BASIC_SIZE 字节"
                                success_count=$((success_count + 1))
                            fi
                        fi
                    fi
                else
                    log_warning "chezmoi 配置文件不存在: $CHEZMOI_CONFIG_FILE，无法应用模板"
                    # 对于 .bashrc，如果配置文件不存在，至少创建一个基本版本
                    if [ "$config_name" = ".bashrc" ]; then
                        log_info "为 .bashrc 创建基本配置..."
                        cat > "$config_file" <<'BASHRC_EOF'
# ~/.bashrc
# Basic bash configuration for container

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

# Load fnm
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
BASHRC_EOF
                        if [ -f "$config_file" ]; then
                            BASIC_SIZE=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
                            log_success "已创建基本 .bashrc 配置，大小: $BASIC_SIZE 字节"
                            success_count=$((success_count + 1))
                        fi
                    fi
                    # 对于 .zprofile，如果配置文件不存在，创建一个基本版本
                    if [ "$config_name" = ".zprofile" ]; then
                        log_info "为 .zprofile 创建基本配置..."
                        cat > "$config_file" <<'ZPROFILE_EOF'
# ~/.zprofile
# Zsh profile configuration (loaded before .zshrc)

# PATH configuration
export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

# Initialize fnm (Fast Node Manager)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
ZPROFILE_EOF
                        if [ -f "$config_file" ]; then
                            BASIC_SIZE=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
                            log_success "已创建基本 .zprofile 配置，大小: $BASIC_SIZE 字节"
                            success_count=$((success_count + 1))
                        fi
                    fi
                fi
            else
                log_warning "模板文件不存在: $CHEZMOI_SOURCE_DIR/$template_file"
                # 如果模板不存在，对于 .zprofile 创建基本配置
                if [ "$config_name" = ".zprofile" ]; then
                    log_info "模板不存在，为 .zprofile 创建基本配置..."
                    cat > "$config_file" <<'ZPROFILE_EOF'
# ~/.zprofile
# Zsh profile configuration (loaded before .zshrc)

# PATH configuration
export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

# Initialize fnm (Fast Node Manager)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
ZPROFILE_EOF
                    if [ -f "$config_file" ]; then
                        BASIC_SIZE=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
                        log_success "已创建基本 .zprofile 配置，大小: $BASIC_SIZE 字节"
                        success_count=$((success_count + 1))
                    fi
                fi
            fi
        fi
    done

    # 验证 .zprofile 是否正确配置 fnm
    if [ -f "$CHEZMOI_DEST_DIR/.zprofile" ]; then
        log_info "检查 .zprofile 中的 fnm 配置..."
        if grep -q "fnm env" "$CHEZMOI_DEST_DIR/.zprofile" 2>/dev/null; then
            log_success ".zprofile 包含 fnm 初始化"
        else
            log_warning ".zprofile 缺少 fnm 初始化，添加基本配置..."
            # 在文件末尾添加 fnm 初始化
            cat >> "$CHEZMOI_DEST_DIR/.zprofile" <<'ZPROFILE_FNM_EOF'

# Initialize fnm (Fast Node Manager) - 由容器安装脚本添加
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
ZPROFILE_FNM_EOF
            log_success "已添加 fnm 初始化到 .zprofile"
        fi
    else
        log_warning ".zprofile 文件不存在，创建基本配置..."
        cat > "$CHEZMOI_DEST_DIR/.zprofile" <<'ZPROFILE_EOF'
# ~/.zprofile
# Zsh profile configuration (loaded before .zshrc)

# PATH configuration
export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

# Initialize fnm (Fast Node Manager)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi
ZPROFILE_EOF
        log_success "已创建 .zprofile 基本配置"
    fi

    # 验证 Oh My Zsh 配置
    if [ -f "$CHEZMOI_DEST_DIR/.zshrc" ]; then
        log_info "检查 Oh My Zsh 配置..."
        if [ -d "$CHEZMOI_DEST_DIR/.oh-my-zsh" ]; then
            log_success "Oh My Zsh 已安装: $CHEZMOI_DEST_DIR/.oh-my-zsh"

            # 检查插件目录
            ZSH_CUSTOM_PLUGINS="$CHEZMOI_DEST_DIR/.oh-my-zsh/custom/plugins"
            ZSH_PLUGINS_DIR="$CHEZMOI_DEST_DIR/.oh-my-zsh/plugins"
            if [ -d "$ZSH_CUSTOM_PLUGINS" ]; then
                log_info "检查自定义插件..."
                local plugins=(
                    "zsh-autosuggestions"
                    "zsh-syntax-highlighting"
                    "zsh-history-substring-search"
                    "zsh-completions"
                )
                for plugin in "${plugins[@]}"; do
                    if [ -d "$ZSH_CUSTOM_PLUGINS/$plugin" ]; then
                        log_success "  插件已安装: $plugin"
                    else
                        log_warning "  插件未安装: $plugin"
                        # 如果 zsh-completions 未安装，尝试安装
                        if [ "$plugin" = "zsh-completions" ]; then
                            log_info "  尝试安装 zsh-completions..."
                            if [ -n "$PROXY_URL" ]; then
                                export http_proxy="$PROXY_URL"
                                export https_proxy="$PROXY_URL"
                                export HTTP_PROXY="$PROXY_URL"
                                export HTTPS_PROXY="$PROXY_URL"
                            fi
                            if git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM_PLUGINS/zsh-completions" 2>&1; then
                                log_success "  zsh-completions 安装成功"
                            else
                                log_warning "  zsh-completions 安装失败"
                            fi
                        fi
                    fi
                done
                # 检查内置插件（如 copydir）
                log_info "检查内置插件..."
                if [ -d "$ZSH_PLUGINS_DIR/copydir" ]; then
                    log_success "  内置插件已存在: copydir"
                else
                    log_warning "  内置插件不存在: copydir（可能是 Oh My Zsh 版本问题，不影响使用）"
                fi
            fi
        else
            log_warning "Oh My Zsh 未安装: $CHEZMOI_DEST_DIR/.oh-my-zsh"
        fi

        # 检查 .zshrc 中的关键配置
        if grep -q "ZSH_THEME" "$CHEZMOI_DEST_DIR/.zshrc"; then
            THEME=$(grep "^ZSH_THEME=" "$CHEZMOI_DEST_DIR/.zshrc" | cut -d'"' -f2 || echo "未找到")
            log_info "Zsh 主题: $THEME"
        fi
    fi

    # 应用 dot_config 目录中的配置文件（如 starship.toml）
    log_info "应用 dot_config 目录中的配置文件..."
    if [ -d "$CHEZMOI_SOURCE_DIR/dot_config" ]; then
        find "$CHEZMOI_SOURCE_DIR/dot_config" -name "*.tmpl" -type f | while read -r tmpl_file; do
            # 计算目标文件路径
            # 例如: /tmp/project/.chezmoi/dot_config/starship/starship.toml.tmpl -> /root/.config/starship/starship.toml
            rel_path="${tmpl_file#$CHEZMOI_SOURCE_DIR/dot_config/}"
            rel_path="${rel_path%.tmpl}"  # 移除 .tmpl 后缀
            dest_file="$CHEZMOI_DEST_DIR/.config/$rel_path"
            dest_dir=$(dirname "$dest_file")

            # 确保目标目录存在
            mkdir -p "$dest_dir"

            # 如果目标文件不存在或太小，应用模板
            if [ ! -f "$dest_file" ] || [ $(stat -c%s "$dest_file" 2>/dev/null || echo "0") -lt 100 ]; then
                log_info "应用配置: $rel_path"
                # 使用 --config 参数确保能读取数据配置
                CHEZMOI_CONFIG_FILE="$CHEZMOI_SOURCE_DIR/chezmoi.toml"
                if [ -f "$CHEZMOI_CONFIG_FILE" ]; then
                    if chezmoi execute-template --config="$CHEZMOI_CONFIG_FILE" < "$tmpl_file" > "$dest_file" 2>&1; then
                        FILE_SIZE=$(stat -c%s "$dest_file" 2>/dev/null || echo "0")
                        if [ "$FILE_SIZE" -gt 100 ]; then
                            log_success "已应用配置: $dest_file ($FILE_SIZE 字节)"
                            success_count=$((success_count + 1))
                        else
                            log_warning "配置文件太小: $dest_file ($FILE_SIZE 字节)"
                            rm -f "$dest_file"
                        fi
                    else
                        log_warning "应用配置失败: $rel_path"
                        if [ -f "$dest_file" ]; then
                            log_info "错误输出:"
                            cat "$dest_file" | head -20 || true
                            rm -f "$dest_file"
                        fi
                    fi
                else
                    log_warning "chezmoi 配置文件不存在: $CHEZMOI_CONFIG_FILE，跳过 $rel_path"
                fi
            else
                log_info "配置已存在: $dest_file"
            fi
        done
    fi

    if [ $success_count -gt 0 ]; then
        log_success "已成功应用 $success_count 个配置文件"
    else
        log_warning "未成功应用任何配置文件"
    fi
}

# 安装 Node.js（使用 fnm，确保代理环境变量已设置）
install_nodejs_with_fnm() {
    log_info "安装 Node.js（使用 fnm）..."

    # 确保 PATH 包含 fnm
    export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

    # 检查 fnm 是否可用
    if ! command -v fnm >/dev/null 2>&1; then
        log_warning "fnm 未找到，跳过 Node.js 安装"
        return 0
    fi

    # 初始化 fnm 环境
    log_info "初始化 fnm 环境..."
    if [ -f "$HOME/.local/share/fnm/fnm" ]; then
        eval "$("$HOME/.local/share/fnm/fnm" env --use-on-cd)" || {
            log_warning "无法从用户目录初始化 fnm，尝试系统路径"
            eval "$(fnm env --use-on-cd)" || {
                log_warning "无法初始化 fnm 环境，跳过 Node.js 安装"
                return 0
            }
        }
    else
        eval "$(fnm env --use-on-cd)" || {
            log_warning "无法初始化 fnm 环境，跳过 Node.js 安装"
            return 0
        }
    fi

    # 检查是否已安装 Node.js
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null || echo "")
        if [ -n "$NODE_VERSION" ]; then
            log_success "Node.js 已安装: $NODE_VERSION"
            return 0
        fi
    fi

    # 设置代理环境变量（fnm 需要这些变量来下载 Node.js）
    if [ -n "$PROXY_URL" ]; then
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
        export all_proxy="$PROXY_URL"
        export ALL_PROXY="$PROXY_URL"
        log_info "已设置代理环境变量: $PROXY_URL"
    else
        log_warning "未设置代理，Node.js 安装可能失败"
    fi

    # 安装 Node.js LTS 版本
    log_info "使用 fnm 安装 Node.js LTS 版本..."
    log_info "注意：如果网络连接失败，请检查代理配置"
    log_info "代理环境变量: http_proxy=$http_proxy, https_proxy=$https_proxy"

    # 尝试安装 LTS 版本（使用 lts/* 表示最新的 LTS 版本）
    # fnm install lts/* 会安装最新的 LTS 版本
    if fnm install lts/* 2>&1; then
        # 安装成功后，使用 lts/* 激活
        fnm use lts/* 2>&1 || {
            # 如果 lts/* 不工作，尝试获取已安装的 LTS 版本
            INSTALLED_VERSION=$(fnm list 2>/dev/null | grep -i "lts" | head -n 1 | awk '{print $1}' || echo "")
            if [ -n "$INSTALLED_VERSION" ]; then
                fnm use "$INSTALLED_VERSION" 2>&1 || log_warning "无法激活 Node.js 版本: $INSTALLED_VERSION"
            else
                log_warning "无法激活 Node.js LTS"
            fi
        }

        # 重新初始化 fnm 环境
        eval "$(fnm env --use-on-cd)" || true

        # 验证安装
        if command -v node >/dev/null 2>&1; then
            NODE_VERSION=$(node --version 2>/dev/null || echo "")
            if [ -n "$NODE_VERSION" ]; then
                log_success "Node.js 安装成功: $NODE_VERSION"
                log_info "Node.js 路径: $(which node)"
            else
                log_warning "Node.js 安装完成但无法获取版本信息"
            fi
        else
            log_warning "Node.js 安装完成但不在 PATH 中"
        fi
    else
        log_warning "Node.js 安装失败（可能是网络问题），可在容器运行时手动安装: fnm install lts/*"
        return 0
    fi
}

# 安装 Neovim 配置
# 安装 TPM (Tmux Plugin Manager)
install_tpm() {
    log_info "安装 TPM (Tmux Plugin Manager)..."

    TPM_DIR="/root/.tmux/plugins/tpm"

    # 检查 TPM 是否已安装
    if [ -d "$TPM_DIR" ] && [ -f "${TPM_DIR}/tpm" ]; then
        log_success "TPM (Tmux Plugin Manager) 已安装"
    else
        log_info "开始安装 TPM (Tmux Plugin Manager)..."

        # 创建目录
        mkdir -p "$TPM_DIR"

        # 设置代理环境变量（如果提供）
        if [ -n "$PROXY_URL" ]; then
            export http_proxy="$PROXY_URL"
            export https_proxy="$PROXY_URL"
            export HTTP_PROXY="$PROXY_URL"
            export HTTPS_PROXY="$PROXY_URL"
            # 配置 git 使用代理
            git config --global http.proxy "$PROXY_URL" 2>/dev/null || true
            git config --global https.proxy "$PROXY_URL" 2>/dev/null || true
            log_info "使用代理安装 TPM: $PROXY_URL"
        fi

        # 克隆 TPM 仓库
        if git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>&1; then
            log_success "TPM (Tmux Plugin Manager) 安装成功"
        else
            log_warning "TPM (Tmux Plugin Manager) 安装失败"
            # 清理 git 代理配置
            if [ -n "$PROXY_URL" ]; then
                git config --global --unset http.proxy 2>/dev/null || true
                git config --global --unset https.proxy 2>/dev/null || true
            fi
            return 1
        fi

        # 清理 git 代理配置（如果之前设置了）
        if [ -n "$PROXY_URL" ]; then
            git config --global --unset http.proxy 2>/dev/null || true
            git config --global --unset https.proxy 2>/dev/null || true
        fi
    fi

    # 安装 tmux 插件（通过 TPM）
    log_info "安装 tmux 插件（通过 TPM）..."

    # 设置代理环境变量（如果提供）
    if [ -n "$PROXY_URL" ]; then
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
        git config --global http.proxy "$PROXY_URL" 2>/dev/null || true
        git config --global https.proxy "$PROXY_URL" 2>/dev/null || true
    fi

    # 解析 .tmux.conf 中的 @plugin 配置并直接安装插件
    # 注意：TPM 插件通常需要在 tmux 会话中通过 prefix + I 安装
    # 但我们可以直接解析配置并克隆插件仓库
    if [ -f "/root/.tmux.conf" ]; then
        log_info "从 .tmux.conf 解析插件配置..."
        # 提取所有 @plugin 配置（跳过注释和空行）
        PLUGINS=$(grep -E "^[[:space:]]*set[[:space:]]+-g[[:space:]]+@plugin" /root/.tmux.conf 2>/dev/null | sed "s/.*'\(.*\)'.*/\1/" | grep -v "^#" || true)
        if [ -n "$PLUGINS" ]; then
            for plugin in $PLUGINS; do
                # 跳过 TPM 本身（已经安装）
                if [ "$plugin" = "tmux-plugins/tpm" ]; then
                    continue
                fi
                # 提取插件名称（例如：catppuccin/tmux -> catppuccin-tmux）
                PLUGIN_NAME=$(echo "$plugin" | sed 's/\//-/g')
                PLUGIN_DIR="/root/.tmux/plugins/$PLUGIN_NAME"
                if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR"/*.tmux 2>/dev/null ] || [ -f "$PLUGIN_DIR"/*.sh 2>/dev/null ]; then
                    log_info "  插件已安装: $plugin"
                else
                    log_info "  安装插件: $plugin -> $PLUGIN_NAME"
                    # 构建 GitHub URL
                    if echo "$plugin" | grep -q "/"; then
                        GITHUB_URL="https://github.com/$plugin.git"
                        if git clone "$GITHUB_URL" "$PLUGIN_DIR" 2>&1; then
                            log_success "  插件安装成功: $plugin"
                        else
                            log_warning "  插件安装失败: $plugin（需要在 tmux 中按 prefix + I 手动安装）"
                        fi
                    fi
                fi
            done
        else
            log_warning "未找到 @plugin 配置，插件需要在 tmux 中手动安装（按 prefix + I）"
        fi
    else
        log_warning ".tmux.conf 不存在，无法自动安装插件"
    fi

    # 清理 git 代理配置
    if [ -n "$PROXY_URL" ]; then
        git config --global --unset http.proxy 2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
    fi

    return 0
}

install_neovim_config() {
    log_info "安装 Neovim 配置..."

    PROJECT_ROOT="/tmp/project"
    NVIM_SUBMODULE_DIR="$PROJECT_ROOT/dotfiles/nvim"
    NVIM_INSTALL_SCRIPT="$NVIM_SUBMODULE_DIR/install.sh"
    COMMON_LIB="$PROJECT_ROOT/scripts/common.sh"

    # 验证 scripts/common.sh 是否存在（Neovim 安装脚本需要）
    if [ ! -f "$COMMON_LIB" ]; then
        log_warning "scripts/common.sh 不存在: $COMMON_LIB"
        log_info "Neovim 安装脚本可能需要此文件，但会尝试继续"
    else
        log_info "找到 scripts/common.sh: $COMMON_LIB"
    fi

    if [ -f "$NVIM_INSTALL_SCRIPT" ]; then
        log_info "使用 Git Submodule 安装 Neovim 配置"
        cd "$PROJECT_ROOT" || log_error "无法切换到项目根目录"

        # 初始化 submodule（如果未初始化）
        if [ ! -f "$NVIM_SUBMODULE_DIR/init.lua" ] && [ ! -d "$NVIM_SUBMODULE_DIR/lua" ]; then
            git submodule update --init --recursive dotfiles/nvim || log_warning "Neovim submodule 初始化失败"
        fi

        # 确保 PATH 包含 uv 和 fnm 的路径
        # uv 安装在 ~/.cargo/bin，fnm 安装在 ~/.local/share/fnm
        export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"

        # 验证 uv 和 fnm 是否在 PATH 中
        log_info "检查 PATH 环境变量..."
        log_info "PATH: $PATH"

        if command -v uv >/dev/null 2>&1; then
            log_success "uv 已找到: $(uv --version 2>&1 | head -n 1)"
        else
            log_warning "uv 未在 PATH 中找到，尝试直接使用完整路径..."
            if [ -f "$HOME/.cargo/bin/uv" ]; then
                log_info "找到 uv: $HOME/.cargo/bin/uv"
                export PATH="$HOME/.cargo/bin:$PATH"
            else
                log_error "uv 未安装或不在预期位置"
            fi
        fi

        if command -v fnm >/dev/null 2>&1; then
            log_success "fnm 已找到: $(fnm --version 2>&1 | head -n 1)"
        else
            log_warning "fnm 未在 PATH 中找到，尝试直接使用完整路径..."
            if [ -f "$HOME/.local/share/fnm/fnm" ]; then
                log_info "找到 fnm: $HOME/.local/share/fnm/fnm"
                export PATH="$HOME/.local/share/fnm:$PATH"
            else
                log_error "fnm 未安装或不在预期位置"
            fi
        fi

        # 运行安装脚本
        chmod +x "$NVIM_INSTALL_SCRIPT"
        # 确保 PROJECT_ROOT 环境变量已设置（Neovim 安装脚本需要）
        export PROJECT_ROOT="$PROJECT_ROOT"

        # 验证 scripts/common.sh 是否可访问
        if [ -f "$COMMON_LIB" ]; then
            log_info "scripts/common.sh 可访问: $COMMON_LIB"
        else
            log_warning "scripts/common.sh 不可访问: $COMMON_LIB"
        fi

        if [ -n "$PROXY_URL" ]; then
            http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" \
            HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL" \
            USE_SYSTEM_NVIM_VENV=1 \
            INSTALL_USER=root \
            PROJECT_ROOT="$PROJECT_ROOT" \
            bash "$NVIM_INSTALL_SCRIPT" || log_warning "Neovim 配置安装失败"
        else
            USE_SYSTEM_NVIM_VENV=1 \
            INSTALL_USER=root \
            PROJECT_ROOT="$PROJECT_ROOT" \
            bash "$NVIM_INSTALL_SCRIPT" || log_warning "Neovim 配置安装失败"
        fi
        # 即使安装失败也继续，不阻止容器构建
        log_success "Neovim 配置安装流程完成"
    else
        log_warning "Neovim 安装脚本未找到: $NVIM_INSTALL_SCRIPT"
    fi
}

# 验证已安装的软件包
verify_installed_packages() {
    log_info "验证已安装的软件包..."

    local packages=(
        "neovim" "tmux" "starship" "git" "zsh"
        "fzf" "ripgrep" "fd" "bat" "eza"
        "lazygit" "btop" "lua" "ruby" "go"
    )

    local missing_packages=()
    for package in "${packages[@]}"; do
        if command -v "$package" >/dev/null 2>&1 || pacman -Qi "$package" >/dev/null 2>&1; then
            log_success "$package 已安装"
        else
            log_warning "$package 未安装"
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_warning "以下软件包未安装: ${missing_packages[*]}"
        log_info "这些软件包应该在 Dockerfile 的 tools stage 中已安装"
    else
        log_success "所有关键软件包已安装"
    fi
}

# 验证版本管理器
verify_version_managers() {
    log_info "验证版本管理器..."

    if command -v uv >/dev/null 2>&1; then
        log_success "uv 已安装: $(uv --version 2>&1 | head -n 1)"
    else
        log_warning "uv 未安装或不在 PATH 中"
    fi

    if command -v fnm >/dev/null 2>&1; then
        log_success "fnm 已安装: $(fnm --version 2>&1 | head -n 1)"
    else
        log_warning "fnm 未安装或不在 PATH 中"
    fi

    if command -v yay >/dev/null 2>&1; then
        log_success "yay 已安装: $(yay --version 2>&1 | head -n 1)"
    else
        log_warning "yay 未安装"
    fi
}

# 验证配置文件
verify_config_files() {
    log_info "验证配置文件..."

    local config_files=(
        "/root/.zprofile"
        "/root/.zshrc"
        "/root/.bashrc"
        "/root/.tmux.conf"
        "/root/.config/starship/starship.toml"
    )

    local success_count=0
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            local file_size=$(stat -c%s "$config_file" 2>/dev/null || echo "0")
            if [ "$file_size" -gt 100 ]; then
                log_success "配置文件存在: $config_file ($file_size 字节)"
                # 特殊检查：.zprofile 应该包含 fnm 初始化
                if [ "$config_file" = "/root/.zprofile" ]; then
                    if grep -q "fnm env" "$config_file" 2>/dev/null; then
                        log_success ".zprofile 包含 fnm 初始化配置"
                    else
                        log_warning ".zprofile 缺少 fnm 初始化配置"
                    fi
                fi
                success_count=$((success_count + 1))
            else
                log_warning "配置文件太小: $config_file ($file_size 字节)"
            fi
        else
            log_warning "配置文件不存在: $config_file"
        fi
    done

    log_info "已验证 $success_count/${#config_files[@]} 个配置文件"
}

# 验证 Neovim 配置
verify_neovim_config() {
    log_info "验证 Neovim 配置..."

    if [ -d "/root/.config/nvim" ]; then
        local nvim_files=$(find /root/.config/nvim -type f 2>/dev/null | wc -l)
        if [ "$nvim_files" -gt 0 ]; then
            log_success "Neovim 配置目录存在: /root/.config/nvim ($nvim_files 个文件)"
        else
            log_warning "Neovim 配置目录为空: /root/.config/nvim"
        fi
    else
        log_warning "Neovim 配置目录不存在: /root/.config/nvim"
    fi
}

# 验证可选工具（参考 Linux 脚本的 install_optional_tools）
verify_optional_tools() {
    log_info "验证可选工具..."

    local optional_tools=("tree" "ctags" "file" "net-tools" "iputils")
    local installed_count=0

    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1 || pacman -Qi "$tool" >/dev/null 2>&1; then
            log_success "$tool 已安装"
            installed_count=$((installed_count + 1))
        else
            log_warning "$tool 未安装"
        fi
    done

    log_info "可选工具验证完成: $installed_count/${#optional_tools[@]} 个已安装"
}

# 验证字体安装（参考 Linux 脚本的 install_font）
verify_font_installation() {
    log_info "验证字体安装..."

    local font_dir="/usr/local/share/fonts/FiraMono-NerdFont"

    if [ -d "$font_dir" ]; then
        local font_files=$(find "$font_dir" -name "*.ttf" -o -name "*.otf" 2>/dev/null | wc -l)
        if [ "$font_files" -gt 0 ]; then
            log_success "FiraMono Nerd Font 已安装: $font_dir ($font_files 个字体文件)"
            # 更新字体缓存
            fc-cache -f >/dev/null 2>&1 || true
        else
            log_warning "字体目录存在但无字体文件: $font_dir"
        fi
    else
        log_warning "字体目录不存在: $font_dir"
    fi
}

# 验证 Shell 工具（参考 Linux 脚本的 install_shell_tools）
verify_shell_tools() {
    log_info "验证 Shell 工具..."

    # 验证 zsh
    if command -v zsh >/dev/null 2>&1; then
        log_success "zsh 已安装: $(zsh --version 2>&1 | head -n 1)"
    else
        log_warning "zsh 未安装"
    fi

    # 验证 Oh My Zsh
    if [ -d "/root/.oh-my-zsh" ]; then
        log_success "Oh My Zsh 已安装: /root/.oh-my-zsh"

        # 验证插件
        local zsh_custom="/root/.oh-my-zsh/custom/plugins"
        local plugins=(
            "zsh-autosuggestions"
            "zsh-history-substring-search"
            "zsh-syntax-highlighting"
        )

        local plugin_count=0
        for plugin in "${plugins[@]}"; do
            if [ -d "$zsh_custom/$plugin" ]; then
                log_success "  插件已安装: $plugin"
                plugin_count=$((plugin_count + 1))
            else
                log_warning "  插件未安装: $plugin"
            fi
        done

        log_info "Oh My Zsh 插件验证完成: $plugin_count/${#plugins[@]} 个已安装"
    else
        log_warning "Oh My Zsh 未安装: /root/.oh-my-zsh"
    fi
}

# 验证 lazyssh（参考 Linux 脚本的 install_lazyssh）
verify_lazyssh() {
    log_info "验证 lazyssh..."

    if command -v lazyssh >/dev/null 2>&1; then
        log_success "lazyssh 已安装: $(lazyssh --version 2>&1 || echo 'unknown version')"
    else
        log_warning "lazyssh 未安装或不在 PATH 中"
        # 检查是否在 .local/bin 中
        if [ -f "/root/.local/bin/lazyssh" ]; then
            log_info "lazyssh 二进制文件存在: /root/.local/bin/lazyssh"
            log_info "请确保 /root/.local/bin 在 PATH 中"
        fi
    fi
}

# 主函数
main() {
    log_info "开始容器内安装流程..."
    log_info "参考 Linux 安装流程: scripts/linux/system_basic_env/install_common_tools.sh"
    log_info "注意：软件包安装已在 Dockerfile 的 tools stage 中完成"
    log_info "容器配置阶段主要负责配置应用和验证"

    # ==========================================
    # Phase 1: Pacman 相关操作（参考 Linux 安装流程 Phase 1）
    # 注意：在容器环境中，软件包已在 Dockerfile 中安装
    # 这里主要进行配置优化和验证
    # ==========================================
    log_info "=========================================="
    log_info "Phase 1: Pacman 配置优化（参考 Linux Phase 1: Pacman operations）"
    log_info "=========================================="

    # 设置代理
    setup_proxy_env

    # 条件配置镜像源和优化 pacman（如果无代理，使用中国镜像源）
    configure_mirrors_conditional

    # 注意：以下操作在 Dockerfile 中已完成，这里只做说明
    # - update_system: 已在 Dockerfile base stage 中完成
    # - install_packages: 已在 Dockerfile tools stage 中完成
    # - ensure_aur_helper: 已在 Dockerfile tools stage 中完成（yay）

    # ==========================================
    # Phase 2: 软件配置安装（参考 Linux 安装流程 Phase 2）
    # ==========================================
    log_info "=========================================="
    log_info "Phase 2: 软件配置安装（参考 Linux Phase 2: Other operations）"
    log_info "=========================================="

    # 首先设置 PATH，确保 uv 和 fnm 可以被找到
    # 注意：uv 和 fnm 已在 Dockerfile 的 tools stage 中安装
    export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"
    log_info "已设置 PATH: $PATH"

    # 验证版本管理器是否可用
    log_info "验证版本管理器..."
    if command -v uv >/dev/null 2>&1; then
        log_success "uv 已安装: $(uv --version 2>&1 | head -n 1)"
    else
        log_warning "uv 未安装或不在 PATH 中"
    fi

    if command -v fnm >/dev/null 2>&1; then
        log_success "fnm 已安装: $(fnm --version 2>&1 | head -n 1)"
    else
        log_warning "fnm 未安装或不在 PATH 中"
    fi

    # 安装 Node.js（使用 fnm，确保代理环境变量已设置）
    install_nodejs_with_fnm

    # 安装 TPM (Tmux Plugin Manager)
    install_tpm

    # 安装 Neovim 配置（参考 Linux 脚本的 install_neovim）
    install_neovim_config

    # 验证可选工具（参考 Linux 脚本的 install_optional_tools）
    verify_optional_tools

    # 注意：以下工具在 Dockerfile 的后续步骤中安装，不在 container_install.sh 中验证
    # - lazyssh: 在 Dockerfile Step 30 中安装
    # - 字体: 在 Dockerfile Step 29 中安装
    # 这些验证将在 Phase 4 中进行（如果需要在构建时验证，可以在这里添加）

    # 验证 Shell 工具（参考 Linux 脚本的 install_shell_tools）
    # 注意：zsh 和 Oh My Zsh 已在 Dockerfile 中安装，这里只验证
    verify_shell_tools

    # ==========================================
    # Phase 3: 配置文件应用（参考 Linux 安装流程）
    # ==========================================
    log_info "=========================================="
    log_info "Phase 3: 配置文件应用"
    log_info "=========================================="

    # 使用 chezmoi 应用配置文件（会应用 .zshrc, .bashrc, .tmux.conf 等）
    apply_config_with_chezmoi

    # ==========================================
    # Phase 4: 验证和总结（参考 Linux 安装流程）
    # ==========================================
    log_info "=========================================="
    log_info "Phase 4: 验证和总结"
    log_info "=========================================="

    # 验证已安装的软件包
    verify_installed_packages

    # 验证版本管理器
    verify_version_managers

    # 验证配置文件
    verify_config_files

    # 验证 Neovim 配置
    verify_neovim_config

    # 验证字体和 lazyssh（这些在 Dockerfile 的后续步骤中安装）
    # 注意：这些验证在 Phase 4 中进行，因为它们在 Dockerfile Step 29-30 中安装
    # 验证 TPM 安装
    log_info "验证 TPM (Tmux Plugin Manager)..."
    if [ -d "/root/.tmux/plugins/tpm" ] && [ -f "/root/.tmux/plugins/tpm/tpm" ]; then
        log_success "TPM 已安装: /root/.tmux/plugins/tpm"
    else
        log_warning "TPM 未安装或安装不完整"
    fi

    log_info "验证字体和 lazyssh（在 Dockerfile 后续步骤中安装）..."
    verify_font_installation
    verify_lazyssh

    log_success "容器内安装完成"
    log_info "=========================================="
    log_info "安装总结（参考 Linux 安装流程）："
    log_info "Phase 1: Pacman 配置优化 - 完成"
    log_info "Phase 2: 软件配置安装 - 完成"
    log_info "  - Neovim 配置已安装（如果可用）"
    log_info "  - 版本管理器已验证（uv, fnm, yay）"
    log_info "  - 可选工具已验证"
    log_info "  - 字体安装已验证"
    log_info "  - Shell 工具已验证"
    log_info "Phase 3: 配置文件应用 - 完成"
    log_info "  - 配置文件已通过 chezmoi 应用"
    log_info "Phase 4: 验证和总结 - 完成"
    log_info ""
    log_info "注意：所有软件包已在 Dockerfile 的 tools stage 中安装"
    log_info "=========================================="
}

# 执行主函数
main "$@"

