# Fish Shell 统一配置文件
# 自动检测操作系统并加载对应配置

# ============================================
# 系统检测
# ============================================
set -l OS (uname -s)

# ============================================
# 交互式会话配置
# ============================================
if status is-interactive
    # 初始化 pyenv（确保 Python 环境正确加载）
    if type -q pyenv
        status --is-interactive; and pyenv init - | source
    end

    # 初始化 direnv（如果使用 direnv，取消注释）
    # if type -q direnv
    #     direnv hook fish | source
    # end

    # 注意: fnm (Fast Node Manager) 配置在 conf.d/fnm.fish 中
    # fnm 会自动处理 Node 版本管理和 .node-version/.nvmrc 文件的自动切换
end

# ============================================
# 通用配置（所有平台）
# ============================================

# 自定义别名
# 将 unset 替换为 Fish 兼容的语法
alias unset 'set --erase'

# 代理设置（通用，平台特定配置会覆盖）
alias h_proxy='set -gx http_proxy http://127.0.0.1:7890; set -gx https_proxy http://127.0.0.1:7890; set -gx all_proxy socks5://127.0.0.1:7890'
alias unset_h='set -e http_proxy; set -e https_proxy; set -e all_proxy'

# 网络检查别名
alias c_google='curl cip.cc'

# 使用 bat 替换 cat，提供更好的格式化输出
alias cat='bat --style=plain'

# 使用 lsd 替换 ls，提供增强的目录列表功能（如果已安装）
# 如果未安装 lsd，则使用 exa 作为备选
if command -v lsd > /dev/null
    alias l='lsd'
    alias la='lsd -a'
    alias ll='lsd -lah'
    alias ls='lsd --color=auto'
else if command -v exa > /dev/null
    alias l='exa'
    alias la='exa -a'
    alias ll='exa -lah'
    alias ls='exa --color=auto'
end

# 使用 trash 替换 rm，实现更安全的删除操作
alias rm='trash -v'

# 添加自定义 bin 目录到 PATH
set -gx PATH $PATH $HOME/.local/bin

# PATH 配置
set -gx PATH $PATH $HOME/.cargo/bin

# ============================================
# 平台特定配置
# ============================================

# macOS 特定配置
if test "$OS" = "Darwin"
    # Autojump（如果已安装）
    if test -f /usr/local/share/autojump/autojump.fish
        source /usr/local/share/autojump/autojump.fish
    end

    # Starship 提示符设置（如果已安装）
    if command -v starship > /dev/null
        starship init fish | source
    end

    # Gemini CLI 配置（可选，根据实际需要取消注释）
    # set -gx GOOGLE_CLOUD_PROJECT "gen-lang-client-0128654003"

    # Claude Code 配置（可选，根据实际需要取消注释）
    # set -gx ANTHROPIC_BASE_URL https://api.kimi.com/coding/
    # set -gx ANTHROPIC_AUTH_TOKEN "your-token-here"

# Linux 特定配置
else if test "$OS" = "Linux"
    # 添加路径：fish 版本 >= 3.3.1
    fish_add_path ~/.cargo/bin
    export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"

    # Pyenv（Linux 可能需要额外的路径初始化）
    if command -v pyenv > /dev/null
        status is-login; and pyenv init --path | source
        status is-interactive; and pyenv init - | source
        pyenv init -
        fish_add_path ~/.pyenv/shims
    end

    # 代理配置（Linux 默认端口可能不同）
    alias h_proxy='set -gx http_proxy http://127.0.0.1:1087; set -gx https_proxy http://127.0.0.1:1087; set -gx all_proxy socks5://127.0.0.1:1087'
    alias unset_h='set -e http_proxy; set -e https_proxy; set -e all_proxy'
end
