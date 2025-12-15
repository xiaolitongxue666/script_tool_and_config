# chezmoi 使用指南

本指南介绍如何使用 chezmoi 管理 dotfiles 配置。

## 目录

- [快速开始](#快速开始)
- [基本操作命令](#基本操作命令)
- [常用工作流程](#常用工作流程)
- [高级功能](#高级功能)
- [平台特定配置](#平台特定配置)
- [代理配置](#代理配置)
- [故障排除](#故障排除)

## 快速开始

### 安装 chezmoi

#### Linux

```bash
# Arch Linux
sudo pacman -S chezmoi

# Ubuntu/Debian
sudo apt-get install chezmoi

# 或使用官方安装脚本
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

#### macOS

```bash
# 使用 Homebrew
brew install chezmoi

# 或使用官方安装脚本
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

#### Windows

```bash
# 使用 winget
winget install --id=twpayne.chezmoi -e

# 或使用官方安装脚本（Git Bash）
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

### 初始化仓库

本项目使用项目内源状态目录模式，配置文件存储在 `.chezmoi/` 目录中。

```bash
# 克隆项目
git clone <repo-url>
cd script_tool_and_config

# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 应用所有配置
chezmoi apply -v
```

或使用项目提供的一键安装脚本：

```bash
./install.sh
```

## 基本操作命令

### 安装和初始化

```bash
# 使用项目管理脚本
./scripts/manage_dotfiles.sh install

# 或手动设置
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
```

### 核心操作命令

#### `chezmoi apply` - 应用配置

将源状态目录中的配置应用到系统。

```bash
# 应用所有配置
chezmoi apply

# 详细输出
chezmoi apply -v

# 预览将要执行的更改（不实际应用）
chezmoi apply --dry-run
```

#### `chezmoi status` - 查看状态

查看配置文件的当前状态。

```bash
# 查看所有文件状态
chezmoi status

# 查看特定文件状态
chezmoi status ~/.zshrc
```

#### `chezmoi diff` - 查看差异

查看源状态目录和系统配置文件的差异。

```bash
# 查看所有差异
chezmoi diff

# 查看特定文件差异
chezmoi diff ~/.zshrc
```

#### `chezmoi add` - 添加文件

将系统中的配置文件添加到 chezmoi 管理。

```bash
# 添加文件
chezmoi add ~/.new_config

# 添加目录
chezmoi add ~/.config/myapp
```

#### `chezmoi update` - 更新配置

从源状态目录更新配置到系统（通常在拉取仓库后使用）。

```bash
# 更新所有配置
chezmoi update -v
```

### 常用工作流程

#### `chezmoi cd` - 进入源状态目录

快速进入 chezmoi 源状态目录。

```bash
chezmoi cd
# 或
cd "$(chezmoi source-path)"
```

#### `chezmoi edit` - 编辑配置文件

编辑源状态目录中的配置文件。

```bash
# 编辑配置文件
chezmoi edit ~/.zshrc

# 编辑后会打开编辑器，chezmoi 会自动检测编辑器
```

#### `chezmoi list` - 列出管理的文件

列出所有受 chezmoi 管理的文件。

```bash
# 列出所有文件
chezmoi managed

# 或使用
chezmoi list
```

## 常用工作流程

### 日常使用

1. **应用配置**：在修改源状态目录后，应用配置到系统
   ```bash
   chezmoi apply -v
   ```

2. **查看差异**：在应用前查看将要进行的更改
   ```bash
   chezmoi diff
   ```

3. **编辑配置**：直接编辑源状态目录中的文件
   ```bash
   chezmoi edit ~/.zshrc
   ```

### 添加新配置

1. **添加文件到管理**
   ```bash
   chezmoi add ~/.new_config
   ```

2. **编辑配置**
   ```bash
   chezmoi edit ~/.new_config
   ```

3. **应用配置**
   ```bash
   chezmoi apply
   ```

4. **提交到 Git**
   ```bash
   git add .chezmoi
   git commit -m "Add new config"
   git push
   ```

### 更新配置

1. **从仓库拉取最新配置**
   ```bash
   git pull
   ```

2. **更新到系统**
   ```bash
   chezmoi update -v
   ```

3. **查看差异**
   ```bash
   chezmoi diff
   ```

### 修改现有配置

1. **编辑配置文件**
   ```bash
   chezmoi edit ~/.zshrc
   ```

2. **查看变更**
   ```bash
   chezmoi diff
   ```

3. **应用变更**
   ```bash
   chezmoi apply
   ```

4. **提交到 Git**
   ```bash
   git add .chezmoi
   git commit -m "Update zsh config"
   git push
   ```

## 高级功能

### 模板变量

chezmoi 支持使用模板变量在配置文件中处理平台差异。

#### 在 `.chezmoi.toml` 中定义变量

```toml
[data]
    os = "{{ .chezmoi.os }}"
    arch = "{{ .chezmoi.arch }}"
    hostname = "{{ .chezmoi.hostname }}"
    proxy = "{{ envOrDefault \"PROXY\" \"http://127.0.0.1:7890\" }}"
```

#### 在配置文件中使用变量

创建模板文件（使用 `.tmpl` 扩展名或在文件名中添加 `.tmpl`）：

```bash
# .chezmoi/dot_bashrc.tmpl
# 平台特定配置
{{ if eq .chezmoi.os "darwin" }}
# macOS 特定配置
export PATH="/opt/homebrew/bin:$PATH"
{{ else if eq .chezmoi.os "linux" }}
# Linux 特定配置
export PATH="/usr/local/bin:$PATH"
{{ end }}

# 使用代理变量
alias h_proxy='export http_proxy={{ .proxy }}; export https_proxy={{ .proxy }}'
```

### 平台特定配置

使用 `run_on_<os>/` 目录来组织平台特定的配置和脚本：

- `run_on_linux/` - Linux 特定配置
- `run_on_darwin/` - macOS 特定配置
- `run_on_windows/` - Windows 特定配置

示例：

```bash
# Linux 特定配置
.chezmoi/run_on_linux/dot_config/i3/config

# macOS 特定配置
.chezmoi/run_on_darwin/dot_yabairc

# Windows 特定配置
.chezmoi/run_on_windows/dot_bash_profile
```

### 一次性脚本（run_once_）

chezmoi 支持 `run_once_` 前缀的脚本，这些脚本只会在首次应用配置时执行一次。

项目中的安装脚本使用此功能：

```bash
# 通用安装脚本
.chezmoi/run_once_install-starship.sh
.chezmoi/run_once_install-zsh.sh
.chezmoi/run_once_install-fish.sh

# 平台特定安装脚本
.chezmoi/run_on_linux/run_once_install-i3wm.sh
.chezmoi/run_on_darwin/run_once_install-yabai.sh
```

### 自动提交和推送

可以在 `.chezmoi.toml` 中配置自动提交和推送：

```toml
[git]
    autoCommit = true
    autoPush = false  # 建议设置为 false，手动控制推送
```

## 平台特定配置

### Linux

Linux 特定的配置和脚本位于 `run_on_linux/` 目录：

- `dot_config/i3/config` - i3wm 窗口管理器配置
- `run_once_install-i3wm.sh` - i3wm 安装脚本
- `run_once_install-dwm.sh` - dwm 安装脚本

### macOS

macOS 特定的配置和脚本位于 `run_on_darwin/` 目录：

- `dot_yabairc` - Yabai 窗口管理器配置
- `dot_skhdrc` - skhd 快捷键配置
- `run_once_install-yabai.sh` - Yabai 安装脚本
- `run_once_install-skhd.sh` - skhd 安装脚本

### Windows

Windows 特定的配置和脚本位于 `run_on_windows/` 目录：

- `dot_bash_profile` - Git Bash 配置
- `dot_bashrc` - Git Bash 配置
- `run_once_install-zsh.sh` - Zsh 安装脚本（通过 MSYS2）

## 代理配置

### 环境变量

chezmoi 支持通过环境变量配置代理：

```bash
# 设置代理
export PROXY="http://127.0.0.1:7890"
export http_proxy="$PROXY"
export https_proxy="$PROXY"

# 应用配置
chezmoi apply -v
```

### 在配置文件中使用代理

代理配置在 `.chezmoi.toml` 中定义：

```toml
[data]
    proxy = "{{ envOrDefault \"PROXY\" (envOrDefault \"http_proxy\" \"http://127.0.0.1:7890\") }}"
```

在配置文件中使用：

```bash
# .chezmoi/dot_bashrc.tmpl
alias h_proxy='export http_proxy={{ .proxy }}; export https_proxy={{ .proxy }}'
```

### 安装脚本中的代理

所有 `run_once_install-*.sh` 脚本都支持代理配置：

```bash
# 脚本会自动使用环境变量中的代理
export PROXY="http://127.0.0.1:7890"
chezmoi apply -v
```

## 故障排除

### 常见问题

#### 1. chezmoi 找不到源状态目录

**问题**：运行 `chezmoi apply` 时提示找不到源状态目录。

**解决**：
```bash
# 设置源状态目录环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 或使用项目管理脚本
./scripts/manage_dotfiles.sh apply
```

#### 2. 配置文件冲突

**问题**：应用配置时提示文件已存在且不同。

**解决**：
```bash
# 查看差异
chezmoi diff ~/.zshrc

# 如果确定要覆盖，使用 --force
chezmoi apply --force ~/.zshrc

# 或先备份
cp ~/.zshrc ~/.zshrc.backup
chezmoi apply ~/.zshrc
```

#### 3. 模板变量未解析

**问题**：配置文件中显示 `{{ .chezmoi.os }}` 而不是实际值。

**解决**：
- 确保文件扩展名为 `.tmpl` 或在文件名中包含 `.tmpl`
- 检查 `.chezmoi.toml` 中的变量定义
- 使用 `chezmoi execute-template` 测试模板：
  ```bash
  chezmoi execute-template '{{ .chezmoi.os }}'
  ```

#### 4. run_once_ 脚本重复执行

**问题**：`run_once_` 脚本每次都会执行。

**解决**：
- 检查脚本是否有正确的 `run_once_` 前缀
- 确保脚本在源状态目录中
- 查看 chezmoi 状态：`chezmoi status`

#### 5. 代理配置不生效

**问题**：安装脚本无法使用代理。

**解决**：
```bash
# 设置代理环境变量
export PROXY="http://127.0.0.1:7890"
export http_proxy="$PROXY"
export https_proxy="$PROXY"

# 重新应用配置
chezmoi apply -v
```

### 获取帮助

```bash
# chezmoi 帮助
chezmoi help

# 查看特定命令帮助
chezmoi help apply

# 使用项目管理脚本
./scripts/manage_dotfiles.sh help
```

### 调试

```bash
# 详细输出
chezmoi apply -v

# 调试模式
chezmoi -v apply

# 查看源状态目录路径
chezmoi source-path

# 查看目标文件路径
chezmoi target-path ~/.zshrc
```

## 更多资源

- [chezmoi 官方文档](https://www.chezmoi.io/docs/)
- [chezmoi 快速开始指南](https://www.chezmoi.io/quick-start/)
- [chezmoi GitHub](https://github.com/twpayne/chezmoi)
