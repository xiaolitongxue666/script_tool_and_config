#!/bin/bash

set -x

patch -p0 < from_p_to_c.patch

cat parents.py

