#!/bin/bash

#Project name is now dir name
project_path=$(pwd)
project_name="${project_path##*/}"
echo "Project name is $project_name"

#Input parameters number
if [ $# != 1 ]; then
    echo "Usage: $0 <Project type>" 
    echo "e.g. : $0 c" 
    exit
fi

#Create project type C
if [ $1 = "c" ];then
    echo "Create a C project"
    project_type="c"
fi

#Create project type Cpp
if [ $1 = "cpp" ];then
    echo "Create a C++ project"
    project_type="cpp"
fi

#Dirs
#If dir not exist , create it.
#build contains different projects build shell
if [ ! -d "./build" ]; then
  mkdir ./build
  echo -e "#!/bin/sh" >> ./build/cmake_all_project.sh
  echo -e "" >> ./build/cmake_all_project.sh
  echo -e "cmake .." >> ./build/cmake_all_project.sh
  echo -e "make clean" >> ./build/cmake_all_project.sh
  echo -e "make" >> ./build/cmake_all_project.sh
fi

#If dir not exist , create it.
#tools contains extern tools 
if [ ! -d "./tools" ]; then
  mkdir ./tools
fi

#If dir not exist , create it.
#work_note contains project key note
if [ ! -d "./work_note" ]; then
  mkdir ./work_note
fi

#If dir not exist , create it.
#src contains all source code
if [ ! -d "./src" ]; then
  mkdir ./src
  echo "Please add source code files to die src and run this shell again !"
fi

#Files
#If file not exist , create it.
git_ignore_file_path="./.gitignore"
if [ ! -f "$git_ignore_file_path" ]; then
  touch "$git_ignore_file_path"

  #Write default ignore rules
  #IDE(Idea) data
  echo -e "# Personal intermediate dirs and files" >> $git_ignore_file_path
  echo -e ".idea/" >> $git_ignore_file_path
  echo -e "cmake-build-debug/" >> $git_ignore_file_path
  #Build shell and cmake data
  echo -e "./auto_build_project_struct.sh" >> $git_ignore_file_path
  echo -e "./ls_dirs_name.sh" >> $git_ignore_file_path
  echo -e "build/" >> $git_ignore_file_path
  #Default git ignore files
  echo -e "./git_ignore_default_c.txt" >> $git_ignore_file_path
  echo -e "./git_ignore_default_cpp.txt" >> $git_ignore_file_path
  #A new line
  echo -e "\n" >> $git_ignore_file_path
  #Intermediate files
  #Project type default ignore intermediate files
  cat ./git_ignore_default_c.txt >> $git_ignore_file_path
fi

#CMakeLists.txt update
cmake_list_file_path="./CMakeLists.txt"

#Recreate cmke list file
rm -rf $cmake_list_file_path
touch $cmake_list_file_path

#Write cmake list file
echo -e "cmake_minimum_required(VERSION 2.8)" >> $cmake_list_file_path
echo -e "project($project_name)" >> $cmake_list_file_path
echo -e "set(CMAKE_CXX_STANDARD 11)" >> $cmake_list_file_path
echo -e "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)" >> $cmake_list_file_path

#A new line
echo -e "\n" >> $cmake_list_file_path

#include dirs
echo -e "include_directories(./src)" >> $cmake_list_file_path
./ls_dirs_name.sh ./src | awk '{print "include_directories("$0")" }' >> $cmake_list_file_path

#A new line
echo -e "\n" >> $cmake_list_file_path

#src files
echo -e "set(src_dir_list_files ./src/*.c ./src/*.h " >> $cmake_list_file_path
./ls_dirs_name.sh ./src | awk '{print " "$0"/*c "$0"/*h " }' >> $cmake_list_file_path
echo -e ")" >> $cmake_list_file_path
echo -e "file(GLOB_RECURSE SOURCES \${src_dir_list_files})" >> $cmake_list_file_path

#A new line
echo -e "\n" >> $cmake_list_file_path

#cmake debug : list all src files
echo -e "message("---Debug Echo---")" >> $cmake_list_file_path
echo -e "foreach(src_file \${SOURCES})" >> $cmake_list_file_path
echo -e "    message(src_file="\${src_file}")" >> $cmake_list_file_path
echo -e "endforeach()" >> $cmake_list_file_path

#A new line
echo -e "\n" >> $cmake_list_file_path

#Final executable file
echo -e "add_executable($project_name \${SOURCES})" >> $cmake_list_file_path