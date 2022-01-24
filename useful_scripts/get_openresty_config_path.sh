#!/bin/bash

#set -x

x=`openresty -V 2>&1`
echo $x | sed -r 's/ /\n/g' | grep "\-\-prefix"
