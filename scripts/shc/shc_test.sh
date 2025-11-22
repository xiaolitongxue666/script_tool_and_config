#!/bin/bash

# 生成随机数示例脚本
echo -n "您想生成多少个随机数？ "
read max

for (( start = 1; start <= $max; start++ ))
do
  echo -e $RANDOM
done
