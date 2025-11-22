#!/bin/bash

set -x 

# 恢复原始文件
cp children.py.bak children.py

cat children.py

cp parents.py.bak parents.py

cat parents.py

# 创建补丁文件
# p 是旧文件，c 是新文件
diff -Nur parents.py children.py > from_p_to_c.patch

cat from_p_to_c.patch
