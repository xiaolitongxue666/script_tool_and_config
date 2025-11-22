#!/bin/bash

set -x

# 获取 OpenResty 安装路径
openresty_install_path=$(openresty -V 2>&1 | tr '\n' '\f' | sed -r 's/.*--prefix=(.*)[[:space:]]--with-cc.*/\1/')
echo $openresty_install_path


# 获取 OpenResty 配置文件绝对路径
openresty_config_file_path=$(openresty -t 2>&1 | tr '\n' '\f' | sed -r 's/.*file[[:space:]](.*)[[:space:]]syntax.*/\1/')
echo $openresty_config_file_path

# 获取 OpenResty 配置目录路径
openresty_config_path=${openresty_config_file_path%/*}
echo $openresty_config_path

# 复制 music-room-test.conf 到 openresty_config_path
# echo "复制 music-room-test.conf 到 $openresty_config_path"
# cp ./music-room-test.conf $openresty_config_path

# 将 music room 子配置添加到 OpenResty 主配置文件
# echo "将 music room 子配置添加到 OpenResty 主配置文件"
# echo "include $openresty_config_path/music-room-test.conf;"

