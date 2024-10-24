# Hisroty
PROMPT_COMMAND='history -a'

# Proxy - Automatically set the proxy on Bash startup
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890

# Proxy
alias h_proxy='export http_proxy=http://127.0.0.1:7890;export https_proxy=http://127.0.0.1:7890'
alias unset_h='unset http_proxy; unset https_proxy'

# Network check alias
alias check_network='curl -IL https://www.google.com 2>/dev/null | grep -q -E "200 OK|Connection established" && echo "Network is OK" || echo "Network is down"'

# Explorer
alias open='explorer'

# Bat instead cat
alias cat='bat'

# Workaround for docker for Windows in Git Bash.
docker()
{
  (export MSYS_NO_PATHCONV=1; "docker.exe" "$@")
}

# Workaround for docker-compose for Windows in Git Bash.
docker-compose()
{
  (export MSYS_NO_PATHCONV=1; "docker-compose.exe" "$@")
}

# Windows Terminal Theme must put at last line
eval "$(oh-my-posh --init --shell bash --config /c/Users/Administrator/AppData/Local/Programs/oh-my-posh/themes/montys.omp.json)"

# Open Default path
cd /d/Code || cd ~

# Display an emoticon after startup
echo "Welcome! 😊"

eval "$(starship init bash)"
