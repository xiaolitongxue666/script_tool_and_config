#!/bin/bash

# https://stackoverflow.com/questions/71483708/shell-script-output-formatting-echo
# https://linuxize.com/post/bash-printf-command/
# https://www.cyberciti.biz/faq/ksh-csh-shell-assign-store-printf-result-variable/

set -x

printf "Open issues: %s\nClosed issues: %s\n" "34" "65"

printf "Decimal: %d\nHex: %x\nOctal: %o\n" 100 100 100
# Decimal: 100
# Hex: 64
# Octal: 144


# %20s means set the field at least 20 characters long
printf "%20s %d\n" Mark 305
#                 Mark 305

# 0 is a flag that pads the number with leading zeros instead of blanks. The output text will have at least 10 characters
printf "%0*d" 10 5
# 0000000005

printf "%.3f" 1.61803398
# printf "%.3f" 1.61803398

# set printf output to a variable
dir="/home/httpd"
j=$(printf "%s" $dir)
echo "$j"
printf "%s\n" $j

# test
index=$(printf "%0*d" 3 5)
printf "index-%s\n" $index