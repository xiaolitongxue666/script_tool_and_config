#!/usr/bin/env bash
set -euo pipefail

# ============================================
# diff/patch 演示：应用补丁文件
# 用法: bash create_patch.sh && bash use_patch.sh
# ============================================
# 2026-09 修复：旧版用相对路径 `patch -p0 < from_p_to_c.patch`，
#   只有在脚本所在目录执行才可用；现统一 cd 到脚本目录。

cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ ! -f from_p_to_c.patch ]]; then
    echo "[ERROR] from_p_to_c.patch not found. Run create_patch.sh first." >&2
    exit 1
fi

# -p0：不去除任何路径层级（补丁头为 `--- parents.py` / `+++ children.py`）
# -N：忽略「补丁已应用」的情况，避免交互式提问
# -s：静默（仅错误输出）
patch -p0 -N -s < from_p_to_c.patch || true

cat parents.py
