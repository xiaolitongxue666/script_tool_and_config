# Git Bash .bashrc
# 非登录交互 shell 配置文件
# 参考: https://git-scm.com/docs/git-bash

# ============================================
# 系统检测
# ============================================
# 确保仅在 Git Bash 环境中加载此配置
if [[ ! "$OSTYPE" =~ ^(msys|mingw|cygwin) ]]; then
    return 0
fi

# ============================================
# 加载 .bash_profile
# ============================================
# 如果 .bash_profile 存在，则加载它
if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi

# ============================================
# inshellisense 按键绑定
# ============================================
# 如果已安装 inshellisense，加载按键绑定
if [ -f ~/.inshellisense/key-bindings.bash ]; then
    source ~/.inshellisense/key-bindings.bash
fi

