#  Ctrl + Shift + A -> Reload Cmake Project

#!/bin/bash

# Function to list directories recursively
list_dirs_recursively() {
    local dir="$1"
    find "$dir" -type d
}

# Project name is now dir name
project_path=$(pwd)
project_name="${project_path##*/}"
echo "Project name is $project_name"

# CMakeLists.txt update
cmake_list_file_path="./CMakeLists.txt"

# Recreate cmke list file
rm -rf $cmake_list_file_path
touch $cmake_list_file_path

# Write cmake list file
echo -e "cmake_minimum_required(VERSION 3.9)" >> $cmake_list_file_path
echo -e "project($project_name)" >> $cmake_list_file_path
echo -e "set(CMAKE_CXX_STANDARD 11)" >> $cmake_list_file_path

# A new line
echo -e "\n" >> $cmake_list_file_path

# Include dirs
list_dirs_recursively "./src" | awk '{print "include_directories("$0")" }' >> "./include_directories.cmake"
echo -e "include(./include_directories.cmake)" >> $cmake_list_file_path

# A new line
echo -e "\n" >> $cmake_list_file_path

# Src files
echo "file(GLOB_RECURSE SOURCES "  >> $cmake_list_file_path
ls -F | grep "/$" | awk '{print "./"$0"*.c ./"$0"*.h" }' | xargs >> $cmake_list_file_path
echo ")"  >> $cmake_list_file_path

# A new line
echo -e "\n" >> $cmake_list_file_path

# Final executable file
echo -e "add_executable($project_name \${SOURCES})" >> $cmake_list_file_path