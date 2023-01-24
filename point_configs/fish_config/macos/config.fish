if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Add nvm path to fish shell
load_nvm > /dev/stderr


# Add by xiaoli
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

# Start starrship
starship init fish | source
