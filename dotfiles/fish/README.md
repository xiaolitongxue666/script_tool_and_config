# Fish Shell 配置

Fish Shell 是一个智能且用户友好的命令行 shell，具有自动补全、语法高亮等功能。

## 配置文件结构

```
fish/
├── config.fish         # 统一配置文件（自动检测系统）
├── conf.d/             # 配置片段目录
│   ├── omf.fish        # Oh My Fish 配置
│   └── fnm.fish        # Fast Node Manager (fnm) 配置
├── completions/        # 补全脚本目录
│   └── alacritty.fish  # Alacritty 补全脚本
├── install.sh          # 自动安装脚本（支持多平台）
├── sync_config.sh      # 配置同步脚本
└── README.md           # 本文件
```

## 安装方法

### 方法 1: 使用安装脚本（推荐）

安装脚本会自动检测操作系统并安装对应配置：

```bash
cd dotfiles/fish
chmod +x install.sh
./install.sh
```

### 方法 2: 手动安装

#### macOS
```bash
brew install fish
```

#### Linux (Arch Linux)
```bash
sudo pacman -S fish
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install fish
```

## 配置加载

### 同步配置

使用配置同步脚本将配置文件同步到用户目录：

```bash
cd dotfiles/fish
chmod +x sync_config.sh
./sync_config.sh
```

### 手动复制配置

统一配置文件会自动检测系统，只需复制一个配置文件：

```bash
mkdir -p ~/.config/fish
cp dotfiles/fish/config.fish ~/.config/fish/

# 如果需要 Oh My Fish 配置
mkdir -p ~/.config/fish/conf.d
cp dotfiles/fish/conf.d/omf.fish ~/.config/fish/conf.d/

# 如果需要 fnm 配置
cp dotfiles/fish/conf.d/fnm.fish ~/.config/fish/conf.d/
```

## 配置说明

### 主要配置文件

- `config.fish`: 主配置文件，包含别名、函数、路径设置等
- `conf.d/`: 配置片段目录
- `completions/`: 自动补全脚本目录

### 统一配置说明

配置文件使用条件判断自动检测操作系统并加载对应配置：
- **macOS**: 自动加载 macOS 特定配置（fnm、Autojump、Starship 等）
- **Linux**: 自动加载 Linux 特定配置（fnm、Pyenv、Cargo 等）
- **通用配置**: 所有平台共享的别名和设置

### 主要功能特性

#### fnm (Fast Node Manager) 集成
- **快速**: 使用 Rust 编写，比传统 Node 版本管理器更快
- **自动切换**: 当进入包含 `.nvmrc` 或 `.node-version` 文件的目录时，自动切换 Node 版本（通过 `--use-on-cd` 参数）
- **跨平台**: 支持 macOS、Windows、Linux
- **简单**: 单文件安装，配置简单
- **参考**: [fnm GitHub](https://github.com/Schniz/fnm)

#### 工具别名
- **lsd**: 优先使用 `lsd` 作为 `ls` 的替代（如果未安装则使用 `exa`）
- **bat**: 使用 `bat` 替代 `cat`，提供语法高亮
- **trash**: 使用 `trash` 替代 `rm`，实现更安全的删除操作

#### 代理配置
- **完整代理支持**: 包括 `http_proxy`、`https_proxy` 和 `all_proxy`（socks5）
- **快速切换**: 使用 `h_proxy` 启用代理，`unset_h` 禁用代理
- **平台特定端口**: macOS 默认使用 7890，Linux 默认使用 1087

#### 环境变量
- **PATH 管理**: 自动添加 `~/.local/bin` 和 `~/.cargo/bin` 到 PATH
- **可选配置**: 包含 Gemini CLI 和 Claude Code 配置示例（已注释，按需启用）

#### Pyenv 集成
- **自动初始化**: 在交互式会话中自动初始化 Pyenv
- **路径管理**: 自动添加 Pyenv shims 到 PATH

## 设置 Fish 为默认 Shell

```bash
# 查看 Fish 路径
which fish

# 设置为默认 Shell
chsh -s $(which fish)

# 或指定完整路径
chsh -s /usr/local/bin/fish  # macOS
chsh -s /usr/bin/fish        # Linux
```

## 安装 Oh My Fish (OMF)

Oh My Fish 是 Fish Shell 的配置框架：

```bash
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
```

### 常用 OMF 插件

```fish
omf install agnoster    # 主题
omf install bass        # 运行 bash 脚本
omf install z           # 目录跳转
```

## 安装推荐工具

为了获得最佳体验，建议安装以下工具：

```bash
# macOS
brew install fnm lsd bat trash-cli starship autojump

# Linux (Arch)
sudo pacman -S lsd bat trash-cli starship autojump
# fnm 需要通过脚本安装或使用 cargo
curl -fsSL https://fnm.vercel.app/install | bash

# Linux (Ubuntu/Debian)
sudo apt-get install lsd bat trash-cli starship autojump
# fnm 需要通过脚本安装或使用 cargo
curl -fsSL https://fnm.vercel.app/install | bash
```

## 安装 fnm (Fast Node Manager)

### 使用脚本安装（推荐）

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

### 使用 Homebrew (macOS/Linux)

```bash
brew install fnm
```

### 使用 Cargo

```bash
cargo install fnm
```

安装后，fnm 配置会自动加载（通过 `conf.d/fnm.fish`）。

### 使用 fnm

```bash
# 安装 Node.js 版本
fnm install 22.17.1

# 使用特定版本
fnm use 22.17.1

# 设置默认版本
fnm default 22.17.1

# 列出已安装的版本
fnm list

# 列出可用的版本
fnm list-remote
```

## 自定义配置

### 设置默认 Node 版本

使用 fnm 设置默认版本：

```bash
fnm default <version>
```

例如：
```bash
fnm default 22.17.1
```

### 启用环境变量配置

如果需要使用 Gemini CLI 或 Claude Code，取消注释相应配置：

```fish
# Gemini CLI 配置
set -gx GOOGLE_CLOUD_PROJECT "your-project-id"

# Claude Code 配置
set -gx ANTHROPIC_BASE_URL https://api.kimi.com/coding/
set -gx ANTHROPIC_AUTH_TOKEN "your-token-here"
```

### 启用 Direnv

如果需要使用 direnv 自动加载环境变量，取消注释：

```fish
if type -q direnv
    direnv hook fish | source
end
```

## 参考链接

- [Fish Shell 官网](https://fishshell.com/)
- [Fish Shell 文档](https://fishshell.com/docs/current/)
- [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish)
- [fnm (Fast Node Manager)](https://github.com/Schniz/fnm) - 快速 Node.js 版本管理器

