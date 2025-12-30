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

# 复制配置文件
copy_config_files() {
    log_info "复制配置文件..."

    PROJECT_ROOT="/tmp/project"

    # 创建配置目录
    mkdir -p /root/.config/starship
    mkdir -p /root/.config/alacritty
    mkdir -p /root/.config/i3
    mkdir -p /root/.config/fish/completions
    mkdir -p /root/.config/fish/conf.d

    # 复制配置文件（简化版，不处理模板变量）
    # 注意：模板文件需要手动处理或使用简化配置

    # Starship 配置
    if [ -f "$PROJECT_ROOT/.chezmoi/dot_config/starship/starship.toml" ]; then
        cp "$PROJECT_ROOT/.chezmoi/dot_config/starship/starship.toml" /root/.config/starship/starship.toml
        log_info "已复制 Starship 配置"
    fi

    # Alacritty 配置
    if [ -f "$PROJECT_ROOT/.chezmoi/dot_config/alacritty/alacritty.toml" ]; then
        cp "$PROJECT_ROOT/.chezmoi/dot_config/alacritty/alacritty.toml" /root/.config/alacritty/alacritty.toml
        log_info "已复制 Alacritty 配置"
    fi

    # i3 配置
    if [ -f "$PROJECT_ROOT/.chezmoi/run_on_linux/dot_config/i3/config" ]; then
        cp "$PROJECT_ROOT/.chezmoi/run_on_linux/dot_config/i3/config" /root/.config/i3/config
        log_info "已复制 i3 配置"
    fi

    # Tmux 配置（需要处理模板，这里使用简化版）
    if [ -f "$PROJECT_ROOT/.chezmoi/dot_tmux.conf.tmpl" ]; then
        # 简单处理：移除模板标记（如果有）
        sed 's/{{.*}}//g' "$PROJECT_ROOT/.chezmoi/dot_tmux.conf.tmpl" > /root/.tmux.conf || \
        cp "$PROJECT_ROOT/.chezmoi/dot_tmux.conf.tmpl" /root/.tmux.conf
        log_info "已复制 Tmux 配置"
    fi

    # Zsh 配置（需要处理模板）
    if [ -f "$PROJECT_ROOT/.chezmoi/dot_zshrc.tmpl" ]; then
        # 简单处理：移除模板标记
        sed 's/{{.*}}//g' "$PROJECT_ROOT/.chezmoi/dot_zshrc.tmpl" > /root/.zshrc || \
        cp "$PROJECT_ROOT/.chezmoi/dot_zshrc.tmpl" /root/.zshrc
        log_info "已复制 Zsh 配置"
    fi

    # Zsh profile
    if [ -f "$PROJECT_ROOT/.chezmoi/dot_zprofile.tmpl" ]; then
        sed 's/{{.*}}//g' "$PROJECT_ROOT/.chezmoi/dot_zprofile.tmpl" > /root/.zprofile || \
        cp "$PROJECT_ROOT/.chezmoi/dot_zprofile.tmpl" /root/.zprofile
        log_info "已复制 Zsh profile"
    fi

    # Bash 配置
    if [ -f "$PROJECT_ROOT/.chezmoi/dot_bashrc.tmpl" ]; then
        sed 's/{{.*}}//g' "$PROJECT_ROOT/.chezmoi/dot_bashrc.tmpl" > /root/.bashrc || \
        cp "$PROJECT_ROOT/.chezmoi/dot_bashrc.tmpl" /root/.bashrc
        log_info "已复制 Bash 配置"
    fi

    log_success "配置文件复制完成"
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
            bash "$NVIM_INSTALL_SCRIPT" || log_warning "Neovim 配置安装失败"
        else
            bash "$NVIM_INSTALL_SCRIPT" || log_warning "Neovim 配置安装失败"
        fi
        log_success "Neovim 配置安装完成"
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

    # 复制配置文件
    copy_config_files

    # 安装 Neovim 配置
    install_neovim_config

    log_success "容器内安装完成"
}

# 执行主函数
main "$@"

