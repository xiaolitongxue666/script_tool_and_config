#!/usr/bin/env bash
set -euo pipefail

# ============================================
# diff/patch 演示：生成补丁文件
# 用法: bash create_patch.sh
# ============================================
# 自包含说明（2026-09 修复）：
#   旧版用 `cp parents.py.bak parents.py` 取「原始版本」，但那些 *.bak
#   被 .gitignore 忽略，且历史上一度散落在 scripts/linux/patch_examples/，
#   导致新克隆后必然 `No such file or directory`。现改为内联写出原始版本。
#   另：旧版用相对路径，只有在脚本所在目录执行才可用；现统一 cd 到脚本目录。

cd "$(dirname "${BASH_SOURCE[0]}")"

# 1) 写出「原始版本」parents.py（比 children.py 多一行）
cat > parents.py <<'EOF'
print("/children")
print("/parents/children")

EOF

# 2) 写出「修改后版本」children.py
cat > children.py <<'EOF'
print("/children")
EOF

# 3) 生成补丁：p = 旧文件 parents.py，c = 新文件 children.py
# diff 在文件不同时返回 1，故需吞掉退出码
diff -Nur parents.py children.py > from_p_to_c.patch || true

cat from_p_to_c.patch
