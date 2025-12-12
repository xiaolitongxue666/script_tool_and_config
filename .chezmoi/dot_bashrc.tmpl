# Bash 统一配置文件
# 自动检测操作系统并加载对应配置

# ============================================
# 系统检测
# ============================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
else
    OS="unknown"
fi

# ============================================
# 通用配置（所有平台）
# ============================================

# 代理别名（通用）
alias h_proxy='export http_proxy=http://127.0.0.1:7890;export https_proxy=http://127.0.0.1:7890'
alias unset_h='unset http_proxy; unset https_proxy'

# Bat instead cat
if command -v bat &> /dev/null; then
    alias cat='bat'
fi

# ============================================
# 平台特定配置
# ============================================

# macOS 特定配置
if [[ "$OS" == "macos" ]]; then
    # 添加用户私有 shell 路径
    export PATH=$PATH:/Users/liyong/Code/Tools/Shells/BashTools

    # SDKMAN（必须在文件末尾）
    export SDKMAN_DIR="/Users/liyong/.sdkman"
    [[ -s "/Users/liyong/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/liyong/.sdkman/bin/sdkman-init.sh"

    # 路径配置
    export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
    export PATH="/Users/liyong/Library/Python/2.7/bin:$PATH"
    export PATH=$PATH':/path/to/add'
    export PATH="/usr/local/bin:$PATH"
    export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"

    # GEM 配置
    export GEM_HOME=$HOME/.gem
    export GEM_PATH=$HOME/.gem

    # NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    # Cargo
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi

# Windows 特定配置（Git Bash/MSYS2）
elif [[ "$OS" == "windows" ]]; then
    # History
    PROMPT_COMMAND='history -a'

    # 代理配置
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890

    # 网络检查别名
    alias check_network='curl -IL https://www.google.com 2>/dev/null | grep -q -E "200 OK|Connection established" && echo "Network is OK" || echo "Network is down"'

    # Explorer
    alias open='explorer'

    # Docker 工作区（Windows Git Bash）
    docker() {
        (export MSYS_NO_PATHCONV=1; "docker.exe" "$@")
    }

    # Docker Compose 工作区（Windows Git Bash）
    docker-compose() {
        (export MSYS_NO_PATHCONV=1; "docker-compose.exe" "$@")
    }

    # Windows Terminal Theme（必须在最后一行）
    if command -v oh-my-posh &> /dev/null; then
        eval "$(oh-my-posh --init --shell bash --config /c/Users/Administrator/AppData/Local/Programs/oh-my-posh/themes/montys.omp.json)"
    fi

    # 打开默认路径
    cd /d/Code 2>/dev/null || cd ~

    # 启动时显示欢迎信息
    echo "Welcome! 😊"

    # Starship
    if command -v starship &> /dev/null; then
        eval "$(starship init bash)"
    fi

# Linux 特定配置
elif [[ "$OS" == "linux" ]]; then
    # Linux 特定配置可以在这里添加
    :
fi

