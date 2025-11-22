#!/bin/bash

#set -x

x=`openresty -V 2>&1`
y=$(echo $x | sed -r 's/ /\n/g' | grep "\-\-prefix" | awk -F [=] {'printf $2'} | tr -d '\r')
echo $y
