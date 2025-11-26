# Zsh 统一配置文件
# 基于 Oh My Zsh 框架，自动检测操作系统并加载对应配置
# 参考: https://github.com/ohmyzsh/ohmyzsh
# 功能对齐: 参考 dotfiles/fish/config.fish，确保功能一致

# ============================================
# Oh My Zsh 配置
# ============================================
# Oh My Zsh 安装路径
export ZSH="$HOME/.oh-my-zsh"

# 主题设置（推荐: agnoster, powerlevel10k, robbyrussell）
ZSH_THEME="agnoster"

# 自动更新设置
# 禁用自动更新（手动更新: omz update）
zstyle ':omz:update' mode disabled

# 自动更新检查频率（天数）
# zstyle ':omz:update' frequency 13

# ============================================
# 插件配置
# ============================================
plugins=(
  git
  docker
  kubectl
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# ============================================
# 加载 Oh My Zsh
# ============================================
if [ -d "$ZSH" ]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "警告: Oh My Zsh 未安装，请运行: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# ============================================
# 系统检测
# ============================================
# 对应 Fish: set -l OS (uname -s)
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" =~ ^(msys|mingw|cygwin) ]]; then
    OS="windows"
else
    OS="unknown"
fi

# ============================================
# 通用配置（所有平台）
# ============================================

# 历史记录配置
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # 在命令间共享历史记录
setopt HIST_IGNORE_DUPS      # 忽略重复命令
setopt HIST_IGNORE_SPACE      # 忽略以空格开头的命令
setopt HIST_VERIFY            # 执行历史命令前先显示

# 自动补全配置
autoload -Uz compinit
compinit

# 目录导航
setopt AUTO_CD                # 输入目录名自动 cd
setopt AUTO_PUSHD             # cd 时自动 pushd
setopt PUSHD_IGNORE_DUPS      # 忽略重复目录
setopt PUSHD_SILENT           # pushd 时不打印目录栈

# 其他选项
setopt CORRECT                # 命令拼写纠正
setopt EXTENDED_GLOB          # 扩展通配符

# 自定义别名
# 注意：zsh 中 unset 是内置命令，不需要别名（Fish 中需要 alias unset 'set --erase'）
alias c_google='curl cip.cc'

# 使用 bat 替换 cat，提供更好的格式化输出
# 对应 Fish: alias cat='bat --style=plain'
if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'
else
    alias cat='cat'
fi

# 使用 lsd 或 exa 替代 ls
# 对应 Fish: if command -v lsd > /dev/null; alias l='lsd' ... end
if command -v lsd &> /dev/null; then
    alias l='lsd'
    alias la='lsd -a'
    alias ll='lsd -lah'
    alias ls='lsd --color=auto'
elif command -v exa &> /dev/null; then
    alias l='exa'
    alias la='exa -a'
    alias ll='exa -lah'
    alias ls='exa --color=auto'
fi

# 使用 trash 替换 rm，实现更安全的删除操作
# 对应 Fish: alias rm='trash -v'
if command -v trash &> /dev/null; then
    alias rm='trash -v'
else
    alias rm='rm'
fi

# 代理设置（通用，平台特定配置会覆盖）
# 对应 Fish: alias h_proxy='set -gx http_proxy ...'
# macOS 默认使用 7890，Linux 默认使用 1087
alias h_proxy='export http_proxy=http://127.0.0.1:7890; export https_proxy=http://127.0.0.1:7890; export all_proxy=socks5://127.0.0.1:7890'
alias unset_h='unset http_proxy; unset https_proxy; unset all_proxy'

# PATH 配置
# 对应 Fish: set -gx PATH $PATH $HOME/.local/bin
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# ============================================
# 平台特定配置
# ============================================

# macOS 特定配置
# 对应 Fish: if test "$OS" = "Darwin" ... end
if [[ "$OS" == "macos" ]]; then
    # Homebrew
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    # Autojump（如果已安装）
    # 对应 Fish: if test -f /usr/local/share/autojump/autojump.fish; source ... end
    if [ -f /usr/local/share/autojump/autojump.sh ]; then
        source /usr/local/share/autojump/autojump.sh
    elif [ -f /opt/homebrew/share/autojump/autojump.sh ]; then
        source /opt/homebrew/share/autojump/autojump.sh
    fi

    # Starship 提示符（如果已安装且未使用 Oh My Zsh 主题）
    # 对应 Fish: if command -v starship > /dev/null; starship init fish | source; end
    # if command -v starship &> /dev/null && [[ "$ZSH_THEME" == "robbyrussell" ]]; then
    #     eval "$(starship init zsh)"
    # fi

    # Gemini CLI 配置（可选，根据实际需要取消注释）
    # 对应 Fish: # set -gx GOOGLE_CLOUD_PROJECT "gen-lang-client-0128654003"
    # export GOOGLE_CLOUD_PROJECT="gen-lang-client-0128654003"

    # Claude Code 配置（可选，根据实际需要取消注释）
    # 对应 Fish: # set -gx ANTHROPIC_BASE_URL https://api.kimi.com/coding/
    # export ANTHROPIC_BASE_URL="https://api.kimi.com/coding/"
    # export ANTHROPIC_AUTH_TOKEN="your-token-here"

# Linux 特定配置
# 对应 Fish: else if test "$OS" = "Linux" ... end
elif [[ "$OS" == "linux" ]]; then
    # 添加路径（类似 fish 的 fish_add_path）
    # 对应 Fish: fish_add_path ~/.cargo/bin
    export PATH="$HOME/.cargo/bin:$PATH"
    export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"

    # Pyenv（Linux 可能需要额外的路径初始化）
    # 对应 Fish: if command -v pyenv > /dev/null; status is-login; and pyenv init --path | source; ... end
    if command -v pyenv > /dev/null; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        export PATH="$PYENV_ROOT/shims:$PATH"
    fi

    # 代理配置（Linux 默认端口可能不同）
    # 对应 Fish: alias h_proxy='set -gx http_proxy http://127.0.0.1:1087 ...'
    alias h_proxy='export http_proxy=http://127.0.0.1:1087; export https_proxy=http://127.0.0.1:1087; export all_proxy=socks5://127.0.0.1:1087'
    alias unset_h='unset http_proxy; unset https_proxy; unset all_proxy'

# Windows Git Bash 特定配置
# 对应 Fish: else if test "$OS" = "Windows" ... end
elif [[ "$OS" == "windows" ]]; then
    # 字符编码设置
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    export LC_CTYPE=zh_CN.UTF-8

    # 代理配置（Windows 默认使用 7890）
    # 对应 Fish: alias h_proxy='set -gx http_proxy http://127.0.0.1:7890 ...'
    alias h_proxy='export http_proxy=http://127.0.0.1:7890; export https_proxy=http://127.0.0.1:7890; export all_proxy=socks5://127.0.0.1:7890'
    alias unset_h='unset http_proxy; unset https_proxy; unset all_proxy'

    # Windows 路径处理
    # Git Bash 中的路径转换
    export MSYS_NO_PATHCONV=1

    # 工具别名（Windows 特定）
    if command -v explorer.exe &> /dev/null; then
        alias open='explorer.exe'
    fi

    # Python 环境（如果使用 uv）
    if [ -d "/c/Users/$USER/.local/bin" ]; then
        export PATH="/c/Users/$USER/.local/bin:$PATH"
    fi
    if [ -d "/c/Users/$USER/AppData/Roaming/uv/python" ]; then
        export PATH="/c/Users/$USER/AppData/Roaming/uv/python/cpython-3.10.16-windows-x86_64-none:$PATH"
    fi
fi

# ============================================
# 工具集成（通用，所有平台）
# ============================================

# fnm (Fast Node Manager) - 如果已安装
# 对应 Fish: conf.d/fnm.fish - fnm env --use-on-cd --shell fish | source
# 参考: https://github.com/Schniz/fnm
# fnm 会自动处理 Node 版本管理和 .node-version/.nvmrc 文件的自动切换
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Pyenv - 如果已安装（macOS 通用配置，Linux 在平台特定部分有额外配置）
# 对应 Fish: if type -q pyenv; status --is-interactive; and pyenv init - | source; end
# 注意：Linux 的 Pyenv 配置在平台特定部分，这里只处理 macOS
if [[ "$OS" == "macos" ]] && command -v pyenv > /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Direnv - 如果已安装（可选）
# 对应 Fish: # if type -q direnv; direnv hook fish | source; end
# if command -v direnv &> /dev/null; then
#     eval "$(direnv hook zsh)"
# fi

# SDKMAN - 如果已安装（可选）
# export SDKMAN_DIR="$HOME/.sdkman"
# [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# ============================================
# 自定义函数
# ============================================

# 快速进入常用目录
# 示例: cdcode, cdwork 等
# alias cdcode='cd ~/Code'
# alias cdwork='cd ~/Work'

# ============================================
# 环境变量（可选，按需取消注释）
# ============================================
# 注意：macOS 特定的环境变量配置在平台特定部分
# 这里可以添加跨平台的环境变量配置
