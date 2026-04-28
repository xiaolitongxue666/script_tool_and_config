#!/bin/sh

# 获取 SVN 版本号
BUILD_VERSION=$(svn info --xml > /tmp/revision && expr substr `head -13 /tmp/revision|grep "revision"` 11 4)
# 获取构建日期
BUILD_DATE=$(date +%Y%m%d_%T)
# 获取构建者
BUILD_BY="$(whoami)"

# 如果要在 make 或 gcc 中使用这些信息，可以尝试以下行
#DEFS += -D_ARM_ -DFIXED_POINT=32 -D_REVISION=$(BUILD_VERSION) -D_BUILD_DATE=$(BUILD_DATE) -D_BUILD_BY=$(BUILD_BY)

echo "BUILD_VERSION = " $BUILD_VERSION
echo "BUILD_DATE = " $BUILD_DATE
echo "BUILD_BY = " $BUILD_BY
