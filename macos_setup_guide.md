# macOS 初装系统部署指南

本指南适用于全新的 macOS 系统，通过 chezmoi 自动安装所需软件和配置。

## 前置条件

### 1. 安装 Xcode Command Line Tools

macOS 开发环境的基础工具：

```bash
# 检查是否已安装
xcode-select -p

# 如果未安装，执行以下命令
xcode-select --install
```

安装过程会弹出对话框，点击"安装"并等待完成（可能需要 10-30 分钟）。

### 2. 安装 Homebrew

Homebrew 是 macOS 的包管理器，必需：

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon Mac 需要添加到 PATH
if [[ $(uname -m) == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Intel Mac 通常已自动添加到 PATH
# 验证安装
brew --version
```

## 部署步骤

### 步骤 1: 克隆项目

```bash
# 克隆项目到本地
git clone <your-repo-url> ~/script_tool_and_config
cd ~/script_tool_and_config

# 如果项目包含 Git Submodule（如 Neovim 配置），需要初始化
git submodule update --init --recursive
```

### 步骤 2: 运行一键安装脚本

项目提供了一键安装脚本，会自动完成所有配置：

```bash
# 进入项目目录
cd ~/script_tool_and_config

# 运行一键安装脚本
./install.sh
```

**脚本会自动执行：**
1. 检测操作系统（macOS）
2. 安装 chezmoi（如果未安装）
3. 初始化 chezmoi 仓库
4. 应用所有配置文件
5. 执行所有 `run_once_install-*.sh.tmpl` 安装脚本

### 步骤 3: 配置代理（可选）

如果需要使用代理加速下载，可以在运行安装脚本前设置：

```bash
# 设置代理环境变量
export PROXY="http://127.0.0.1:7890"
export http_proxy="$PROXY"
export https_proxy="$PROXY"

# 然后运行安装脚本
./install.sh
```

### 步骤 4: 等待安装完成

安装过程会自动安装以下软件：

**版本管理器**
- fnm (Node.js 版本管理)
- uv (Python 包管理器)
- rustup (Rust 工具链，可选)

**终端工具**
- starship (跨 shell 提示符)
- tmux (终端复用器)
- alacritty (GPU 加速终端)

**文件工具**
- bat, eza, fd, ripgrep, fzf, trash-cli

**开发工具**
- git, neovim, lazygit, git-delta, gh

**Shell 环境**
- zsh + oh-my-zsh
- fish shell

**窗口管理器（macOS 特有）**
- yabai (平铺式窗口管理器)
- skhd (快捷键守护进程)

**字体**
- FiraMono Nerd Font

**系统监控工具**
- btop, fastfetch

### 步骤 5: 验证安装

安装完成后，验证关键工具：

```bash
# 检查 chezmoi
chezmoi --version

# 检查 Homebrew 工具
brew list | grep -E "(git|neovim|tmux|starship)"

# 检查版本管理器
fnm --version
uv --version

# 检查 Shell 环境
zsh --version
fish --version

# 检查配置文件
ls -la ~/.zshrc
ls -la ~/.config/fish/config.fish
ls -la ~/.config/starship/starship.toml
```

## 使用管理脚本

项目提供了统一的管理脚本，方便日常使用：

```bash
# 查看帮助
./scripts/manage_dotfiles.sh help

# 应用所有配置
./scripts/manage_dotfiles.sh apply

# 查看配置差异
./scripts/manage_dotfiles.sh diff

# 查看配置状态
./scripts/manage_dotfiles.sh status

# 编辑配置文件
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 列出所有受管理的文件
./scripts/manage_dotfiles.sh list
```

## 手动安装方式

如果一键安装脚本遇到问题，可以手动执行：

### 1. 安装 chezmoi

```bash
# 使用 Homebrew（推荐）
brew install chezmoi

# 或使用官方安装脚本
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

### 2. 初始化 chezmoi

```bash
# 进入项目目录
cd ~/script_tool_and_config

# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 应用所有配置（会自动执行安装脚本）
chezmoi apply -v
```

## 配置文件位置

安装完成后，配置文件会部署到以下位置：

**Shell 配置**
- `~/.zshrc` - Zsh 配置
- `~/.zprofile` - Zsh 启动配置
- `~/.config/fish/config.fish` - Fish Shell 配置

**终端和工具配置**
- `~/.config/alacritty/alacritty.toml` - Alacritty 终端配置
- `~/.tmux.conf` - Tmux 配置
- `~/.config/starship/starship.toml` - Starship 提示符配置

**窗口管理器配置（macOS）**
- `~/.yabairc` - Yabai 配置
- `~/.skhdrc` - skhd 配置

## 常见问题

### Q: 安装过程中提示需要 Xcode Command Line Tools

**解决**：运行 `xcode-select --install` 并等待安装完成。

### Q: Homebrew 安装失败

**解决**：
1. 检查网络连接
2. 如果在中国大陆，可以配置镜像源：
   ```bash
   # 使用中科大镜像
   export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
   export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
   ```
3. 重新运行安装脚本

### Q: chezmoi 找不到源状态目录

**解决**：
```bash
# 设置源状态目录环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 或使用管理脚本（会自动设置）
./scripts/manage_dotfiles.sh apply
```

### Q: 某些软件安装失败

**解决**：
1. 检查网络连接和代理设置
2. 查看详细日志：`chezmoi apply -v`
3. 手动安装失败的软件：
   ```bash
   brew install <package-name>
   ```

### Q: 配置文件冲突

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

### Q: 如何重新运行安装脚本

chezmoi 的 `run_once_` 脚本只执行一次。如果需要重新运行：

```bash
# 方法 1: 删除执行记录（不推荐）
chezmoi forget ~/.local/share/chezmoi/run_once_install-*.sh.tmpl

# 方法 2: 直接运行脚本（需要先执行模板）
chezmoi execute-template < .chezmoi/run_once_install-zsh.sh.tmpl | bash
```

## 后续配置

### 1. 配置 Yabai 和 skhd（可选）

如果安装了 Yabai 窗口管理器：

```bash
# 启动 Yabai
brew services start yabai

# 启动 skhd
brew services start skhd

# 配置权限（首次需要）
# 系统设置 > 隐私与安全性 > 辅助功能 > 添加 Terminal
```

### 2. 配置 Neovim（如果使用 Git Submodule）

```bash
# 确保 submodule 已初始化
git submodule update --init dotfiles/nvim

# Neovim 配置会自动通过 chezmoi 管理
```

### 3. 配置 Git

```bash
# 设置 Git 用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 查看配置
git config --global --list
```

## 完成

安装完成后，重启终端或执行：

```bash
# 重新加载 Shell 配置
source ~/.zshrc

# 或打开新终端窗口
```

现在你的 macOS 系统已经配置完成，可以开始使用了！

## 参考文档

- [readme.md](readme.md) - 项目主文档
- [chezmoi_guide.md](chezmoi_guide.md) - chezmoi 使用指南
- [software_list.md](software_list.md) - 软件清单
- [project_structure.md](project_structure.md) - 项目结构说明

