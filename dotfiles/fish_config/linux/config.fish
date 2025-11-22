if status is-interactive
    # 交互式会话中可以运行的命令
end

# Npm
function nvm
     bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end

# 添加别名
alias unset 'set -e'  # 某些操作系统找不到 unset 命令
alias h_proxy='export http_proxy=http://127.0.0.1:1087;export https_proxy=http://127.0.0.1:1087'
alias unset_h='unset http_proxy; unset https_proxy'
alias c_google='curl cip.cc'
alias cat='bat --style=plain'
alias l='exa'
alias la='exa -a'
alias ll='exa -lah'
alias ls='exa --color=auto'
alias rm='trash -v'

# 添加路径：fish 版本 >= 3.3.1
fish_add_path ~/.cargo/bin
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"

# Pyenv
status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source
pyenv init -
fish_add_path ~/.pyenv/shims
