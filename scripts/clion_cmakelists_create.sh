#  Ctrl + Shift + A -> 重新加载 Cmake 项目

#!/bin/bash

# 递归列出目录的函数
list_dirs_recursively() {
    local dir="$1"
    find "$dir" -type d
}

# 项目名称使用当前目录名
project_path=$(pwd)
project_name="${project_path##*/}"
echo "Project name is $project_name"

# CMakeLists.txt 更新
cmake_list_file_path="./CMakeLists.txt"

# 重新创建 cmake 列表文件
rm -rf $cmake_list_file_path
touch $cmake_list_file_path

# 写入 cmake 列表文件
echo -e "cmake_minimum_required(VERSION 3.9)" >> $cmake_list_file_path
echo -e "project($project_name)" >> $cmake_list_file_path
echo -e "set(CMAKE_CXX_STANDARD 11)" >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# 包含目录
list_dirs_recursively "./src" | awk '{print "include_directories("$0")" }' >> "./include_directories.cmake"
echo -e "include(./include_directories.cmake)" >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# 源文件
echo "file(GLOB_RECURSE SOURCES "  >> $cmake_list_file_path
ls -F | grep "/$" | awk '{print "./"$0"*.c ./"$0"*.h" }' | xargs >> $cmake_list_file_path
echo ")"  >> $cmake_list_file_path

# 新行
echo -e "\n" >> $cmake_list_file_path

# 最终可执行文件
echo -e "add_executable($project_name \${SOURCES})" >> $cmake_list_file_path