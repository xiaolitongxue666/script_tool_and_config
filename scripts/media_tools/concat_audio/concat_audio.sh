#!/bin/bash

set -x

# 使用 FFmpeg 连接音频文件
# -f concat: 使用 concat 分离器
# -i contact.txt: 输入文件列表
# -c copy: 直接复制流，不重新编码
ffmpeg -f concat -i contact.txt -c copy $1

