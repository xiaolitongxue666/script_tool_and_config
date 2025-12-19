#!/bin/bash

set -x

# FFmpeg 示例命令（已注释）
#ffmpeg -i 720P30H264.ts -i 200x200.png -filter_complex overlay=W-w:56 output_test.ts
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 200x200.png -filter_complex overlay=W-w:0 -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 200x200.png -filter_complex "[1]lut=a=val*0.3[a];[0][a]overlay=W-w:0" -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i News_Background_Left.mp4 -filter_complex "[1]lut=a=val*0.3[a];[0][a]overlay=W/2:0" -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i News_Background_Left.mp4 -filter_complex overlay=W/2:0 -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 1.2M_2M.ts -filter_complex overlay=W/2:0 -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i udp://127.0.0.1:5001?fifo_size=100000000 -filter_complex overlay=W/2:0 -f rtp_mpegts rtp://192.168.1.139:9900

# 右侧添加水印的方法
#ffmpeg -i udp://127.0.0.1:5000?fifo_size=100000000 -i 1080P.png -filter_complex "[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto" -f rtp_mpegts rtp://192.168.1.139:9900
#ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -i 1080P.png -filter_complex "[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto" -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

# 多终端示例（已注释）
# for i in {0..0}
# do
#    echo "打开终端索引 $i 并运行 ffmpeg 命令"
#    #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -i udp://127.0.0.1:500$i?fifo_size=100000000 -c:v libx265 -f rtp_mpegts rtp://192.168.1.139:990$i" &
#    xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:500$i?fifo_size=100000000 -i 200x200.png -filter_complex \"[1]lut=a=val*0.3[a];[0][a]overlay=W-w:0\" -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:990$i" &
# done

# echo "欢迎使用 leonli 的 ffmpeg 测试脚本"

# 选项菜单（已注释）
# options=(
#    "设置输入多路数量 (1~8)"
#    "设置转码方案"
#    "运行测试！"
# )

# 主循环（已注释）
# COLUMNS=20
# while true; do
#     cd $base_dir
#     echo -e "\e[33m选择选项:\e[0m"
#     select opt in "${options[@]}"; do
#         case $opt in
#             "设置输入多路数量 (1~8)")
#                 echo -e "\e[33m您选择了 $REPLY，即 $opt\e[0m"
#
#                 read -p "按 [1~8] 确认使用多路输入数量。 " -n 1 -r
#                 echo ""
#                #  if [[ ! $REPLY =~ ^[Yy]$ ]]; thenkkk
#                #    echo "请删除您不想使用的发布包文件，然后重试。"
#                #    end_script
#                #  fi
#                echo -e "\e[33m您输入的数字是 $REPLY\e[0m"
#                break
#             ;;
#             *) echo -e "\e[31\无效选择！\e[0m"
#             ;;
#         esac
#     done
# done


# 打开多个终端并运行 FFmpeg 命令
for ((i = 0; i < $1; i++));
do
    src_port=$((5000+$i));
    dst_port=$((9900+$i));
   echo "打开终端索引 $i 并从源端口 $src_port 到目标端口 $dst_port 运行 ffmpeg 命令"
   # CPU 转码（已注释）
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -i udp://127.0.0.1:$src_port?fifo_size=100000000 -c:v libx265 -f rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # T408 硬件转码
   # -> H264
   # 无叠加（已注释）
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # 叠加水印（已注释）
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex overlay=0:0 -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # 透明叠加
   xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=0:0:format=auto\" -c:v h264_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # -> H265
   # 无叠加（已注释）
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # 叠加（已注释）
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex overlay=0:0 -c:v h265_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &

   # 透明叠加（已注释）
   #xterm -title "Terminal $i" -e bash -c "ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:$src_port?fifo_size=100000000 -i 1080P.png -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto\" -c:v h265_ni_enc -xcoder-params  \"RcEnable=1:bitrate=20000000:repeatHeaders=1\"  -f  rtp_mpegts rtp://192.168.1.139:$dst_port" &
done
