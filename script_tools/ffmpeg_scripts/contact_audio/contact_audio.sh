#!/bin/bash

set -x

ffmpeg -f concat -i contact.txt -c copy $1

