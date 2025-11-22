if status is-interactive
    # 交互式会话中可以运行的命令
end

# 将 nvm 路径添加到 fish shell
load_nvm > /dev/stderr


# 由 xiaoli 添加
alias unset 'set --erase'
alias h_proxy='export http_proxy=http://127.0.0.1:7890;export https_proxy=http://127.0.0.1:7890'
alias unset_h='unset http_proxy; unset https_proxy'
alias c_google='curl cip.cc'

alias cat='bat --style=plain'

alias l='exa'
alias la='exa -a'
alias ll='exa -lah'
alias ls='exa --color=auto'
alias rm='trash -v'

# Autojump
source /usr/local/share/autojump/autojump.fish

# 启动 starship
starship init fish | source
