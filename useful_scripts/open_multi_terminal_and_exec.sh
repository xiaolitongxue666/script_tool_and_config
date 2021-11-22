#!/bin/bash

set -x

# https://unix.stackexchange.com/questions/454880/open-multiple-terminal-but-without-closing-the-previous-one-using-shell-script
# Open multiple terminals and executing commands

for i in {0..6}
do
   echo "Open terminal index $i and run ffmpeg commands"
   xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -hwframes 0 -i udp://127.0.0.1:500$i?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:990$i" &
   #sleep 5
done


