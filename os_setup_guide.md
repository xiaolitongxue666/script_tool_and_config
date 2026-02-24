# 操作系统新系统安装指南（chezmoi 流程）

本指南适用于在全新的操作系统上使用 chezmoi 管理 dotfiles 配置，支持 Windows、macOS 和 Linux。

## 目录

- [Windows 安装指南](#windows-安装指南)
- [macOS 安装指南](#macos-安装指南)
- [通用操作](#通用操作)

---

## Windows 安装指南

### 前置条件

- Windows 10/11
- Git Bash（如果没有，会在安装过程中安装）
- 管理员权限（部分软件安装需要）
- 网络连接

### 完整安装流程

#### 第一步：安装 chezmoi

chezmoi 是 dotfiles 管理工具，需要先安装。

**方法 1：使用项目提供的安装脚本（推荐）**

```bash
# 在 Git Bash 中执行
cd /e/Code/my_code/DotfilesAndScript/script_tool_and_config
bash scripts/chezmoi/install_chezmoi.sh
```

**方法 2：使用 winget（Windows 包管理器）**

```bash
winget install --id=twpayne.chezmoi -e
```

**方法 3：使用官方安装脚本**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

**验证安装**

```bash
chezmoi --version
```

如果显示版本号，说明安装成功。

#### 第二步：初始化 chezmoi 仓库

在项目目录中设置 chezmoi 源状态目录：

```bash
# 进入项目目录
cd /e/Code/my_code/DotfilesAndScript/script_tool_and_config

# 设置源状态目录环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 创建必要的目录（Windows 需要）
mkdir -p ~/.local/share/chezmoi
```

或使用项目管理脚本：

```bash
./scripts/manage_dotfiles.sh install
```

#### 第三步：安装所需软件

chezmoi 会在首次应用配置时自动执行 `run_once_install-*.sh.tmpl` 脚本，这些脚本会自动安装所需软件。

**使用一键安装脚本（推荐）**

```bash
# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 应用所有配置（会自动执行安装脚本）
chezmoi apply -v
```

**使用 Windows 专用安装脚本（PowerShell）**

项目还提供了 Windows 专用的 PowerShell 安装脚本，功能更强大：

```powershell
# 以管理员身份运行 PowerShell
cd E:\Code\my_code\DotfilesAndScript\script_tool_and_config\scripts\windows\system_basic_env

# 运行安装脚本
.\install_common_tools.ps1
```

或使用批处理文件（最简单）：

```cmd
# 双击运行（会自动请求管理员权限）
install_common_tools.bat
```

**注意**：PowerShell 脚本支持：
- 自动检测并安装包管理器（winget/chocolatey）
- 交互式选择要安装的工具
- 自动安装字体
- 详细的安装日志
- PATH 环境变量自动管理

**可用的安装脚本**

- `run_once_install-common-tools.sh.tmpl` - 通用工具（bat, eza, fd, ripgrep, fzf, lazygit, git-delta, gh）
- `run_once_install-version-managers.sh.tmpl` - 版本管理器（fnm, uv, rustup）
- `run_once_install-oh-my-posh.sh.tmpl` - Oh My Posh（Windows 提示符工具）
- `run_once_install-neovim.sh.tmpl` - Neovim 编辑器
- `run_once_install-git.sh.tmpl` - Git
- `run_once_install-starship.sh.tmpl` - Starship 提示符（可选）
- `run_once_install-alacritty.sh.tmpl` - Alacritty 终端
- `run_once_install-nerd-fonts.sh.tmpl` - Nerd Fonts 字体

#### 第四步：配置所需软件

chezmoi 会自动应用所有配置文件到系统。

**应用所有配置**

```bash
# 确保已设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 应用所有配置
chezmoi apply -v
```

**配置文件映射**

chezmoi 会将以下配置文件应用到系统：

**Windows 特定配置**（`.chezmoi/run_on_windows/`）：
- `dot_bash_profile` → `~/.bash_profile`（Git Bash 登录配置）
- `dot_bashrc` → `~/.bashrc`（Git Bash 非登录配置）

**通用配置**（`.chezmoi/`）：
- `dot_config/alacritty/alacritty.toml` → `~/.config/alacritty/alacritty.toml`
- `dot_config/starship/starship.toml` → `~/.config/starship/starship.toml`
- `dot_config/fish/config.fish` → `~/.config/fish/config.fish`（如果使用 Fish Shell）
- `dot_tmux.conf` → `~/.tmux.conf`（如果使用 Tmux）
- `dot_zshrc` → `~/.zshrc`（如果使用 Zsh）

#### 第五步：纳入 chezmoi 管理

如果系统中有现有的配置文件，需要将它们添加到 chezmoi 管理。

**添加现有配置文件**

```bash
# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 添加配置文件到 chezmoi 管理
chezmoi add ~/.bash_profile
chezmoi add ~/.bashrc
chezmoi add ~/.config/alacritty/alacritty.toml
```

### Windows 完整执行示例

```bash
# ============================================
# 1. 安装 chezmoi
# ============================================
cd /e/Code/my_code/DotfilesAndScript/script_tool_and_config
bash scripts/chezmoi/install_chezmoi.sh

# 验证安装
chezmoi --version

# ============================================
# 2. 初始化 chezmoi 仓库
# ============================================
# 创建必要的目录（Windows 需要）
mkdir -p ~/.local/share/chezmoi

# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# ============================================
# 3. 安装所需软件
# ============================================
# 应用所有配置（会自动执行安装脚本）
chezmoi apply -v

# ============================================
# 4. 配置所需软件
# ============================================
# 应用所有配置
chezmoi apply -v

# 查看配置状态
chezmoi status

# 查看配置差异
chezmoi diff

# ============================================
# 5. 纳入 chezmoi 管理（如果有现有配置）
# ============================================
# 添加现有配置文件
chezmoi add ~/.bash_profile
chezmoi add ~/.bashrc

# 提交到 Git
git add .chezmoi
git commit -m "Add Windows config files"
git push
```

### Windows 故障排除

**问题 1：chezmoi 找不到源状态目录**

```bash
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
```

或使用项目管理脚本：
```bash
./scripts/manage_dotfiles.sh apply
```

**问题 2：Windows Git Bash 上 chezmoi 找不到状态目录**

```bash
# 创建 chezmoi 状态目录
mkdir -p ~/.local/share/chezmoi

# 然后运行 chezmoi 命令
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

**问题 3：配置文件冲突**

```bash
# 查看差异
chezmoi diff ~/.bash_profile

# 如果确定要覆盖，使用 --force
chezmoi apply --force ~/.bash_profile

# 或先备份
cp ~/.bash_profile ~/.bash_profile.backup
chezmoi apply ~/.bash_profile
```

---

## macOS 安装指南

### 前置条件

#### 1. 安装 Xcode Command Line Tools

macOS 开发环境的基础工具：

```bash
# 检查是否已安装
xcode-select -p

# 如果未安装，执行以下命令
xcode-select --install
```

安装过程会弹出对话框，点击"安装"并等待完成（可能需要 10-30 分钟）。

#### 2. 安装 Homebrew

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

### 部署步骤

#### 步骤 1: 克隆项目

```bash
# 克隆项目到本地
git clone <your-repo-url> ~/script_tool_and_config
cd ~/script_tool_and_config

# 如果项目包含 Git Submodule（如 Neovim 配置），需要初始化
# 注意：dotfiles/ 目录现在仅用于 nvim Git Submodule
git submodule update --init --recursive
```

#### 步骤 2: 运行一键安装脚本

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

#### 步骤 3: 配置代理（可选）

如果需要使用代理加速下载，可以在运行安装脚本前设置：

```bash
# 设置代理环境变量
export PROXY="http://127.0.0.1:7890"
export http_proxy="$PROXY"
export https_proxy="$PROXY"

# 然后运行安装脚本
./install.sh
```

#### 步骤 4: 等待安装完成

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

**GUI 应用（macOS 特有）**
- Maccy (轻量级剪贴板管理器)
  - 快捷键：`Shift+Command+C` 打开
  - 功能：保存剪贴板历史，快速搜索和粘贴
  - 官网：https://maccy.app

#### 步骤 5: 验证安装

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

### macOS 手动安装方式

如果一键安装脚本遇到问题，可以手动执行：

#### 1. 安装 chezmoi

```bash
# 使用 Homebrew（推荐）
brew install chezmoi

# 或使用官方安装脚本
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

#### 2. 初始化 chezmoi

```bash
# 进入项目目录
cd ~/script_tool_and_config

# 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 应用所有配置（会自动执行安装脚本）
chezmoi apply -v
```

### macOS 配置文件位置

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

### macOS 常见问题

**Q: 安装过程中提示需要 Xcode Command Line Tools**

**解决**：运行 `xcode-select --install` 并等待安装完成。

**Q: Homebrew 安装失败**

**解决**：
1. 检查网络连接
2. 如果在中国大陆，可以配置镜像源：
   ```bash
   # 使用中科大镜像
   export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
   export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
   ```
3. 重新运行安装脚本

**Q: chezmoi 找不到源状态目录**

**解决**：
```bash
# 设置源状态目录环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 或使用管理脚本（会自动设置）
./scripts/manage_dotfiles.sh apply
```

**Q: 某些软件安装失败**

**解决**：
1. 检查网络连接和代理设置
2. 查看详细日志：`chezmoi apply -v`
3. 手动安装失败的软件：
   ```bash
   brew install <package-name>
   ```

**Q: 配置文件冲突**

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

**Q: 如何重新运行安装脚本**

chezmoi 的 `run_once_` 脚本只执行一次。如果需要重新运行：

```bash
# 方法 1: 删除执行记录（不推荐）
chezmoi forget ~/.local/share/chezmoi/run_once_install-*.sh.tmpl

# 方法 2: 直接运行脚本（需要先执行模板）
chezmoi execute-template < .chezmoi/run_once_install-zsh.sh.tmpl | bash
```

### macOS 后续配置

#### 1. 配置 Yabai 和 skhd（可选）

如果安装了 Yabai 窗口管理器：

```bash
# 启动 Yabai
brew services start yabai

# 启动 skhd
brew services start skhd

# 配置权限（首次需要）
# 系统设置 > 隐私与安全性 > 辅助功能 > 添加 Terminal
```

#### 2. 配置 Neovim（如果使用 Git Submodule）

```bash
# 确保 submodule 已初始化
git submodule update --init dotfiles/nvim

# 注意：dotfiles/ 目录现在仅用于 nvim Git Submodule
# 所有其他配置已迁移到 .chezmoi/ 目录，由 chezmoi 统一管理
# Neovim 配置会自动通过 chezmoi 管理（创建符号链接到 ~/.config/nvim）
```

#### 3. 配置 Git

```bash
# 设置 Git 用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 查看配置
git config --global --list
```

---

## 通用操作

### 使用管理脚本

项目提供了统一的管理脚本，方便日常使用：

```bash
# 查看帮助
./scripts/manage_dotfiles.sh help

# 安装 chezmoi 并初始化
./scripts/manage_dotfiles.sh install

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

### 日常使用

#### 更新配置

```bash
# 从仓库拉取最新配置
git pull

# 更新到系统
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi update -v
```

#### 修改配置

```bash
# 编辑配置
chezmoi edit ~/.zshrc

# 查看变更
chezmoi diff

# 应用变更
chezmoi apply -v

# 提交到 Git
git add .chezmoi
git commit -m "Update config"
git push
```

#### 添加新配置

```bash
# 添加新配置文件
chezmoi add ~/.new_config

# 编辑配置
chezmoi edit ~/.new_config

# 应用配置
chezmoi apply ~/.new_config

# 提交到 Git
git add .chezmoi
git commit -m "Add new config"
git push
```

#### SSH 配置管理

SSH 配置文件（`~/.ssh/config`）已纳入 chezmoi 管理，可以通过 lazyssh 或直接编辑进行管理。

**首次纳入管理（当前系统）：**

```bash
# 1. 备份现有配置（SSH + Git）
./scripts/common/utils/backup_ssh_config.sh
./scripts/common/utils/backup_git_config.sh

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

**新系统部署：**

部署前建议备份 `~/.ssh/config` 与 `~/.gitconfig`（执行 `backup_ssh_config.sh`、`backup_git_config.sh`）：

```bash
# 1. 确保 ~/.ssh 目录存在
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. 使用部署脚本（推荐）
./scripts/common/utils/setup_ssh_config.sh

# 或手动应用配置
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply ~/.ssh/config
chmod 600 ~/.ssh/config
```

**日常使用：**

```bash
# 编辑 SSH 配置（使用 lazyssh 或直接编辑）
chezmoi edit ~/.ssh/config

# 如果使用 lazyssh 修改了配置，需要同步
chezmoi re-add ~/.ssh/config
git add .chezmoi/dot_ssh/config
git commit -m "Update SSH config"
git push

# 查看配置差异
chezmoi diff ~/.ssh/config
```

**使用 lazyssh 配置的 Host：**

通过 lazyssh 配置的 Host 可以直接在终端使用，无需打开 lazyssh 界面：

```bash
# 连接到服务器（进入 shell + 开启端口转发）
ssh alchemy-studio-tunnel

# 只开启端口转发，不进入 shell（推荐后台运行）
ssh -f -N alchemy-studio-tunnel

# 双层隧道示例（通过跳板转发）
ssh -f -N mini-server-container-vnc    # 本地 5903 → 内层容器 5909
```

**简化使用（推荐添加别名）：**

在 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
# 双层 VNC 隧道一键开启
alias vnc-mini='ssh -f -N mini-server-container-vnc'

# alchemy-studio 主机 VNC
alias vnc-alchemy='ssh -f -N alchemy-studio-vnc'

# moicen 主机 VNC
alias vnc-moicen='ssh -f -N moicen-vnc'
```

保存后执行 `source ~/.zshrc`，以后直接使用 `vnc-mini` 等别名即可。

**检查隧道状态：**

```bash
# 检查端口是否在监听
lsof -i:5903
# 或
netstat -an | grep 5903
```

详细说明请参考：[chezmoi_use_guide.md](chezmoi_use_guide.md#使用-lazyssh-配置的-host)

**安全注意事项：**
- SSH 配置文件权限必须为 600
- 私钥文件（`id_*`）不会被纳入管理，已在 `.gitignore` 和 `.chezmoiignore` 中排除
- 保持仓库私有，不要公开包含 SSH 配置的仓库

### 代理配置

如果需要使用代理，可以设置环境变量：

```bash
# 设置代理
export PROXY="http://127.0.0.1:7890"
export http_proxy="$PROXY"
export https_proxy="$PROXY"

# 然后应用配置
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

代理配置会自动传递给所有安装脚本。

---

## 参考文档

- [README.md](README.md) - 项目主文档
- [chezmoi_use_guide.md](chezmoi_use_guide.md) - chezmoi 使用指南
- [SOFTWARE_LIST.md](SOFTWARE_LIST.md) - 软件清单
- [project_structure.md](project_structure.md) - 项目结构说明
- [scripts/windows/system_basic_env/README.md](scripts/windows/system_basic_env/README.md) - Windows 工具安装脚本说明
- [scripts/macos/system_basic_env/README.md](scripts/macos/system_basic_env/README.md) - macOS 工具安装脚本说明
- [chezmoi 官方文档](https://www.chezmoi.io/docs/)

---

## 总结

### Windows 安装流程

1. ✅ **安装 chezmoi** - 使用 `scripts/chezmoi/install_chezmoi.sh` 或 winget
2. ✅ **初始化仓库** - 设置 `CHEZMOI_SOURCE_DIR` 环境变量
3. ✅ **安装所需软件** - 使用 `chezmoi apply -v` 或 PowerShell 脚本
4. ✅ **配置所需软件** - 使用 `chezmoi apply -v` 应用所有配置
5. ✅ **纳入 chezmoi 管理** - 使用 `chezmoi add` 添加现有配置

### macOS 安装流程

1. ✅ **安装前置条件** - Xcode Command Line Tools 和 Homebrew
2. ✅ **安装 chezmoi** - 使用 Homebrew 或官方脚本
3. ✅ **初始化仓库** - 设置 `CHEZMOI_SOURCE_DIR` 环境变量
4. ✅ **安装所需软件** - 使用 `chezmoi apply -v` 自动安装
5. ✅ **配置所需软件** - 使用 `chezmoi apply -v` 应用所有配置
6. ✅ **后续配置** - Yabai、skhd、Neovim 等可选配置

所有步骤完成后，系统配置已完全由 chezmoi 管理，可以通过 Git 进行版本控制和同步。

