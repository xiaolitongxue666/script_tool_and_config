#!/bin/sh

# CMake 构建脚本
# 功能：使用 CMake 构建项目
# 步骤：
#   1. 运行 cmake 生成构建文件
#   2. 清理之前的构建文件
#   3. 编译项目

cmake ..
make clean
make
