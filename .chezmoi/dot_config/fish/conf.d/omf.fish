# Oh My Fish 安装路径
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# 加载 Oh My Fish 配置
if test -f "$OMF_PATH/init.fish"
    source $OMF_PATH/init.fish
end

