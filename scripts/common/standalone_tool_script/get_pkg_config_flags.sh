#!/bin/sh

set -x

# 获取 libavutil 的编译标志
pkg-config --cflags libavutil

# 获取 libavutil 的链接库
pkg-config --libs libavutil