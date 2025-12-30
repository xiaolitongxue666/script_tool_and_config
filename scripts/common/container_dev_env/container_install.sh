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

# 条件配置镜像源
configure_mirrors_conditional() {
    if [ -z "$PROXY_URL" ]; then
        log_info "配置中国镜像源（无代理）"

        # 备份原始配置
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup || true

        # 配置中国镜像源
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

        # 优化 pacman 配置
        if ! grep -q "^HoldPkg" /etc/pacman.conf; then
            sed -i '/^\[options\]/a\
HoldPkg     = pacman glibc\
Architecture = auto\
CheckSpace\
SigLevel    = Required DatabaseOptional\
LocalFileSigLevel = Optional' /etc/pacman.conf
        fi

        # 确保 ParallelDownloads 已启用
        if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
            sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf || true
            if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
                sed -i '/^\[options\]/a\ParallelDownloads = 5' /etc/pacman.conf
            fi
        fi

        # 确保 core, extra 仓库使用镜像列表
        if ! grep -q "^Include = /etc/pacman.d/mirrorlist" /etc/pacman.conf; then
            sed -i '/^\[core\]/,/^\[/ { /^\[core\]/a\
Include = /etc/pacman.d/mirrorlist
}' /etc/pacman.conf
            sed -i '/^\[extra\]/,/^\[/ { /^\[extra\]/a\
Include = /etc/pacman.d/mirrorlist
}' /etc/pacman.conf
        fi

        # 添加 archlinuxcn 源
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
        fi

        log_success "中国镜像源配置完成"
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
    if [ -n "$PROXY_URL" ]; then
        export PROXY="$PROXY_URL"
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
    fi

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
    else
        log_warning "chezmoi source-path 命令失败"
    fi

    # 使用 chezmoi apply 应用配置
    # --force: 强制覆盖已存在的文件（容器环境需要）
    # --verbose: 显示详细输出
    # 注意：chezmoi 会自动使用 CHEZMOI_SOURCE_DIR 环境变量
    # 目标目录由 $HOME 环境变量决定
    log_info "执行 chezmoi apply..."
    log_info "源目录: $CHEZMOI_SOURCE_DIR"
    log_info "目标目录: $HOME"

    # 先检查源目录内容
    if [ -d "$CHEZMOI_SOURCE_DIR" ]; then
        log_info "chezmoi 源目录内容:"
        ls -la "$CHEZMOI_SOURCE_DIR" | head -10 || true
    fi

    # 执行 chezmoi apply，捕获详细输出
    log_info "开始执行 chezmoi apply..."

    # 先测试 chezmoi 是否能正常工作
    log_info "测试 chezmoi 命令..."
    if ! chezmoi --version >/dev/null 2>&1; then
        log_error "chezmoi 命令不可用"
        return 1
    fi

    # 检查源目录中的模板文件
    if [ -f "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" ]; then
        log_info "找到 .zshrc 模板文件"
        log_info "模板文件大小: $(stat -c%s "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" 2>/dev/null || echo "unknown") 字节"
    else
        log_warning "未找到 .zshrc 模板文件: $CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl"
        log_info "源目录中的文件:"
        ls -la "$CHEZMOI_SOURCE_DIR" | grep -E "zshrc|bashrc|tmux" || true
    fi

    # 执行 chezmoi apply
    log_info "执行: chezmoi apply --force --verbose"
    CHEZMOI_EXIT_CODE=0
    if chezmoi apply --force --verbose 2>&1 | tee /tmp/chezmoi_output.log; then
        CHEZMOI_EXIT_CODE=0
        log_success "chezmoi 配置应用成功"
    else
        CHEZMOI_EXIT_CODE=$?
        log_error "chezmoi 配置应用失败，退出码: $CHEZMOI_EXIT_CODE"
    fi

    # 显示 chezmoi 输出（如果有）
    if [ -f /tmp/chezmoi_output.log ]; then
        log_info "chezmoi 输出（最后 50 行）:"
        tail -50 /tmp/chezmoi_output.log || true
    fi

    # 如果失败，尝试诊断
    if [ $CHEZMOI_EXIT_CODE -ne 0 ]; then
        log_warning "chezmoi apply 失败，尝试诊断..."
        log_info "检查 chezmoi 状态:"
        chezmoi status 2>&1 | head -20 || true
        log_warning "继续执行，但配置可能不完整"
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
                if chezmoi execute-template < "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" > "$CHEZMOI_DEST_DIR/.zshrc.new" 2>/dev/null; then
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
            if chezmoi execute-template < "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" > "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null; then
                NEW_SIZE=$(stat -c%s "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null || stat -f%z "$CHEZMOI_DEST_DIR/.zshrc" 2>/dev/null || echo "0")
                if [ "$NEW_SIZE" -gt 1000 ]; then
                    log_success "手动创建 .zshrc 成功，大小: $NEW_SIZE 字节"
                else
                    log_warning "手动创建的 .zshrc 太小: $NEW_SIZE 字节"
                fi
            else
                log_error "手动创建 .zshrc 失败"
            fi
        fi
    fi

    # 验证关键配置文件是否已创建
    local config_files=(
        "$CHEZMOI_DEST_DIR/.zshrc"
        "$CHEZMOI_DEST_DIR/.bashrc"
        "$CHEZMOI_DEST_DIR/.tmux.conf"
    )

    local success_count=0
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            log_success "配置文件已创建: $config_file"
            success_count=$((success_count + 1))
        else
            log_warning "配置文件未创建: $config_file"
        fi
    done

    # 验证 Oh My Zsh 配置
    if [ -f "$CHEZMOI_DEST_DIR/.zshrc" ]; then
        log_info "检查 Oh My Zsh 配置..."
        if [ -d "$CHEZMOI_DEST_DIR/.oh-my-zsh" ]; then
            log_success "Oh My Zsh 已安装: $CHEZMOI_DEST_DIR/.oh-my-zsh"

            # 检查插件目录
            ZSH_CUSTOM_PLUGINS="$CHEZMOI_DEST_DIR/.oh-my-zsh/custom/plugins"
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
                    fi
                done
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

    if [ $success_count -gt 0 ]; then
        log_success "已成功应用 $success_count 个配置文件"
    else
        log_warning "未成功应用任何配置文件"
    fi
}

# 安装 Neovim 配置
install_neovim_config() {
    log_info "安装 Neovim 配置..."

    PROJECT_ROOT="/tmp/project"
    NVIM_SUBMODULE_DIR="$PROJECT_ROOT/dotfiles/nvim"
    NVIM_INSTALL_SCRIPT="$NVIM_SUBMODULE_DIR/install.sh"

    if [ -f "$NVIM_INSTALL_SCRIPT" ]; then
        log_info "使用 Git Submodule 安装 Neovim 配置"
        cd "$PROJECT_ROOT"

        # 初始化 submodule（如果未初始化）
        if [ ! -f "$NVIM_SUBMODULE_DIR/init.lua" ] && [ ! -d "$NVIM_SUBMODULE_DIR/lua" ]; then
            git submodule update --init --recursive dotfiles/nvim || log_warning "Neovim submodule 初始化失败"
        fi

        # 运行安装脚本
        chmod +x "$NVIM_INSTALL_SCRIPT"
        if [ -n "$PROXY_URL" ]; then
            http_proxy="$PROXY_URL" https_proxy="$PROXY_URL" \
            HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL" \
            USE_SYSTEM_NVIM_VENV=1 \
            INSTALL_USER=root \
            bash "$NVIM_INSTALL_SCRIPT" || log_warning "Neovim 配置安装失败"
        else
            USE_SYSTEM_NVIM_VENV=1 \
            INSTALL_USER=root \
            bash "$NVIM_INSTALL_SCRIPT" || log_warning "Neovim 配置安装失败"
        fi
        # 即使安装失败也继续，不阻止容器构建
        log_success "Neovim 配置安装流程完成"
    else
        log_warning "Neovim 安装脚本未找到: $NVIM_INSTALL_SCRIPT"
    fi
}

# 主函数
main() {
    log_info "开始容器内安装流程..."

    # 设置代理
    setup_proxy_env

    # 条件配置镜像源
    configure_mirrors_conditional

    # 使用 chezmoi 应用配置文件
    apply_config_with_chezmoi

    # 安装 Neovim 配置
    install_neovim_config

    log_success "容器内安装完成"
}

# 执行主函数
main "$@"

