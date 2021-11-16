#!/bin/bash

set -x

# https://unix.stackexchange.com/questions/454880/open-multiple-terminal-but-without-closing-the-previous-one-using-shell-script
# Open multiple terminals and executing commands

#!/bin/bash
for i in {1..5}
do
   echo "Open terminal index $i and run ffmpeg commands"
   xterm -title "Terminal $i" -e bash -c "htop" &
done
