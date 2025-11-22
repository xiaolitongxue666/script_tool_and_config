#!/bin/bash

set -x 

cp children.py.bak children.py

cat children.py

cp parents.py.bak parents.py

cat parents.py

# p 是旧文件，c 是新文件
diff -Nur parents.py children.py > from_p_to_c.patch

cat from_p_to_c.patch


