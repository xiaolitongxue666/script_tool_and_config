#!/bin/bash

set -x

# 应用补丁文件
patch -p0 < from_p_to_c.patch

cat parents.py
