#!/bin/bash

echo -n "How many random numbers do you want to generate? "
read max

for (( start = 1; start <= $max; start++ ))
do
  echo -e $RANDOM
done
