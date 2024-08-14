#!/bin/bash

while true; do
  ffmpeg -re -stream_loop -1 -i 'caminandes_llamigos_720p.ts' \
  -acodec copy -vcodec copy -strict -2 -y -fflags +genpts -rw_timeout 20000000 \
  -f mpegts 'srt://192.168.10.63:8890?streamid=publish:mystream&pkt_size=1316'

  if [ $? -eq 0 ]; then
    echo "FFmpeg exited normally."
    break
  else
    echo "FFmpeg disconnected. Reconnecting..."
    sleep 1
  fi
done