cmake_minimum_required(VERSION 2.8)
project(AutoCreateProjectTest)
set(CMAKE_CXX_STANDARD 11)


include_directories(./src)
include_directories(./src/sub_1)
include_directories(./src/sub_2)


file(GLOB_RECURSE SOURCES src/*.c src/*.h)


message(---Debug Echo---)
foreach(src_file ${SOURCES})
    message(src_file=${src_file})
endforeach()


add_executable(AutoCreateProjectTest ${SOURCES})
