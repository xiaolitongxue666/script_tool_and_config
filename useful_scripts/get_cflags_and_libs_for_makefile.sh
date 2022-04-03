#!/bin/sh

set -x

pkg-config --cflags libavutil

pkg-config --libs libavutil