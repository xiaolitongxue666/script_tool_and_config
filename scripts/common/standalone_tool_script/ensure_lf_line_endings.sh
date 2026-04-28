#!/usr/bin/env bash

# ============================================
# 确保所有文件使用 LF 换行符
# 在 Docker 构建前运行此脚本
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "=========================================="
echo "规范化文件换行符为 LF"
echo "=========================================="
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 查找所有文本文件（排除 Windows 脚本）
find "$PROJECT_ROOT" -type f \( \
    -name "*.sh" -o \
    -name "*.lua" -o \
    -name "*.toml" -o \
    -name "*.json" -o \
    -name "*.yaml" -o \
    -name "*.yml" -o \
    -name "*.md" -o \
    -name "*.txt" -o \
    -name "*.conf" -o \
    -name "*.config" -o \
    -name "*.ini" -o \
    -name "*.c" -o \
    -name "*.cpp" -o \
    -name "*.h" -o \
    -name "*.hpp" -o \
    -name "*.py" -o \
    -name "*.rs" -o \
    -name "*.go" -o \
    -name "*.java" -o \
    -name "*.js" -o \
    -name "*.ts" -o \
    -name "*.tsx" \
\) \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/.venv/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/scripts/windows/**/*.bat" \
    -not -path "*/scripts/windows/**/*.ps1" \
    -not -path "*/scripts/windows/**/*.cmd" \
    -print0 | while IFS= read -r -d '' file; do

    # 检查是否包含 CRLF
    if grep -q $'\r' "$file" 2>/dev/null; then
        echo "修复: $file"
        # 使用 sed 移除 CR
        sed -i 's/\r$//' "$file" 2>/dev/null || true
    fi
done

echo ""
echo "=========================================="
echo "完成"
echo "=========================================="
echo ""
echo "建议："
echo "1. 运行: git add --renormalize ."
echo "2. 运行: git commit -m 'Normalize line endings to LF'"
echo "3. 设置: git config core.autocrlf false"

