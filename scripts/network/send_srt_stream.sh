#!/bin/bash

# 设置默认参数值
DEVICE_IP="192.168.10.11"
PORT="9095"
INPUT_FILE="/d/Video/TestVideo/1080p30.ts"

# 从命令行获取参数
if [ "$1" != "" ]; then
  DEVICE_IP="$1"
fi
if [ "$2" != "" ]; then
  PORT="$2"
fi
if [ "$3" != "" ]; then
  INPUT_FILE="$3"
fi

# 主循环
while true; do
  ffmpeg -re -stream_loop -1 -i "$INPUT_FILE" \
  -acodec copy -vcodec copy -strict -2 -y -fflags +genpts -rw_timeout 20000000 \
  -f mpegts "srt://${DEVICE_IP}:${PORT}?streamid=publish:mystream&pkt_size=1316"

  if [ $? -eq 0 ]; then
    echo "FFmpeg 正常退出。"
    break
  else
    echo "FFmpeg 连接断开。正在重新连接..."
    sleep 1
  fi
done