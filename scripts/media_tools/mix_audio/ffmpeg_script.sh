#!/bin/bash

set -x

# 目标采样率和声道数
target_ar=44100
target_ac=2

# 获取时长的函数（带错误处理）
get_duration() {
    local file="$1"
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || {
        echo "错误: 无法获取文件时长: $file" >&2
        return 1 # 指示失败
    }
}

# 函数：重采样音频（带检查）
resample_audio() {
    local input="$1"
    local output="${input%.*}.repick.mp3"

    # 检查输出文件是否存在且有内容
    if [[ -f "$output" && -s "$output" ]]; then
        echo "$output 已存在，跳过重采样。"
        echo "$output"
        return 0 # 成功，跳过
    fi

    ffmpeg -i "$input" -ar "$target_ar" -ac "$target_ac" "$output" 2>/dev/null || {
        echo "错误: 重采样失败: $input" >&2
        return 1
    }

    echo "$output"
}

# 声明一个数组来保存音频文件
audio_files=("Jay_01.mp3" "Jay_02.mp3")

# 初始化数组来保存重采样文件和时长
resampled_files=()
durations=()

# 必要时重采样每个音频文件
for file in "${audio_files[@]}"; do
    resampled_file=$(resample_audio "$file") || exit 1
    duration=$(get_duration "$resampled_file") || exit 1
    resampled_files+=("$resampled_file")
    durations+=("$duration")
done

# 检查时长是否为有效数字
for duration in "${durations[@]}"; do
    if [[ ! "$duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "错误: 无效的时长值: $duration" >&2
        exit 1
    fi
done

# 计算最小时长，处理可能的空字符串或零
min_duration="${durations[0]}"
for duration in "${durations[@]}"; do
    if [[ -z "$duration" ]]; then
        echo "错误: 一个或多个时长为空。" >&2
        exit 1
    fi
    if (( $(echo "$duration < $min_duration" | bc -l) )); then
        min_duration="$duration"
    fi
done

if (( $(echo "$min_duration == 0" | bc -l) )); then
    echo "错误: 最小时长为零，无法继续。" >&2
    exit 1
fi

# 准备用于混音的 filter_complex 字符串
filter_complex=""
for i in "${!resampled_files[@]}"; do
    if [[ $i -eq 0 ]]; then
        filter_complex+="[${i}:a]"
    else
        filter_complex+="[${i}:a]atrim=duration=$min_duration[trimmed$i];"
        filter_complex+="[trimmed$i]"
    fi
done

# 添加 amix 过滤器
filter_complex+="amix=inputs=${#resampled_files[@]}:duration=first:dropout_transition=3[a]"

# 使用最小时长混合音频文件，使用 -y 覆盖输出文件
ffmpeg -y \
    $(for file in "${resampled_files[@]}"; do echo -n "-i $file "; done) \
    -filter_complex "$filter_complex" \
    -map "[a]" \
    -c:a libmp3lame \
    -qscale:a 2 \
    Jay_mixed.mp3