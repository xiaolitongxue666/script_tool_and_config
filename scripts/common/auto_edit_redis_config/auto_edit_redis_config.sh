#!/bin/bash

set -x 

# 修改 Redis 配置文件中的端口号
# 将端口从 6379 改为 63798
sed -i "s/port 6379/port 63798/" /Users/liyong/Code/Bash/audo_edit_redis_config
