#!/usr/bin/env bash
# ============================================
# 代理检测逻辑测试（验证 WSL/直连等场景）
# 输出到 logs/test_proxy.log（仅最近一次）
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
log_setup "test_proxy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "代理逻辑测试 - $(date)"
echo "=========================================="

PASSED=0
FAILED=0

CORE_SCRIPT="${PROJECT_ROOT}/scripts/chezmoi/chezmoi_core.sh"

# 辅助函数：在子 shell 中执行 chezmoi_detect_proxy
detect_proxy_in_subshell() {
    local env_vars="$1"
    bash -c "
source '${CORE_SCRIPT}'
${env_vars} chezmoi_detect_proxy
" 2>/dev/null
}

# 测试 1: 环境变量优先
echo -n "[Test 1] 环境变量 PROXY 优先 ... "
result=$(detect_proxy_in_subshell "PROXY=http://192.168.1.100:8080")

if [[ "$result" == "http://192.168.1.100:8080" ]]; then
    echo "PASS (got: $result)"
    PASSED=$((PASSED + 1))
else
    echo "FAIL (expected: http://192.168.1.100:8080, got: $result)"
    FAILED=$((FAILED + 1))
fi

# 测试 2: http_proxy 环境变量
echo -n "[Test 2] http_proxy 环境变量 ... "
result=$(detect_proxy_in_subshell "http_proxy=http://127.0.0.1:7890")

if [[ "$result" == "http://127.0.0.1:7890" ]]; then
    echo "PASS (got: $result)"
    PASSED=$((PASSED + 1))
else
    echo "FAIL (expected: http://127.0.0.1:7890, got: $result)"
    FAILED=$((FAILED + 1))
fi

# 测试 3: 无环境变量时默认 127.0.0.1:7890
echo -n "[Test 3] 默认代理地址 ... "
result=$(detect_proxy_in_subshell "unset http_proxy https_proxy PROXY;")

if [[ "$result" == "http://127.0.0.1:7890" ]]; then
    echo "PASS (got: $result)"
    PASSED=$((PASSED + 1))
else
    echo "FAIL (expected: http://127.0.0.1:7890, got: $result)"
    FAILED=$((FAILED + 1))
fi

# 测试 4: 代理补全 http:// 前缀
echo -n "[Test 4] 代理补全 http:// 前缀 ... "
result=$(bash -c "
source '${CORE_SCRIPT}'
chezmoi_setup_proxy '127.0.0.1:7890' >/dev/null 2>&1
echo \"\$PROXY\"
" 2>/dev/null)

if [[ "$result" == "http://127.0.0.1:7890" ]]; then
    echo "PASS (got: $result)"
    PASSED=$((PASSED + 1))
else
    echo "FAIL (expected: http://127.0.0.1:7890, got: $result)"
    FAILED=$((FAILED + 1))
fi

# 测试 5: 已有 http:// 前缀不再重复添加
echo -n "[Test 5] 已有 http:// 前缀不重复添加 ... "
result=$(bash -c "
source '${CORE_SCRIPT}'
chezmoi_setup_proxy 'http://192.168.1.1:7890' >/dev/null 2>&1
echo \"\$PROXY\"
" 2>/dev/null)

if [[ "$result" == "http://192.168.1.1:7890" ]]; then
    echo "PASS (got: $result)"
    PASSED=$((PASSED + 1))
else
    echo "FAIL (expected: http://192.168.1.1:7890, got: $result)"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "=========================================="
echo "结果: $PASSED 通过, $FAILED 失败"
echo "=========================================="

exit $FAILED
