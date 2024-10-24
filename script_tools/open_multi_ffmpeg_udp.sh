#!/bin/bash

# Number of times to run the command
NUM_CHANNELS=5

# Base port number
BASE_PORT=9090

# IP address of the device
DEVICE_IP="192.168.10.11"

# Input file
INPUT_FILE="1080p30.ts"

# FFmpeg command path
FFMPEG_COMMAND="/home/leonli/Videos/ffmpeg"

# ffmpeg common parameters
FFMPEG_PARAMS="-re -stream_loop -1 -i '${INPUT_FILE}' -acodec copy -vcodec copy -strict -2 -y -fflags +genpts -rw_timeout 20000000"

# SRT common parameters
SRT_PARAMS="pkt_size=1316&latency=20000&oheadbw=25"

# Loop to open xterm windows and run the commands
for (( i=0; i<$NUM_CHANNELS; i++ ))
do
    PORT=$((BASE_PORT + i))
    COMMAND="$FFMPEG_COMMAND $FFMPEG_PARAMS -f mpegts 'srt://${DEVICE_IP}:${PORT}?${SRT_PARAMS}'"
    xterm -hold -e "$COMMAND" &
done

echo "Started $NUM_CHANNELS ffmpeg processes in separate xterm windows."
