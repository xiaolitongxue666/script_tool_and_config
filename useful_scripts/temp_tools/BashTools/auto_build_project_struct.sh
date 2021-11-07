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
#build_sh contains different projects build shell
if [ ! -d "./build_sh" ]; then
  mkdir ./build_sh
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

#Create C project ignore file
if [ $project_type = "c" ];then
echo "Create a C project ignore file"
cat > $git_ignore_file_path <<EOF
	# Prerequisites
	*.d

	# Object files
	*.o
	*.ko
	*.obj
	*.elf

	# Linker output
	*.ilk
	*.map
	*.exp

	# Precompiled Headers
	*.gch
	*.pch

	# Libraries
	*.lib
	*.a
	*.la
	*.lo

	# Shared objects (inc. Windows DLLs)
	*.dll
	*.so
	*.so.*
	*.dylib

	# Executables
	*.exe
	*.out
	*.app
	*.i*86
	*.x86_64
	*.hex

	# Debug files
	*.dSYM/
	*.su
	*.idb
	*.pdb

	# Kernel Module Compile Results
	*.mod*
	*.cmd
	.tmp_versions/
	modules.order
	Module.symvers
	Mkfile.old
	dkms.conf
EOF
fi

#Create C++ project ignore file
if [ $project_type = "cpp" ];then
    echo "Create a C++ project ignore file"
	cat > $git_ignore_file_path <<EOF
	# Prerequisites
	*.d

	# Compiled Object files
	*.slo
	*.lo
	*.o
	*.obj

	# Precompiled Headers
	*.gch
	*.pch

	# Compiled Dynamic libraries
	*.so
	*.dylib
	*.dll

	# Fortran module files
	*.mod
	*.smod

	# Compiled Static libraries
	*.lai
	*.la
	*.a
	*.lib

	# Executables
	*.exe
	*.out
	*.app

EOF
fi

  #Write default ignore rules
  #IDE(Idea) data
  #A new line
  echo -e "\n" >> $git_ignore_file_path
  echo -e "	# Personal intermediate dirs and files" >> $git_ignore_file_path
  echo -e "	.idea/" >> $git_ignore_file_path
  echo -e "	cmake-build-debug/" >> $git_ignore_file_path
  #Build shell and cmake data
  echo -e "	build_sh/" >> $git_ignore_file_path
  #A new line
  echo -e "\n" >> $git_ignore_file_path
fi

#CMakeLists.txt update
cmake_list_file_path="./CMakeLists.txt"

#Recreate cmke list file
rm -rf $cmake_list_file_path
touch $cmake_list_file_path

#Write cmake list file
echo -e "cmake_minimum_required(VERSION 3.9)" >> $cmake_list_file_path
echo -e "project($project_name)" >> $cmake_list_file_path
echo -e "set(CMAKE_CXX_STANDARD 11)" >> $cmake_list_file_path

#A new line
echo -e "\n" >> $cmake_list_file_path

#include dirs
ls_dirs_name.sh ./src | awk '{print "include_directories("$0")" }' >> $cmake_list_file_path

#A new line
echo -e "\n" >> $cmake_list_file_path

#src files
echo -e "file(GLOB_RECURSE SOURCES "src/*.c" "src/*.h")" >> $cmake_list_file_path

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