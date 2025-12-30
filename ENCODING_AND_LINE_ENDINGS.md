# 文件编码和换行符规范

本项目要求所有文件使用 **UTF-8 编码**和 **LF 换行符**（Windows 脚本除外）。

## 规范要求

### 编码
- **所有文本文件**: UTF-8（无 BOM）
- **Windows PowerShell 脚本**: UTF-8 with BOM（如果需要）

### 换行符
- **所有文件**: LF (`\n`)
- **Windows 脚本例外**:
  - `scripts/windows/**/*.bat` - CRLF
  - `scripts/windows/**/*.ps1` - CRLF
  - `scripts/windows/**/*.cmd` - CRLF

## 配置文件

项目已配置以下文件来确保规范：

1. **`.gitattributes`** - Git 换行符控制
   - 所有 `.sh` 文件: `eol=lf`
   - 所有 `.lua` 文件: `eol=lf`
   - 所有配置文件: `eol=lf`
   - Windows 脚本: `eol=crlf`

2. **`.editorconfig`** - 编辑器配置
   - 默认: `charset = utf-8`, `end_of_line = lf`
   - Windows 脚本: `end_of_line = crlf`

3. **`.vscode/settings.json`** - VS Code/Cursor 配置
   - 默认: `files.encoding = utf8`, `files.eol = \n`
   - Shell 脚本: `files.eol = \n`

## 检查和修复工具

### 1. 自动检查脚本

```bash
# 检查所有文件的编码和换行符
./scripts/common/utils/check_and_fix_encoding.sh
```

### 2. 规范化换行符脚本

```bash
# 确保所有文件使用 LF 换行符
./scripts/common/utils/ensure_lf_line_endings.sh
```

### 3. Git 规范化

```bash
# 重新规范化所有文件（根据 .gitattributes）
git add --renormalize .

# 查看更改
git status

# 提交更改
git commit -m "Normalize line endings to LF"
```

## Git 配置建议

为了避免换行符问题，建议设置：

```bash
# 禁用自动换行符转换（推荐）
git config core.autocrlf false

# 或者使用 input（在 commit 时转换 CRLF 为 LF，checkout 时不转换）
git config core.autocrlf input
```

**注意**: 如果团队中有 Windows 用户，建议使用 `input` 而不是 `false`。

## Docker 构建注意事项

在 Docker 构建时，如果文件在 Windows 上被 checkout，可能会包含 CRLF。可以在 Dockerfile 中添加转换：

```dockerfile
# 安装 dos2unix（如果需要）
RUN pacman -S --noconfirm dos2unix || true

# 转换特定文件
RUN dos2unix /tmp/project/dotfiles/nvim/install.sh 2>/dev/null || \
    sed -i 's/\r$//' /tmp/project/dotfiles/nvim/install.sh || true
```

或者使用 sed 命令（更通用）：

```dockerfile
# 转换所有 .sh 文件
RUN find /tmp/project -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
```

## 验证方法

### 检查单个文件

```bash
# 检查编码
file -bi <file>

# 检查换行符（包含 CRLF 会显示 ^M）
cat -A <file> | head -5

# 或使用 od
od -c <file> | head -5 | grep -E "\\r|\\n"
```

### 查找 CRLF 文件

```bash
# 查找包含 CRLF 的文件
find . -type f -name "*.sh" -exec grep -l $'\r' {} \;
```

## 常见问题

### 1. 文件在 Windows 上显示为 CRLF

**原因**: `core.autocrlf=true` 导致 checkout 时转换

**解决**:
- 设置 `git config core.autocrlf false` 或 `input`
- 运行 `git add --renormalize .` 重新规范化

### 2. Docker 构建时出现 `$'\r': command not found`

**原因**: 文件包含 CRLF 换行符

**解决**:
- 在 Dockerfile 中添加换行符转换
- 或确保文件在仓库中已经是 LF

### 3. 编辑器自动转换换行符

**解决**:
- 安装 EditorConfig 扩展
- 检查 `.editorconfig` 配置
- 检查编辑器设置

## 维护建议

1. **提交前检查**: 使用 `check_and_fix_encoding.sh` 检查文件
2. **CI/CD 检查**: 在 CI 中添加换行符检查
3. **团队规范**: 统一 Git 配置（`core.autocrlf`）
4. **定期检查**: 定期运行规范化脚本

## 相关文件

- `.gitattributes` - Git 换行符配置
- `.editorconfig` - 编辑器配置
- `.vscode/settings.json` - VS Code 配置
- `scripts/common/utils/check_and_fix_encoding.sh` - 检查脚本
- `scripts/common/utils/ensure_lf_line_endings.sh` - 规范化脚本

