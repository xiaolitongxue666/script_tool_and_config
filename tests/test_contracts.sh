#!/usr/bin/env bash
# ============================================
# 契约测试：结构与命名规则回归
# 用法: bash tests/test_contracts.sh
# ============================================
# 本测试把「文档里写的规则」变成可执行的断言，防止再次漂移。
# 规则来源：AGENTS.md §「库 vs 可执行：两份契约」「命名边界」「文件格式」。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

PASSED=0
FAILED=0
ok()   { PASSED=$((PASSED + 1)); echo "[PASS] $1"; }
bad()  { FAILED=$((FAILED + 1)); echo "[FAIL] $1"; }
head2() { echo ""; echo "--- $1"; }

# ============================================
# 1. 目录结构契约
# ============================================
head2 "目录结构"

[[ -f scripts/lib/common.sh ]] && ok "库根 scripts/lib/common.sh 存在" \
    || bad "缺少 scripts/lib/common.sh"
[[ -d scripts/lib/chezmoi ]] && ok "chezmoi 库目录 scripts/lib/chezmoi/ 存在" \
    || bad "缺少 scripts/lib/chezmoi/"
[[ -d scripts/chezmoi ]] && ok "chezmoi 入口目录 scripts/chezmoi/ 存在" \
    || bad "缺少 scripts/chezmoi/"
[[ -d scripts/tools ]] && ok "独立工具目录 scripts/tools/ 存在" \
    || bad "缺少 scripts/tools/"
[[ -d scripts/deploy_utils ]] && ok "部署辅助 scripts/deploy_utils/ 存在" \
    || bad "缺少 scripts/deploy_utils/"
[[ ! -e scripts/common.sh ]] && ok "旧位置 scripts/common.sh 已移除" \
    || bad "scripts/common.sh 仍在（应迁至 scripts/lib/）"
[[ ! -d scripts/common ]] && ok "旧 scripts/common/ 已移除" \
    || bad "scripts/common/ 仍在（工具应迁至 scripts/tools/）"
# run_on_* 目录已废弃（不是 chezmoi 平台目录）
if find scripts -maxdepth 1 -type d -name 'run_on*' 2>/dev/null | grep -q .; then
    bad "scripts/ 下仍有 run_on_* 目录"
else
    ok "无 scripts/run_on_* 目录"
fi

# ============================================
# 2. 库 vs 可执行 契约
# ============================================
head2 "库契约（scripts/lib/** 被 source）"

lib_bad_set=0
lib_bad_x=0
while IFS= read -r -d '' f; do
    if grep -qE '^set -euo pipefail' "$f"; then
        echo "       ✗ 库不应写 set -euo pipefail: $f"; lib_bad_set=$((lib_bad_set + 1))
    fi
    if [[ -x "$f" ]]; then
        echo "       ✗ 库不应设可执行位: $f"; lib_bad_x=$((lib_bad_x + 1))
    fi
done < <(find scripts/lib -name '*.sh' -print0 2>/dev/null)
[[ "$lib_bad_set" -eq 0 ]] && ok "scripts/lib/** 均未写 set -euo pipefail" \
    || bad "$lib_bad_set 个库文件误写 set -euo pipefail"
[[ "$lib_bad_x" -eq 0 ]] && ok "scripts/lib/** 均无可执行位" \
    || bad "$lib_bad_x 个库文件误设 +x"

head2 "入口契约（文档中以 ./ 调用的脚本须可执行）"

missing_x=0
while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    case "$f" in *.sh) ;; *) continue ;; esac
    # 被 source 的是库，不要求 +x
    if grep -rqs "source.*$(basename "$f")" --include='*.sh' --include='*.sh.tmpl' scripts .chezmoi 2>/dev/null; then
        continue
    fi
    if [[ ! -x "$f" ]]; then
        echo "       ✗ 文档以 ./ 调用但缺 +x: $f"; missing_x=$((missing_x + 1))
    fi
done < <(grep -rhoE '\./[A-Za-z0-9_/.-]+\.sh' --include='*.md' --include='*.mdc' docs README.md AGENTS.md CLAUDE.md 2>/dev/null \
         | sed 's|^\./||' | sort -u)
[[ "$missing_x" -eq 0 ]] && ok "文档中以 ./ 调用的脚本均可执行" \
    || bad "$missing_x 个脚本缺可执行位"

# 可执行位置必须 +x（AGENTS.md「库 vs 可执行：两份契约」的入口侧）。
# 2026-09 审计发现 52 个既有脚本缺 +x —— 它们不在文档的 ./ 调用清单里，故上面那条查不到。
noexec=0
while IFS= read -r -d '' f; do
    case "$f" in
        scripts/tools/shc/echo_hello_world.sh) continue ;;   # 演示 source 内建的负载，非独立进程
    esac
    # 被 source 的是库，不要求 +x
    if grep -rqs "source.*$(basename "$f")" --include='*.sh' --include='*.sh.tmpl' scripts .chezmoi 2>/dev/null; then
        continue
    fi
    echo "       ✗ 可执行位置缺 +x: $f"; noexec=$((noexec + 1))
done < <(find scripts/chezmoi scripts/deploy_utils scripts/linux scripts/windows scripts/tools tests \
             -name '*.sh' ! -perm -u+x -print0 2>/dev/null)
[[ "$noexec" -eq 0 ]] && ok "可执行位置脚本均已 chmod +x" \
    || bad "$noexec 个可执行位置脚本缺 +x"

# ============================================
# 3. 文档链接契约
# ============================================
head2 "文档链接"

link_broken=0
while IFS= read -r md; do
    [[ -f "$md" ]] || continue
    dir="$(dirname "$md")"
    while IFS= read -r target; do
        [[ -n "$target" ]] || continue
        case "$target" in http*|mailto:*|"") continue ;; esac
        # 去掉锚点
        t="${target%%#*}"
        [[ -n "$t" ]] || continue
        if [[ ! -e "${dir}/${t}" ]]; then
            echo "       ✗ ${md} → ${target}"; link_broken=$((link_broken + 1))
        fi
    done < <(grep -oE '\]\([^)#]+' "$md" 2>/dev/null | sed 's/^](//')
done < <(find docs scripts/chezmoi scripts/deploy_utils scripts/tools scripts/linux scripts/windows -name '*.md' 2>/dev/null; echo README.md; echo AGENTS.md; echo CLAUDE.md)
[[ "$link_broken" -eq 0 ]] && ok "文档相对链接全部可解析" \
    || bad "$link_broken 个失效文档链接"

# ============================================
# 4. 已废弃写法 / 结构
# ============================================
head2 "已废弃写法"

if grep -rqs 'export CHEZMOI_SOURCE_DIR=' --include='*.md' docs README.md AGENTS.md CLAUDE.md 2>/dev/null \
   && grep -rhs 'export CHEZMOI_SOURCE_DIR=' --include='*.md' docs README.md AGENTS.md CLAUDE.md 2>/dev/null | grep -qv '无效'; then
    bad "文档中仍有教用户 export CHEZMOI_SOURCE_DIR 的用法（对 chezmoi CLI 无效）"
else
    ok "无 CHEZMOI_SOURCE_DIR 误用"
fi

# 代码：出现陈旧路径会直接导致 source/调用失败 → 零容忍
# 排除本文件：守卫自身必须写明它要拦截的模式（自指），目录是否消失由 #1 结构断言负责
if grep -rqs 'scripts/common/' --include='*.sh' --include='*.tmpl' --include='*.bat' --include='*.ps1' \
        --exclude='test_contracts.sh' scripts .chezmoi tests install.sh deploy.sh 2>/dev/null; then
    bad "代码中仍有 scripts/common/ 旧路径引用"
    grep -rns 'scripts/common/' --include='*.sh' --include='*.tmpl' --include='*.bat' --include='*.ps1' \
        --exclude='test_contracts.sh' scripts .chezmoi tests install.sh deploy.sh 2>/dev/null | head -5 | sed 's/^/       /'
else
    ok "代码中无 scripts/common/ 旧路径引用"
fi

# 文档：允许出现「旧路径 → 新路径」的迁移标注（记录历史），但不得当作现行路径
doc_old_path=$(grep -rns 'scripts/common/' --include='*.md' --include='*.mdc' \
    docs README.md AGENTS.md CLAUDE.md .cursor 2>/dev/null | grep -v '→' || true)
if [[ -n "$doc_old_path" ]]; then
    bad "文档中仍把 scripts/common/ 当作现行路径（仅允许 '旧 → 新' 迁移标注）"
    printf '%s\n' "$doc_old_path" | head -5 | sed 's/^/       /'
else
    ok "文档中 scripts/common/ 仅出现在迁移标注中"
fi

if grep -rqsE '\$[a-zA-Z_][a-zA-Z0-9_]*[一-龥【】（）]' --include='*.sh' --include='*.tmpl' scripts .chezmoi install.sh deploy.sh 2>/dev/null; then
    bad "存在 \$var 紧跟中文/全角标点（应写 \${var}）"
else
    ok "全角标点变量展开合规"
fi

# ============================================
# 5. 文件格式契约
# ============================================
head2 "文件格式"

miss_nl=0
while IFS= read -r -d '' f; do
    [[ -s "$f" ]] || continue
    [[ -n "$(tail -c 1 "$f")" ]] && { echo "       ✗ 缺末尾换行: $f"; miss_nl=$((miss_nl + 1)); }
done < <(find scripts .chezmoi tests docs -type f \( -name '*.sh' -o -name '*.sh.tmpl' -o -name '*.md' -o -name '*.conf' \) -print0 2>/dev/null)
[[ "$miss_nl" -eq 0 ]] && ok "源文件均有末尾换行" || bad "$miss_nl 个文件缺末尾换行"

crlf_bad=0
while IFS= read -r -d '' f; do
    grep -qU $'\r' "$f" 2>/dev/null && { echo "       ✗ 非 Windows 文件含 CR: $f"; crlf_bad=$((crlf_bad + 1)); }
done < <(find scripts .chezmoi tests -type f \( -name '*.sh' -o -name '*.sh.tmpl' -o -name '*.md' \) -print0 2>/dev/null)
[[ "$crlf_bad" -eq 0 ]] && ok "非 Windows 文件均为 LF" || bad "$crlf_bad 个文件含 CR"

# ============================================
# 6. 命名契约（普通脚本区 snake_case）
# ============================================
head2 "命名"

kebab=0
while IFS= read -r -d '' f; do
    b="$(basename "$f")"
    case "$b" in
        *-*.sh|*-*.bat|*-*.ps1)
            # 排除 tests/ 与明确的历史例外
            echo "       ✗ 普通脚本区出现 kebab-case 脚本名: $f"; kebab=$((kebab + 1)) ;;
    esac
done < <(find scripts -maxdepth 1 -type f \( -name '*.sh' \) -print0 2>/dev/null)
[[ "$kebab" -eq 0 ]] && ok "scripts/ 根目录脚本名为 snake_case" || bad "$kebab 个 kebab-case 脚本名"

# ============================================
# 7. 部署入口契约（install.sh / deploy.sh 职责不得混同）
#    回归守卫：2026-09 曾发生 deploy.sh 被整份覆盖成 install.sh 内容的事故
# ============================================
head2 "部署入口"

[[ -f install.sh && -f deploy.sh ]] && ok "install.sh 与 deploy.sh 均存在" || bad "install.sh 或 deploy.sh 缺失"

entry_x=0
for f in install.sh deploy.sh scripts/manage_dotfiles.sh; do
    [[ -x "$f" ]] || { echo "       ✗ 缺少可执行位: $f"; entry_x=$((entry_x + 1)); }
done
[[ "$entry_x" -eq 0 ]] && ok "三个部署入口均可执行" || bad "$entry_x 个部署入口缺少可执行位"

if cmp -s install.sh deploy.sh; then
    bad "deploy.sh 与 install.sh 内容完全相同（入口职责已混同）"
else
    ok "deploy.sh 与 install.sh 内容不同（入口职责分离）"
fi

grep -q '\[1/6\]' install.sh && ok "install.sh 含首次安装阶段标记 [1/6]" || bad "install.sh 缺少首次安装阶段标记"
grep -q 'DIAGNOSE_SCRIPT' deploy.sh && ok "deploy.sh 含增量部署诊断逻辑" || bad "deploy.sh 缺少增量部署诊断逻辑"
if grep -q 'DIAGNOSE_SCRIPT' install.sh; then
    bad "install.sh 混入了 deploy.sh 的增量部署逻辑"
else
    ok "install.sh 未混入增量部署逻辑"
fi

echo ""
echo "=========================================="
echo "Summary (contracts)"
echo "=========================================="
echo "passed: $PASSED, failed: $FAILED"
exit "$FAILED"
