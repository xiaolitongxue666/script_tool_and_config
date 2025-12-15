# script_tool_and_config

个人软件配置和常用脚本集合

本项目包含我在日常开发中使用的各种脚本工具和软件配置文件，涵盖 Linux、macOS 和 Windows 平台。

## 支持的平台

- **Windows**: Windows 10/11 (winget, MSYS2)
- **macOS**: macOS 10.15+ (Homebrew)
- **Linux**:
  - ArchLinux (pacman)
  - Ubuntu/Debian (apt)
  - CentOS/RHEL (dnf/yum)
  - Fedora (dnf)

详细平台支持说明见下方"平台支持"章节。

## 平台支持

### 支持的操作系统

#### Windows
- **支持版本**: Windows 10/11
- **包管理器**:
  - `winget` (Windows Package Manager) - 优先使用
  - `pacman` (MSYS2) - 备选
- **Shell 环境**: Git Bash, MSYS2
- **特殊说明**:
  - 需要创建 `~/.local/share/chezmoi` 目录（脚本会自动处理）
  - 支持通过 MSYS2 安装 Unix 工具

#### macOS
- **支持版本**: macOS 10.15+ (Catalina 及以上)
- **包管理器**: `brew` (Homebrew) - 必需
- **架构支持**: Intel (x86_64) 和 Apple Silicon (arm64)
- **特殊说明**:
  - 需要先安装 Homebrew
  - Apple Silicon Mac 使用 `/opt/homebrew`，Intel Mac 使用 `/usr/local`

#### Linux

**ArchLinux**
- **包管理器**: `pacman`
- **支持版本**: 最新稳定版
- **特殊脚本**:
  - `scripts/linux/system_basic_env/install_common_tools.sh` - 仅支持 ArchLinux
  - `scripts/linux/system_basic_env/configure_china_mirrors.sh` - 配置中国镜像源

**Ubuntu/Debian**
- **包管理器**: `apt` (apt-get)
- **支持版本**:
  - Ubuntu 18.04+ (LTS 和最新版)
  - Debian 10+ (Buster 及以上)
- **特殊说明**: 使用 `apt-get` 命令

**CentOS/RHEL**
- **包管理器**:
  - `dnf` (CentOS 8+, RHEL 8+, Fedora) - 优先使用
  - `yum` (CentOS 7-, RHEL 7-) - 旧版本
- **支持版本**:
  - CentOS 7 (使用 yum)
  - CentOS 8+ (使用 dnf)
  - RHEL 7 (使用 yum)
  - RHEL 8+ (使用 dnf)
  - Fedora (使用 dnf)

### 包管理器检测顺序

**Linux**
1. `pacman` (ArchLinux)
2. `apt-get` (Ubuntu/Debian)
3. `dnf` (CentOS 8+/RHEL 8+/Fedora)
4. `yum` (CentOS 7-/RHEL 7-)

**Windows**
1. `winget` (Windows Package Manager)
2. `pacman.exe` (MSYS2)

**macOS**
1. `brew` (Homebrew) - 必需

### 平台特定功能

**Windows**
- Git Bash 配置 (`~/.bash_profile`, `~/.bashrc`)
- MSYS2 支持
- Zsh 通过 MSYS2 安装

**macOS**
- Yabai 窗口管理器配置
- skhd 快捷键配置
- Homebrew 集成

**Linux**
- **ArchLinux 特定**:
  - i3wm 窗口管理器配置
  - dwm 窗口管理器配置
  - 中国镜像源配置脚本
  - AUR 助手 (yay) 安装
- **通用 Linux**:
  - Shell 配置 (Bash, Zsh, Fish)
  - Tmux 配置
  - Starship 提示符
  - Alacritty 终端

### 测试状态

**已验证平台**
- ✅ Windows 10/11 (Git Bash)
- ✅ macOS (Intel 和 Apple Silicon)
- ✅ ArchLinux
- ✅ Ubuntu 20.04/22.04
- ✅ CentOS 7 (yum)
- ✅ CentOS 8+ (dnf)

**部分支持**
- ⚠️ Debian (理论上支持，未充分测试)
- ⚠️ RHEL (理论上支持，未充分测试)
- ⚠️ Fedora (理论上支持，未充分测试)

### 已知限制

1. **ArchLinux 特定脚本**: `install_common_tools.sh` 仅支持 ArchLinux，其他发行版会报错
2. **Windows 路径**: 某些脚本在 Windows 上可能需要路径转换
3. **权限要求**: Linux 安装脚本需要 sudo 权限
4. **网络要求**: 首次安装需要网络连接（下载软件包）

## 快速开始（使用 chezmoi）

本项目使用 [chezmoi](https://www.chezmoi.io/) 统一管理所有 dotfiles 配置。chezmoi 是一个强大的 dotfiles 管理工具，支持跨平台配置管理、模板变量、加密等功能。

### 新系统安装

**如果是全新的系统，请参考：**
- 📖 [OS_SETUP_GUIDE.md](OS_SETUP_GUIDE.md) - Windows/macOS 新系统完整安装指南
- 🚀 Windows 快速执行：双击 `scripts/windows/install_with_chezmoi.bat`（需要管理员权限）

该指南包含完整的安装流程：
- **Windows**: 5 步流程（安装 chezmoi → 初始化 → 安装软件 → 配置软件 → 纳入管理）
- **macOS**: 6 步流程（前置条件 → 安装 chezmoi → 初始化 → 安装软件 → 配置软件 → 后续配置）

### 一键安装

```bash
# 克隆项目
git clone <repo-url>
cd script_tool_and_config

# 运行一键安装脚本
./install.sh
```

安装脚本会自动：
- 检测操作系统
- 安装 chezmoi（如果未安装）
- 初始化 chezmoi 仓库
- 应用所有配置文件到系统

### 使用管理脚本

项目提供了统一的管理脚本 `scripts/manage_dotfiles.sh`：

```bash
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

# 查看帮助
./scripts/manage_dotfiles.sh help
```

### 日常使用

```bash
# 应用所有配置
chezmoi apply -v

# 查看配置差异
chezmoi diff

# 编辑配置文件
chezmoi edit ~/.zshrc

# 添加新配置文件
chezmoi add ~/.new_config

# 更新配置到仓库
chezmoi re-add
git add .chezmoi
git commit -m "Update config"
git push
```

### 详细文档

更多使用说明请参考：
- [OS_SETUP_GUIDE.md](OS_SETUP_GUIDE.md) - Windows/macOS 新系统完整安装指南
- [CHEZMOI_GUIDE.md](CHEZMOI_GUIDE.md) - 完整的 chezmoi 使用指南
- [SOFTWARE_LIST.md](SOFTWARE_LIST.md) - 完整的软件清单和分类
- [project_structure.md](project_structure.md) - 详细的项目结构说明
- [chezmoi 官方文档](https://www.chezmoi.io/docs/)

## 详细使用说明

### 1. 如何下载安装 chezmoi

chezmoi 是一个跨平台的 dotfiles 管理工具，支持 Linux、macOS 和 Windows。

#### 方法一：使用项目提供的安装脚本（推荐）

```bash
# 进入项目目录
cd script_tool_and_config

# 运行安装脚本（会自动检测系统并安装）
bash scripts/chezmoi/install_chezmoi.sh
```

#### 方法二：使用系统包管理器

**Linux (Arch Linux)**
```bash
sudo pacman -S chezmoi
```

**Linux (Ubuntu/Debian)**
```bash
sudo apt-get update
sudo apt-get install chezmoi
```

**macOS**
```bash
brew install chezmoi
```

**Windows**
```bash
# 使用 winget
winget install --id=twpayne.chezmoi -e

# 或使用 MSYS2
pacman -S chezmoi
```

#### 方法三：使用官方安装脚本

```bash
# 适用于所有平台
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# 安装后需要将 ~/.local/bin 添加到 PATH
# Linux/macOS: 添加到 ~/.bashrc 或 ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Windows (Git Bash): 添加到 ~/.bash_profile
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
```

#### 验证安装

```bash
# 检查版本
chezmoi --version

# 查看帮助
chezmoi help
```

### 2. 如何在当前系统安装所需软件

本项目使用 chezmoi 的 `run_once_` 脚本机制自动安装所需软件。这些脚本只会在首次应用配置时执行一次。

#### 初始化项目并应用配置

```bash
# 1. 克隆项目
git clone <repo-url>
cd script_tool_and_config

# 2. 设置源状态目录（重要！）
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 3. 应用所有配置（会自动执行 run_once_ 安装脚本）
chezmoi apply -v
```

#### 可用的安装脚本

项目包含以下 `run_once_install-*.sh.tmpl` 模板脚本，会在首次应用时自动执行。所有脚本已使用 chezmoi 模板系统，根据平台自动判断是否执行。

**通用工具（所有平台）**
- `run_once_install-starship.sh.tmpl` - Starship 提示符
- `run_once_install-git.sh.tmpl` - Git
- `run_once_install-neovim.sh.tmpl` - Neovim
- `run_once_install-common-tools.sh.tmpl` - 通用工具（bat, eza, fd, ripgrep, fzf, lazygit, git-delta, gh）
- `run_once_install-version-managers.sh.tmpl` - 版本管理器（fnm, uv, rustup）

**Linux/macOS 通用**
- `run_once_install-tmux.sh.tmpl` - Tmux
- `run_once_install-alacritty.sh.tmpl` - Alacritty
- `run_once_install-zsh.sh.tmpl` - Zsh 和 Oh My Zsh
- `run_once_install-fish.sh.tmpl` - Fish Shell

**Linux 特有**
- `run_once_install-i3wm.sh.tmpl` - i3wm 窗口管理器
- `run_once_install-dwm.sh.tmpl` - dwm 窗口管理器

**macOS 特有**
- `run_once_install-yabai.sh.tmpl` - Yabai 窗口管理器
- `run_once_install-skhd.sh.tmpl` - skhd 快捷键守护进程

**Windows 特有**
- `run_once_install-oh-my-posh.sh.tmpl` - Oh My Posh

**注意**：
- 所有脚本使用模板条件判断，不符合平台条件的脚本不会执行
- Windows 上默认使用 **Git Bash**，不安装 Fish Shell
- Windows 上的 Zsh 安装是可选的（需要 MSYS2）
- 详细软件清单请参考：[software_list.md](software_list.md)

#### 代理配置（可选）

如果需要在安装过程中使用代理，可以设置环境变量：

```bash
# 设置代理
export PROXY="http://127.0.0.1:7890"
export http_proxy="$PROXY"
export https_proxy="$PROXY"

# 然后应用配置
chezmoi apply -v
```

代理配置会自动传递给所有安装脚本。

#### 手动触发安装脚本

如果需要重新运行某个安装脚本（例如软件被卸载后），可以：

```bash
# 方法一：删除 chezmoi 的执行记录（不推荐）
chezmoi forget ~/.local/share/chezmoi/run_once_install-*.sh.tmpl

# 方法二：直接运行脚本（需要先执行模板）
chezmoi execute-template < .chezmoi/run_once_install-zsh.sh.tmpl | bash
```

### 3. 如何在当前系统配置所需配置文件

chezmoi 会将 `.chezmoi/` 目录中的配置文件应用到系统的相应位置。

#### 配置文件映射规则

chezmoi 使用以下命名规则将源文件映射到目标位置：

- `dot_*` → `~/.`（例如：`dot_zshrc` → `~/.zshrc`）
- `dot_config/*` → `~/.config/*`（例如：`dot_config/fish/config.fish` → `~/.config/fish/config.fish`）
- `run_once_*.sh` → 执行一次（安装脚本）
- `run_on_<os>/*` → 仅在指定操作系统执行

#### 应用配置文件

```bash
# 1. 确保已设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 2. 应用所有配置
chezmoi apply -v

# 3. 或应用特定文件
chezmoi apply ~/.zshrc
```

#### 查看配置状态

```bash
# 查看所有文件状态
chezmoi status

# 查看特定文件状态
chezmoi status ~/.zshrc

# 查看配置差异
chezmoi diff

# 查看特定文件差异
chezmoi diff ~/.zshrc
```

#### 编辑配置文件

```bash
# 编辑配置文件（会自动打开编辑器）
chezmoi edit ~/.zshrc

# 或直接编辑源文件
# 编辑后需要重新应用
chezmoi apply ~/.zshrc
```

#### 添加新配置文件

```bash
# 1. 添加文件到 chezmoi 管理
chezmoi add ~/.new_config

# 2. 编辑配置
chezmoi edit ~/.new_config

# 3. 应用配置
chezmoi apply ~/.new_config

# 4. 提交到 Git
git add .chezmoi
git commit -m "Add new config"
git push
```

#### 使用模板变量

chezmoi 支持在配置文件中使用模板变量，实现跨平台配置。所有安装脚本已转换为模板格式（`.tmpl`），使用模板条件判断平台。

**在 `.chezmoi.toml` 中定义变量：**
```toml
[data]
    os = "{{ .chezmoi.os }}"
    proxy = "{{ envOrDefault \"PROXY\" \"http://127.0.0.1:7890\" }}"
```

**在配置文件中使用（文件名需要包含 `.tmpl` 或使用 `.tmpl` 扩展名）：**
```bash
# .chezmoi/dot_bashrc.tmpl
{{ if eq .chezmoi.os "darwin" }}
# macOS 特定配置
export PATH="/opt/homebrew/bin:$PATH"
{{ else if eq .chezmoi.os "linux" }}
# Linux 特定配置
export PATH="/usr/local/bin:$PATH"
{{ end }}

# 使用代理变量
alias h_proxy='export http_proxy={{ .proxy }}'
```

**安装脚本模板示例：**
```bash
# .chezmoi/run_once_install-tmux.sh.tmpl
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") -}}
#!/bin/bash
# 安装逻辑（仅在 Linux/macOS 上执行）
{{- end -}}
```

#### 平台特定配置

项目使用 `run_on_<os>/` 目录组织平台特定的配置文件，安装脚本已统一到根目录并使用模板条件判断：

- **Linux 配置**：`.chezmoi/run_on_linux/`
  - `dot_config/i3/config` → `~/.config/i3/config`

- **macOS 配置**：`.chezmoi/run_on_darwin/`
  - `dot_yabairc` → `~/.yabairc`
  - `dot_skhdrc` → `~/.skhdrc`

- **Windows 配置**：`.chezmoi/run_on_windows/`
  - `dot_bash_profile` → `~/.bash_profile`
  - `dot_bashrc` → `~/.bashrc`

这些配置只会在对应的操作系统上应用。安装脚本使用模板条件判断，不符合平台条件的脚本不会执行。

#### 更新配置

```bash
# 1. 从仓库拉取最新配置
git pull

# 2. 更新到系统
chezmoi update -v

# 3. 查看变更
chezmoi diff
```

#### 配置文件列表

当前项目管理的配置文件包括：

**Shell 配置**
- `~/.zshrc` - Zsh 配置
- `~/.zprofile` - Zsh 启动配置
- `~/.bashrc` - Bash 配置（模板，支持多平台）
- `~/.config/fish/config.fish` - Fish Shell 配置

**终端和工具配置**
- `~/.config/alacritty/alacritty.toml` - Alacritty 终端配置
- `~/.tmux.conf` - Tmux 配置
- `~/.config/starship/starship.toml` - Starship 提示符配置

**窗口管理器配置（平台特定）**
- `~/.config/i3/config` - i3wm 配置（Linux）
- `~/.yabairc` - Yabai 配置（macOS）
- `~/.skhdrc` - skhd 配置（macOS）

完整的软件清单和配置文件映射请参考：[software_list.md](software_list.md)

### 使用项目管理脚本

项目提供了统一的管理脚本 `scripts/manage_dotfiles.sh`，封装了常用操作：

```bash
# 安装 chezmoi 并初始化
./scripts/manage_dotfiles.sh install

# 应用所有配置
./scripts/manage_dotfiles.sh apply

# 更新配置
./scripts/manage_dotfiles.sh update

# 查看配置差异
./scripts/manage_dotfiles.sh diff

# 查看配置状态
./scripts/manage_dotfiles.sh status

# 编辑配置文件
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 列出所有受管理的文件
./scripts/manage_dotfiles.sh list

# 进入源状态目录
./scripts/manage_dotfiles.sh cd

# 查看帮助
./scripts/manage_dotfiles.sh help
```

### 故障排除

#### 问题：chezmoi 找不到源状态目录

**解决：**
```bash
# 设置源状态目录环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 或使用项目管理脚本（会自动设置）
./scripts/manage_dotfiles.sh apply
```

#### 问题：配置文件冲突

**解决：**
```bash
# 查看差异
chezmoi diff ~/.zshrc

# 如果确定要覆盖，使用 --force
chezmoi apply --force ~/.zshrc

# 或先备份
cp ~/.zshrc ~/.zshrc.backup
chezmoi apply ~/.zshrc
```

#### 问题：模板变量未解析

**解决：**
- 确保文件扩展名为 `.tmpl` 或在文件名中包含 `.tmpl`
- 检查 `.chezmoi.toml` 中的变量定义
- 使用 `chezmoi execute-template` 测试模板：
  ```bash
  chezmoi execute-template '{{ .chezmoi.os }}'
  ```

#### 问题：run_once_ 脚本重复执行

**解决：**
- 检查脚本是否有正确的 `run_once_` 前缀
- 确保脚本在源状态目录中
- 查看 chezmoi 状态：`chezmoi status`

#### 问题：Windows Git Bash 上 chezmoi 找不到状态目录

**问题**：在 Windows Git Bash 上运行 `chezmoi apply` 或 `chezmoi diff` 时出现错误：
```
chezmoi: GetFileAttributesEx C:/Users/Administrator/.local/share/chezmoi: The system cannot find the file specified.
```

**原因**：chezmoi 需要 `~/.local/share/chezmoi` 目录来存储状态信息，但在 Windows 上该目录可能不存在。

**解决**：

**方法一：使用项目管理脚本（推荐）**
```bash
# 项目管理脚本会自动创建必要的目录
./scripts/manage_dotfiles.sh apply
./scripts/manage_dotfiles.sh diff
```

**方法二：手动创建目录**
```bash
# 创建 chezmoi 状态目录
mkdir -p ~/.local/share/chezmoi

# 然后运行 chezmoi 命令
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

**方法三：使用 chezmoi init（如果使用默认源状态目录）**
```bash
# 如果使用默认源状态目录（非项目内目录）
chezmoi init <repo-url>
```

**注意**：本项目使用项目内源状态目录模式（`.chezmoi/`），因此需要设置 `CHEZMOI_SOURCE_DIR` 环境变量，并确保状态目录存在。

### 传统方式（Legacy）

原有的 `dotfiles/` 目录已标记为 legacy，仅保留配置文件作为参考。所有安装脚本已迁移到 `.chezmoi/` 目录并使用模板系统管理。详情请参考：[dotfiles/legacy.md](dotfiles/legacy.md)

## 项目结构

```
script_tool_and_config/
├── .chezmoi/                       # chezmoi 源状态目录（所有配置文件）
│   ├── dot_*                       # 通用配置文件（模板格式）
│   ├── dot_config/                 # ~/.config 目录下的配置
│   ├── run_once_install-*.sh.tmpl  # 模板化的安装脚本（使用 chezmoi 模板条件）
│   ├── run_on_linux/               # Linux 特定配置
│   ├── run_on_darwin/              # macOS 特定配置
│   └── run_on_windows/             # Windows 特定配置
├── .chezmoi.toml                   # chezmoi 配置文件
├── .chezmoiignore                  # chezmoi 忽略文件
├── install.sh                      # 一键安装脚本
├── dotfiles/                       # 配置文件（Legacy，仅保留配置文件）
│   ├── LEGACY.md                   # Legacy 说明文档
│   ├── alacritty/                  # Alacritty 配置（仅配置文件）
│   ├── bash/                       # Bash 配置（仅配置文件）
│   ├── fish/                       # Fish Shell 配置（仅配置文件）
│   ├── i3wm/                       # i3 窗口管理器配置（仅配置文件）
│   ├── skhd/                       # skhd 配置（仅配置文件）
│   ├── starship/                   # Starship 配置（仅配置文件）
│   ├── tmux/                       # Tmux 配置（仅配置文件）
│   ├── yabai/                      # Yabai 配置（仅配置文件）
│   └── zsh/                        # Zsh 配置（仅配置文件）
│
└── scripts/                        # 脚本工具集合（按系统分类）
    ├── common.sh                    # 通用函数库（所有脚本共享）
    ├── chezmoi/                     # chezmoi 相关脚本
    │   ├── README.md                # chezmoi 脚本说明
    │   ├── common_install.sh        # 通用安装函数库
    │   ├── install_chezmoi.sh      # chezmoi 安装脚本
    │   └── helpers.sh              # 辅助函数
    ├── manage_dotfiles.sh           # dotfiles 管理脚本
    ├── README.md                    # scripts 目录说明
    ├── windows/                     # Windows 专用脚本
    │   ├── install_with_chezmoi.sh  # Windows 完整安装脚本
    │   ├── install_with_chezmoi.bat # Windows 安装批处理
    │   └── system_basic_env/        # Windows 基础环境安装
    │       └── README.md            # Windows 工具安装说明
    ├── macos/                       # macOS 专用脚本
    │   └── system_basic_env/        # macOS 基础环境安装
    │       └── README.md            # macOS 工具安装说明
    └── linux/                       # Linux 专用脚本和跨平台脚本
        ├── system_basic_env/        # 系统基础环境安装脚本（ArchLinux）
        │   ├── USAGE.md             # 使用说明
        │   └── TEST_MIRRORS_README.md # 镜像测试说明
        ├── network/                 # 网络配置脚本
        ├── hardware/                # 硬件安装脚本
        ├── utils/                   # 通用工具脚本（跨平台）
        ├── project_tools/           # 项目生成和管理工具（跨平台）
        ├── media_tools/             # 媒体处理工具（跨平台）
        ├── git_templates/           # Git 相关模板（跨平台）
        ├── patch_examples/          # 补丁使用示例（跨平台）
        │   └── README.md            # 补丁使用说明
        ├── shc/                     # Shell 脚本编译器示例（跨平台）
        └── auto_edit_redis_config/  # Redis 配置编辑（跨平台）
```

### 关键目录说明

- **`.chezmoi/`**: 所有配置文件和管理脚本，使用 chezmoi 模板系统
- **`dotfiles/`**: Legacy 目录，仅保留配置文件作为参考（已迁移到 `.chezmoi/`）
- **`scripts/`**: 功能性脚本，按平台分类组织

### 文档结构

**根目录文档：**
- `README.md` - 项目主文档（本文件）
- `OS_SETUP_GUIDE.md` - Windows/macOS 新系统完整安装指南
- `CHEZMOI_GUIDE.md` - chezmoi 使用指南
- `SOFTWARE_LIST.md` - 软件清单和分类
- `project_structure.md` - 详细的项目结构说明

**子目录文档：**
- `scripts/README.md` - scripts 目录说明
- `scripts/chezmoi/README.md` - chezmoi 脚本说明
- `scripts/linux/system_basic_env/USAGE.md` - ArchLinux 系统配置使用说明
- `scripts/windows/system_basic_env/README.md` - Windows 工具安装说明
- `scripts/macos/system_basic_env/README.md` - macOS 工具安装说明
- `dotfiles/LEGACY.md` - Legacy 配置说明

## 主要功能分类

### 1. 环境构建和配置 (environment_setup)

#### Linux
- **ArchLinux 相关**
  - `archlinux_pacman_config/`: Pacman 包管理器配置，包括中国镜像源配置
  - `archlinux_software_auto_install/`: ArchLinux 常用软件自动安装脚本
  - `archlinux_environment_auto_install.sh`: ArchLinux 环境自动安装（Neovim、Git、Python 等）
  - `add_china_source_for_archlinux_pacman_config.sh`: 为 ArchLinux 添加中国镜像源

- **窗口管理器**
  - `i3wm_config/`: i3 窗口管理器配置文件

- **编辑器配置**
  - `auto_install_neovim_for_archlinux.sh`: ArchLinux 上自动安装 Neovim
  - `auto_install_fish_and_omf.sh`: 安装 Fish Shell 和 Oh My Fish
  - `install_neovim.sh`: 安装 Neovim（包含 Windows 配置说明）
    - **Windows 配置**: 需要设置 `XDG_CONFIG_HOME` 环境变量，详见脚本注释

#### Windows
- `keyboard_exchange_esc_and_tab/`: 键盘 ESC 和 TAB 键交换配置

### 2. 点配置文件 (dotfiles)

所有工具配置遵循统一的结构：**工具名/配置文件/readme.md/install.sh**

#### Shell 配置
- **Fish Shell** (`fish/`)
  - 支持多平台（Linux、macOS）
  - `config.fish`: **统一配置文件**，自动检测系统并加载对应配置
  - `install.sh`: 自动安装和配置脚本，支持自动检测系统、安装 Fish、同步配置（包含自动备份）
  - `completions/`: 补全脚本目录
  - `conf.d/fnm.fish`: fnm (Fast Node Manager) 配置
  - **主要特性**:
    - fnm 自动切换（根据 `.nvmrc` 或 `.node-version` 文件）
    - Pyenv 集成
    - 智能工具别名（lsd/bat/trash）
    - 完整代理支持（http/https/socks5）
    - 路径自动管理

- **Bash** (`bash/`)
  - 支持多平台（macOS、Windows、Linux）
  - `config.sh`: **统一配置文件**，自动检测系统并加载对应配置
  - `install.sh`: 自动安装和配置脚本，支持自动检测系统、同步配置（包含自动备份）

- **Zsh** (`zsh/`)
  - 支持多平台（macOS、Linux）
  - `.zshrc`: **统一配置文件**，基于 Oh My Zsh 框架
  - `install.sh`: 自动安装脚本，包含 Zsh 和 Oh My Zsh 安装，以及配置同步功能
  - **主要特性**:
    - Oh My Zsh 集成（主题、插件）
    - Fish-like 体验插件（自动安装）：
      - `zsh-autosuggestions`：实时历史建议
      - `zsh-history-substring-search`：子字符串历史搜索
      - `zsh-syntax-highlighting`：实时语法高亮
    - fnm 自动检测和加载
    - Pyenv 集成
    - 智能工具别名（lsd/bat/trash）
    - 完整代理支持（http/https/socks5）
    - 历史记录优化配置

#### 终端和窗口管理
- **Alacritty** (`alacritty/`): GPU 加速终端模拟器
  - `alacritty.toml`: 完整的配置文件（TOML 格式，从 0.13.0 版本开始使用）
  - `install.sh`: 自动安装脚本（macOS）
  - 支持 macOS、Linux、Windows 平台
  - 参考: [Alacritty GitHub](https://github.com/alacritty/alacritty)

- **Tmux** (`tmux/`): 终端复用器
  - `tmux.conf`: Tmux 配置文件
  - `install.sh`: 自动安装脚本（支持多平台）

- **i3** (`i3wm/`): 平铺式窗口管理器（仅 Linux）
  - `config`: i3 配置文件
  - `install.sh`: 自动安装脚本（仅 Linux）

- **dwm** (`dwm/`): 动态窗口管理器（仅 Linux）
  - `install.sh`: 自动安装脚本（支持多 Linux 发行版）
  - `config.h`: 自定义配置文件（可选）
  - 参考: [dwm 官网](https://dwm.suckless.org/)

- **Yabai** (`yabai/`): macOS 平铺式窗口管理器
  - `yabairc`: Yabai 配置文件
  - `install.sh`: 自动安装脚本（仅 macOS）

- **skhd** (`skhd/`): macOS 快捷键守护进程
  - `skhdrc`: skhd 配置文件
  - `install.sh`: 自动安装脚本（仅 macOS）

#### 其他工具配置
- **Neovim** (`nvim/`): 现代化 Neovim 配置（使用 Git Submodule 管理）
  - **配置方式**: Git Submodule（独立仓库）
  - `install.sh`: 自动安装脚本（支持多平台，包含配置同步和备份）
  - 支持 macOS、Linux、Windows 平台
  - **主要特性**:
    - 基于 Lua 的现代化配置
    - lazy.nvim 插件管理器
    - 代码补全、LSP 支持、语法高亮
    - 文件浏览、模糊查找、Git 集成
    - 丰富的 UI 组件和主题
  - **Submodule 使用**:
    - 首次克隆后需要初始化: `git submodule update --init dotfiles/nvim`
    - 更新配置: `git submodule update --remote dotfiles/nvim`
  - **原始仓库**: https://github.com/xiaolitongxue666/nvim

- **IdeaVim** (`nvim/ideavimrc/`): IntelliJ IDEA 系列 IDE 的 Vim 模拟插件配置
  - **配置方式**: 位于 nvim submodule 中
  - `.ideavimrc`: IdeaVim 配置文件（已与 basic.lua 同步配置）
  - `install.sh`: 自动安装脚本（支持多平台，包含配置同步和备份）
  - 支持 macOS、Linux、Windows 平台
  - **主要特性**:
    - Vim 键位映射和编辑体验
    - IDEA 动作集成（调试、重构、跳转等）
    - 自定义 Leader 键和快捷键
    - 窗口管理和代码导航
    - 配置与 Neovim basic.lua 保持一致
  - **Submodule 使用**:
    - 首次克隆后需要初始化: `git submodule update --init dotfiles/nvim`
    - 更新配置: `git submodule update --remote dotfiles/nvim`
  - **注意**: 配置位于 `dotfiles/nvim/ideavimrc/`，通过 nvim submodule 管理

- **SecureCRT** (`secure_crt/`): SSH 客户端配置和自动化脚本
  - `SecureCRTV8_VM_Login_TOP.vbs`: VBScript 自动化脚本
  - `install.sh`: 自动安装脚本（Windows）

### 3. 脚本工具 (scripts)

脚本按操作系统分类组织，详见 `scripts/readme.md`。

#### Windows 专用脚本 (`scripts/windows/`)
- **windows_scripts/**: Windows 批处理脚本
  - `open_multi_vlc.bat`: 打开多个 VLC 播放器实例
  - `open_16_vlc.bat`: 打开 16 个 VLC 播放器实例

#### macOS 专用脚本 (`scripts/macos/`)
- 预留目录，用于 macOS 专用脚本

#### Linux 专用脚本和跨平台脚本 (`scripts/linux/`)

**系统基础环境安装脚本 (`system_basic_env/`)**
- ArchLinux 系统基础环境安装和配置脚本
  - `configure_china_mirrors.sh`: 快速配置中国镜像源（9个可用镜像，2025年11月更新）
    - 配置主仓库镜像（core, extra）
    - 配置 archlinuxcn 仓库镜像（8个可用镜像）
    - 自动备份原始配置
    - 移除已废弃的 community 仓库配置
  - `install_common_tools.sh`: 一键安装常用开发工具和环境
    - **智能代理策略**：pacman 操作使用国内源直连，其他操作使用代理
    - **两阶段安装**：
      - 第一阶段：pacman 相关操作（镜像源配置、系统更新、基础包安装、AUR 助手）
      - 第二阶段：其他工具安装（uv、fnm、Neovim、字体等）
    - **Neovim Python 环境**：自动配置 Python 虚拟环境（支持系统级/用户级）
    - **自动配置**：镜像源、pacman 优化、archlinuxcn-keyring 安装
    - 详细日志记录和错误处理
    - 支持 `USE_SYSTEM_NVIM_VENV=1` 环境变量（系统级 Python 环境）
    - 支持 `NO_PROXY=1` 环境变量（完全禁用代理）
  - `install_environment.sh`: 安装开发环境
  - `install_neovim.sh`: 安装 Neovim
  - `install_common_software.sh`: 安装常用软件
  - `install_gnome.sh`: 安装 GNOME 桌面环境
  - `install_network_manager.sh`: 安装网络管理器
  - `usage.md`: 脚本使用说明文档

**网络配置脚本 (`network/`)**
- `configure_ethernet_mac.sh`: 配置以太网 MAC 地址
- `deploy_openresty.sh`: 部署 OpenResty
- `send_srt_stream.sh`: 发送 SRT 流

**硬件安装脚本 (`hardware/`)**
- `install_netint_t4xx.sh`: 安装 Netint T4XX 硬件加速卡

**通用工具脚本 (`utils/`) - 跨平台**
- `append_text_to_file.sh`: 追加文本到文件
- `append_lines_to_file.sh`: 追加多行文本到文件
- `replace_text_in_files.sh`: 替换文件中的文本
- `list_all_directories.sh`: 列出所有目录
- `list_all_files_and_directories.sh`: 列出所有文件和目录
- `get_directory_name.sh`: 获取目录名称
- `get_openresty_path.sh`: 获取 OpenResty 路径
- `get_pkg_config_flags.sh`: 获取 pkg-config 编译标志
- `get_svn_revision.sh`: 获取 SVN 版本号
- `update_ts_key_pair.sh`: 更新 TS 密钥对
- `open_multiple_terminals.sh`: 打开多个终端
- `compare_static_lib_objects.sh`: 比较静态库对象文件
- `demo_printf_formatting.sh`: printf 格式化示例
- `demo_heredoc.sh`: heredoc 示例

**项目工具 (`project_tools/`) - 跨平台**
- `create_c_source_file.sh`: 创建 C 源文件
- `generate_cmake_lists.sh`: 生成 CMakeLists.txt
- `generate_log4c_config.sh`: 生成 log4c 配置
- `merge_static_libraries.sh`: 合并多个静态库
- **cpp_project_generator/**: C/C++ 项目生成器
  - `generate_project.sh`: 自动创建项目结构
  - `cmake_all_project.sh`: CMake 构建脚本
  - `ls_dirs_name.sh`: 列出目录名称

**媒体处理工具 (`media_tools/`) - 跨平台**
- `open_multiple_ffmpeg_srt.sh`: 打开多个 FFmpeg SRT 流
- `open_multiple_ffmpeg_udp.sh`: 打开多个 FFmpeg UDP 流
- **concat_audio/**: 音频连接脚本
- **mix_audio/**: 音频混合脚本（支持多文件混合、重采样等）

**Git 模板 (`git_templates/`) - 跨平台**
- `github_common_config.sh`: GitHub 常用配置
- `default_gitignore_files/`: 默认 .gitignore 文件模板

**补丁示例 (`patch_examples/`) - 跨平台**
- `create_patch.sh`: 创建补丁文件
- `use_patch.sh`: 应用补丁文件
- `readme.md`: 详细使用说明

**Shell 脚本编译器 (`shc/`) - 跨平台**
- **shc** 是 "Shell Script Compiler" 的缩写，用于将 Shell 脚本编译为二进制可执行文件
- 通过编译可以保护脚本源代码，防止被查看或修改
- 包含示例脚本和编译后的二进制文件（.sh.x）及生成的 C 源代码（.sh.x.c）
- 使用方法：`shc -f script.sh` 将生成 `script.sh.x` 可执行文件

**Redis 配置编辑 (`auto_edit_redis_config/`) - 跨平台**
- `auto_edit_redis_config.sh`: 自动编辑 Redis 配置

**通用函数库 (`common.sh`)**
- 提供颜色输出、日志记录、错误处理等功能
- 所有脚本可以引用此函数库

## 使用说明

### Git Submodule 说明

本项目使用 Git Submodule 管理部分配置（如 Neovim 配置）。首次克隆项目后需要初始化 submodule：

```bash
# 初始化所有 submodule
git submodule update --init --recursive

# 或只初始化特定 submodule
git submodule update --init dotfiles/nvim
```

克隆项目时同时克隆 submodule：

```bash
git clone --recursive git@github.com:your-username/script_tool_and_config.git
```

更新 submodule：

```bash
# 更新到远程仓库的最新提交
git submodule update --remote dotfiles/nvim
```

### 基本使用

大多数脚本都可以直接运行，但某些脚本可能需要：
1. 执行权限：`chmod +x script_name.sh`
2. 特定环境：某些脚本针对特定操作系统（如 ArchLinux）
3. 依赖工具：确保已安装所需工具（如 ffmpeg、cmake 等）
4. Git Submodule：某些配置需要先初始化 submodule（见上方说明）

### 示例

#### 创建 C/C++ 项目
```bash
cd scripts/linux/project_tools/cpp_project_generator
./generate_project.sh c    # 创建 C 项目
./generate_project.sh cpp  # 创建 C++ 项目
```

#### 配置 ArchLinux 镜像源
```bash
cd scripts/linux/system_basic_env
sudo ./configure_china_mirrors.sh
```

#### 一键安装常用开发工具（ArchLinux）
```bash
cd scripts/linux/system_basic_env

# 标准安装（用户级 Neovim Python 环境，默认启用代理）
sudo ./install_common_tools.sh

# 使用系统级 Neovim Python 环境（root 和所有用户共享）
sudo -E USE_SYSTEM_NVIM_VENV=1 ./install_common_tools.sh

# 完全禁用代理（所有操作都直连）
sudo -E NO_PROXY=1 ./install_common_tools.sh

# 组合使用
sudo -E USE_SYSTEM_NVIM_VENV=1 NO_PROXY=1 ./install_common_tools.sh
```

**安装脚本功能**：
- 自动配置中国镜像源（9个可用镜像）
- 优化 pacman 配置（并行下载、移除废弃配置）
- 安装基础开发工具（git、neovim、tmux、starship 等）
- 安装 AUR 助手（yay）
- 安装 Python 包管理器（uv）
- 安装 Node.js 版本管理器（fnm）
- 配置 Neovim Python 环境（pynvim、pyright、ruff-lsp 等）
- 安装 Nerd Font 字体（FiraMono）
- 安装 Oh My Zsh

**详细说明**：参见 `scripts/linux/system_basic_env/usage.md`

#### 安装和配置工具（使用统一安装脚本）

所有 dotfiles 工具都提供了统一的安装脚本，位于各工具目录下：

**Fish Shell**
```bash
cd dotfiles/fish
chmod +x install.sh
./install.sh
```

**Bash**
```bash
cd dotfiles/bash
chmod +x install.sh
./install.sh
```

**Neovim（使用 Git Submodule）**
```bash
# 1. 首次克隆项目后，初始化 submodule
cd script_tool_and_config
git submodule update --init --recursive

# 2. 安装 Neovim 配置
cd dotfiles/nvim
chmod +x install.sh
./install.sh

# 3. 更新配置（当 submodule 更新后）
git submodule update --remote dotfiles/nvim
cd dotfiles/nvim
./install.sh
```

**IdeaVim（位于 nvim submodule 中）**
```bash
# 1. 确保 nvim submodule 已初始化
cd script_tool_and_config
git submodule update --init dotfiles/nvim

# 2. 安装 IdeaVim 配置
cd dotfiles/nvim/ideavimrc
chmod +x install.sh
./install.sh

# 3. 在 IDE 中安装 IdeaVim 插件
#    - 打开 Settings / Preferences (Windows/Linux: Ctrl+Alt+S, macOS: Cmd+,)
#    - 进入 Plugins
#    - 搜索 "IdeaVim" 并安装
#    - 重启 IDE

# 4. 更新配置（当 submodule 更新后）
git submodule update --remote dotfiles/nvim
cd dotfiles/nvim/ideavimrc
./install.sh
```

**Alacritty 终端（macOS）**
```bash
# 方法 1: 使用 Homebrew（推荐）
brew install --cask alacritty

# 方法 2: 使用安装脚本
cd dotfiles/alacritty
chmod +x install.sh
./install.sh

# 安装后，复制配置文件（注意：使用 TOML 格式）
mkdir -p ~/.config/alacritty
cp alacritty.toml ~/.config/alacritty/
```

**Tmux**
```bash
cd dotfiles/tmux
chmod +x install.sh
./install.sh
```

**dwm (Dynamic Window Manager)**
```bash
cd dotfiles/dwm
chmod +x install.sh
./install.sh
```

安装脚本会自动：
- 检测 Linux 发行版并安装依赖
- 克隆 dwm 源码并编译安装
- 可选安装 st (Simple Terminal)
- 创建 XSession 桌面文件

**注意**: dwm 的配置通过编辑源代码（`config.h`）完成，需要重新编译。详见 `dotfiles/dwm/readme.md`。

**同步配置**

对于支持多系统的工具，可以使用配置同步脚本将配置文件同步到用户目录：

```bash
# Fish Shell（配置同步已集成到 install.sh 中）
cd dotfiles/fish
chmod +x install.sh
./install.sh  # 安装脚本会自动同步配置（包含自动备份）

# Bash（配置同步已集成到 install.sh 中）
cd dotfiles/bash
chmod +x install.sh
./install.sh  # 安装脚本会自动同步配置（包含自动备份）

# Zsh（配置同步已集成到 install.sh 中）
cd dotfiles/zsh
chmod +x install.sh
./install.sh  # 安装脚本会自动同步配置
```

**注意**:
- Alacritty 从 0.13.0 版本开始使用 TOML 格式配置文件（`alacritty.toml`），旧版 YAML 格式（`alacritty.yml`）已不再支持
- 所有安装脚本都会自动检测操作系统并安装对应配置

## 工具配置结构说明

所有 dotfiles 工具遵循统一的结构：

```
工具名/
├── 配置文件              # 工具的主配置文件
├── install.sh            # 自动安装脚本（自动检测系统）
├── config_loader.sh      # 配置加载脚本（多系统工具，自动检测系统）
└── readme.md             # 配置说明和使用指南
```

### 多系统配置工具

对于支持多系统的工具（如 Fish、Bash），使用**统一配置文件**，通过条件判断自动检测系统并加载对应配置：

```
工具名/
├── config.fish 或 config.sh  # 统一配置文件（自动检测系统）
├── completions/             # 补全脚本目录（如适用）
├── install.sh               # 自动安装脚本（自动检测系统，包含配置同步和备份）
└── readme.md                # 配置说明
```

**优势**：
- ✅ 只需维护一个配置文件
- ✅ 自动检测操作系统
- ✅ 条件判断加载平台特定配置
- ✅ 减少配置重复和冗余
- ✅ 结构更简洁清晰

## 文件换行符配置

本项目使用多种配置文件来确保不同操作系统的脚本文件使用正确的换行符：

### 配置文件说明

1. **`.editorconfig`** - 编辑器通用配置
   - 按路径模式设置换行符
   - Windows 脚本（`scripts/windows/**/*.bat`, `*.ps1`）使用 CRLF
   - Linux 脚本（`scripts/linux/**/*.sh`, `scripts/common.sh`）使用 LF
   - 所有 Shell 脚本（`*.sh`）使用 LF

2. **`.gitattributes`** - Git 版本控制配置
   - 确保 Git 仓库中文件使用正确的换行符
   - Windows 脚本在仓库中保持 CRLF
   - Linux 脚本在仓库中保持 LF
   - 防止 Git 自动转换导致的问题

3. **`.vscode/settings.json`** - VS Code/Cursor 编辑器配置
   - 文件类型级别的换行符设置
   - 启用 EditorConfig 支持
   - 自动检测文件编码

### 使用建议

1. **安装 EditorConfig 扩展**（如果使用 VS Code）：
   - 扩展 ID: `EditorConfig.EditorConfig`
   - Cursor 内置支持 EditorConfig

2. **验证配置**：
   - 打开文件后，查看状态栏的换行符显示（LF/CRLF）
   - 保存文件时，编辑器会自动应用配置

3. **修复现有文件**：
   ```bash
   # 在 Linux 系统上修复所有 .sh 文件
   find scripts -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;

   # 或使用 dos2unix（如果已安装）
   find scripts -name "*.sh" -type f -exec dos2unix {} \;
   ```

## 注意事项

1. **统一结构**: 所有工具配置遵循统一的结构，便于管理和使用
2. **自动检测**: 安装脚本和配置加载脚本会自动检测操作系统
3. **权限要求**: 某些脚本需要 root 权限（使用 `sudo`）
4. **平台特定**: 部分脚本仅适用于特定操作系统，请根据实际情况使用
5. **备份**: 修改系统配置文件前，建议先备份原文件
6. **换行符**: 确保使用正确的换行符格式（Windows 脚本用 CRLF，Linux 脚本用 LF）

## 许可证

详见 [LICENSE](LICENSE) 文件

## 更新日志

### 2024-12 项目整理
- ✅ 删除冗余文档（md_files_structure.md）
- ✅ 整合项目结构说明到 README.md
- ✅ 更新文档引用和索引
- ✅ 更新 .gitignore（添加项目特定临时文件）
- ✅ 合并 Windows 和 macOS 安装指南为 OS_SETUP_GUIDE.md
- ✅ 创建 Windows 完整安装脚本（install_with_chezmoi.sh/bat）

### 2024 整理
- ✅ 重新分析整个项目结构
- ✅ 整理重复冗余的代码和配置
- ✅ 将所有注释翻译为中文
- ✅ 重命名拼写错误的文件和目录
- ✅ 根据功能和作用重命名文件和文件夹
- ✅ 添加 Alacritty 终端安装脚本和配置文件
- ✅ 统一工具配置结构（工具名/配置文件/readme.md/install.sh）
- ✅ 为多系统配置工具创建统一配置加载脚本
- ✅ 移动安装脚本到对应工具目录
- ✅ 添加 dwm (Dynamic Window Manager) 配置
- ✅ 按系统分类重组 scripts 目录（windows/、macos/、linux/）
- ✅ 更新 .gitignore（注释翻译为中文，添加项目特定规则）
- ✅ 更新项目文档

### 重命名说明

#### 主要目录重命名
- `env_building_and_config` → `environment_setup` (更简洁明了)
- `point_configs` → `dotfiles` (更标准的命名)
- `script_tools` → `scripts` (更简洁)

#### 子目录重命名
- `auto_create_c_or_c_plus_project` → `cpp_project_generator` (更清晰的功能描述)
- `ffmpeg_scripts` → `media_tools` (更通用的命名)
- `contact_audio` → `concat_audio` (更准确的术语)
- `git_reference` → `git_templates` (更准确的描述)
- `how_to_use_diff_and_patch` → `patch_examples` (更简洁)
- `windows_bat_scripts` → `windows_scripts` (更通用)

#### 文件重命名
- `archlinux_enviroment_auto_install.sh` → `archlinux_environment_auto_install.sh` (修正拼写)
- `clion_cmaketxt_create.sh` → `clion_cmakelists_create.sh` (修正拼写)
- `github_common_confing.sh` → `github_common_config.sh` (修正拼写)
- `SecurtCRTV8_VM_Login_TOP.vbs` → `SecureCRTV8_VM_Login_TOP.vbs` (修正拼写)
- `auto_build_project_struct.sh` → `generate_project.sh` (更简洁)
- `create_new_C_code_file.sh` → `create_c_file.sh` (更简洁)
- `zsh_with_ob_my_zsh_config` → `zsh_with_oh_my_zsh_config` (修正拼写)

## 贡献

欢迎提交 Issue 和 Pull Request！
