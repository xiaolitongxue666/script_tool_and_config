#!/bin/bash

set -x 

cp children.py.bak children.py

cat children.py

cp parents.py.bak parents.py

cat parents.py

# p is old file , c is newer file
diff -Nur parents.py children.py > from_p_to_c.patch

cat from_p_to_c.patch


