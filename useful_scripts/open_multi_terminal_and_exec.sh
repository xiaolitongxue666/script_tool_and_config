#!/bin/bash

set -x

# Example
#ffmpeg -i 720P30H264.ts -i 200x200.png -filter_complex overlay=W-w:56 output_test.ts
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 200x200.png -filter_complex overlay=W-w:0 -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 200x200.png -filter_complex "[1]lut=a=val*0.3[a];[0][a]overlay=W-w:0" -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i News_Background_Left.mp4 -filter_complex "[1]lut=a=val*0.3[a];[0][a]overlay=W/2:0" -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i News_Background_Left.mp4 -filter_complex overlay=W/2:0 -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 1.2M_2M.ts -filter_complex overlay=W/2:0 -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i udp://127.0.0.1:5001?fifo_size=100000000 -filter_complex overlay=W/2:0 -f rtp_mpegts rtp://192.168.1.139:9900

# Right add watermark way
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 1080P.png -filter_complex "[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto" -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -i 1080P.png -filter_complex "[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto" -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

# Multi example
# for i in {0..0}
# do
#    echo "Open terminal index $i and run ffmpeg commands"
#    #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -i udp://127.0.0.1:500$i?fifo_size=100000000 -c:v libx265 -f rtp_mpegts rtp://192.168.1.139:990$i" &
#    xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:500$i?fifo_size=100000000 -i 200x200.png -filter_complex \"[1]lut=a=val*0.3[a];[0][a]overlay=W-w:0\" -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:990$i" &
# done

# echo "Welcome to leonli's ffmpeg test script"

# options=(
#    "Set input multi number (1~8)"
#    "Set transcode solution"
#    "Run test !"
# )

# Main loop
# COLUMNS=20
# while true; do
#     cd $base_dir
#     echo -e "\e[33mChoose an option:\e[0m"
#     select opt in "${options[@]}"; do
#         case $opt in
#             "Set input multi number (1~8)")
#                 echo -e "\e[33mYou chose $REPLY which is $opt\e[0m"

#                 read -p "Press [1~8] to confirm the use of multi input number. " -n 1 -r
#                 echo ""
#                #  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#                #    echo "Please remove release package files you do not wish to use and try again."
#                #    end_script
#                #  fi
#                echo -e "\e[33mYou enter number is $REPLY\e[0m"
#                break
#             ;;
#             *) echo -e "\e[31\Invalid choice!\e[0m"
#             ;;
#         esac
#     done
# done


for ((i = 0; i < $1; i++));
do
    src_port=$((5000+$i));
    dst_port=$((9900+$i));
   echo "Open terminal index $i and run ffmpeg commands from src port $src_port to dst port $dst_port"
   # CPU
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -i udp://127.0.0.1:$src_port?fifo_size=100000000 -c:v libx265 -f rtp_mpegts rtp://192.168.1.139:$dst_port" &

   #T408
   # -> H264
   # None
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # Overlay
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex overlay=0:0 -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # Transparent
   xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=0:0:format=auto\" -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # -> H265
   # None
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # Overlay
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex overlay=0:0 -c:v h265_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # Transparent
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto\" -c:v h265_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &
done

