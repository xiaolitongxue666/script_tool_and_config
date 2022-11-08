#!/bin/bash

set -x

# Get openresty install path
openresty_install_path=$(openresty -V 2>&1 | tr '\n' '\f' | sed -r 's/.*--prefix=(.*)[[:space:]]--with-cc.*/\1/')
echo $openresty_install_path


# Get openresty config file with absolute path
openresty_config_file_path=$(openresty -t 2>&1 | tr '\n' '\f' | sed -r 's/.*file[[:space:]](.*)[[:space:]]syntax.*/\1/')
echo $openresty_config_file_path

# Get openresty config path
openresty_config_path=${openresty_config_file_path%/*}
echo $openresty_config_path

# Copy music-room-test.conf to openresty_config_path
# echo "Copy music-room-test.conf to $openresty_config_path"
# cp ./music-room-test.conf $openresty_config_path

# Add music room sub config to oprensty main config file
# echo "Add music room sub config to openresty main config file"
# echo "include $openresty_config_path/music-room-test.conf;"

