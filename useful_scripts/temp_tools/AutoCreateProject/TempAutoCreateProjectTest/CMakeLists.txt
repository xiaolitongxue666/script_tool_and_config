cmake_minimum_required(VERSION 2.8)
project(AutoCreateProjectTest)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include_directories(./src)
include_directories(./src/sub_1)
include_directories(./src/sub_2)

set(src_dir_list_files  ./src/*.c ./src/*.h 
						./src/sub_1/*.c ./src/sub_1/*.h 
						./src/sub_1/*.c ./src/sub_2/*.h
						)

file(GLOB_RECURSE SOURCES ${src_dir_list_files})

message(---Debug Echo---)
foreach(src_file ${SOURCES})
    message(src_file=${src_file})
endforeach()


add_executable(AutoCreateProjectTest ${SOURCES})
