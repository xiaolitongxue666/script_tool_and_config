#!/bin/bash

# Default values
NUM_CHANNELS=5  # Number of ffmpeg processes to start
BASE_PORT=9090  # Base port number for ffmpeg processes
DEVICE_IP="192.168.10.11"  # IP address of the device

# Path to the second script
SECOND_SCRIPT="/home/leonli/Videos/send_srt.sh"

# Get command line arguments
DEVICE_IP="${1:-$DEVICE_IP}"  # Get the IP address from the first argument, or use the default value
BASE_PORT="${2:-$BASE_PORT}"  # Get the base port from the second argument, or use the default value
NUM_CHANNELS="${3:-$NUM_CHANNELS}"  # Get the number of channels from the third argument, or use the default value

# Loop to open xterm windows and run the script
for (( i=0; i<$NUM_CHANNELS; i++ ))
do
    PORT=$((BASE_PORT + i))  # Calculate the port number for the current channel
    xterm -hold -e "$SECOND_SCRIPT $DEVICE_IP $PORT" &  # Open a new xterm window and run the script with the calculated port
done

echo "Started $NUM_CHANNELS ffmpeg processes in separate xterm windows."  # Print a message indicating the number of processes started