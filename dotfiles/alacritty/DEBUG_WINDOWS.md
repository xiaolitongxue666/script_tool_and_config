# Alacritty Windows 调试指南

## 查看启动日志

### 方法 1: 使用命令行参数（推荐）

在命令行中运行 Alacritty 并查看详细日志：

```bash
# 查看所有事件和详细日志
alacritty.exe --print-events -vvv

# 或者只查看错误信息
alacritty.exe -vvv 2>&1 | tee alacritty_debug.log
```

### 方法 2: 启用持久化日志

在配置文件中启用持久化日志记录：

1. 编辑配置文件：`%APPDATA%\alacritty\alacritty.toml`

2. 取消注释并修改 `[debug]` 部分：

```toml
[debug]
  # 保持日志文件在退出后不删除
  persistent_logging = true

  # 日志级别：Off, Error, Warn, Info, Debug, Trace
  log_level = "Debug"

  # 打印所有窗口事件
  print_events = true
```

3. 日志文件位置：`%APPDATA%\alacritty\alacritty.log`

### 方法 3: 使用 PowerShell 捕获错误

```powershell
# 在 PowerShell 中运行
alacritty.exe 2>&1 | Out-File -FilePath alacritty_error.log
```

## 常见问题排查

### 1. 闪退问题

**症状**：Alacritty 启动后立即关闭

**可能原因**：
- Shell 路径配置错误
- 配置文件语法错误
- 缺少必要的依赖

**排查步骤**：

1. **检查 Shell 路径**：
   ```bash
   # 查看配置文件中的 shell 路径
   grep -A 2 "\[terminal.shell\]" "%APPDATA%\alacritty\alacritty.toml"

   # 验证路径是否存在
   test -f "C:\msys64\usr\bin\bash.exe" && echo "路径存在" || echo "路径不存在"
   ```

2. **检查配置文件语法**：
   ```bash
   # 使用 alacritty 验证配置
   alacritty.exe --config-file "%APPDATA%\alacritty\alacritty.toml" --print-events -vvv
   ```

3. **临时使用默认配置**：
   ```bash
   # 备份当前配置
   mv "%APPDATA%\alacritty\alacritty.toml" "%APPDATA%\alacritty\alacritty.toml.backup"

   # 使用默认配置启动
   alacritty.exe
   ```

### 2. Shell 路径格式错误

**症状**：日志显示 `Error: Os { code: 2, kind: NotFound, message: "系统找不到指定的文件。" }`

**原因**：TOML 配置文件中路径的反斜杠转义不正确

**修复方法**：

在 TOML 配置文件中，Windows 路径的反斜杠需要转义为双反斜杠：

```toml
# 错误示例
[terminal.shell]
  program = "C:\msys64\usr\bin\bash.exe"  # ❌ 错误

# 正确示例
[terminal.shell]
  program = "C:\\msys64\\usr\\bin\\bash.exe"  # ✅ 正确
```

### 3. 配置文件路径问题

**检查配置文件位置**：

```bash
# Windows 默认配置文件位置
echo %APPDATA%\alacritty\alacritty.toml

# 检查文件是否存在
test -f "%APPDATA%\alacritty\alacritty.toml" && echo "配置文件存在" || echo "配置文件不存在"
```

### 4. 使用 PowerShell 作为默认 Shell

如果 Git Bash 有问题，可以临时使用 PowerShell：

```toml
[terminal.shell]
  program = "powershell.exe"
  args = []
```

或者完全注释掉 `[terminal.shell]` 部分，让 Alacritty 使用默认的 PowerShell。

## 调试命令速查

```bash
# 1. 查看 Alacritty 版本
alacritty.exe --version

# 2. 查看帮助信息
alacritty.exe --help

# 3. 使用调试模式启动
alacritty.exe --print-events -vvv

# 4. 指定配置文件启动
alacritty.exe --config-file "C:\path\to\alacritty.toml" -vvv

# 5. 验证配置文件语法（会显示错误信息）
alacritty.exe --config-file "%APPDATA%\alacritty\alacritty.toml" --print-events 2>&1 | head -50

# 6. 检查 shell 路径是否存在
where.exe bash.exe
test -f "C:\msys64\usr\bin\bash.exe" && echo "存在" || echo "不存在"
```

## 日志分析

查看日志时，关注以下关键信息：

1. **配置文件加载**：
   ```
   [INFO] Configuration files loaded from: "..."
   ```

2. **Shell 启动错误**：
   ```
   [ERROR] Error: Os { code: 2, kind: NotFound, ... }
   ```

3. **配置文件导入错误**：
   ```
   [INFO] Config import not found: "..."
   ```

4. **字体加载问题**：
   ```
   [WARN] Failed to load font: "..."
   ```

## 快速修复脚本

如果遇到问题，可以运行安装脚本重新配置：

```bash
cd /e/Code/my_code/DotfilesAndScript/script_tool_and_config
bash dotfiles/alacritty/install.sh
```

选择：
- 不卸载旧版本（n）
- 覆盖现有配置文件（y）

## 联系支持

如果问题仍然存在，请提供以下信息：

1. Alacritty 版本：`alacritty.exe --version`
2. 操作系统版本
3. 配置文件内容（相关部分）
4. 完整的错误日志：`alacritty.exe --print-events -vvv 2>&1`

