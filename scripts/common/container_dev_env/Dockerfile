# ============================================
# Docker ArchLinux 开发环境
# 多阶段构建，优化镜像大小
# ============================================

# Stage 1: base - 基础系统包和镜像源配置
FROM archlinux:latest AS base

# 构建参数：代理地址（可选）
ARG PROXY=""

# 先初始化 pacman key（不需要网络）
RUN pacman-key --init && \
    pacman-key --populate archlinux

# 条件配置镜像源和 pacman
# 注意：构建上下文是项目根目录
COPY scripts/common/container_dev_env/configure_mirrors.sh /tmp/configure_mirrors.sh
RUN chmod +x /tmp/configure_mirrors.sh && \
    PROXY="$PROXY" /tmp/configure_mirrors.sh && \
    rm -f /tmp/configure_mirrors.sh

# 同步 pacman 数据库并生成语言环境（在设置环境变量之前）
RUN mkdir -p /var/lib/pacman/sync /var/cache/pacman/pkg && \
    chmod 777 /var/lib/pacman/sync /var/cache/pacman/pkg && \
    if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    pacman -Sy --noconfirm && \
    sed -i '/en_US.UTF-8/s/^#//' /etc/locale.gen 2>/dev/null || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 更新系统并安装基础包
RUN mkdir -p /var/lib/pacman/sync /var/cache/pacman/pkg && \
    chmod 777 /var/lib/pacman/sync && \
    chmod 777 /var/cache/pacman/pkg && \
    if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    (pacman -Syu --noconfirm || (sleep 5 && pacman -Syu --noconfirm)) && \
    (pacman -S --needed --noconfirm \
        base-devel git curl wget aria2 sudo which unzip zip \
        openssh iputils file net-tools || \
     (sleep 5 && pacman -S --needed --noconfirm \
        base-devel git curl wget aria2 sudo which unzip zip \
        openssh iputils file net-tools))

# Stage 2: tools - 开发工具和版本管理器
FROM base AS tools

ARG PROXY=""

# 设置代理环境变量（如果提供）
# 注意：ENV 不支持条件语法，在 RUN 中设置

# 安装 archlinuxcn-keyring（如果配置了 archlinuxcn 源）
RUN if grep -q "archlinuxcn" /etc/pacman.conf; then \
        pacman -Sy --noconfirm && \
        pacman -S --noconfirm archlinuxcn-keyring || true; \
    fi

# 安装 pacman 包（包括 go，yay 需要）
RUN mkdir -p /var/cache/pacman/pkg && \
    chmod 777 /var/cache/pacman/pkg && \
    pacman -S --needed --noconfirm \
        tmux starship github-cli lazygit git-delta \
        fzf ripgrep fd bat eza trash-cli fastfetch btop \
        neovim gcc make tree cmake ctags zsh go \
        lua ruby php composer julia xclip && \
    # 清除 btop 的 capabilities，解决容器中 "operation not permitted" 问题
    setcap -r /usr/sbin/btop 2>/dev/null || true

# 安装 AUR 助手 (yay)
# 注意：makepkg 不允许以 root 运行，创建临时用户并配置 sudo
RUN if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    cd /tmp && \
    git clone https://aur.archlinux.org/yay.git && \
    chown -R builder:builder yay && \
    cd yay && \
    su builder -c "makepkg -si --noconfirm --skipinteg" && \
    cd / && \
    rm -rf /tmp/yay && \
    sed -i '/^builder ALL=(ALL) NOPASSWD: ALL$/d' /etc/sudoers && \
    userdel -r builder

# 安装版本管理器 (uv, fnm)
RUN if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    # 安装 uv \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    # 安装 fnm \
    curl -fsSL https://fnm.vercel.app/install | sh -s -- --skip-shell && \
    # 添加到 PATH \
    echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"' >> /root/.bashrc && \
    echo 'eval "$(fnm env --use-on-cd)"' >> /root/.bashrc

# 安装 Oh My Zsh
RUN if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    export RUNZSH=no && \
    export KEEP_ZSHRC=yes && \
    export CHSH=no && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# 安装 Oh My Zsh 插件
RUN if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    ZSH_CUSTOM="${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/plugins" && \
    mkdir -p "$ZSH_CUSTOM" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/zsh-autosuggestions" || true && \
    git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/zsh-history-substring-search" || true && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/zsh-syntax-highlighting" || true

# Stage 3: config - 配置文件和 Neovim
FROM tools AS config

ARG PROXY=""

# 设置代理环境变量（在 RUN 中设置）

# 复制项目文件（用于安装配置）
WORKDIR /tmp/project

# 复制安装脚本
# 注意：构建上下文是项目根目录
COPY scripts/common/container_dev_env/container_install.sh /tmp/container_install.sh
RUN chmod +x /tmp/container_install.sh

# 复制配置文件目录（.chezmoi 和 dotfiles）
# 注意：构建上下文是项目根目录
COPY .chezmoi /tmp/project/.chezmoi
COPY dotfiles /tmp/project/dotfiles

# 运行安装脚本
RUN if [ -n "$PROXY" ]; then \
        export PROXY="$PROXY"; \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    /tmp/container_install.sh

# 安装字体 (FiraMono Nerd Font)
RUN if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    pacman -S --needed --noconfirm fontconfig && \
    FONT_DIR="/usr/local/share/fonts/FiraMono-NerdFont" && \
    mkdir -p "$FONT_DIR" && \
    FONT_VERSION="3.2.1" && \
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/FiraMono.zip" && \
    cd /tmp && \
    curl -L "$FONT_URL" -o font.zip && \
    unzip -o font.zip -d "$FONT_DIR" && \
    rm -f font.zip && \
    fc-cache -f || true

# 安装 lazyssh（如果可用）
RUN if [ -n "$PROXY" ]; then \
        export http_proxy="http://$PROXY"; \
        export https_proxy="http://$PROXY"; \
        export HTTP_PROXY="http://$PROXY"; \
        export HTTPS_PROXY="http://$PROXY"; \
    fi && \
    (yay -S --noconfirm lazyssh-bin 2>/dev/null || \
     (INSTALL_DIR="/root/.local/bin" && \
      mkdir -p "$INSTALL_DIR" && \
      ARCH=$(uname -m) && \
      echo "检测架构: $ARCH" && \
      LATEST_TAG=$(curl -fsSL https://api.github.com/repos/Adembc/lazyssh/releases/latest 2>/dev/null | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$' | head -1) && \
      if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "null" ]; then \
          echo "下载 lazyssh 版本: $LATEST_TAG (架构: $ARCH)" && \
          DOWNLOAD_URL="https://github.com/Adembc/lazyssh/releases/download/${LATEST_TAG}/lazyssh_Linux_${ARCH}.tar.gz" && \
          curl -fsSL -L "$DOWNLOAD_URL" -o /tmp/lazyssh.tar.gz && \
          if [ -f /tmp/lazyssh.tar.gz ] && [ -s /tmp/lazyssh.tar.gz ]; then \
              tar -xzf /tmp/lazyssh.tar.gz -C /tmp && \
              find /tmp -name "lazyssh" -type f -executable -exec mv {} "$INSTALL_DIR/" \; 2>/dev/null && \
              chmod +x "$INSTALL_DIR/lazyssh" 2>/dev/null || true && \
              rm -rf /tmp/lazyssh* && \
              echo "lazyssh 安装成功: $INSTALL_DIR/lazyssh"; \
          else \
              echo "警告: lazyssh 下载失败或文件为空"; \
          fi; \
      else \
          echo "警告: 无法获取 lazyssh 最新版本"; \
      fi)) || echo "警告: lazyssh 安装失败，可在运行时手动安装"

# Stage 4: final - 最终镜像
FROM config AS final

ARG PROXY=""

# 清理缓存和临时文件
RUN pacman -Scc --noconfirm && \
    rm -rf /tmp/* /var/tmp/* /root/.cache/*

# 设置工作目录
WORKDIR /workspace

# 配置环境变量
ENV PATH="/root/.cargo/bin:/root/.local/share/fnm:/root/.local/bin:$PATH"
ENV SHELL=/bin/zsh

# 设置默认 shell
RUN chsh -s /bin/zsh root || true

# 确保 zsh 配置文件也包含 PATH（如果 .zshrc 不存在或未设置）
RUN if [ ! -f /root/.zshrc ] || ! grep -q "\.local/bin" /root/.zshrc 2>/dev/null; then \
        echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/share/fnm:$HOME/.local/bin:$PATH"' >> /root/.zshrc; \
    fi

# 设置代理环境变量（如果提供，用于运行时）
# 在运行时通过 docker run -e 传递

# 默认命令
# 使用 sleep infinity 以支持后台运行（Windows 环境下 tail -f /dev/null 会失败）
CMD ["sleep", "infinity"]

