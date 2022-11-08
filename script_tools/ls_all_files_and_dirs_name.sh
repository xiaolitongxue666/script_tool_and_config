#!/bin/bash

function get_dirs_and_files(){
    for element in `ls $1`
    do  
        dir_or_file=$1"/"$element
        if [ -d $dir_or_file ]
        then 
            echo $dir_or_file
            get_dirs_and_files $dir_or_file
        else
            echo $dir_or_file
        fi  
    done
}
root_dir="$1"
get_dirs_and_files $root_dir

# If want to add a string at each line head, can use like 
# ./ls_all_dirs_name.sh application | awk '{print "head string" $0 }'

# If want to echo to clipboard
# install a mini tool use like "apt-get install xclip"
#./ls_all_dirs_name.sh component | awk '{print "INCLUDES\t+= -I$(MK_ROOT)/" $0 }' | xclip 

