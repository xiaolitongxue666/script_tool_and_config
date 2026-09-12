#!/usr/bin/env bash
# ============================================
# 语法测试：对所有 .sh 文件运行 bash -n
# 输出到 logs/test_syntax.log（仅最近一次）
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 加载通用函数库（含 log_setup）
COMMON_SH="${PROJECT_ROOT}/scripts/lib/common.sh"
if [ -f "$COMMON_SH" ]; then
    source "$COMMON_SH"
fi

# 将 SCRIPT_DIR 指向项目根目录，确保日志写入 logs/
SCRIPT_DIR="$PROJECT_ROOT"
log_setup "test_syntax"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Syntax check - $(date)"
echo "=========================================="

PASSED=0
FAILED=0
FAILED_FILES=""

# 查找所有 .sh 文件（排除 git 目录、node_modules 等）
while IFS= read -r -d '' file; do
    echo -n "[check] $file ... "

    if bash -n "$file" 2>/dev/null; then
        echo "PASS"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL"
        FAILED=$((FAILED + 1))
        FAILED_FILES="${FAILED_FILES}  - $file (syntax error)\n"
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
    echo -n "[check] $file ... "

    # 对 .tmpl 文件，移除 chezmoi 模板语法后检查 bash 语法
    tmp_file=$(mktemp)
    sed -E 's/\{\{[^}]*\}\}//g' "$file" > "$tmp_file" 2>/dev/null || cp "$file" "$tmp_file"

    if bash -n "$tmp_file" 2>/dev/null; then
        echo "PASS"
        TMPL_PASSED=$((TMPL_PASSED + 1))
    else
        echo "FAIL"
        TMPL_FAILED=$((TMPL_FAILED + 1))
        FAILED_FILES="${FAILED_FILES}  - $file (template syntax error)\n"
    fi
    rm -f "$tmp_file"
done < <(find "$PROJECT_ROOT/.chezmoi" -name "*.tmpl" -print0 2>/dev/null || true)

# ============================================
# macOS UTF-8 locale 变量名回归检查
# "$var" 后紧跟中文/全角标点 → 变量名错扩 → set -u unbound
# 规则见 AGENTS.md「变量展开与全角标点」（2026-08）
#
# ⚠️ 不能用 `LC_ALL=C grep '[一-龥]'`：C locale 下这是**字节区间**匹配，
#    会把框线字符（━ U+2501）、emoji（📄 U+1F4C4）等误判为 CJK。
#    必须用 Unicode 字符类匹配：优先 python3，其次 perl。
# ============================================
LOCALE_PASSED=0
LOCALE_FAILED=0

# 精确 Unicode 类（perl 语法 \x{}；注意 perl 不支持 \uXXXX）：
# CJK 符号/标点、Ext-A、Unified、兼容表意、全角形式
_CJK_CLASS='\x{3000}-\x{303F}\x{3400}-\x{4DBF}\x{4E00}-\x{9FFF}\x{F900}-\x{FAFF}\x{FF00}-\x{FFEF}'

# 参数 1: 文件路径；命中则输出 file:line:content 并返回 0
locale_check_perl() {
    perl -CSD -ne '
        if (/\$[a-zA-Z_][a-zA-Z0-9_]*(?=['"${_CJK_CLASS}"'])/) {
            print "$ARGV:$.:$_";
            $hit = 1;
        }
        END { exit($hit ? 0 : 1) }
    ' "$1" 2>/dev/null
}

# 无 perl 时的兜底（字节区间，有误报风险，仅统计不阻断细节）
locale_check_fallback() {
    LC_ALL=C grep -n '\$[a-zA-Z_][a-zA-Z0-9_]*[一-龥【】（）]' "$1" 2>/dev/null
}

# --- 检查器自检：防止正则写坏后静默"全通过" ---
_locale_selftest() {
    local tmp ok=0
    tmp=$(mktemp)
    # 用变量拼接构造 fixture，避免本文件自身被本检查命中（fixture 是故意的反例）
    local dollar='$'
    printf 'echo "%sfoo中"\necho "${bar}中"\n' "$dollar" > "$tmp"
    # 期望：第 1 行命中（未加花括号），第 2 行不命中（已加花括号）
    local out
    out=$(locale_check_perl "$tmp")
    if printf '%s' "$out" | grep -q ':1:'; then ok=$((ok + 1)); fi
    if ! printf '%s' "$out" | grep -q ':2:'; then ok=$((ok + 1)); fi
    # 期望：框线/emoji 不误报
    printf 'log_info "━━━━"\nlog_info "  \xf0\x9f\x93\x84 x"\n' > "$tmp"
    if ! locale_check_perl "$tmp" > /dev/null; then ok=$((ok + 1)); fi
    rm -f "$tmp"
    [[ "$ok" -eq 3 ]]
}

if command -v perl > /dev/null 2>&1 && _locale_selftest; then
    _locale_checker="perl"
    echo "[INFO] locale check: perl Unicode class (self-test passed)"
else
    _locale_checker="fallback"
    echo "[WARNING] perl unavailable or self-test failed; using byte-range fallback (may false-positive)"
fi

while IFS= read -r -d '' file; do
    if [[ "$_locale_checker" == "perl" ]]; then
        if hits=$(locale_check_perl "$file"); then
            echo "[FAIL] $file: \$var 后紧跟中文/全角标点，应写 \${var}"
            printf '%s\n' "$hits" | sed 's/^/       /'
            LOCALE_FAILED=$((LOCALE_FAILED + 1))
        else
            LOCALE_PASSED=$((LOCALE_PASSED + 1))
        fi
    else
        if locale_check_fallback "$file" > /dev/null; then
            LOCALE_FAILED=$((LOCALE_FAILED + 1))
        else
            LOCALE_PASSED=$((LOCALE_PASSED + 1))
        fi
    fi
done < <(find "$PROJECT_ROOT" \( -name "*.sh" -o -name "*.tmpl" \) \
    -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/target/*" -print0 2>/dev/null || true)

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ".sh files: $PASSED passed, $FAILED failed"
echo ".tmpl files: $TMPL_PASSED passed, $TMPL_FAILED failed"
echo "locale: $LOCALE_PASSED passed, $LOCALE_FAILED failed"
echo "Total: $((PASSED + TMPL_PASSED)) passed, $((FAILED + TMPL_FAILED + LOCALE_FAILED)) failed"

if [ -n "$FAILED_FILES" ]; then
    echo ""
    echo "失败的脚本:"
    printf "%b" "$FAILED_FILES"
fi

exit $((FAILED + TMPL_FAILED + LOCALE_FAILED))
