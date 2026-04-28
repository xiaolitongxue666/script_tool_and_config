#!/usr/bin/env bash

# ============================================
# 检查和修复文件编码和换行符
# 确保所有文件使用 UTF-8 编码和 LF 换行符
# ============================================

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 统计
TOTAL_FILES=0
FIXED_FILES=0
ERROR_FILES=0
SKIPPED_FILES=0

# 需要跳过的目录和文件
SKIP_PATTERNS=(
    ".git"
    "node_modules"
    ".venv"
    "__pycache__"
    "*.pyc"
    "*.pyo"
    "*.so"
    "*.dll"
    "*.exe"
    "*.zip"
    "*.tar.gz"
    "*.jpg"
    "*.png"
    "*.gif"
    "*.ico"
    ".cache"
    "lazy-lock.json"
)

# 需要保留 CRLF 的文件（Windows 脚本）
CRLF_FILES=(
    "scripts/windows/**/*.bat"
    "scripts/windows/**/*.ps1"
    "scripts/windows/**/*.cmd"
)

# 检查文件是否应该跳过
should_skip() {
    local file="$1"
    local basename=$(basename "$file")

    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]] || [[ "$basename" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# 检查文件是否应该使用 CRLF
should_use_crlf() {
    local file="$1"

    for pattern in "${CRLF_FILES[@]}"; do
        if [[ "$file" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# 检查文件编码
check_encoding() {
    local file="$1"

    # 使用 file 命令检查编码
    if command -v file >/dev/null 2>&1; then
        local encoding=$(file -bi "$file" 2>/dev/null | sed -n 's/.*charset=\([^;]*\).*/\1/p' || echo "")
        if [[ -z "$encoding" ]]; then
            # 尝试检测是否为二进制文件
            if file "$file" | grep -q "text"; then
                encoding="utf-8"
            else
                encoding="binary"
            fi
        fi
        echo "$encoding"
    else
        # 如果没有 file 命令，假设是 UTF-8
        echo "utf-8"
    fi
}

# 检查换行符类型
check_line_ending() {
    local file="$1"

    # 检查是否包含 CRLF
    if grep -q $'\r' "$file" 2>/dev/null; then
        echo "CRLF"
    else
        echo "LF"
    fi
}

# 修复文件编码和换行符
fix_file() {
    local file="$1"
    local encoding="$2"
    local line_ending="$3"
    local should_crlf="$4"

    local temp_file="${file}.tmp"
    local fixed=0

    # 读取文件内容
    if [[ "$encoding" != "utf-8" ]] && [[ "$encoding" != "us-ascii" ]] && [[ "$encoding" != "binary" ]]; then
        echo -e "${YELLOW}  警告: 文件编码为 $encoding，尝试转换为 UTF-8${NC}"
        # 尝试使用 iconv 转换（如果可用）
        if command -v iconv >/dev/null 2>&1; then
            if iconv -f "$encoding" -t "UTF-8" "$file" > "$temp_file" 2>/dev/null; then
                mv "$temp_file" "$file"
                fixed=1
            fi
        fi
    fi

    # 修复换行符
    if [[ "$should_crlf" == "0" ]] && [[ "$line_ending" == "CRLF" ]]; then
        # 需要转换为 LF
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$file" >/dev/null 2>&1 && fixed=1
        else
            # 使用 sed 移除 CR
            sed -i 's/\r$//' "$file" 2>/dev/null && fixed=1
        fi
    elif [[ "$should_crlf" == "1" ]] && [[ "$line_ending" == "LF" ]]; then
        # 需要转换为 CRLF
        if command -v unix2dos >/dev/null 2>&1; then
            unix2dos "$file" >/dev/null 2>&1 && fixed=1
        else
            # 使用 sed 添加 CR
            sed -i 's/$/\r/' "$file" 2>/dev/null && fixed=1
        fi
    fi

    if [[ $fixed -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

# 处理单个文件
process_file() {
    local file="$1"

    TOTAL_FILES=$((TOTAL_FILES + 1))

    # 检查是否应该跳过
    if should_skip "$file"; then
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        return 0
    fi

    # 检查是否为二进制文件
    if ! file "$file" 2>/dev/null | grep -q "text"; then
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        return 0
    fi

    # 检查编码和换行符
    local encoding=$(check_encoding "$file")
    local line_ending=$(check_line_ending "$file")
    local should_crlf=0

    if should_use_crlf "$file"; then
        should_crlf=1
    fi

    # 检查是否需要修复
    local needs_fix=0
    local issues=()

    if [[ "$encoding" != "utf-8" ]] && [[ "$encoding" != "us-ascii" ]] && [[ "$encoding" != "binary" ]]; then
        needs_fix=1
        issues+=("编码: $encoding")
    fi

    if [[ "$should_crlf" == "0" ]] && [[ "$line_ending" == "CRLF" ]]; then
        needs_fix=1
        issues+=("换行符: CRLF (应为 LF)")
    elif [[ "$should_crlf" == "1" ]] && [[ "$line_ending" == "LF" ]]; then
        needs_fix=1
        issues+=("换行符: LF (应为 CRLF)")
    fi

    if [[ $needs_fix -eq 1 ]]; then
        echo -e "${YELLOW}修复: $file${NC}"
        echo -e "  问题: ${issues[*]}"

        if fix_file "$file" "$encoding" "$line_ending" "$should_crlf"; then
            echo -e "${GREEN}  ✓ 已修复${NC}"
            FIXED_FILES=$((FIXED_FILES + 1))
        else
            echo -e "${RED}  ✗ 修复失败${NC}"
            ERROR_FILES=$((ERROR_FILES + 1))
        fi
    else
        echo -e "${GREEN}✓ $file${NC} (UTF-8, $line_ending)"
    fi
}

# 主函数
main() {
    echo "=========================================="
    echo "检查和修复文件编码和换行符"
    echo "=========================================="
    echo "项目根目录: $PROJECT_ROOT"
    echo ""

    # 查找所有文本文件
    echo "扫描文件..."
    echo ""

    # 处理不同类型的文件
    local file_types=(
        "*.sh"
        "*.lua"
        "*.toml"
        "*.json"
        "*.yaml"
        "*.yml"
        "*.md"
        "*.txt"
        "*.conf"
        "*.config"
        "*.ini"
        "*.c"
        "*.cpp"
        "*.h"
        "*.hpp"
        "*.py"
        "*.rs"
        "*.go"
        "*.java"
        "*.js"
        "*.ts"
        "*.tsx"
    )

    # 使用 find 查找文件
    while IFS= read -r -d '' file; do
        process_file "$file"
    done < <(find "$PROJECT_ROOT" -type f \( \
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
    \) -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.venv/*" -not -path "*/__pycache__/*" -print0)

    echo ""
    echo "=========================================="
    echo "统计结果"
    echo "=========================================="
    echo "总文件数: $TOTAL_FILES"
    echo -e "${GREEN}已修复: $FIXED_FILES${NC}"
    echo -e "${YELLOW}已跳过: $SKIPPED_FILES${NC}"
    if [[ $ERROR_FILES -gt 0 ]]; then
        echo -e "${RED}失败: $ERROR_FILES${NC}"
    fi
    echo ""
}

# 执行主函数
main "$@"

