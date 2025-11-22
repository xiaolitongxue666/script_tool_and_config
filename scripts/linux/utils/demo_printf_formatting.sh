#!/bin/bash

# 参考链接:
# https://stackoverflow.com/questions/71483708/shell-script-output-formatting-echo
# https://linuxize.com/post/bash-printf-command/
# https://www.cyberciti.biz/faq/ksh-csh-shell-assign-store-printf-result-variable/

set -x

printf "打开的问题: %s\n已关闭的问题: %s\n" "34" "65"

printf "十进制: %d\n十六进制: %x\n八进制: %o\n" 100 100 100
# 十进制: 100
# 十六进制: 64
# 八进制: 144


# %20s 表示字段至少 20 个字符长
printf "%20s %d\n" Mark 305
#                 Mark 305

# 0 是一个标志，用前导零填充数字而不是空格。输出文本至少 10 个字符
printf "%0*d" 10 5
# 0000000005

printf "%.3f" 1.61803398
# printf "%.3f" 1.61803398

# 将 printf 输出设置到变量
dir="/home/httpd"
j=$(printf "%s" $dir)
echo "$j"
printf "%s\n" $j

# 测试
index=$(printf "%0*d" 3 5)
printf "index-%s\n" $index
