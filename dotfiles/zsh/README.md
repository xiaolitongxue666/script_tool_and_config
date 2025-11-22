# Zsh 配置

Zsh (Z Shell) 是一个功能强大的 Shell，具有自动补全、语法高亮、主题支持等功能。通常与 [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) 框架配合使用。

**参考**:
- [Zsh 官网](https://www.zsh.org/)
- [Zsh GitHub](https://github.com/zsh-users/zsh)
- [Oh My Zsh GitHub](https://github.com/ohmyzsh/ohmyzsh)

## 配置文件结构

```
zsh/
├── .zshrc              # 统一配置文件（自动检测系统）
├── install.sh          # 自动安装脚本（支持多平台）
├── sync_config.sh      # 配置同步脚本
├── how_to_config_zsh.md  # 配置指南（参考）
└── README.md           # 本文件
```

## 安装方法

### 方法 1: 使用安装脚本（推荐）

安装脚本会自动检测操作系统并安装 Zsh 和 Oh My Zsh：

```bash
cd dotfiles/zsh
chmod +x install.sh
./install.sh
```

### 方法 2: 手动安装

#### macOS
```bash
# macOS 通常已预装 Zsh
# 或使用 Homebrew 安装最新版本
brew install zsh
```

#### Linux (Arch Linux)
```bash
sudo pacman -S zsh
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install zsh
```

#### Linux (Fedora/CentOS)
```bash
sudo yum install zsh
```

## 安装 Oh My Zsh

Oh My Zsh 是 Zsh 的配置框架，提供了丰富的主题和插件：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 安装选项

```bash
# 不更改默认 Shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --skip-chsh

# 不替换现有 .zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc

# 完全静默安装
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

## 配置使用

### 同步配置

使用配置同步脚本将配置文件同步到用户目录：

```bash
cd dotfiles/zsh
chmod +x sync_config.sh
./sync_config.sh
```

### 手动复制配置

```bash
# 复制统一配置文件
cp dotfiles/zsh/.zshrc ~/.zshrc
```

### 重新加载配置

```bash
source ~/.zshrc
```

## 配置说明

### 主要配置文件

- `.zshrc`: 主配置文件，包含 Oh My Zsh 设置、插件、别名等

### 统一配置说明

配置文件使用条件判断自动检测操作系统并加载对应配置：
- **macOS**: 自动加载 macOS 特定配置（Homebrew、Autojump、Starship 等）
- **Linux**: 自动加载 Linux 特定配置（Pyenv 额外配置、代理端口等）
- **通用配置**: 所有平台共享的别名和设置

### 功能对齐

本配置参考 `dotfiles/fish/config.fish`，确保 Fish 和 Zsh 具有相同的功能：

- ✅ **系统检测**: 自动检测 macOS/Linux
- ✅ **别名配置**: c_google, cat (bat), ls (lsd/exa), rm (trash), h_proxy, unset_h
- ✅ **PATH 管理**: ~/.local/bin, ~/.cargo/bin
- ✅ **工具集成**: fnm, Pyenv, Autojump (macOS), Starship (可选), Direnv (可选)
- ✅ **平台特定**: macOS 和 Linux 分别处理
- ✅ **代理配置**: 支持平台特定端口（macOS: 7890, Linux: 1087）

### 主要功能特性

#### Oh My Zsh 集成
- **主题**: 默认使用 `agnoster` 主题（可在配置中修改）
- **插件**: 预配置常用插件（git、docker、kubectl、z、zsh-autosuggestions、zsh-syntax-highlighting）
- **自动更新**: 默认禁用，可手动运行 `omz update` 更新

#### 工具别名
- **lsd/exa**: 优先使用 `lsd` 作为 `ls` 的替代（如果未安装则使用 `exa`）
- **bat**: 使用 `bat` 替代 `cat`，提供语法高亮
- **trash**: 使用 `trash` 替代 `rm`，实现更安全的删除操作

#### 代理配置
- **完整代理支持**: 包括 `http_proxy`、`https_proxy` 和 `all_proxy`（socks5）
- **快速切换**: 使用 `h_proxy` 启用代理，`unset_h` 禁用代理
- **平台特定端口**: macOS 默认使用 7890，Linux 默认使用 1087

#### 工具集成
- **fnm**: 自动检测并加载 fnm (Fast Node Manager)
- **Pyenv**: 自动检测并初始化 Pyenv
- **Direnv**: 可选集成（已注释，按需启用）
- **SDKMAN**: 可选集成（已注释，按需启用）

#### 历史记录配置
- **共享历史**: 在命令间共享历史记录
- **去重**: 自动忽略重复命令
- **大容量**: 保存 10000 条历史记录

## 设置 Zsh 为默认 Shell

```bash
# 查看 Zsh 路径
which zsh

# 设置为默认 Shell
chsh -s $(which zsh)

# 或指定完整路径
chsh -s /bin/zsh        # macOS
chsh -s /usr/bin/zsh    # Linux
```

## 常用 Oh My Zsh 主题

### 推荐主题

- **agnoster**: 功能丰富，显示 Git 状态（默认）
- **powerlevel10k**: 高性能，高度可定制（需要单独安装）
- **robbyrussell**: 简洁经典（Oh My Zsh 默认）
- **pure**: 简洁美观

### 查看和切换主题

```bash
# 查看可用主题
ls ~/.oh-my-zsh/themes/

# 编辑配置文件更改主题
vim ~/.zshrc
# 修改 ZSH_THEME="主题名称"
```

### 安装 Powerlevel10k（推荐）

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

然后在 `.zshrc` 中设置：
```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

## 常用 Oh My Zsh 插件

### 内置插件

编辑 `~/.zshrc`，在 `plugins` 中添加插件：

```bash
plugins=(
  git              # Git 命令别名和补全
  docker           # Docker 命令补全
  kubectl          # Kubernetes 命令补全
  z                # 智能目录跳转
  zsh-autosuggestions    # 自动建议（需要安装）
  zsh-syntax-highlighting # 语法高亮（需要安装）
)
```

### 安装外部插件

#### zsh-autosuggestions
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

#### zsh-syntax-highlighting
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### 其他推荐插件

- **zsh-completions**: 更多补全规则
- **zsh-history-substring-search**: 历史记录子串搜索
- **colored-man-pages**: 彩色 man 页面
- **command-not-found**: 命令未找到时的建议

## 安装推荐工具

为了获得最佳体验，建议安装以下工具：

```bash
# macOS
brew install lsd bat trash-cli starship fnm

# Linux (Arch)
sudo pacman -S lsd bat trash-cli starship
curl -fsSL https://fnm.vercel.app/install | bash

# Linux (Ubuntu/Debian)
sudo apt-get install lsd bat trash-cli starship
curl -fsSL https://fnm.vercel.app/install | bash
```

## 自定义配置

### 修改主题

编辑 `~/.zshrc`，找到以下行并修改：

```bash
ZSH_THEME="agnoster"  # 修改为你喜欢的主题
```

### 添加自定义别名

在 `~/.zshrc` 末尾添加：

```bash
# 自定义别名
alias myalias='your command here'
```

### 启用环境变量配置

如果需要使用 Gemini CLI 或 Claude Code，取消注释相应配置：

```bash
# Gemini CLI 配置
export GOOGLE_CLOUD_PROJECT="your-project-id"

# Claude Code 配置
export ANTHROPIC_BASE_URL="https://api.kimi.com/coding/"
export ANTHROPIC_AUTH_TOKEN="your-token-here"
```

### 启用 Direnv

如果需要使用 direnv 自动加载环境变量，取消注释：

```bash
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi
```

## 配置文件位置

- **主配置**: `~/.zshrc`
- **Oh My Zsh**: `~/.oh-my-zsh/`
- **自定义插件**: `~/.oh-my-zsh/custom/plugins/`
- **自定义主题**: `~/.oh-my-zsh/custom/themes/`

## 更新 Oh My Zsh

```bash
omz update
```

## 卸载 Oh My Zsh

```bash
uninstall_oh_my_zsh
```

## 参考链接

- [Zsh 官网](https://www.zsh.org/)
- [Zsh GitHub](https://github.com/zsh-users/zsh)
- [Oh My Zsh GitHub](https://github.com/ohmyzsh/ohmyzsh)
- [Oh My Zsh 主题列表](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)
- [Oh My Zsh 插件列表](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
