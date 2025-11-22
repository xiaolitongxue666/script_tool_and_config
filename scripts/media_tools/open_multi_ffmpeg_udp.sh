#!/bin/bash

# 运行命令的次数
NUM_CHANNELS=5

# 基础端口号
BASE_PORT=9090

# 设备的 IP 地址
DEVICE_IP="192.168.10.11"

# 输入文件
INPUT_FILE="1080p30.ts"

# FFmpeg 命令路径
FFMPEG_COMMAND="/home/leonli/Videos/ffmpeg"

# ffmpeg 通用参数
FFMPEG_PARAMS="-re -stream_loop -1 -i '${INPUT_FILE}' -acodec copy -vcodec copy -strict -2 -y -fflags +genpts -rw_timeout 20000000"

# SRT 通用参数
SRT_PARAMS="pkt_size=1316&latency=20000&oheadbw=25"

# 循环打开 xterm 窗口并运行命令
for (( i=0; i<$NUM_CHANNELS; i++ ))
do
    PORT=$((BASE_PORT + i))
    COMMAND="$FFMPEG_COMMAND $FFMPEG_PARAMS -f mpegts 'srt://${DEVICE_IP}:${PORT}?${SRT_PARAMS}'"
    xterm -hold -e "$COMMAND" &
done

echo "Started $NUM_CHANNELS ffmpeg processes in separate xterm windows."
