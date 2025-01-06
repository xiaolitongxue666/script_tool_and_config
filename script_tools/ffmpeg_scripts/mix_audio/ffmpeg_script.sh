#!/bin/bash

set -x

# Target sampling rate and channels
target_ar=44100
target_ac=2

# Function to get duration with error handling
get_duration() {
    local file="$1"
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || {
        echo "Error getting duration of $file" >&2
        return 1 # Indicate failure
    }
}

# Function: Resample audio (with checks)
resample_audio() {
    local input="$1"
    local output="${input%.*}.repick.mp3"

    # Check if output file exists and has content
    if [[ -f "$output" && -s "$output" ]]; then
        echo "$output already exists, skipping resampling."
        echo "$output"
        return 0 # Success, skip
    fi

    ffmpeg -i "$input" -ar "$target_ar" -ac "$target_ac" "$output" 2>/dev/null || {
        echo "Error resampling $input" >&2
        return 1
    }

    echo "$output"
}

# Declare an array to hold audio files
audio_files=("Jay_01.mp3" "Jay_02.mp3")

# Initialize an array to hold resampled files and durations
resampled_files=()
durations=()

# Resample each audio file if necessary
for file in "${audio_files[@]}"; do
    resampled_file=$(resample_audio "$file") || exit 1
    duration=$(get_duration "$resampled_file") || exit 1
    resampled_files+=("$resampled_file")
    durations+=("$duration")
done

# Check if durations are valid numbers
for duration in "${durations[@]}"; do
    if [[ ! "$duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Invalid duration value: $duration" >&2
        exit 1
    fi
done

# Calculate minimum duration, handling potential empty strings or zero
min_duration="${durations[0]}"
for duration in "${durations[@]}"; do
    if [[ -z "$duration" ]]; then
        echo "One or more durations are empty." >&2
        exit 1
    fi
    if (( $(echo "$duration < $min_duration" | bc -l) )); then
        min_duration="$duration"
    fi
done

if (( $(echo "$min_duration == 0" | bc -l) )); then
    echo "Minimum duration is zero. Cannot proceed." >&2
    exit 1
fi

# Prepare the filter_complex string for mixing
filter_complex=""
for i in "${!resampled_files[@]}"; do
    if [[ $i -eq 0 ]]; then
        filter_complex+="[${i}:a]"
    else
        filter_complex+="[${i}:a]atrim=duration=$min_duration[trimmed$i];"
        filter_complex+="[trimmed$i]"
    fi
done

# Add the amix filter
filter_complex+="amix=inputs=${#resampled_files[@]}:duration=first:dropout_transition=3[a]"

# Mix audio files using the minimum duration, with -y to overwrite output file
ffmpeg -y \
    $(for file in "${resampled_files[@]}"; do echo -n "-i $file "; done) \
    -filter_complex "$filter_complex" \
    -map "[a]" \
    -c:a libmp3lame \
    -qscale:a 2 \
    Jay_mixed.mp3