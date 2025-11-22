#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

function start_script() {
    printf "\n"
    printf "Start $1 script\n"
}

function end_script() {
    printf "\n"
    printf "End script\n"

    trap - EXIT
    exit 0
}


# 黑色        0;30     深灰色       1;30
# 红色        0;31     浅红色       1;31
# 绿色        0;32     浅绿色       1;32
# 棕色/橙色   0;33     黄色         1;33
# 蓝色        0;34     浅蓝色       1;34
# 紫色        0;35     浅紫色       1;35
# 青色        0;36     浅青色       1;36
# 浅灰色      0;37     白色         1;37

readonly BLACK='\e[0;30m'
readonly RED='\e[0;31m'
readonly GREEN='\e[0;32m'
readonly ORANGE='\e[0;33m'
readonly BLUE='\e[0;34m'
readonly PURPLE='\e[0;35m'
readonly CYAN='\e[0;36m'
readonly LIGHT_GRAY='\e[0;37m'

readonly DARK_GRAY='\e[1;30m'
readonly LIGHT_RED='\e[1;31m'
readonly LIGHT_GREEN='\e[1;32m'
readonly YELLOW='\e[1;33m'
readonly LIGHT_BLUE='\e[1;34m'
readonly LIGHT_PURPLE='\e[1;35m'
readonly LIGHT_CYAN='\e[1;36m'
readonly WHITE='\e[1;37m'
readonly NO_COLOR='\e[0m'

function echo_color_message(){
    echo -e "$1 $2 $NO_COLOR"
}

