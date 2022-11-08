#!/bin/bash
ls_all_dirs_name.sh . | awk '{print "include_directories(" $0 ")" > "include_directories.cmake" }' 