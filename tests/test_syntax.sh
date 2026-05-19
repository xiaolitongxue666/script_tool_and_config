#!/usr/bin/env bash
# ============================================
# 语法测试：对所有 .sh 文件运行 bash -n
# 输出到 logs/test_syntax.log（仅最近一次）
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 加载通用函数库（含 log_setup）
COMMON_SH="${PROJECT_ROOT}/scripts/common.sh"
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
fi

# 将 SCRIPT_DIR 指向项目根目录，确保日志写入 logs/
SCRIPT_DIR="$PROJECT_ROOT"
log_setup "test_syntax"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "语法测试 - $(date)"
echo "=========================================="

PASSED=0
FAILED=0
FAILED_FILES=""

# 查找所有 .sh 文件（排除 git 目录、node_modules 等）
while IFS= read -r -d '' file; do
    echo -n "[检查] $file ... "

    if bash -n "$file" 2>/dev/null; then
        echo "PASS"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL"
        FAILED=$((FAILED + 1))
        FAILED_FILES="${FAILED_FILES}  - $file (语法错误)\n"
    fi
done < <(find "$PROJECT_ROOT" -name "*.sh" \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/target/*" \
    -print0 2>/dev/null || true)

# 统计 .tmpl 文件中的 shell 脚本（chezmoi 模板）
TMPL_PASSED=0
TMPL_FAILED=0
while IFS= read -r -d '' file; do
    # 跳过不是 shell 脚本的 .tmpl
    first_line=$(head -n 1 "$file" 2>/dev/null || echo "")
    if [[ "$first_line" != "#!/bin/bash" ]] && [[ "$first_line" != "#!/usr/bin/env bash" ]]; then
        continue
    fi
    echo -n "[检查] $file ... "

    # 对 .tmpl 文件，移除 chezmoi 模板语法后检查 bash 语法
    tmp_file=$(mktemp)
    sed -E 's/\{\{[^}]*\}\}//g' "$file" > "$tmp_file" 2>/dev/null || cp "$file" "$tmp_file"

    if bash -n "$tmp_file" 2>/dev/null; then
        echo "PASS"
        TMPL_PASSED=$((TMPL_PASSED + 1))
    else
        echo "FAIL"
        TMPL_FAILED=$((TMPL_FAILED + 1))
        FAILED_FILES="${FAILED_FILES}  - $file (模板语法错误)\n"
    fi
    rm -f "$tmp_file"
done < <(find "$PROJECT_ROOT/.chezmoi" -name "*.tmpl" -print0 2>/dev/null || true)

echo ""
echo "=========================================="
echo "结果摘要"
echo "=========================================="
echo ".sh 文件: $PASSED 通过, $FAILED 失败"
echo ".tmpl 文件: $TMPL_PASSED 通过, $TMPL_FAILED 失败"
echo "总: $((PASSED + TMPL_PASSED)) 通过, $((FAILED + TMPL_FAILED)) 失败"

if [ -n "$FAILED_FILES" ]; then
    echo ""
    echo "失败的脚本:"
    printf "%b" "$FAILED_FILES"
fi

exit $((FAILED + TMPL_FAILED))
