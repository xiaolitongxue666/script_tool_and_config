# 软件清单

本文档列出了项目中管理的所有软件，按平台分类。

## 多系统共有软件

### 版本管理器

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **fnm** | Fast Node Manager (Node.js 版本管理) | `run_once_install-version-managers.sh.tmpl` |
| **uv** | Python 包管理器 | `run_once_install-version-managers.sh.tmpl` |
| **rustup** | Rust 工具链（可选） | `run_once_install-version-managers.sh.tmpl` |

### 终端工具

| 软件 | 描述 | 支持平台 | 安装脚本 |
|------|------|----------|----------|
| **starship** | 跨 shell 提示符 | Linux, macOS, Windows | `run_once_install-starship.sh.tmpl` |
| **tmux** | 终端复用器 | Linux, macOS | `run_once_install-tmux.sh.tmpl` |
| **TPM** | Tmux Plugin Manager（tmux 插件管理器） | Linux, macOS | `run_once_install-tmux.sh.tmpl` |
| **alacritty** | GPU 加速终端模拟器 | Linux, macOS | `run_once_install-alacritty.sh.tmpl` |

### 文件工具

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **bat** | cat 替代工具（语法高亮） | `run_once_install-common-tools.sh.tmpl` |
| **eza** | ls 替代工具 | `run_once_install-common-tools.sh.tmpl` |
| **fd** | find 替代工具（快速文件查找） | `run_once_install-common-tools.sh.tmpl` |
| **ripgrep (rg)** | grep 替代工具（快速文本搜索） | `run_once_install-common-tools.sh.tmpl` |
| **fzf** | 模糊查找工具 | `run_once_install-common-tools.sh.tmpl` |
| **trash-cli** | 命令行回收站工具 | `run_once_install-common-tools.sh.tmpl` (Linux/macOS) |

### 开发工具

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **git** | 版本控制系统 | `run_once_install-git.sh.tmpl` |
| **neovim** | 现代文本编辑器 | `run_once_install-neovim.sh.tmpl` |
| **lazygit** | Git TUI 工具 | `run_once_install-common-tools.sh.tmpl` |
| **git-delta** | Git diff 增强工具 | `run_once_install-common-tools.sh.tmpl` |
| **gh** | GitHub CLI | `run_once_install-common-tools.sh.tmpl` |
| **lazyssh** | 终端 SSH 管理器 | `install_common_tools.sh` (macOS/Linux) |

### 系统工具

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **curl** | 网络传输工具 | 系统自带或包管理器 |
| **wget** | 文件下载工具 | 系统自带或包管理器 |
| **aria2** | 多线程下载工具 | 系统自带或包管理器 |
| **tree** | 目录树显示工具 | 系统自带或包管理器 |
| **which** | 查找命令位置工具 | 系统自带或包管理器 |

### 字体

| 软件 | 描述 | 支持平台 | 安装脚本 |
|------|------|----------|----------|
| **Nerd Fonts (FiraMono)** | 编程字体（支持图标显示） | Linux, macOS, Windows | `run_once_install-nerd-fonts.sh.tmpl` |

## Linux 特有软件

### Shell 环境

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **zsh** | Z shell | `run_once_install-zsh.sh.tmpl` |
| **oh-my-zsh** | Zsh 配置框架 | `run_once_install-zsh.sh.tmpl` |
| **fish** | Fish Shell | `run_once_install-fish.sh.tmpl` |

### 窗口管理器

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **i3wm** | 平铺式窗口管理器 | `run_once_install-i3wm.sh.tmpl` |
| **dwm** | 动态窗口管理器 | `run_once_install-dwm.sh.tmpl` |

### 系统监控工具

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **btop** | 系统监控工具（htop 替代） | `run_once_install-common-tools.sh.tmpl` |
| **fastfetch** | 系统信息展示工具 | `run_once_install-common-tools.sh.tmpl` |

## macOS 特有软件

### Shell 环境

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **zsh** | Z shell（macOS 默认） | `run_once_install-zsh.sh.tmpl` |
| **oh-my-zsh** | Zsh 配置框架 | `run_once_install-zsh.sh.tmpl` |
| **fish** | Fish Shell | `run_once_install-fish.sh.tmpl` |

### 窗口管理器

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **yabai** | 平铺式窗口管理器 | `run_once_install-yabai.sh.tmpl` |
| **skhd** | 快捷键守护进程 | `run_once_install-skhd.sh.tmpl` |

### 系统监控工具

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **btop** | 系统监控工具（htop 替代） | `run_once_install-common-tools.sh.tmpl` |
| **fastfetch** | 系统信息展示工具 | `run_once_install-common-tools.sh.tmpl` |

## Windows 特有软件

### Shell 环境

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **zsh** | Z shell（通过 MSYS2，可选） | `run_once_install-zsh.sh.tmpl` |
| **oh-my-posh** | PowerShell 提示符工具 | `run_once_install-oh-my-posh.sh.tmpl` |

### 系统监控工具

| 软件 | 描述 | 安装脚本 |
|------|------|----------|
| **bottom** | 系统监控工具（btop 的 Windows 替代） | `run_once_install-common-tools.sh.tmpl` |

## 配置文件

### 通用配置

| 配置文件 | 目标位置 | 源文件 |
|----------|----------|--------|
| **Bash 配置** | `~/.bashrc` | `.chezmoi/dot_bashrc.tmpl` |
| **Zsh 配置** | `~/.zshrc` | `.chezmoi/dot_zshrc` |
| **Zsh Profile** | `~/.zprofile` | `.chezmoi/dot_zprofile` |
| **Tmux 配置** | `~/.tmux.conf` | `.chezmoi/dot_tmux.conf` |
| **Starship 配置** | `~/.config/starship/starship.toml` | `.chezmoi/dot_config/starship/starship.toml` |

#### Tmux 插件（通过 TPM 管理）

所有 tmux 插件通过 TPM (Tmux Plugin Manager) 管理，配置在 `~/.tmux.conf` 中声明。

| 插件 | 描述 | 基本用法 |
|------|------|----------|
| **tmux-plugins/tpm** | TPM 插件管理器本身 | 必须第一个安装 |
| **tmux-plugins/tmux-sensible** | 基础 tmux 设置，提供合理的默认配置 | 安装后自动生效 |
| **catppuccin/tmux** | Catppuccin Mocha 主题 | 通过 `@catppuccin_flavor` 配置 |
| **tmux-plugins/tmux-yank** | 改进复制粘贴功能，支持系统剪贴板集成 | 复制模式中按 `y` 复制到剪贴板 |
| **tmux-plugins/tmux-resurrect** | 保存和恢复 tmux 会话状态 | `prefix + Ctrl-s` 保存，`prefix + Ctrl-r` 恢复 |
| **tmux-plugins/tmux-continuum** | 自动保存和恢复会话 | 自动定期保存，tmux 启动时自动恢复 |

**插件管理快捷键**：
- 安装插件：`prefix + I`（大写 I）
- 更新插件：`prefix + U`（大写 U）
- 卸载插件：`prefix + alt + u`（小写 u）
| **Alacritty 配置** | `~/.config/alacritty/alacritty.toml` | `.chezmoi/dot_config/alacritty/alacritty.toml` |
| **Fish 配置** | `~/.config/fish/config.fish` | `.chezmoi/dot_config/fish/config.fish` |
| **SSH 配置** | `~/.ssh/config` | `.chezmoi/dot_ssh/config` |

### Linux 特定配置

| 配置文件 | 目标位置 | 源文件 |
|----------|----------|--------|
| **i3wm 配置** | `~/.config/i3/config` | `.chezmoi/run_on_linux/dot_config/i3/config` |

### macOS 特定配置

| 配置文件 | 目标位置 | 源文件 |
|----------|----------|--------|
| **Yabai 配置** | `~/.yabairc` | `.chezmoi/run_on_darwin/dot_yabairc` |
| **skhd 配置** | `~/.skhdrc` | `.chezmoi/run_on_darwin/dot_skhdrc` |

### Windows 特定配置

| 配置文件 | 目标位置 | 源文件 |
|----------|----------|--------|
| **Git Bash Profile** | `~/.bash_profile` | `.chezmoi/run_on_windows/dot_bash_profile` |
| **Git Bash RC** | `~/.bashrc` | `.chezmoi/run_on_windows/dot_bashrc` |

## 安装方式说明

### 使用 chezmoi 自动安装

所有软件通过 chezmoi 的 `run_once_` 脚本机制自动安装。首次运行 `chezmoi apply` 时，这些脚本会自动执行。

```bash
# 应用所有配置（包括安装脚本）
chezmoi apply -v
```

### 手动安装

如果需要手动安装某个软件，可以：

1. **查看安装脚本**：
   ```bash
   chezmoi cat .chezmoi/run_once_install-[tool].sh.tmpl
   ```

2. **直接运行脚本**（不推荐，因为脚本可能依赖 chezmoi 环境）：
   ```bash
   bash .chezmoi/run_once_install-[tool].sh.tmpl
   ```

3. **使用包管理器**：
   - Linux: `pacman -S`, `apt-get install`, `dnf install`
   - macOS: `brew install`
   - Windows: `winget install`

## 包管理器映射

### Linux

| 发行版 | 包管理器 | 示例命令 |
|--------|----------|----------|
| Arch Linux | pacman | `sudo pacman -S package` |
| Ubuntu/Debian | apt | `sudo apt-get install package` |
| Fedora/CentOS/RHEL | dnf/yum | `sudo dnf install package` |

### macOS

| 包管理器 | 示例命令 |
|----------|----------|
| Homebrew | `brew install package` |

### Windows

| 包管理器 | 示例命令 |
|----------|----------|
| winget | `winget install --id=package.id` |
| MSYS2 pacman | `pacman.exe -S package` |

## SSH 配置管理

### lazyssh

**lazyssh** 是一个终端 SSH 管理器，可以方便地管理 SSH 配置：

- **功能**：查看、添加、编辑、删除 SSH 服务器配置
- **安装**：通过 `install_common_tools.sh` 脚本自动安装（macOS/Linux）
- **使用**：运行 `lazyssh` 启动交互式界面
- **配置同步**：修改后使用 `chezmoi re-add ~/.ssh/config` 同步到 chezmoi

### SSH 配置文件管理

SSH 配置文件（`~/.ssh/config`）已纳入 chezmoi 管理：

- **源文件**：`.chezmoi/dot_ssh/config`
- **目标位置**：`~/.ssh/config`
- **权限**：自动设置为 600
- **备份**：使用 `scripts/common/utils/backup_ssh_config.sh` 备份
- **部署**：使用 `scripts/common/utils/setup_ssh_config.sh` 部署

**首次纳入管理：**
```bash
# 1. 备份现有配置
./scripts/common/utils/backup_ssh_config.sh

# 2. 纳入 chezmoi 管理
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi add ~/.ssh/config

# 3. 应用配置
chezmoi apply ~/.ssh/config
chmod 600 ~/.ssh/config
```

**安全注意事项：**
- SSH 配置文件不包含私钥，相对安全
- 私钥文件（`id_*`）已在 `.gitignore` 和 `.chezmoiignore` 中排除
- 保持仓库私有，不要公开包含 SSH 配置的仓库

详细说明请参考：[chezmoi_use_guide.md](chezmoi_use_guide.md#ssh-配置管理)

## 注意事项

1. **首次安装**：所有 `run_once_` 脚本只会在首次 `chezmoi apply` 时执行一次
2. **代理配置**：安装脚本支持通过环境变量 `PROXY` 配置代理
3. **平台检测**：脚本会自动检测操作系统和包管理器
4. **错误处理**：如果某个软件安装失败，脚本会继续安装其他软件
5. **已安装检查**：脚本会检查软件是否已安装，避免重复安装
6. **SSH 配置**：SSH 配置文件通过 chezmoi 管理，私钥文件不会被纳入管理

## 更新日志

- 2024-12-XX: 初始版本，整理所有软件清单
