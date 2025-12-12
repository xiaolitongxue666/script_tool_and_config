# 平台支持说明

本项目支持以下操作系统和发行版：

## 支持的操作系统

### Windows
- **支持版本**: Windows 10/11
- **包管理器**:
  - `winget` (Windows Package Manager) - 优先使用
  - `pacman` (MSYS2) - 备选
- **Shell 环境**: Git Bash, MSYS2
- **特殊说明**:
  - 需要创建 `~/.local/share/chezmoi` 目录（脚本会自动处理）
  - 支持通过 MSYS2 安装 Unix 工具

### macOS
- **支持版本**: macOS 10.15+ (Catalina 及以上)
- **包管理器**: `brew` (Homebrew) - 必需
- **架构支持**: Intel (x86_64) 和 Apple Silicon (arm64)
- **特殊说明**:
  - 需要先安装 Homebrew
  - Apple Silicon Mac 使用 `/opt/homebrew`，Intel Mac 使用 `/usr/local`

### Linux

#### ArchLinux
- **包管理器**: `pacman`
- **支持版本**: 最新稳定版
- **特殊脚本**:
  - `scripts/linux/system_basic_env/install_common_tools.sh` - 仅支持 ArchLinux
  - `scripts/linux/system_basic_env/configure_china_mirrors.sh` - 配置中国镜像源

#### Ubuntu/Debian
- **包管理器**: `apt` (apt-get)
- **支持版本**:
  - Ubuntu 18.04+ (LTS 和最新版)
  - Debian 10+ (Buster 及以上)
- **特殊说明**: 使用 `apt-get` 命令

#### CentOS/RHEL
- **包管理器**:
  - `dnf` (CentOS 8+, RHEL 8+, Fedora) - 优先使用
  - `yum` (CentOS 7-, RHEL 7-) - 旧版本
- **支持版本**:
  - CentOS 7 (使用 yum)
  - CentOS 8+ (使用 dnf)
  - RHEL 7 (使用 yum)
  - RHEL 8+ (使用 dnf)
  - Fedora (使用 dnf)

## 包管理器检测顺序

### Linux
1. `pacman` (ArchLinux)
2. `apt-get` (Ubuntu/Debian)
3. `dnf` (CentOS 8+/RHEL 8+/Fedora)
4. `yum` (CentOS 7-/RHEL 7-)

### Windows
1. `winget` (Windows Package Manager)
2. `pacman.exe` (MSYS2)

### macOS
1. `brew` (Homebrew) - 必需

## 平台特定功能

### Windows
- Git Bash 配置 (`~/.bash_profile`, `~/.bashrc`)
- MSYS2 支持
- Zsh 通过 MSYS2 安装

### macOS
- Yabai 窗口管理器配置
- skhd 快捷键配置
- Homebrew 集成

### Linux
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

## 配置文件位置

### 通用配置
- Shell 配置: `~/.zshrc`, `~/.bashrc`, `~/.config/fish/config.fish`
- Tmux: `~/.tmux.conf`
- Starship: `~/.config/starship/starship.toml`
- Alacritty: `~/.config/alacritty/alacritty.toml`

### 平台特定配置
- **Linux**: `~/.config/i3/config` (i3wm)
- **macOS**: `~/.yabairc`, `~/.skhdrc`
- **Windows**: `~/.bash_profile`, `~/.bashrc` (Git Bash)

## 安装脚本支持

### 通用安装脚本 (run_once_)
- `run_once_install-zsh.sh` - Zsh 和 Oh My Zsh
- `run_once_install-fish.sh` - Fish Shell
- `run_once_install-tmux.sh` - Tmux
- `run_once_install-starship.sh` - Starship
- `run_once_install-alacritty.sh` - Alacritty

### 平台特定安装脚本
- **Linux**:
  - `run_on_linux/run_once_install-i3wm.sh`
  - `run_on_linux/run_once_install-dwm.sh`
- **macOS**:
  - `run_on_darwin/run_once_install-yabai.sh`
  - `run_on_darwin/run_once_install-skhd.sh`
- **Windows**:
  - `run_on_windows/run_once_install-zsh.sh`

## 测试状态

### 已验证平台
- ✅ Windows 10/11 (Git Bash)
- ✅ macOS (Intel 和 Apple Silicon)
- ✅ ArchLinux
- ✅ Ubuntu 20.04/22.04
- ✅ CentOS 7 (yum)
- ✅ CentOS 8+ (dnf)

### 部分支持
- ⚠️ Debian (理论上支持，未充分测试)
- ⚠️ RHEL (理论上支持，未充分测试)
- ⚠️ Fedora (理论上支持，未充分测试)

## 已知限制

1. **ArchLinux 特定脚本**: `install_common_tools.sh` 仅支持 ArchLinux，其他发行版会报错
2. **Windows 路径**: 某些脚本在 Windows 上可能需要路径转换
3. **权限要求**: Linux 安装脚本需要 sudo 权限
4. **网络要求**: 首次安装需要网络连接（下载软件包）

## 故障排除

### Windows
- 如果遇到 "找不到状态目录" 错误，运行 `./scripts/manage_dotfiles.sh apply` 会自动创建
- 确保 Git Bash 或 MSYS2 已正确安装

### macOS
- 确保 Homebrew 已安装：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Apple Silicon Mac 需要将 Homebrew 路径添加到 PATH

### Linux
- 确保有 sudo 权限
- CentOS/RHEL 8+ 确保使用 dnf 而不是 yum
- ArchLinux 特定脚本需要先确认系统是 ArchLinux

## 贡献

如果发现某个平台的支持有问题，请：
1. 检查包管理器是否正确检测
2. 查看相关脚本的日志输出
3. 提交 Issue 并附上系统信息和错误日志
