#install zsh

pacman -S zsh

#oh my zsh theme

<https://github.com/ohmyzsh/ohmyzsh/wiki/Themes> 

suggest sgnoster

#change default shell

chsh -s /bin/zsh

#default config

cp /usr/share/oh-my-zsh/zshrc ~/.zshrc

#change theme

edit ~/.zshrc 

find ZSH_THEME="robbyrussell" 

change to 

ZSH_THEME="agnoster"

#exit zsh and rerun zsh

