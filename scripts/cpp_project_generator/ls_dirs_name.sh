#!/bin/bash
function getdir(){
    for element in `ls $1`
    do  
        dir_or_file=$1"/"$element
        if [ -d $dir_or_file ]
        then 
            echo $dir_or_file
            getdir $dir_or_file
        # else
        #     echo $dir_or_file
        fi  
    done
}
root_dir="$1"
getdir $root_dir

# 如果想在每行开头添加字符串，可以使用这个
# ./ls_all_dirs_name.sh application | awk '{print "head string" $0 }'

# 如果想输出到剪贴板
# 安装一个小工具使用 "apt-get install xclip"
# ./ls_all_dirs_name.sh component | awk '{print "INCLUDES\t+= -I$(MK_ROOT)/" $0 }' | xclip 