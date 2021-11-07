if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Add by xiaoli
alias h_proxy='export http_proxy=http://127.0.0.1:1087;export https_proxy=http://127.0.0.1:1087'
alias unset_h='unset http_proxy; unset https_proxy'
alias c_google='curl www.google.com'

alias cat='bat --style=plain'

alias l='exa'
alias la='exa -a'
alias ll='exa -lah'
alias ls='exa --color=auto'


