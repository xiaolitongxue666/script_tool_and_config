# Git Bash 配置文件
# 仅适用于 Windows Git Bash 环境
# 参考: https://git-scm.com/docs/git-bash

# ============================================
# 系统检测
# ============================================
# 确保仅在 Git Bash 环境中加载此配置
if [[ ! "$OSTYPE" =~ ^(msys|mingw|cygwin) ]]; then
    return 0
fi

# ============================================
# 历史记录配置
# ============================================
# 自动追加历史记录到文件
PROMPT_COMMAND='history -a'

# 历史记录设置
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# ============================================
# 代理配置
# ============================================
# 默认代理设置（自动启用）
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890

# 代理控制别名
# h_proxy: 快速启用代理
alias h_proxy='export http_proxy=http://127.0.0.1:7890; export https_proxy=http://127.0.0.1:7890'
# unset_h: 关闭代理
alias unset_h='unset http_proxy; unset https_proxy'

# 网络检查别名（可选，已注释）
# alias check_network='curl -IL https://www.google.com 2>/dev/null | grep -q -E "200 OK|Connection established" && echo "Network is OK" || echo "Network is down"'

# ============================================
# 环境变量配置
# ============================================

# Google Cloud 项目配置
export GOOGLE_CLOUD_PROJECT="gen-lang-client-0128654003"

# PostgreSQL 配置
# 注意：路径中包含空格，使用引号包裹
export CARGO_ENCODED_RUSTFLAGS="-L /d/Program Files/PostgreSQL/17/lib"
export C_INCLUDE_PATH="/d/Program Files/PostgreSQL/17/include"

# Python 环境配置（uv）
export PATH="/c/Users/Administrator/.local/bin:/c/Users/Administrator/AppData/Roaming/uv/python/cpython-3.10.16-windows-x86_64-none:$PATH"

# 字符编码设置
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8

# ============================================
# 别名配置
# ============================================

# 文件管理器
alias open='explorer'

# Make 命令（使用 MinGW 版本）
alias make='mingw32-make'

# Python 别名
alias python='python3.10'

# Lua 别名（可选，已注释）
# alias lua='lua5.1'

# 使用 bat 替代 cat（如果已安装，可选）
# alias cat='bat'

# ============================================
# Docker 工作区配置（可选，已注释）
# ============================================
# Windows 上 Docker 的路径转换工作区
# docker()
# {
#   (export MSYS_NO_PATHCONV=1; "docker.exe" "$@")
# }
# docker-compose()
# {
#   (export MSYS_NO_PATHCONV=1; "docker-compose.exe" "$@")
# }

# ============================================
# Shell 增强工具
# ============================================

# 注意：inshellisense 按键绑定在 .bashrc 中加载
# 这样可以确保在非登录 shell 中也能使用

# Oh My Posh 主题配置
# 注意：必须放在最后，因为它会初始化提示符
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh --init --shell bash --config ~/AppData/Local/Programs/oh-my-posh/themes/montys.omp.json)"
fi

# Starship 提示符（可选，已注释）
# 如果使用 Starship，请注释掉 Oh My Posh 配置
# eval "$(starship init bash)"

# ============================================
# 自动启动 Zsh（如果可用）
# ============================================
# 如果 zsh 已安装且可用，自动启动 zsh
# 这允许在 Alacritty 中启动 Git Bash 后自动切换到 zsh
if command -v zsh &> /dev/null && [ -t 1 ]; then
    # 检查是否已经在 zsh 中（避免循环）
    if [ -z "$ZSH_VERSION" ]; then
        exec zsh
    fi
fi

# ============================================
# 启动配置（可选）
# ============================================

# 自动切换到默认目录（可选，已注释）
# cd /d/Code || cd ~

# 显示欢迎信息（可选，已注释）
# echo "Welcome! 😊"

