# Starship 提示符配置

Starship 是一个快速、可定制、跨 shell 的提示符，支持 Bash、Fish、Zsh、PowerShell 等。

**参考**: [Starship 官方文档](https://starship.rs/)

## 功能特性

- ✨ **美观的提示符**: 适配 Dracula 主题颜色
- 🚀 **快速响应**: 异步执行，不阻塞终端
- 📦 **模块化设计**: 按需显示 Git、编程语言版本等信息
- 🎨 **高度可定制**: 支持自定义格式、颜色、符号

## 安装

### macOS (Homebrew)

```bash
brew install starship
```

### Linux

```bash
curl -sS https://starship.rs/install.sh | sh
```

### 其他系统

参考 [官方安装文档](https://starship.rs/guide/#%F0%9F%9A%80-installation)

## 配置

### 1. 复制配置文件

```bash
# 从项目目录复制配置文件到系统位置
cp dotfiles/starship/starship.toml ~/.config/starship/starship.toml
```

### 2. 初始化 Shell

#### Fish

在 `~/.config/fish/config.fish` 中添加：

```fish
# Starship 提示符设置
if command -v starship > /dev/null
    starship init fish | source
end
```

#### Bash

在 `~/.bashrc` 或 `~/.bash_profile` 中添加：

```bash
# Starship 提示符设置
eval "$(starship init bash)"
```

#### Zsh

在 `~/.zshrc` 中添加：

```zsh
# Starship 提示符设置
eval "$(starship init zsh)"
```

### 3. 重新加载 Shell

```bash
# Fish
source ~/.config/fish/config.fish

# Bash
source ~/.bashrc

# Zsh
source ~/.zshrc
```

## 配置说明

### 提示符格式

当前配置的提示符格式：

```
username directory git_branch git_status [语言版本] >
```

### 模块说明

#### 用户名模块 (`username`)
- 显示当前用户名
- 普通用户：紫色
- root 用户：红色

#### 目录模块 (`directory`)
- 显示当前工作目录
- 自动截断长路径（显示最后 3 个目录）
- 常见目录使用图标替换（如 📄 Documents）

#### Git 分支模块 (`git_branch`)
- 显示当前 Git 分支
- 仅在 Git 仓库中显示

#### Git 状态模块 (`git_status`)
- 显示 Git 仓库状态
- 符号说明：
  - `⚡` 冲突
  - `✓` 已同步/已暂存
  - `?` 未跟踪文件
  - `⇡` 领先远程
  - `⇣` 落后远程
  - `📝` 已修改
  - `✘` 已删除

#### 编程语言版本模块

自动检测并显示以下语言的版本：

- **Node.js**: 检测 `package.json`, `node_modules`
- **Rust**: 检测 `Cargo.toml`, `Cargo.lock`
- **Python**: 检测 `.python-version`, `requirements.txt`, `pyproject.toml` 等
- **Go**: 检测 `go.mod`, `go.sum` 等
- **C/C++**: 检测 `Makefile`, `CMakeLists.txt` 等
- **Java**: 检测 `pom.xml`, `build.gradle` 等

#### 字符模块 (`character`)
- 成功命令：绿色 `>`
- 失败命令：红色 `>`
- Vim 模式：绿色 `<`

## 自定义配置

### 修改颜色

编辑 `~/.config/starship/starship.toml`，修改各模块的 `style` 属性：

```toml
[username]
style_user = "bold purple"  # 修改为其他颜色
```

### 启用/禁用模块

设置 `disabled = true` 来禁用模块：

```toml
[time]
disabled = true  # 禁用时间模块
```

### 修改提示符格式

编辑 `format` 字段来重新排列或添加/移除模块：

```toml
format = """
$username\
$directory\
$git_branch\
$character\
"""
```

## 故障排除

### 提示符不显示

1. 检查 Starship 是否已安装：
   ```bash
   starship --version
   ```

2. 检查 Shell 初始化是否正确：
   ```bash
   # Fish
   starship init fish
   
   # Bash
   starship init bash
   
   # Zsh
   starship init zsh
   ```

3. 检查配置文件语法：
   ```bash
   starship config --help
   ```

### 模块不显示

- 检查模块是否被禁用（`disabled = true`）
- 检查模块的检测条件（`detect_files`, `detect_folders`）
- 检查命令超时设置（`command_timeout`）

### 性能问题

如果提示符响应慢：

1. 增加命令超时时间：
   ```toml
   command_timeout = 2000  # 增加到 2000 毫秒
   ```

2. 禁用不必要的模块

3. 检查是否有慢速命令（如网络请求）

## 参考资源

- [Starship 官方文档](https://starship.rs/)
- [配置参考](https://starship.rs/config/)
- [预设配置](https://starship.rs/presets/)
- [GitHub 仓库](https://github.com/starship/starship)

## 更新日志

- **2024-11**: 初始配置，适配 Dracula 主题
- 合并旧配置，优化模块显示
- 添加常见目录图标替换
- 优化 Git 状态显示

