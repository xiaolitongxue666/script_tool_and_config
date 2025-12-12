# Fast Node Manager (fnm) 配置
# 参考: https://github.com/Schniz/fnm

# 初始化 fnm 环境并启用自动版本切换
# --use-on-cd: 当进入包含 .node-version 或 .nvmrc 文件的目录时自动切换 Node 版本
if command -v fnm > /dev/null
    fnm env --use-on-cd --shell fish | source
end

