#Add user private shell path
export PATH=$PATH:/Users/liyong/Code/Tools/Shells/BashTools

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/liyong/.sdkman"
[[ -s "/Users/liyong/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/liyong/.sdkman/bin/sdkman-init.sh"

export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
export PATH="/Users/liyong/Library/Python/2.7/bin:$PATH"
export PATH=$PATH':/path/to/add'
export GEM_HOME=$HOME/.gem
export GEM_PATH=$HOME/.gem

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
. "$HOME/.cargo/env"
