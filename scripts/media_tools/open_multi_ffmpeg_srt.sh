#!/bin/bash

# 默认值
NUM_CHANNELS=5  # 要启动的 ffmpeg 进程数量
BASE_PORT=9090  # ffmpeg 进程的基础端口号
DEVICE_IP="192.168.10.11"  # 设备的 IP 地址

# 第二个脚本的路径
SECOND_SCRIPT="/home/leonli/Videos/send_srt.sh"

# 获取命令行参数
DEVICE_IP="${1:-$DEVICE_IP}"  # 从第一个参数获取 IP 地址，或使用默认值
BASE_PORT="${2:-$BASE_PORT}"  # 从第二个参数获取基础端口，或使用默认值
NUM_CHANNELS="${3:-$NUM_CHANNELS}"  # 从第三个参数获取通道数量，或使用默认值

# 循环打开 xterm 窗口并运行脚本
for (( i=0; i<$NUM_CHANNELS; i++ ))
do
    PORT=$((BASE_PORT + i))  # 计算当前通道的端口号
    xterm -hold -e "$SECOND_SCRIPT $DEVICE_IP $PORT" &  # 打开新的 xterm 窗口并使用计算的端口运行脚本
done

echo "Started $NUM_CHANNELS ffmpeg processes in separate xterm windows."  # 打印消息，指示已启动的进程数量