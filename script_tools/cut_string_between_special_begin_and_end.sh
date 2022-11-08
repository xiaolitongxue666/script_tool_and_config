#!/bin/bash

set -x

# Get openresty install path
openresty_install_path=$(openresty -V 2>&1 | tr '\n' '\f' | sed -r 's/.*--prefix=(.*)[[:space:]]--with-cc.*/\1/')
echo $openresty_install_path

# Get openresty config file with absolute path
openresty_config_file_path=$(openresty -t 2>&1 | tr '\n' '\f' | sed -r 's/.*file[[:space:]](.*)[[:space:]]syntax.*/\1/')
echo $openresty_config_file_path

