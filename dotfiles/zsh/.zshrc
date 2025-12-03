# Zsh 统一配置文件
# 基于 Oh My Zsh 框架，自动检测操作系统并加载对应配置
# 参考: https://github.com/ohmyzsh/ohmyzsh
# 功能对齐: 参考 dotfiles/fish/config.fish，确保功能一致

# ============================================
# HOME 变量修复（必须在最前面，Git Bash 启动的 zsh 中 HOME 可能不正确）
# ============================================
# 检测操作系统
if [[ "$OSTYPE" =~ ^(msys|mingw|cygwin) ]]; then
    # Windows Git Bash 环境
    # 修复 HOME 变量：Git Bash 启动的 zsh 中 HOME 可能被设置为 /home/Administrator
    # 或者可能是 Windows 路径格式 c:/users/administrator，需要转换为 /c/Users/Administrator
    # 注意：此修复必须在任何其他配置之前执行，因为 Oh My Zsh 和其他工具依赖正确的 HOME

    # 首先，如果 HOME 是 Windows 路径格式（c:/users/administrator），转换为 Unix 格式
    if [[ "$HOME" =~ ^[a-zA-Z]: ]]; then
        # Windows 路径格式，转换为 Unix 格式
        # c:/users/administrator -> /c/Users/Administrator
        # 步骤1: 提取盘符
        DRIVE_LETTER=$(echo "$HOME" | cut -c1 | tr '[:upper:]' '[:lower:]')
        # 步骤2: 提取路径部分并转换为小写
        PATH_AFTER_DRIVE=$(echo "$HOME" | cut -d':' -f2 | sed 's|^/||' | tr '[:upper:]' '[:lower:]')
        # 步骤3: 将路径的每个目录首字母大写
        if [ -n "$PATH_AFTER_DRIVE" ]; then
            # 分割路径为目录数组（使用 zsh 兼容的方法）
            # 使用 zsh 的数组语法
            CONVERTED_PATH=""
            # 使用 zsh 的 (s:/:) 分割语法
            dirs=(${(s:/:)PATH_AFTER_DRIVE})
            for dir in "${dirs[@]}"; do
                if [ -n "$dir" ]; then
                    # 首字母大写
                    FIRST_CHAR=$(echo "$dir" | cut -c1 | tr '[:lower:]' '[:upper:]')
                    REST_CHARS=$(echo "$dir" | cut -c2-)
                    UPPER_DIR="${FIRST_CHAR}${REST_CHARS}"
                    if [ -z "$CONVERTED_PATH" ]; then
                        CONVERTED_PATH="$UPPER_DIR"
                    else
                        CONVERTED_PATH="$CONVERTED_PATH/$UPPER_DIR"
                    fi
                fi
            done
            HOME="/${DRIVE_LETTER}/${CONVERTED_PATH}"
        else
            HOME="/${DRIVE_LETTER}"
        fi
        export HOME
    fi

    # 如果 HOME 不正确，立即修复它
    if [ "$HOME" = "/home/Administrator" ] || [ ! -d "$HOME" ] || [ ! -f "$HOME/.zshrc" ]; then
        # 方法1: 从 USERPROFILE 环境变量获取（最可靠）
        if [ -n "$USERPROFILE" ]; then
            # 转换 Windows 路径格式（C:\Users\Administrator -> /c/Users/Administrator）
            WIN_HOME=$(echo "$USERPROFILE" | sed 's|\\|/|g' | sed 's|^\([A-Za-z]\):|/\1|' | tr '[:upper:]' '[:lower:]' | sed 's|^/\([a-z]\)|/\1|')
            # 确保首字母大写
            WIN_HOME=$(echo "$WIN_HOME" | sed 's|^/\([a-z]\)/\([a-z]*\)|/\1/\u\2|')
            if [ -d "$WIN_HOME" ] && [ -f "$WIN_HOME/.zshrc" ]; then
                export HOME="$WIN_HOME"
            fi
        fi
        # 方法2: 如果还是不对，尝试常见路径
        if [ "$HOME" = "/home/Administrator" ] || [ ! -f "$HOME/.zshrc" ]; then
            for test_home in "/c/Users/Administrator" "/d/Users/Administrator" "/e/Users/Administrator"; do
                if [ -d "$test_home" ] && [ -f "$test_home/.zshrc" ]; then
                    export HOME="$test_home"
                    break
                fi
            done
        fi
        # 方法3: 如果以上方法都失败，尝试从当前脚本位置推断
        # 注意：这应该在最后尝试，因为可能不准确
        if [ "$HOME" = "/home/Administrator" ] || [ ! -f "$HOME/.zshrc" ]; then
            # 尝试从当前工作目录推断
            if [ -f "/c/Users/Administrator/.zshrc" ]; then
                export HOME="/c/Users/Administrator"
            fi
        fi
    fi
fi

# ============================================
# 字符编码设置（确保中文正确显示）
# ============================================
# 注意：Windows 的字符编码设置已移至 .zprofile
# 这里保留是为了兼容性，但主要配置在 .zprofile 中

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
# 注意：zsh-autosuggestions 和 zsh-syntax-highlighting 需要单独安装
# 如果未安装，这些插件会被忽略，不会影响其他功能
plugins=(
  git
  docker
  kubectl
  z
  # zsh-autosuggestions  # 需要安装: git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  # zsh-syntax-highlighting  # 需要安装: git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
)

# ============================================
# 加载 Oh My Zsh
# ============================================
if [ -d "$ZSH" ]; then
    # 加载 Oh My Zsh 核心
    source $ZSH/oh-my-zsh.sh

    # 确保 cli.zsh 被加载（提供 omz 命令）
    # 显式加载 cli.zsh 以确保 omz 命令可用
    # 注意：必须在 oh-my-zsh.sh 加载后立即加载
    if [ -f "$ZSH/lib/cli.zsh" ]; then
        source "$ZSH/lib/cli.zsh"
    fi

    # 验证 Oh My Zsh 是否正确加载
    if [ -z "$ZSH_VERSION" ]; then
        echo "警告: Oh My Zsh 可能未正确加载"
    fi
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
# 对应 Fish: if command -v lsd > /dev/null; alias l='lsd --icon=always' ... end
# 注意：需要安装 Nerd Fonts 才能正确显示图标
if command -v lsd &> /dev/null; then
    alias l='lsd --icon=always'
    alias la='lsd --icon=always -a'
    alias ll='lsd --icon=always -lah'
    alias ls='lsd --icon=always --color=auto'
elif command -v exa &> /dev/null; then
    alias l='exa --icons'
    alias la='exa --icons -a'
    alias ll='exa --icons -lah'
    alias ls='exa --icons --color=auto'
fi

# 使用 trash 替换 rm，实现更安全的删除操作
# 对应 Fish: alias rm='trash -v'
if command -v trash &> /dev/null; then
    alias rm='trash -v'
else
    alias rm='rm'
fi

# ============================================
# 平台特定配置（交互式 shell 专用）
# ============================================
# 注意：环境变量（PATH、fnm、pyenv 等）已移至 .zprofile
# .zprofile 会在 .zshrc 之前加载，确保环境变量在所有登录方式下都可用

# macOS 特定配置
# 对应 Fish: if test "$OS" = "Darwin" ... end
if [[ "$OS" == "macos" ]]; then
    # 代理配置（macOS 使用本地代理）
    # 对应 Fish: alias h_proxy='set -gx http_proxy http://127.0.0.1:7890 ...'
    alias h_proxy='export http_proxy=http://127.0.0.1:7890; export https_proxy=http://127.0.0.1:7890; export all_proxy=socks5://127.0.0.1:7890'
    alias unset_h='unset http_proxy; unset https_proxy; unset all_proxy'

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
    # 代理配置（Linux 默认端口可能不同）
    # 对应 Fish: alias h_proxy='set -gx http_proxy http://192.168.1.76:7890 ...'
    alias h_proxy='export http_proxy=http://192.168.1.76:7890; export https_proxy=http://192.168.1.76:7890; export all_proxy=socks5://192.168.1.76:7890'
    alias unset_h='unset http_proxy; unset https_proxy; unset all_proxy'

# Windows Git Bash 特定配置
# 对应 Fish: else if test "$OS" = "Windows" ... end
elif [[ "$OS" == "windows" ]]; then
    # 代理配置（Windows 默认使用 7890）
    # 对应 Fish: alias h_proxy='set -gx http_proxy http://192.168.1.76:7890 ...'
    alias h_proxy='export http_proxy=http://192.168.1.76:7890; export https_proxy=http://192.168.1.76:7890; export all_proxy=socks5://192.168.1.76:7890'
    alias unset_h='unset http_proxy; unset https_proxy; unset all_proxy'

    # Windows 路径处理
    # Git Bash 中的路径转换
    export MSYS_NO_PATHCONV=1

    # 工具别名（Windows 特定）
    if command -v explorer.exe &> /dev/null; then
        alias open='explorer.exe'
    fi
fi

# ============================================
# 工具集成（交互式 shell 专用）
# ============================================
# 注意：fnm 和 pyenv 的环境变量初始化已在 .zprofile 中完成
# 这里只处理交互式 shell 特有的配置

# fnm (Fast Node Manager) - 交互式 shell 配置
# 注意：环境变量已在 .zprofile 中设置，这里只确保交互式功能正常
if command -v fnm &> /dev/null; then
    # fnm 的交互式功能（如自动切换版本）已在 .zprofile 中通过 --use-on-cd 配置
    # 这里不需要额外配置
    :
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
