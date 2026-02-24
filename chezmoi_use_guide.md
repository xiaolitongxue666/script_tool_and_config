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

## SSH 配置管理

SSH 配置文件（`~/.ssh/config`）已纳入 chezmoi 管理，可以通过 lazyssh 或直接编辑进行管理。

### 安全性说明

**相对安全的原因：**
- `~/.ssh/config` 文件本身**不包含私钥**，只包含连接配置信息
- 文件内容主要是：主机别名、用户名、端口、端口转发规则、代理配置等
- 私钥文件（`id_rsa`, `id_ed25519` 等）已在 `.gitignore` 和 `.chezmoiignore` 中被排除，不会被纳入管理

**需要注意的敏感信息：**
- 主机名和 IP 地址
- 用户名
- 端口转发规则（可能暴露内部网络结构）
- 代理配置

**建议：**
- ✅ 私有仓库：可以安全地纳入管理
- ⚠️ 如果未来需要公开仓库，考虑使用 chezmoi 加密功能或模板变量

### 首次纳入管理

如果当前系统已有 SSH 配置，需要先备份再纳入管理：

```bash
# 1. 备份现有配置
./scripts/common/utils/backup_ssh_config.sh

# 2. 将配置纳入 chezmoi 管理
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi add ~/.ssh/config

# 3. 验证配置
chezmoi diff ~/.ssh/config

# 4. 应用配置（确保权限正确）
chezmoi apply ~/.ssh/config
chmod 600 ~/.ssh/config

# 5. 提交到 Git
git add .chezmoi/dot_ssh/
git commit -m "Add SSH config to chezmoi management"
git push
```

### 新系统部署

在新系统上部署 SSH 配置：

```bash
# 方法一：使用部署脚本（推荐）
./scripts/common/utils/setup_ssh_config.sh

# 方法二：手动部署
# 1. 确保 ~/.ssh 目录存在
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. 应用配置
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply ~/.ssh/config
chmod 600 ~/.ssh/config
```

### 日常使用

#### 编辑 SSH 配置

```bash
# 方法一：使用 chezmoi 编辑
chezmoi edit ~/.ssh/config

# 方法二：使用 lazyssh 编辑（推荐）
lazyssh
# 在 lazyssh 中编辑配置后，需要同步到 chezmoi
```

#### 同步 lazyssh 的更改

如果使用 lazyssh 修改了配置，需要同步到 chezmoi：

```bash
# lazyssh 修改了 ~/.ssh/config 后
chezmoi re-add ~/.ssh/config
git add .chezmoi/dot_ssh/config
git commit -m "Update SSH config"
git push
```

#### 查看配置差异

```bash
# 查看源状态和系统配置的差异
chezmoi diff ~/.ssh/config

# 查看配置状态
chezmoi status ~/.ssh/config
```

### 备份和恢复

#### 手动备份

```bash
# 使用备份脚本
./scripts/common/utils/backup_ssh_config.sh

# 或手动备份
cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
```

#### 恢复备份

```bash
# 查看所有备份
ls -lh ~/.ssh/config.backup.*

# 恢复指定备份
cp ~/.ssh/config.backup.YYYYMMDD_HHMMSS ~/.ssh/config
chmod 600 ~/.ssh/config
```

### 安全注意事项

1. **文件权限**：确保 `~/.ssh/config` 权限为 600
2. **目录权限**：确保 `~/.ssh` 目录权限为 700
3. **私钥保护**：确保所有私钥文件（`id_*`）不被纳入管理
4. **仓库访问**：保持仓库私有，不要公开包含 SSH 配置的仓库
5. **敏感信息**：如果配置包含高度敏感信息，考虑使用 chezmoi 加密功能

### 使用 lazyssh 管理

lazyssh 是一个终端 SSH 管理器，可以方便地管理 SSH 配置：

```bash
# 启动 lazyssh
lazyssh

# 在 lazyssh 中可以：
# - 查看所有服务器配置
# - 添加新服务器
# - 编辑现有服务器
# - 删除服务器
# - 测试连接
# - 管理端口转发
```

修改后记得同步到 chezmoi：

```bash
chezmoi re-add ~/.ssh/config
```

### 使用 lazyssh 配置的 Host

通过 lazyssh 配置的 Host 是标准的 OpenSSH 别名，**可以直接在终端使用 `ssh 主机名` 命令执行**，无需打开 lazyssh 的 TUI 界面。

#### 基本用法

配置好的 Host 可以直接使用：

```bash
# 连接到服务器（进入 shell + 开启端口转发）
ssh alchemy-studio-tunnel

# 只开启端口转发，不进入 shell（推荐后台运行）
ssh -f -N alchemy-studio-tunnel
```

**参数说明：**
- `-f`：后台运行
- `-N`：不执行远程命令，只用于端口转发

#### 常见场景示例

**1. 跳板隧道（单层转发）**

```bash
# alchemy-studio-tunnel: 本地 10001 → 远程 localhost:10001
ssh -f -N alchemy-studio-tunnel    # 只开启隧道
ssh alchemy-studio-tunnel          # 进入 shell + 开启隧道
```

**2. 双层隧道（通过跳板转发）**

```bash
# mini-server-container-vnc: 通过跳板转发内层容器 VNC
ssh -f -N mini-server-container-vnc    # 只开启完整双层隧道
ssh mini-server-container-vnc          # 进入 shell + 开启所有隧道
```

执行后，本地 5903 端口直通内层容器的 5909 VNC 服务，可用 VNC 客户端连接 `localhost:5903`。

**3. VNC 端口转发（单层）**

```bash
# alchemy-studio-vnc: 本地 5901 → 远程 5901
ssh -f -N alchemy-studio-vnc

# moicen-vnc: 本地 5904 → 远程 5901
ssh -f -N moicen-vnc
```

#### 简化命令（推荐使用别名）

为了更方便使用，可以在 `~/.zshrc` 或 `~/.bashrc` 中添加别名：

```bash
# 双层 VNC 隧道一键开启
alias vnc-mini='ssh -f -N mini-server-container-vnc'

# alchemy-studio 主机 VNC
alias vnc-alchemy='ssh -f -N alchemy-studio-vnc'

# moicen 主机 VNC
alias vnc-moicen='ssh -f -N moicen-vnc'

# 只开跳板隧道（如果单独需要）
alias tunnel-jump='ssh -f -N alchemy-studio-tunnel'
```

保存后执行 `source ~/.zshrc`（或重启终端），以后直接使用：

```bash
vnc-mini        # 一键开启最常用的双层 VNC 隧道
vnc-alchemy     # 开启 alchemy-studio VNC
vnc-moicen      # 开启 moicen VNC
```

#### 检查隧道状态

```bash
# 检查端口是否在监听
netstat -an | grep 5903
# 或
lsof -i:5903

# 查看所有 SSH 连接
ps aux | grep ssh
```

#### 使用建议

- **日常使用**：99% 的情况直接使用 `ssh 主机名` 或自定义别名，无需打开 lazyssh
- **配置管理**：只在需要新增/修改主机配置时才打开 lazyssh
- **后台运行**：使用 `ssh -f -N 主机名` 只开启隧道，不占用终端

## Git 全局配置

Git 全局配置（`~/.gitconfig`）由 `dot_gitconfig.tmpl` 管理，包含：

- **[user]**：`name`、`email`（需在 data 或 `.chezmoi.toml.local` 中设置 `git_user_name`、`git_user_email`，避免敏感信息进仓库）
- **[core]**：`autocrlf`（Windows 为 true，其余为 input）、`longpaths`（仅 Windows true）、`color.ui`
- **GitHub 代理**：`[http "https://github.com"]` / `[https "https://github.com"]` 的 `proxy`，使用 data 中的 `proxy`

**不纳入模板的项**（请在本机或单独配置中设置）：`safe.directory`、`credential.*`、`filter.lfs.*` 等机器/用户私有项。

**设置姓名与邮箱**：在仓库根目录创建或编辑 `.chezmoi.toml.local`（该文件已被忽略，不会提交），添加：

```toml
[data]
    git_user_name = "你的姓名"
    git_user_email = "your.email@example.com"
```

然后执行 `chezmoi apply -v` 即可更新 `~/.gitconfig`。

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

## Zsh 和 Oh My Zsh 插件配置

### 插件列表

项目配置了以下 Zsh 和 Oh My Zsh 插件，提供类似 Fish Shell 的使用体验。

#### 内置插件（Oh My Zsh 自带）

- **git** - Git 命令别名和补全
- **docker** - Docker 命令补全
- **kubectl** - Kubernetes 命令补全
- **z** - 智能目录跳转
- **colored-man-pages** - 彩色 man 页面
- **extract** - 解压各种格式文件（tar, zip, rar 等）
- **web-search** - 网络搜索快捷命令（google, github, bing 等）
- **copydir** - 复制路径到剪贴板
- **copyfile** - 复制文件内容到剪贴板
- **dirhistory** - 目录历史导航（Alt+←/→，需要终端支持）

#### 外部插件（自动安装）

- **zsh-autosuggestions** - 实时历史建议（灰色提示）
- **zsh-history-substring-search** - 子字符串历史搜索（上下箭头）
- **zsh-completions** - 更多补全选项
- **zsh-syntax-highlighting** - 语法高亮（必须最后加载）

### 插件功能说明

#### colored-man-pages
为 man 页面添加颜色，提升可读性。
```bash
man ls  # 显示彩色输出
```

#### web-search
提供快捷命令在浏览器中搜索。
```bash
google "search term"
github "oh-my-zsh"
bing "search term"
duckduckgo "search term"
baidu "搜索词"
```

#### copydir / copyfile
快速复制路径或文件内容。
```bash
copydir              # 复制当前目录路径
copyfile ~/.zshrc    # 复制文件内容到剪贴板
```

#### extract
统一解压命令，自动识别压缩格式。
```bash
extract file.zip
extract file.tar.gz
extract file.rar
```

#### dirhistory
目录历史导航（类似浏览器前进/后退）。
- `Alt + ←` - 返回上一个访问的目录
- `Alt + →` - 前进到下一个目录

**注意**：某些终端（如 VS Code/Cursor 集成终端）可能不支持 Alt 键绑定。可以使用：
- `Esc` + `Left/Right` 作为替代
- 或使用独立终端应用（如 Alacritty）

#### zsh-autosuggestions
根据历史记录实时显示命令建议（灰色文字）。
- `→` 或 `End` - 接受建议
- `Ctrl + →` - 接受建议的一个词
- `Esc` - 忽略建议

#### zsh-history-substring-search
使用上下箭头搜索包含输入字符串的历史命令。
- `↑` - 向上搜索匹配的历史命令
- `↓` - 向下搜索匹配的历史命令

#### zsh-syntax-highlighting
实时高亮命令语法，错误命令显示为红色。
- 正确命令：绿色/蓝色
- 错误命令：红色
- 字符串：引号内特殊颜色

### 插件测试

可以通过以下方式测试插件功能：

```bash
# 1. 测试 colored-man-pages
man ls  # 应该看到彩色输出

# 2. 测试 web-search
google test  # 应该打开浏览器搜索

# 3. 测试 copydir
copydir  # 复制当前目录路径

# 4. 测试 copyfile
copyfile ~/.zshrc  # 复制文件内容

# 5. 测试 extract
extract file.zip  # 解压文件

# 6. 测试 dirhistory
# 使用 Alt+←/→ 导航（需要终端支持）

# 7. 测试 zsh-autosuggestions
# 输入命令后应该看到灰色建议

# 8. 测试 zsh-syntax-highlighting
# 输入命令应该看到颜色高亮

# 9. 测试 zsh-history-substring-search
# 输入部分命令后按 ↑ 搜索历史
```

### 配置位置

- 配置文件: `~/.zshrc`
- 源文件: `.chezmoi/dot_zshrc`
- 插件目录: `~/.oh-my-zsh/custom/plugins/`
- 内置插件: `~/.oh-my-zsh/plugins/`

### 更新插件配置

```bash
cd ~/Code/DotfilesAndScript/script_tool_and_config
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply ~/.zshrc
source ~/.zshrc
```

## 更多资源

- [chezmoi 官方文档](https://www.chezmoi.io/docs/)
- [chezmoi 快速开始指南](https://www.chezmoi.io/quick-start/)
- [chezmoi GitHub](https://github.com/twpayne/chezmoi)
