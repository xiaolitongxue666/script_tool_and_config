#!/bin/bash

source common.sh

function replace_text_in_files(){

    echo_color_message $YELLOW "Replace text in files $1 $2"

    sed -i "s|$1|$2|g" test_file.txt
}

main(){

    replace_text_in_files $1 $2

    exit 0
}

main $1 $2
