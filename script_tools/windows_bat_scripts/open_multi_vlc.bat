@echo off
setlocal enabledelayedexpansion
set "address=udp://@192.168.10.214"
set "pkt_size=1316"
set "start_num=9900"
set "repeat_count=5"

set /a max_index=%repeat_count%-1

for /L %%i in (0,1,%max_index%) do (
    set /a current_num=%start_num% + %%i
    echo start /d "D:\Program Files (x86)\VideoLAN\VLC" vlc.exe -vvv %address%:!current_num!?pkt_size=%pkt_size%
    start /d "D:\Program Files (x86)\VideoLAN\VLC" vlc.exe -vvv %address%:!current_num!?pkt_size=%pkt_size%
)

endlocal
