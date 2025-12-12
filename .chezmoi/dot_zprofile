# ============================================
# Zsh 登录 Shell 环境变量配置
# 所有登录方式（本地登录、SSH 登录）都会读取此文件
# ============================================
# 注意：此文件在 .zshrc 之前加载，用于设置环境变量
# 参考: https://zsh.sourceforge.io/Intro/intro_3.html

# ============================================
# 基础 PATH 配置
# ============================================
# 基础路径（本地本来就有的）
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# 系统路径（根据操作系统添加）
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux 特定路径
    export PATH="/usr/local/bin:$PATH"
    export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS 特定路径
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif [[ "$OSTYPE" =~ ^(msys|mingw|cygwin) ]]; then
    # Windows Git Bash 特定路径
    if [ -d "/c/Users/$USER/.local/bin" ]; then
        export PATH="/c/Users/$USER/.local/bin:$PATH"
    fi
    if [ -d "/c/Users/$USER/AppData/Roaming/uv/python" ]; then
        export PATH="/c/Users/$USER/AppData/Roaming/uv/python/cpython-3.10.16-windows-x86_64-none:$PATH"
    fi
fi

# ============================================
# fnm (Fast Node Manager) - Node.js 版本管理
# ============================================
# 参考: https://github.com/Schniz/fnm
# fnm 会自动处理 Node 版本管理和 .node-version/.nvmrc 文件的自动切换
if [ -d "$HOME/.local/share/fnm" ]; then
    export PATH="$HOME/.local/share/fnm:$PATH"
    # 初始化 fnm（登录 shell 需要）
    if command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --use-on-cd)"
    fi
elif [ -d "$HOME/.fnm" ]; then
    export PATH="$HOME/.fnm:$PATH"
    if command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --use-on-cd)"
    fi
fi

# ============================================
# uv (Python 包管理器)
# ============================================
# 参考: https://github.com/astral-sh/uv
# 确保 uv 在 PATH 中（通常安装在 ~/.cargo/bin 或 ~/.local/bin）
if [ -d "$HOME/.cargo/bin" ] && ! echo "$PATH" | grep -q "$HOME/.cargo/bin"; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# ============================================
# Pyenv (Python 版本管理)
# ============================================
# 参考: https://github.com/pyenv/pyenv
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    # 登录 shell 需要 init --path
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    export PATH="$PYENV_ROOT/shims:$PATH"
fi

# ============================================
# 其他工具初始化（按需取消注释）
# ============================================

# Direnv - 自动加载 .envrc 文件
# if command -v direnv >/dev/null 2>&1; then
#     eval "$(direnv hook zsh)"
# fi

# SDKMAN - Java 开发工具管理
# export SDKMAN_DIR="$HOME/.sdkman"
# [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Go 环境
# export GOPATH="$HOME/go"
# export PATH="$HOME/go/bin:$PATH"

# Rust 环境（通常已通过 ~/.cargo/bin 配置）
# export CARGO_HOME="$HOME/.cargo"
# export RUSTUP_HOME="$HOME/.rustup"

# ============================================
# 字符编码设置（确保中文正确显示）
# ============================================
if [[ "$OSTYPE" =~ ^(msys|mingw|cygwin) ]]; then
    # Windows Git Bash 环境
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    export LC_CTYPE=zh_CN.UTF-8
    export TERM=xterm-256color
fi

# ============================================
# 加载 .zshrc（交互式 shell 配置）
# ============================================
# 让 login shell 也读取 .zshrc（防止漏掉极少数只在 interactive 才需要的变量）
[ -f ~/.zshrc ] && source ~/.zshrc

