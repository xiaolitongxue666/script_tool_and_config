原始输入文件:
input_8b_h265_4kp25.00_20m.ts  
input_8b_h265_4kp50.00_20m.ts
input_8b_h265_4kp59.94_20m.ts

一、文件到文件转码：
转码：	H265 -> H265
ffmpeg -re -c:v h265_ni_dec -i input_8b_h265_4kp50.00_20m.ts -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" output_t408_8bit_h265_4kp50_20m.ts -y

转码：	H265 -> H264
ffmpeg -re -c:v h265_ni_dec -i input_8b_h265_4kp50.00_20m.ts -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" output_t408_8bit_h264_4kp50_20m.ts -y

转码:	H264 -> H264
ffmpeg -re -c:v h264_ni_dec -i output_t408_8bit_h264_4kp50_20m.ts -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" ouput_another_t408_8bit_h264_4kp50_20m.ts -y

转码:	H264 -> H265
ffmpeg -re -c:v h264_ni_dec -i output_t408_8bit_h264_4kp50_20m.ts -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" ouput_another_t408_8bit_h265_4kp50_20m.ts -y

解码:
//纯软件解码
ffmpeg -i input_8b_h265_4kp50.00_20m.ts -s 3840x2160 -pix_fmt yuv420p yuv420p_orig_4kp50.yuv
ffmpeg -i input_8b_h265_1080P60.ts -s 1920x1080 -pix_fmt yuv420p yuv420p_orig_1080P60.yuv

//NETINT硬件解码
ffmpeg -y -hide_banner -nostdin -vsync 0 -c:v h265_ni_dec -i input_8b_h265_4kp50.00_20m.ts -s 3840x2160 -pix_fmt yuv420p -c:v rawvideo yuv420p_orig_4kp50.yuv
ffmpeg -y -hide_banner -nostdin -vsync 0 -c:v h264_ni_dec -i output_t408_8bit_h264_4kp50_20m.ts -s 3840x2160 -pix_fmt yuv420p -c:v rawvideo yuv420p_orig_4kp50.yuv

播放YUV:
ffplay -video_size 3840x2160 -i yuv420p_orig_4kp50.yuv
ffplay -video_size 1920x1080 -i yuv420p_orig_1080P60.yuv

二、YUV到编码到流
编码:	YUV->H265->实时流(RTP单播)
ffmpeg -r 50 -stream_loop -1 -f rawvideo -pix_fmt yuv420p -s 3840x2160  -i yuv420p_orig_4kp50.yuv -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 3840x2160 -r 50 -f  rtp_mpegts rtp://192.168.1.139:9900

编码:	YUV->H264->实时流(UDP组播)
ffmpeg -r 50 -stream_loop -1 -f rawvideo -pix_fmt yuv420p -s 3840x2160  -i yuv420p_orig_4kp50.yuv -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 3840x2160 -r 50 -f  rtp_mpegts rtp://192.168.1.139:9900

三、文件到转码到流
ffmpeg -re -stream_loop -1 -c:v h265_ni_dec -i input_8b_h265_4kp50.00_20m.ts -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

转码：  H265->h264->实时流（RTP单播）
ffmpeg -re -c:v h265_ni_dec -i input_8b_h265_4kp50.00_20m.ts -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

转码：	H265->h265->实时流（UDP组播）
ffmpeg -re -c:v h265_ni_dec -i input_8b_h265_4kp50.00_20m.ts -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -f mpegts udp://192.168.1.139:9900

推流：	在T408机器上，自已推流，自己收流（UDP组播）
ffmpeg -re -stream_loop -1 -i input_8b_h265_4kp50.00_20m.ts -acodec copy -vcodec copy -f mpegts udp://127.0.0.1:5000

转码：	自己收流->h265->流输出（RTP单播输出）
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=50000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 2路4KP25 HEVC输入 → 2路4KP25 AVC输入 (25 | (66/79) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

// 2路4KP25 HEVC输入 → 2路4KP25 HEVC输入 (25 | (66/87) 正常播放)
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

================================================================================================================================================

// 1路4KP50 HEVC输入 → 1路4KP50 AVC输入 (50 | (65/86) 正常播放, 运行一段时间后才能达到50fps )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

// 1路4KP50 HEVC输入 → 1路4KP50 HEVC输入 (50 | (64/86) 正常播放, 运行一段时间后才能达到50fps)
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

================================================================================================================================================

// 1路4KP59.94 HEVC输入 → 1路4KP59.94 AVC输入 (56 | (10/83) 无法正常播放,卡顿, 马赛克 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

// 1路4KP59.94 HEVC输入 → 1路4KP59.94 HEVC输入 (56 | (73/100) 无法正常播放,卡顿, 马赛克 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

================================================================================================================================================

// 1路4KP60 HEVC输入 → 1路1路4KP60 AVC输入 (13 | (2/6) 无法正常播放,卡顿严重 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

// 1路4KP60 HEVC输入 → 1路1路4KP60 HEVC输入 (14 | (3/14) 无法正常播放,卡顿严重 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

================================================================================================================================================

// 1路4KP60 AVC输入 → 1路4KP60 AVC输入 (13 | (3/10) 无法正常播放,卡顿严重 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

// 1路4KP60 AVC输入 → 1路4KP60 HEVC输入 (14 | (6/20) 无法正常播放,卡顿严重 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  

================================================================================================================================================

//多路进多路出带滤镜
ffmpeg -re -c:v h265_ni_dec \
-i udp://127.0.0.1:5000?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

//一入多出转码无滤镜(测试播放正常 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9900 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9901 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 1280x720 -f  rtp_mpegts rtp://192.168.1.139:9902 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 640x480 -f  rtp_mpegts rtp://192.168.1.139:9903 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -s 320x240 -f  rtp_mpegts rtp://192.168.1.139:9904

//一入多出转码同一滤镜 透明水印  * 2 (测试01)
ffmpeg -re -c:v h265_ni_dec \
-i udp://127.0.0.1:5000?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto[transparent];[0]asplit=5[aout1][aout2][aout3][aout4][aout5];[transparent]split=5[out1][out2][out3][out4][out5]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out1] -map [aout1] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9900 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out2] -map [aout2] -s 1920x1080 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9901 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out3] -map [aout3] -s 1280x720 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9902 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out4] -map [aout4] -s 640x480 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9903 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out5] -map [aout5] -s 480x360 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9904

//一入多出转码同一滤镜 透明水印  * 2 (测试02)
ffmpeg -re -c:v h265_ni_dec \
-i udp://127.0.0.1:5001?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto[transparent];[0]asplit=5[aout1][aout2][aout3][aout4][aout5];[transparent]split=5[out1][out2][out3][out4][out5]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out1] -map [aout1] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9905 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out2] -map [aout2] -s 1920x1080 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9906 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out3] -map [aout3] -s 1280x720 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9907 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out4] -map [aout4] -s 640x480 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9908 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out5] -map [aout5] -s 480x360 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9909


//一入多出转码同一滤镜 透明水印 (测试设置使用CPU核心数)
ffmpeg -re -c:v h265_ni_dec \
-threads 1 \
-i udp://127.0.0.1:5000?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto[transparent];[0]asplit=5[aout1][aout2][aout3][aout4][aout5];[transparent]split=5[out1][out2][out3][out4][out5]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out1] -map [aout1] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9900 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out2] -map [aout2] -s 1920x1080 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9901 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out3] -map [aout3] -s 1280x720 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9902 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out4] -map [aout4] -s 640x480 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9903 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out5] -map [aout5] -s 480x360 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9904

//测试1  正常播放
ffmpeg -re -c:v h265_ni_dec \
-threads 1 \
-i udp://127.0.0.1:5000?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto[transparent];[0]asplit=4[aout1][aout2][aout3][aout4];[transparent]split=4[out1][out2][out3][out4]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out1] -map [aout1] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9900 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out2] -map [aout2] -s 1280x720 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9901 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out3] -map [aout3] -s 640x480 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9902 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out4] -map [aout4] -s 480x360 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9903

//测试2  正常播放
ffmpeg -re -c:v h265_ni_dec \
-threads 1 \
-i udp://127.0.0.1:5001?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto[transparent];[0]asplit=4[aout1][aout2][aout3][aout4];[transparent]split=4[out1][out2][out3][out4]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out1] -map [aout1] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9905 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out2] -map [aout2] -s 1280x720 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9906 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out3] -map [aout3] -s 640x480 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9907 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out4] -map [aout4] -s 480x360 -r 30 -f  rtp_mpegts rtp://192.168.1.139:9908


//一入多出转码同一滤镜 透明水印 (测试不修改帧率)
ffmpeg -re -c:v h265_ni_dec \
-threads 1 \
-i udp://127.0.0.1:5000?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo];[0][logo]overlay=W/2:0:format=auto[transparent];[0]asplit=5[aout1][aout2][aout3][aout4][aout5];[transparent]split=5[out1][out2][out3][out4][out5]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out1] -map [aout1] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9900 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out2] -map [aout2] -s 1920x1080 -f  rtp_mpegts rtp://192.168.1.139:9901 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out3] -map [aout3] -s 1280x720 -f  rtp_mpegts rtp://192.168.1.139:9902 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out4] -map [aout4] -s 640x480 -f  rtp_mpegts rtp://192.168.1.139:9903 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [out5] -map [aout5] -s 480x360 -f  rtp_mpegts rtp://192.168.1.139:9904

//一入多出转码同各自滤镜 透明水印(正常播放)
ffmpeg -re -c:v h265_ni_dec \
-i udp://127.0.0.1:5000?fifo_size=100000000 \
-i 1080P.png \
-filter_complex \
'[1]format=rgba,colorchannelmixer=aa=0.5[logo1];[1]format=rgba,colorchannelmixer=aa=0.5[logo2];[0]split=2[v1][v2];[v1][logo1]overlay=W/2:0:format=auto[vout1];[v2][logo2]overlay=W/4:0:format=auto[vout2];[0]asplit=2[aout1][aout2]' \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [vout1] -map [aout1] -s 1280x720 -f  rtp_mpegts rtp://192.168.1.139:9900 \
-c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1" -map [vout2] -map [aout2] -s 640x480 -f  rtp_mpegts rtp://192.168.1.139:9901

================================================================================================================================================

// 1路1080P30 HEVC输入 → 8路1080P30 AVC输出 (30 | (10/83) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907

// 1路1080P30 HEVC输入 → 8路1080P30 HEVC输出 (30 | (09/88) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907

// 1路1080P30 AVC输入 → 8路1080P30 AVC输出 (30 | (10/82) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907

// 1路1080P30 AVC输入 → 8路1080P30 HEVC输出 (30 | (10/84) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907

================================================================================================================================================

// 1路1080P60 HEVC输入 → 4路1080P60 AVC输出 (60 | (19/83) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903

// 1路1080P60 HEVC输入 → 4路1080P60 HEVC输出 (60 | (19/85) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903

// 1路1080P60 AVC输入 → 4路1080P60 AVC输出 (60 | (20/83) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903

// 1路1080P60 AVC输入 → 4路1080P60 HEVC输出 (60 | (21/85) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903

================================================================================================================================================

// 1路720P30 HEVC输入 → 12路720P30 AVC输出 (30 | (4/69) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9908 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9909 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9910 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9911

// 1路720P30 HEVC输入 → 12路720P30 HEVC输出 (30 | (4/63) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9908 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9909 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9910 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9911

// 1路720P30 AVC输入 → 12路720P30 AVC输出 (30 | (4/65) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9908 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9909 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9910 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9911

// 1路720P30 AVC输入 → 12路720P30 HEVC输出 (30 | (4/64) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9908 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9909 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9910 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9911

================================================================================================================================================

// 1路720P60 HEVC输入 → 6路720P60 AVC输出 (60 | (8/64) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905

// 1路720P60 HEVC输入 → 6路720P60 HEVC输出 (60 | (9/60) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905

// 1路720P60 AVC输入 → 6路720P60 AVC输出 (60 | (9/58) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905

// 1路720P60 AVC输入 → 6路720P60 HEVC输出 (60 | (21/85) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905

================================================================================================================================================

// 7路1080P30 HEVC输入 → 7路1080P30 HEVC输出 (30 | (70/97) 正常播放 )
ffmpeg -re -c:v h265_ni_dec -hwframes 0 -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 8路1080P30 HEVC输入 → 8路1080P30 AVC输出 (30 | (88/100) 正常播放,板卡负载会到100,fps均稳定在30帧 )
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 7路1080P30 AVC输入 → 7路1080P30 HEVC输出 (30 | (76/99) 正常播放 )
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 8路1080P30 AVC输入 → 8路1080P30 AVC输出 (30 | (96/99) 正常播放 备注: 资源使用接近极限,间隔出现掉帧 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 4路1080P60 AVC输入 → 4路1080P60 AVC输出 (60 | (92/91) 正常播放 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 3路1080P60 AVC输入 → 3路1080P60 HEVC输出 (60 | (64/74) 正常播放 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 4路1080P60 HEVC输入 → 4路1080P60 AVC输出 (60 | (79/88) 正常播放 ) 
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 3路1080P60 HEVC输入 → 3路1080P60 HEVC输出 (60 | (58/73) 播放有花屏马赛克 ) 
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 7路720P60 HEVC输入 → 7路720P60 HEVC输出 (60 | (64/79) 正常播放 ) 
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 8路720P60 HEVC输入 → 8路720P60 AVC输出 (60 | (76/79) 正常播放 ) 
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 7路720P60 AVC输入 → 7路720P60 HEVC输出 (60 | (72/80) 正常播放 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 8路720P60 AVC输入 → 8路720P60 AVC输出 (60 | (86/82) 正常播放 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 15路720P30 HEVC输入 → 15路720P30 HEVC输出 (30 | (75/96) 正常播放 ) 
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 16路720P30 HEVC输入 → 16路720P30 AVC输出 (30 | (79/88) 部分通道正常播放 部分通道帧数维持在29 ) 
ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

// 14路720P30 AVC输入 → 14路720P30 HEVC输出 (30 | (71/84) 正常播放 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h265_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

// 15路720P30 AVC输入 → 15路720P30 AVC输出 (30 | (79/88) 部分通道正常播放 部分通道帧数维持在29 ) 
ffmpeg -re -c:v h264_ni_dec -i udp://127.0.0.1:5000?fifo_size=100000000 -c:v h264_ni_enc -xcoder-params "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

================================================================================================================================================

//Test
ffmpeg -stream_loop -1 -c:v h265_ni_dec -i 1080P30_H265_MPEG1-2.ts -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9901 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9902 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9903 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9904 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9905 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9906 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9907

ffmpeg -re -c:v h265_ni_dec -i udp://127.0.0.1:5000?fifo_size=400000000 -c:v h264_ni_enc -xcoder-params  "RcEnable=1:bitrate=20000000:repeatHeaders=1"  -f  rtp_mpegts rtp://192.168.1.139:9900

//添加osd
#播放yuv raw视频
ffplay -i overlap.yuv -f rawvideo -vcodec rawvideo -pixel_format yuv420p -video_size 1920x1080 -framerate 30

#保存网络串流到YUV
ffmpeg -i rtp://192.168.2.102:5004 -f rawvideo -vcodec rawvideo -pix_fmt yuv420p -s 1920x1080 -r 30 -t 5 rawvideo5.yuv


#yuv-overlay-yuv
ffmpeg -f rawvideo -vcodec rawvideo -pix_fmt yuv420p -s 1920x1080 -r 30 -i rawvideo.yuv -i 1.png -filter_complex "overlay=(main_w-overlay_w-20):(20)" -f rawvideo -vcodec rawvideo -pix_fmt yuv420p -s 1920x1080 -r 30 overlap.yuv

#用空输出来测试yuv-overlay-null,loop输入
ffmpeg -stream_loop -1 -f rawvideo -vcodec rawvideo -pix_fmt yuv420p -s 1920x1080 -r 30 -i rawvideo10.yuv -i 1.png -filter_complex "overlay=(main_w-overlay_w-20):(20)" -f rawvideo -vcodec rawvideo -pix_fmt yuv420p -s 1920x1080 -r 30 -f null -

//建Ramdisk的script
#!/bin/bash  
ramfs_size_mb=1024  
mount_point=~/volatile  

ramfs_size_sectors=$((${ramfs_size_mb}*1024*1024/512))  
ramdisk_dev=`hdid -nomount ram://${ramfs_size_sectors}`  
newfs_hfs -v 'Volatile' ${ramdisk_dev}  
mkdir -p ${mount_point}  
mount -o noatime -t hfs ${ramdisk_dev} ${mount_point}  

echo "remove with:"  
echo "umount ${mount_point}"  
echo "diskutil eject ${ramdisk_dev}"

=================================================================================
# 显示T408固件信息
nvme list

# 初始化NETINT设备
init_rsrc

# 显示pcie信息
lspci -vvv -d 1d82:

lspci -vvv -d 1d82: | grep Width

lspci -vvv -d 1d82: | grep Speed

#监控加载
sudo watch -n 1 -d ni_rsrc_mon

FFmpeg https://ffmpeg.org/ffmpeg.html
-hide_banner 	- 关闭一些默认打印
-i 			- 输入文件
-c 			- 编解码器的名字
-r 			- 设置帧速率(Hz值，分数或缩写)
-pix_fmt 		- 设置像素格式
-s 			- 设置帧大小(WxH或简称)
-f 			- 设置格式(例子: -f rtp_mpegts rtp://120.120.120.217:5000)
-re 			- 以原始帧率读取,相当于设置成 -readrate 1.
-stream_loop 	- 设置输入流应循环的次数
-pix_fmt 		- 设置像素格式
-y 			- 覆盖输出文件
-vsync		- 视频同步方法(0:直通 | 1:帧将被复制和丢弃，以准确实现所要求的恒定帧速率 | 2:视觉效果 帧与其时间戳一起传递或丢弃，以防止 2 个帧具有相同的时间戳)

-xcoder-params
RcEnable 		- 使能rate控制(1:Enable)
bitrate 		- 设置编码比特率(bps), 
repeatHeaders - 指定编码器是否在所有i帧上重复VPS/SPS/PPS报头(1:Enable)

# taskset 命令使用
taskset -c -p <PID>
taskset -pc <CORE_INDEX> <PID>



