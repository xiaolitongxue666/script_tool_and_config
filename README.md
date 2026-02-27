# script_tool_and_config

个人软件配置和常用脚本集合，使用 [chezmoi](https://www.chezmoi.io/) 统一管理 dotfiles。

## ✨ 核心特性

- 🚀 **一键安装所需软件和配置**：执行 `./install.sh` 即可完成 chezmoi 安装、配置应用、run_once 软件安装及验证；**区分不同 OS**（linux/darwin/windows）与 **WSL**（Linux 子类型）。
- 🔄 **智能同步**：配置差异自动检测和应用，软件状态智能管理
- 🎯 **跨平台支持**：Windows、macOS、Linux（Arch/Ubuntu/Debian/WSL、Fedora 等）
- 📦 **模板化管理**：使用 chezmoi 模板系统实现平台特定配置
- 🔧 **自动化安装**：通过 `run_once_` 机制安装通用工具、字体、zsh、Neovim 等，Arch 专属由 run_on_linux 下 run_once 处理
- 🛠️ **工具脚本集合**：跨平台脚本工具，涵盖开发、网络、媒体处理等场景

## 🚀 快速开始

### 方式一：一键安装（推荐）

```bash
# 克隆项目
git clone <repo-url>
cd script_tool_and_config

# 运行一键安装脚本
./install.sh
```

### 方式二：手动安装

```bash
# 1. 安装 chezmoi
bash scripts/chezmoi/install_chezmoi.sh

# 2. 设置源状态目录
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 3. 应用所有配置（首次应用前建议备份 ~/.ssh/config 与 ~/.gitconfig，参见 scripts/common/utils 下 backup_ssh_config.sh、backup_git_config.sh）
chezmoi apply -v
```

### Windows 快速安装

双击 `scripts/windows/install_with_chezmoi.bat`（需要管理员权限）

## 📖 详细文档

| 文档 | 说明 |
|------|------|
| [INSTALL_GUIDE.md](INSTALL_GUIDE.md) | 一键安装与配置入口（推荐先看） |
| [os_setup_guide.md](os_setup_guide.md) | Windows/macOS/Linux 分步安装指南 |
| [chezmoi_use_guide.md](chezmoi_use_guide.md) | chezmoi 详细使用指南 |
| [SOFTWARE_LIST.md](SOFTWARE_LIST.md) | 完整软件清单与 run_once 对应关系 |
| [scripts/linux/system_basic_env/INSTALL_STATUS.md](scripts/linux/system_basic_env/INSTALL_STATUS.md) | 所需软件安装与配置状态清单（验证项与命令） |
| [VERIFICATION_RESULT.md](VERIFICATION_RESULT.md) | 当前环境验证结果摘要；安装后可用 `scripts/chezmoi/verify_installation.sh` 生成报告 |
| [project_structure.md](project_structure.md) | 详细项目结构说明 |
| [AGENTS.md](AGENTS.md) | 代码代理开发指南 |
| [ENCODING_AND_LINE_ENDINGS.md](ENCODING_AND_LINE_ENDINGS.md) | 文件编码与换行符规范 |
| [scripts/common/utils/DEPLOYMENT_GUIDE.md](scripts/common/utils/DEPLOYMENT_GUIDE.md) | 部署流程（Windows/Arch） |
| [scripts/common/utils/SFTP_SYNC_GUIDE.md](scripts/common/utils/SFTP_SYNC_GUIDE.md) | SFTP 与同步指南 |

## 💻 支持的平台

### Windows
- **版本**：Windows 10/11
- **包管理器**：winget（优先）、MSYS2 pacman
- **Shell**：Git Bash、PowerShell

### macOS
- **版本**：macOS 10.15+（Catalina 及以上）
- **包管理器**：Homebrew（必需）
- **架构**：Intel (x86_64) 和 Apple Silicon (arm64)

### Linux
| 发行版 | 包管理器 | 测试状态 |
|--------|----------|----------|
| Arch Linux | pacman | ✅ 已验证 |
| Ubuntu/Debian | apt | ✅ 已验证 |
| CentOS/RHEL | dnf/yum | ✅ 已验证 |
| Fedora | dnf | ⚠️ 理论支持 |

### 代理与 Pacman

- **代理**：`install.sh` 从环境变量 `PROXY` 或 `http_proxy` 读取，并导出为 `http_proxy`/`HTTPS_PROXY` 等；run_once 脚本通过 `env http_proxy` 使用，与 install.sh 一致。使用方式：`./install.sh --proxy http://127.0.0.1:7890` 或 `export PROXY=...`。
- **Pacman（Arch）**：run_on_linux 的 pacman/镜像配置**不使用**代理，直连国内源；其他下载（GitHub、官方安装脚本等）使用上述环境变量代理。

## 📁 项目结构

```
script_tool_and_config/
├── .chezmoi/                       # chezmoi 配置源目录
│   ├── dot_*                       # 通用配置文件（模板格式）
│   ├── dot_config/                 # ~/.config 目录下的配置
│   ├── run_once_install-*.sh.tmpl  # 自动安装脚本（仅首次执行）
│   ├── run_on_linux/               # Linux 特定配置
│   ├── run_on_darwin/              # macOS 特定配置
│   └── run_on_windows/             # Windows 特定配置
│
├── scripts/                        # 脚本工具集合
│   ├── common.sh                    # 通用函数库
│   ├── manage_dotfiles.sh           # dotfiles 管理脚本
│   ├── chezmoi/                     # chezmoi 相关脚本
│   ├── common/                      # 跨平台脚本
│   ├── linux/                      # Linux 专用脚本
│   ├── macos/                      # macOS 专用脚本
│   └── windows/                    # Windows 专用脚本
│
├── dotfiles/                       # 点文件目录（Neovim 由 run_once 克隆到 ~/.config/nvim，不在此仓库）
│
├── install.sh                      # 一键安装脚本
├── README.md                       # 本文件
├── AGENTS.md                       # 代码代理开发指南
├── chezmoi_use_guide.md           # chezmoi 使用指南
├── SOFTWARE_LIST.md                # 软件清单
└── project_structure.md            # 项目结构说明
```

详细结构见 [project_structure.md](project_structure.md)。

## 🔧 常用命令

### 使用项目管理脚本

```bash
# 应用所有配置
./scripts/manage_dotfiles.sh apply

# 查看配置差异
./scripts/manage_dotfiles.sh diff

# 查看配置状态
./scripts/manage_dotfiles.sh status

# 编辑配置文件
./scripts/manage_dotfiles.sh edit ~/.zshrc
```

### 使用 chezmoi 命令

```bash
# 应用所有配置
chezmoi apply -v

# 查看配置差异
chezmoi diff

# 编辑配置文件
chezmoi edit ~/.zshrc

# 添加新配置文件
chezmoi add ~/.new_config
```

## 📦 主要软件清单

### 版本管理器
- **fnm** - Node.js 版本管理
- **uv** - Python 包管理器
- **rustup** - Rust 工具链

### 终端工具
- **starship** - 跨 shell 提示符
- **tmux** - 终端复用器
- **alacritty** - GPU 加速终端模拟器

### 文件工具
- **bat** - cat 替代工具（语法高亮）
- **eza** - ls 替代工具
- **fd** - find 替代工具
- **ripgrep** - grep 替代工具
- **fzf** - 模糊查找工具

### 开发工具
- **neovim** - 现代文本编辑器
- **git** - 版本控制系统
- **lazygit** - Git TUI 工具
- **gh** - GitHub CLI

详细软件清单请参考：[SOFTWARE_LIST.md](SOFTWARE_LIST.md)

## 🎯 主要功能分类

### 1. 环境配置管理
通过 chezmoi 统一管理所有配置文件，支持：
- Shell 配置（Bash、Zsh、Fish）
- 终端配置（Tmux、Alacritty）
- 窗口管理器（i3wm、dwm、Yabai）
- 开发工具配置（Neovim、Git）

### 2. 软件自动安装
通过 `run_once_` 脚本自动安装常用软件：
- 自动检测操作系统和包管理器
- 智能跳过已安装软件
- 支持代理配置
- 详细的安装日志

### 3. 脚本工具集合
按平台分类的实用脚本：

**跨平台脚本**（`scripts/common/`）
- **utils/**: 通用工具脚本
- **project_tools/**: 项目生成和管理工具
- **media_tools/**: 媒体处理工具
- **git_templates/**: Git 模板和配置

**Linux 专用脚本**（`scripts/linux/`）
- **system_basic_env/**: 系统基础环境安装
- **network/**: 网络配置脚本
- **hardware/**: 硬件安装脚本

**Windows 专用脚本**（`scripts/windows/`）
- **windows_scripts/**: Windows 批处理脚本

### 4. Neovim 配置
Neovim 配置由 run_once_install-neovim-config 克隆到 `~/.config/nvim` 并执行其 install.sh；上游仓库 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim)。配置基于 Lua、lazy.nvim、LSP 等。若上游 install.sh 需与 run_once 协作（同源跳过、uv/fnm 按需安装等），见 [docs/NEOVIM_INSTALL_REQUIREMENTS.md](docs/NEOVIM_INSTALL_REQUIREMENTS.md)。

## 📚 使用指南

### 配置文件管理

所有配置通过 chezmoi 管理，工作流程：

```bash
# 1. 编辑配置文件
chezmoi edit ~/.zshrc

# 2. 查看变更
chezmoi diff ~/.zshrc

# 3. 应用配置
chezmoi apply ~/.zshrc

# 4. 提交到仓库
git add .chezmoi
git commit -m "Update zsh config"
git push
```

本项目提供的 `~/.zshrc` 已关闭 zsh 拼写纠错（`correct`/`correct_all`），输错命令不会出现 `[nyae]?` 提示，可直接重新输入。

### 智能安装机制

`install.sh` 脚本提供智能功能：

- **配置对比机制**：自动检测模板生成的配置与本地配置是否一致
- **软件安装检查**：已安装的软件跳过，未安装的软件自动安装
- **详细日志输出**：显示每个步骤的详细状态和进度

### Git Submodule 管理

Neovim 配置使用 Git Submodule 管理：

```bash
# 更新 Neovim 配置（配置位于 ~/.config/nvim）
cd ~/.config/nvim && git pull && ./install.sh
```

## 🛡️ 安全和规范

### 文件编码和换行符
- **编码**：UTF-8（无 BOM）
- **换行符**：LF（`\n`），Windows 脚本（`.bat`, `.ps1`, `.cmd`）使用 CRLF
- **配置文件**：已配置 `.gitattributes`、`.editorconfig` 和 `.vscode/settings.json`

### 检查和修复工具

```bash
# 检查所有文件的编码和换行符
./scripts/common/utils/check_and_fix_encoding.sh

# 规范化换行符为 LF
./scripts/common/utils/ensure_lf_line_endings.sh
```

详细说明请参考：[ENCODING_AND_LINE_ENDINGS.md](ENCODING_AND_LINE_ENDINGS.md)

## ⚠️ 注意事项

1. **权限要求**：某些脚本需要 root 权限（使用 `sudo`）
2. **平台特定**：部分脚本仅适用于特定操作系统
3. **备份**：修改系统配置文件前，建议先备份原文件
4. **Neovim 配置**：由 run_once_install-neovim-config 自动克隆到 ~/.config/nvim 并执行 install.sh
5. **代理配置**：安装脚本支持通过 `PROXY` 环境变量配置代理

## 🔗 相关链接

- [chezmoi 官方文档](https://www.chezmoi.io/docs/)
- [Neovim 官方文档](https://neovim.io/doc/)
- [AGENTS.md](AGENTS.md) - 代码代理开发指南
- [部署流程指南](scripts/common/utils/DEPLOYMENT_GUIDE.md) - Windows 和 Arch Linux 之间的配置部署流程

## 📝 更新日志

### 2025-01 项目梳理优化
- ✅ 优化打印信息内容：统一所有脚本使用 log_info/log_success/log_warning/log_error 函数
- ✅ 删除无用文件：清理临时日志文件和测试文件
- ✅ 更新 .gitignore：确保所有临时文件、日志文件、备份文件都被忽略
- ✅ 更新文档：确保 README.md、project_structure.md 等文档与代码实现一致

### 2024-12 项目重构
- ✅ 统一配置管理：所有配置文件转换为 Chezmoi 模板格式
- ✅ 创建配置审计脚本：`scripts/chezmoi/audit_configs.sh`
- ✅ 创建统一配置管理脚本：`scripts/chezmoi/manage_configs.sh`
- ✅ 改进 `install.sh`：集成新的配置管理机制
- ✅ 清理冗余文件：删除已转换为模板格式的原配置文件

## 📄 许可证

详见 [LICENSE](LICENSE) 文件
