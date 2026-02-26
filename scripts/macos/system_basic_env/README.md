# macOS 基础工具安装脚本

本目录为 macOS 专用安装脚本。一键安装与跨平台流程见项目根目录 [INSTALL_GUIDE.md](../../../INSTALL_GUIDE.md)。

用于在 macOS 系统上自动安装基础开发工具的 Bash 脚本。

## 功能特性

- 使用 **Homebrew** 作为包管理器
- 自动检测并安装 Homebrew（如果未安装）
- 自动检测已安装工具和字体，避免重复安装
- 支持代理配置（默认 `http://127.0.0.1:7890`）
- 详细的安装进度和日志记录
- **PATH 环境变量管理**：自动记录 PATH 配置
- **PATH 备份功能**：在修改 PATH 前自动备份

## 工具列表

### Homebrew 公式工具

#### 基础工具
- **git** - 版本控制系统
- **curl** - 网络传输工具
- **wget** - 文件下载工具
- **aria2** - 多线程下载工具
- **tmux** - 终端复用工具
- **starship** - 跨 shell 提示符
- **gh** - GitHub CLI
- **lazygit** - Git TUI 工具
- **git-delta** - Git diff 增强工具

#### 文件查找和搜索工具
- **fzf** - 模糊查找工具
- **ripgrep (rg)** - 快速文本搜索工具
- **fd** - find 替代工具（快速文件查找）
- **bat** - cat 替代工具（语法高亮）
- **eza** - ls 替代工具
- **trash-cli** - 命令行回收站工具

#### 系统监控工具
- **fastfetch** - 系统信息展示工具
- **btop** - 系统监控工具（htop 替代）

#### 开发工具
- **neovim** - 现代文本编辑器
- **gcc** - GNU 编译器集合
- **make** - 构建自动化工具
- **cmake** - 跨平台构建系统
- **ctags** - 代码索引工具
- **tree** - 目录树显示工具
- **openssh** - SSH 客户端和服务器
- **file** - 文件类型识别工具
- **unzip** - ZIP 解压工具
- **zip** - ZIP 压缩工具
- **which** - 查找命令位置工具

### 编程语言工具

- **uv** - Python 包管理器（优先通过 Homebrew 安装，失败则使用官方脚本）
- **fnm** - Node.js 版本管理器（优先通过 Homebrew 安装，失败则使用官方脚本）

### Shell 工具

- **zsh** - Z shell（macOS 默认 shell）
- **oh-my-zsh** - Zsh 配置框架

### 字体

- **FiraMono Nerd Font** - 编程字体（支持图标，通过 Homebrew Cask 安装）

### GUI 应用（Homebrew Cask）

- **Maccy** - 轻量级剪贴板管理器（通过 Homebrew Cask 安装）
  - 快捷键：`Shift+Command+C` 打开
  - 功能：保存剪贴板历史，快速搜索和粘贴
  - 官网：https://maccy.app

## 使用方法

### 基本用法

```bash
# 直接运行（不需要 root 权限）
./install_common_tools.sh
```

### 使用代理

脚本默认使用代理 `http://127.0.0.1:7890`。如果需要自定义代理地址，可以通过环境变量设置：

```bash
# 使用自定义代理地址
HTTP_PROXY=http://your-proxy:port ./install_common_tools.sh

# 或同时设置 HTTP 和 HTTPS 代理
HTTP_PROXY=http://your-proxy:port HTTPS_PROXY=http://your-proxy:port ./install_common_tools.sh
```

### 禁用代理

如果需要禁用代理，可以设置空值：

```bash
HTTP_PROXY= HTTPS_PROXY= ./install_common_tools.sh
```

## 环境变量说明

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `HTTP_PROXY` | HTTP 代理地址 | `http://127.0.0.1:7890` |
| `HTTPS_PROXY` | HTTPS 代理地址 | `http://127.0.0.1:7890` |
| `DEFAULT_PROXY_URL` | 默认代理地址 | `http://127.0.0.1:7890` |

## 安装流程

1. **系统检查**
   - 检查是否为 macOS 系统
   - 检查 Homebrew 是否安装，未安装则自动安装

2. **环境准备**
   - 创建日志、状态、配置目录
   - 配置代理（默认 `http://127.0.0.1:7890`）
   - 备份 PATH 环境变量

3. **更新 Homebrew**
   - 执行 `brew update`（使用代理）

4. **安装工具（自动跳过已安装）**
   - 安装 Homebrew 公式工具（检查 `brew list`）
   - 安装 Homebrew Cask 工具（检查 `brew list --cask`）
   - 安装编程工具（uv, fnm，检查 `command -v`）
   - 安装字体（检查字体文件是否存在）
   - 安装 Shell 工具（zsh, oh-my-zsh）

5. **Neovim 配置**
   - 调用 `dotfiles/nvim/install.sh`（如果存在）

6. **完成**
   - 打印安装摘要
   - 显示 PATH 配置说明

## 已安装检查逻辑

脚本会自动检查并跳过已安装的工具和字体：

- **Homebrew 包**：使用 `brew list <package>` 检查
- **Homebrew Cask 包**：使用 `brew list --cask <package>` 检查
- **命令**：使用 `command -v <command>` 检查
- **字体**：检查 `/Library/Fonts/` 和 `~/Library/Fonts/` 中是否存在字体文件

已安装的工具会显示日志并跳过，未安装的工具会继续安装。

## 日志和状态

- **日志目录**：`logs/system_basic_env/`
- **状态目录**：`~/.local/share/system_basic_env/`
- **配置目录**：`~/.config/system_basic_env/`
- **PATH 配置文件**：`~/.config/system_basic_env/path.env`

所有操作都会记录到带时间戳的日志文件中。

## PATH 环境变量管理

脚本会自动记录 PATH 配置到 `~/.config/system_basic_env/path.env` 文件。建议在 `~/.zprofile` 中加载此文件：

```bash
# 在 ~/.zprofile 中添加
if [ -f ~/.config/system_basic_env/path.env ]; then
    source ~/.config/system_basic_env/path.env
fi
```

这样可以确保所有登录方式（本地登录、SSH 登录）都能正确加载环境变量。

## 故障排除

### Homebrew 安装失败

如果 Homebrew 安装失败，可以手动安装：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

然后重新运行脚本。

### 代理连接失败

如果代理连接失败，脚本会显示警告但继续执行。可以：

1. 检查代理服务是否运行
2. 检查代理地址和端口是否正确
3. 尝试禁用代理使用直连

### 工具安装失败

如果某个工具安装失败，脚本会显示警告但继续执行其他工具的安装。可以：

1. 查看日志文件了解详细错误信息
2. 手动安装失败的工具：`brew install <package>`
3. 检查网络连接和代理设置

### 字体未显示

如果安装的字体未显示：

1. 检查字体文件是否存在：
   ```bash
   ls ~/Library/Fonts/ | grep -i fira
   ```

2. 重启终端应用或系统

3. 在终端设置中选择 FiraMono Nerd Font

## 注意事项

1. **不需要 root 权限**：Homebrew 安装在用户目录下，不需要 sudo
2. **自动跳过已安装**：脚本会自动检测并跳过已安装的工具和字体
3. **代理配置**：默认使用 `http://127.0.0.1:7890`，可通过环境变量覆盖
4. **PATH 管理**：建议在 `~/.zprofile` 中加载 PATH 配置文件

## 相关脚本

- `scripts/linux/system_basic_env/install_common_tools.sh` - Linux 版本
- `scripts/windows/system_basic_env/install_common_tools.ps1` - Windows 版本

