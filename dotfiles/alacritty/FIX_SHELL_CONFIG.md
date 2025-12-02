# 修复 Alacritty 使用 Git Bash 而不是 PowerShell

## 问题
Alacritty 启动后仍然使用 PowerShell 而不是 Git Bash。

## 解决方案

### 1. 确认配置文件位置
配置文件位于：`%APPDATA%\alacritty\alacritty.toml`

### 2. 检查配置格式
确保配置文件中包含以下内容：

```toml
[shell]
  program = "D:\\Program Files\\Git\\usr\\bin\\bash.exe"
  args = ["--login"]
```

**重要提示**：
- 使用 `[shell]` 而不是 `[terminal.shell]`（Alacritty 0.16.1）
- 路径中的反斜杠必须转义为双反斜杠 `\\`
- 路径必须用双引号包裹

### 3. 验证路径
确保 Git Bash 路径正确：

```bash
# 检查路径是否存在
test -f "D:\Program Files\Git\usr\bin\bash.exe" && echo "路径存在" || echo "路径不存在"

# 测试 bash 是否可执行
"D:\Program Files\Git\usr\bin\bash.exe" --version
```

### 4. 完全重启 Alacritty
1. **完全关闭所有 Alacritty 窗口**
2. 检查任务管理器中是否还有 Alacritty 进程
3. 重新启动 Alacritty

### 5. 使用命令行测试
如果配置仍然不生效，可以尝试使用命令行参数指定配置：

```bash
alacritty.exe --config-file "%APPDATA%\alacritty\alacritty.toml"
```

### 6. 检查日志
查看 Alacritty 启动日志，确认配置是否被加载：

```bash
alacritty.exe --print-events -vvv 2>&1 | grep -i "shell\|config"
```

### 7. 临时解决方案
如果上述方法都不行，可以尝试：

1. **删除配置文件，让 Alacritty 重新生成**：
   ```bash
   mv "%APPDATA%\alacritty\alacritty.toml" "%APPDATA%\alacritty\alacritty.toml.backup"
   ```

2. **手动创建最小配置**：
   ```toml
   [shell]
   program = "D:\\Program Files\\Git\\usr\\bin\\bash.exe"
   args = ["--login"]
   ```

3. **使用环境变量**（如果支持）：
   ```bash
   set ALACRITTY_SHELL="D:\Program Files\Git\usr\bin\bash.exe"
   ```

## 常见问题

### Q: 配置修改后仍然使用 PowerShell
A:
1. 确保完全关闭所有 Alacritty 窗口
2. 检查配置文件语法是否正确（TOML 格式）
3. 验证路径是否正确且可执行

### Q: 路径格式问题
A:
- Windows 路径在 TOML 中必须使用双反斜杠：`D:\\Program Files\\...`
- 或者使用正斜杠：`D:/Program Files/...`（某些版本可能支持）

### Q: 配置被忽略
A:
- 检查是否有其他配置文件覆盖了设置
- 检查配置文件加载顺序
- 查看 Alacritty 日志确认配置是否被读取

## 验证配置生效

启动 Alacritty 后，应该看到 Git Bash 的提示符，而不是 PowerShell 提示符：

**Git Bash 提示符示例**：
```bash
Administrator@DESKTOP-XXX /e/Code/my_code/...
$
```

**PowerShell 提示符示例**：
```powershell
PS E:\Code\my_code\...>
```

