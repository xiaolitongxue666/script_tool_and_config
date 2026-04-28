# 项目结构

本文档为项目目录结构的权威来源，其他文档中的结构描述均以此为准。

## 项目定位

本项目包含两大组成部分：

| 组成部分 | 目录 | 说明 | 处理原则 |
|---------|------|------|---------|
| **独立工具脚本** | `scripts/common/standalone_tool_script/`、`project_tools/`、`ffmpeg-magic/`、`git_templates/`、`shc/`、`patch_examples/`、`auto_edit_redis_config/` | 通用独立工具，可脱离项目单独使用 | **永不删除** |
| **多系统部署配置** | `install.sh`、`deploy.sh`、`scripts/chezmoi/`、`scripts/common/deploy_utils/`、`.chezmoi/` | 通过脚本 + chezmoi 安装软件和部署配置 | 删除仅限废弃项 |

使用场景：在全新 OS 上，通过脚本安装该 OS 所需工具软件，用 chezmoi 模板生成配置文件并部署到正确位置。

```
script_tool_and_config/
├── .editorconfig                    # 编辑器配置
├── .gitattributes                   # Git 换行符规则
├── .gitignore                       # Git 忽略规则
├── .chezmoi/                        # chezmoi 源状态目录（配置模板）
│   ├── chezmoi.toml                 # chezmoi source repo 配置
│   ├── .chezmoidata.toml            # 静态默认数据
│   ├── dot_*.tmpl                   # 跨平台配置模板
│   ├── dot_config/                  # ~/.config/ 配置模板
│   ├── run_once_00-*.sh.tmpl        # 优先安装脚本（版本管理器等，字母序最先执行）
│   ├── run_once_install-*.sh.tmpl   # 一次性安装脚本模板
│   ├── run_sync_*.sh.tmpl           # 同步脚本（如 Windows Terminal、Ghostty 配置同步）
│   ├── run_on_linux/                # Linux 特定配置（含 run_once_*、dot_config/）
│   ├── run_on_darwin/               # macOS 特定配置（含 run_once_*、dot_config/）
│   └── run_on_windows/              # Windows 特定配置（含 run_once_*、dot_config/）
│
├── .chezmoi.toml                    # chezmoi 用户级配置参考（实际运行时由 install.sh 覆盖写入 ~/.config/chezmoi/chezmoi.toml）
├── .chezmoiignore                   # chezmoi 忽略规则
├── .vscode/                         # VS Code 配置
│   └── settings.json
├── .opencode/                       # OpenCode 插件配置（openspec 命令）
├── LICENSE                           # 许可证 (MIT)
│
├── install.sh                        # 一键安装入口
├── deploy.sh                         # 快速部署入口
├── manage_dotfiles.sh               # (在 scripts/ 下) dotfiles 管理入口
│
├── README.md                         # 项目主文档
├── AGENTS.md                         # 代理/编码规范
├── docs/                             # 文档目录
│   ├── PROJECT_STRUCTURE.md          # 项目结构说明（本文件）
│   ├── SOFTWARE_LIST.md              # 软件清单
│   ├── ENCODING_AND_LINE_ENDINGS.md  # 编码和换行符规范
│   ├── CHEZMOI_USE_GUIDE.md          # chezmoi 使用指南
│   ├── OS_SETUP_GUIDE.md             # 操作系统设置指南
│   ├── INSTALL_GUIDE.md              # 一键安装与首次配置入口
│   ├── TEST_PLAN_NVIM_INDEPENDENT.md # Neovim 独立化测试计划
│   └── ...
│
├── scripts/                          # 脚本工具集合
│   ├── common.sh                     # 通用函数库（颜色、日志、错误处理）
│   ├── manage_dotfiles.sh           # dotfiles 管理脚本
│   ├── README.md                     # scripts 目录说明
│   │
│   ├── chezmoi/                      # chezmoi 安装与管理脚本
│   │   ├── README.md                 # chezmoi 脚本说明
│   │   ├── install_chezmoi.sh       # 安装 chezmoi 工具
│   │   ├── common_install.sh        # 通用安装函数库（OS检测、包管理器、代理）
│   │   ├── install_helpers.sh       # 安装辅助函数（软件状态检查）
│   │   ├── audit_configs.sh         # 配置审计脚本
│   │   ├── verify_installation.sh   # 安装后验证脚本
│   │   ├── diagnose_chezmoi.sh      # chezmoi 诊断脚本
│   │   ├── ensure_ssh_prereqs.sh    # SSH 前置依赖检查
│   │   └── helpers.sh               # chezmoi 辅助函数
│   │
│   ├── common/                       # 跨平台通用脚本
│   │   ├── deploy_utils/            # 部署辅助脚本
│   │   │   ├── backup_ssh_config.sh       # 备份 ~/.ssh/config
│   │   │   ├── backup_git_config.sh       # 备份 ~/.gitconfig
│   │   │   ├── setup_ssh_config.sh        # 部署 SSH 配置
│   │   │   ├── check_zsh_omz.sh           # Zsh/OMZ 状态检查
│   │   │   ├── manual_zsh_setup.sh        # 手动 Zsh/OMZ 安装
│   │   │   ├── measure_zsh_startup.sh     # Zsh 启动时间测量
│   │   │   ├── nvim_checkhealth_to_log.sh # Neovim checkhealth 日志
│   │   │   ├── diagnose_deployment.sh     # 部署诊断
│   │   │   ├── force_apply_configs.sh     # 强制应用配置
│   │   │   ├── ensure_chezmoi_unlocked.sh # chezmoi 锁检测
│   │   │   ├── fix_chezmoi_lock.sh        # chezmoi 锁修复
│   │   │   ├── remote_init.sh             # 远程项目初始化
│   │   │   ├── sync_to_remote.sh          # 同步到远程
│   │   │   ├── test_tmux_remote.sh        # 远程 tmux 测试
│   │   │   ├── SSH_CONFIG_SETUP.md        # SSH 配置说明
│   │   │   ├── DEPLOYMENT_GUIDE.md        # 部署流程指南
│   │   │   ├── MANUAL_ZSH_SETUP_GUIDE.md  # 手动 Zsh 配置指南
│   │   │   └── SFTP_SYNC_GUIDE.md         # SFTP 同步指南
│   │   │
│   │   ├── standalone_tool_script/  # 独立工具脚本
│   │   │   ├── check_and_fix_encoding.sh      # 编码和换行符检查修复
│   │   │   ├── ensure_lf_line_endings.sh      # 换行符规范化
│   │   │   ├── append_text_to_file.sh         # 文本追加
│   │   │   ├── append_lines_to_file.sh        # 多行追加
│   │   │   ├── replace_text_in_files.sh       # 文本替换
│   │   │   ├── extract_text_between_markers.sh# 标记间文本提取
│   │   │   ├── remove_prefix_from_lines.sh    # 行前缀移除
│   │   │   ├── list_all_directories.sh        # 递归列目录
│   │   │   ├── list_all_files_and_directories.sh # 递归列文件和目录
│   │   │   ├── get_directory_name.sh          # 获取当前目录名
│   │   │   ├── get_openresty_path.sh          # OpenResty 路径
│   │   │   ├── get_pkg_config_flags.sh        # pkg-config 标志
│   │   │   ├── get_svn_revision.sh            # SVN 版本号
│   │   │   ├── compare_static_lib_objects.sh  # 静态库对象比较
│   │   │   ├── update_ts_key_pair.sh          # TS 密钥对更新
│   │   │   ├── demo_printf_formatting.sh      # printf 格式化示例
│   │   │   └── demo_heredoc.sh                # Heredoc 示例
│   │   │
│   │   ├── container_dev_env/        # Docker 容器开发环境
│   │   │   ├── Dockerfile            # Docker 镜像定义
│   │   │   ├── build.sh              # 构建镜像
│   │   │   ├── run.sh                # 运行容器
│   │   │   ├── run-wsl.sh            # WSL 容器启动
│   │   │   ├── container_install.sh  # 容器内安装脚本
│   │   │   ├── configure_mirrors.sh  # 镜像源配置
│   │   │   ├── check_chezmoi_config.sh # chezmoi 配置检查
│   │   │   ├── test_ssh_agent_windows.sh # Windows SSH Agent 测试
│   │   │   ├── test_ssh_agent_wsl2.sh    # WSL2 SSH Agent 测试
│   │   │   └── README.md             # 使用说明
│   │   │
│   │   ├── project_tools/            # 项目生成和管理工具
│   │   │   ├── create_c_source_file.sh
│   │   │   ├── generate_cmake_lists.sh
│   │   │   ├── generate_log4c_config.sh
│   │   │   ├── merge_static_libraries.sh
│   │   │   └── cpp_project_generator/
│   │   │
│   │   ├── ffmpeg-magic/             # FFmpeg 相关脚本工具
│   │   │   ├── open_multiple_ffmpeg_srt.sh
│   │   │   ├── open_multiple_ffmpeg_udp.sh
│   │   │   ├── open_multiple_terminals.sh
│   │   │   ├── send_srt_stream.sh
│   │   │   ├── install_netint_t4xx.sh
│   │   │   ├── concat_audio/
│   │   │   └── mix_audio/
│   │   │
│   │   ├── git_templates/            # Git 模板
│   │   │   ├── github_common_config.sh
│   │   │   └── default_gitignore_files/
│   │   │
│   │   ├── patch_examples/           # 补丁使用示例
│   │   ├── shc/                      # Shell 脚本编译器示例
│   │   └── auto_edit_redis_config/   # Redis 配置编辑
│   │
│   ├── linux/                        # Linux 专用脚本
│   │   ├── system_basic_env/        # 系统基础环境
│   │   │   ├── README.md             # 使用说明
│   │   │   ├── configure_china_mirrors.sh    # 国内镜像源配置
│   │   │   ├── test_mirrors.sh              # 镜像源可用性测试
│   │   │   ├── get_wsl_system_info.sh       # WSL 系统信息
│   │   │   ├── verify_wsl_ssh.sh            # WSL SSH 验证
│   │   │   ├── INSTALL_STATUS.md            # 安装状态清单
│   │   │   └── TEST_README.md               # 测试文档
│   │   │
│   │   └── network/                  # 网络配置脚本
│   │       ├── configure_ethernet_mac.sh
│   │       └── deploy_openresty.sh
│   │
│   └── windows/                      # Windows 专用脚本
│       ├── install_with_chezmoi.bat  # Windows chezmoi 安装入口 (BAT)
│       ├── install_with_chezmoi.sh   # Windows chezmoi 安装入口 (Shell)
│       ├── system_basic_env/
│       │   ├── README.md
│       │   ├── install_common_tools.ps1  # PowerShell 工具安装
│       │   ├── install_common_tools.bat  # 工具安装入口 (BAT)
│       │   ├── setup_ime.sh              # 输入法配置
│       │   ├── add_btop4win_to_git_bash.sh   # btop4win Git Bash 配置
│       │   ├── configure_btop4win_path.ps1   # btop4win PATH 配置
│       │   ├── set_xdg_config_home.ps1       # XDG_CONFIG_HOME 设置
│       │   ├── set_xdg_config_home.bat       # XDG 设置入口 (BAT)
│       └── windows_scripts/
│           ├── open_multi_vlc.bat
│           └── open_16_vlc.bat
│
├── openspec/                         # OpenSpec 规范驱动开发
│   ├── AGENTS.md
│   └── PROJECT.md
│
├── ai-unified-config/                 # AI 代理统一配置（如 OpenCode、Claude Code）
├── graphify-out/                      # Graphify 知识图谱分析缓存
│
├── temp/                              # 临时文件目录（common_install.sh 使用）
└── logs/                              # 安装日志目录（.gitignore 忽略）
```

## 目录说明

### 根目录与文档

- **install.sh**: 一键安装入口脚本。完整调用链见下方流程图
- **deploy.sh**: 快速部署入口脚本（需 chezmoi 已安装，含 Zsh/OMZ 预安装）
- **README.md**: 项目主文档，包含快速开始、使用说明等
- **AGENTS.md**: 代理与编码规范，包含代码风格、命名规范、最佳实践
- **docs/**: 文档目录，含 PROJECT_STRUCTURE.md（本文件）、SOFTWARE_LIST.md、INSTALL_GUIDE.md 等
- **.opencode/**: OpenCode 插件命令（openspec-apply、openspec-archive、openspec-proposal）
- **ai-unified-config/**: AI 代理统一配置（跨 OpenCode、Claude Code 等）
- **graphify-out/**: Graphify 知识图谱分析输出缓存

### install.sh 调用链（核心安装流程）

```
install.sh
  ├─ 解析参数（--proxy、--test-remote、--commit）
  ├─ 检测 OS（Linux/macOS/Windows）与代理（WSL 自动检测宿主机 IP）
  │
  ├─ [1/5] 安装 chezmoi
  │   └─ scripts/chezmoi/install_chezmoi.sh
  │       ├─ macOS: brew install chezmoi 或官方安装脚本
  │       ├─ Linux: pacman/apt-get/dnf 或官方安装脚本
  │       └─ Windows: winget 或官方安装脚本
  │
  ├─ [2/5] 初始化 chezmoi 环境
  │   ├─ 创建 ~/.local/bin、~/.local/share/chezmoi
  │   ├─ 写入 ~/.config/chezmoi/chezmoi.toml（sourceDir 绝对路径）
  │   └─ Windows: 设置 [interpreters.sh]（bash 解释器）
  │
  ├─ [3/5] 检查配置并应用（chezmoi 核心流程）
  │   ├─ chezmoi status  → 检查未同步项（M/A/D/R）
  │   ├─ chezmoi diff    → 检查模板与本地差异
  │   ├─ ensure_ssh_prereqs.sh → 确保 SSH ProxyCommand 依赖
  │   └─ chezmoi apply -v --force → 触发所有 run_once_*.sh.tmpl 脚本
  │       ├─ run_once_00-install-version-managers.sh.tmpl (fnm, uv, rustup)
  │       ├─ run_once_install-common-tools.sh.tmpl (bat, eza, fd, rg, fzf 等)
  │       ├─ run_once_install-zsh.sh.tmpl (zsh, oh-my-zsh, 插件)
  │       ├─ run_once_install-git.sh.tmpl
  │       ├─ run_once_install-neovim.sh.tmpl (>= 0.11.0)
  │       ├─ run_once_install-neovim-config.sh.tmpl (克隆到 ~/.config/nvim)
  │       ├─ run_once_install-starship.sh.tmpl
  │       ├─ run_once_install-nerd-fonts.sh.tmpl (FiraMono Nerd Font)
  │       ├─ run_once_install-tmux.sh.tmpl (Linux/macOS)
  │       ├─ run_once_install-fish.sh.tmpl (Linux/macOS)
  │       ├─ run_once_install-opencode.sh.tmpl
  │       ├─ run_once_install-system-basic-env.sh.tmpl
  │       ├─ run_once_install-ai-unified-config.sh.tmpl
  │       ├─ run_on_linux/run_once_*.sh.tmpl (仅 Linux)
  │       ├─ run_on_darwin/run_once_*.sh.tmpl (仅 macOS)
  │       └─ run_on_windows/run_once_*.sh.tmpl (仅 Windows)
  │
  ├─ [4/5] 软件安装状态检查
  │   └─ report_install_status_by_platform()
  │       扫描所有 run_once_*.sh.tmpl，按 OS 列出已安装/未安装
  │
  └─ [5/5] 验证与确认
      ├─ verify_installation.sh → 字体、Shell、PATH、通用工具、SSH/connect
      ├─ (可选) test_tmux_remote.sh → 远程 tmux 测试
      └─ (可选) git add + commit + push → 自动提交（--commit）

### .chezmoi/ 目录

所有配置文件模板由 chezmoi 统一管理。目录结构按 chezmoi 约定：
- 根目录下的 `dot_*.tmpl` → 对应 `~/.` 下的配置文件
- `run_once_00-install-*.sh.tmpl` → 优先安装脚本（按字母序最先执行，如版本管理器）
- `run_once_install-*.sh.tmpl` → 一次性安装脚本（按目标名字母序执行）
- `run_sync_*.sh.tmpl` → 每次 apply 均执行的同步脚本（如 Windows Terminal 配置同步）
- `run_on_linux/`、`run_on_darwin/`、`run_on_windows/` → 平台特定配置

**run_once 脚本按执行顺序：**

| 脚本 | 安装内容 | 平台 |
|------|---------|------|
| `run_once_00-install-version-managers.sh.tmpl` | fnm, uv, rustup | 多平台 |
| `run_once_install-ai-unified-config.sh.tmpl` | AI 代理统一配置 | 多平台 |
| `run_once_install-common-tools.sh.tmpl` | bat, eza, fd, rg, fzf, lazygit, git-delta, gh, trash-cli, btop, fastfetch | 多平台 |
| `run_once_install-fish.sh.tmpl` | fish shell | Linux, macOS |
| `run_once_install-git.sh.tmpl` | git, connect-proxy | 多平台 |
| `run_once_install-neovim.sh.tmpl` | neovim (>= 0.11.0) | 多平台 |
| `run_once_install-neovim-config.sh.tmpl` | 克隆 nvim 配置到 ~/.config/nvim | 多平台 |
| `run_once_install-nerd-fonts.sh.tmpl` | FiraMono Nerd Font | 多平台 |
| `run_once_install-opencode.sh.tmpl` | OpenCode CLI | 多平台 |
| `run_once_install-starship.sh.tmpl` | starship 提示符 | 多平台 |
| `run_once_install-system-basic-env.sh.tmpl` | 系统基础环境 | 多平台 |
| `run_once_install-tmux.sh.tmpl` | tmux, TPM 插件 | Linux, macOS |
| `run_once_install-zsh.sh.tmpl` | zsh, oh-my-zsh, 插件 | Linux, macOS, Windows(MSYS2) |
| `run_once_install-alacritty.sh.tmpl` | alacritty 终端 | 仅 Linux |
| `run_once_install-dwm.sh.tmpl` | dwm 窗口管理器 | 仅 Linux |
| `run_once_install-i3wm.sh.tmpl` | i3wm 窗口管理器 | 仅 Linux |
| `run_once_install-lazyssh.sh.tmpl` | lazyssh | 仅 Linux |
| `run_once_install-maccy.sh.tmpl` | maccy 剪贴板 | 仅 macOS |
| `run_once_install-skhd.sh.tmpl` | skhd 快捷键 | 仅 macOS |
| `run_once_install-yabai.sh.tmpl` | yabai 窗口管理器 | 仅 macOS |
| `run_once_install-oh-my-posh.sh.tmpl` | oh-my-posh | 仅 Windows |
| `run_on_linux/run_once_configure-pacman.sh.tmpl` | Arch 镜像与 pacman 配置 | 仅 Linux(Arch) |
| `run_on_linux/run_once_install-arch-base-packages.sh.tmpl` | base-devel, gcc 等 | 仅 Linux(Arch) |
| `run_on_linux/run_once_install-aur-helper.sh.tmpl` | yay/paru AUR 助手 | 仅 Linux |
| `run_on_darwin/run_once_configure-homebrew.sh.tmpl` | Homebrew 配置 | 仅 macOS |
| `run_on_darwin/run_once_install-connect.sh.tmpl` | connect (SSH 代理) | 仅 macOS |
| `run_on_darwin/run_once_install-ghostty.sh.tmpl` | Ghostty 终端 | 仅 macOS |
| `run_on_darwin/run_onchange_sync_ghostty_config_to_app_support.sh.tmpl` | Ghostty 配置同步 | 仅 macOS |
| `run_on_windows/run_once_install-windows-terminal.sh.tmpl` | Windows Terminal | 仅 Windows |
| `run_on_windows/run_onchange_sync_windows_terminal_config.sh.tmpl` | WT 配置同步 | 仅 Windows |

**注意**：`run_onchange_*` 类型的脚本仅在脚本内容变化时执行（非 run_once），用于确保配置文件同步到应用实际路径并减少 `chezmoi status` 噪音。

### scripts/ 目录

按功能和平台分类的脚本工具集合：

| 目录 | 用途 |
|------|------|
| `common.sh` | 通用函数库（颜色、日志、错误处理），所有脚本共享 |
| `manage_dotfiles.sh` | dotfiles 管理入口（status/diff/apply/edit） |
| `chezmoi/` | chezmoi 安装、验证、诊断脚本 |
| `common/deploy_utils/` | 部署辅助脚本（SSH/Zsh/OMZ 备份、诊断、同步） |
| `common/standalone_tool_script/` | 独立工具脚本（文本处理、编码检查、文件操作） |
| `common/container_dev_env/` | Docker 容器开发环境 |
| `common/project_tools/` | C/C++ 项目生成和构建工具 |
| `common/ffmpeg-magic/` | FFmpeg 流媒体工具 |
| `common/git_templates/` | Git 配置和 .gitignore 模板 |
| `common/patch_examples/` | diff/patch 使用示例 |
| `common/shc/` | Shell 脚本编译器示例 |
| `common/auto_edit_redis_config/` | Redis 配置自动编辑 |
| `linux/` | Linux 专用脚本（系统基础环境、网络配置） |
| `darwin/` | macOS 专用脚本 |
| `windows/` | Windows 专用脚本（.bat/.ps1） |

### 脚本分类

- **系统基础环境安装**：`scripts/linux/system_basic_env/`、`scripts/windows/system_basic_env/`
- **部署辅助**：`scripts/common/deploy_utils/`（备份、诊断、同步、SSH/Zsh 配置）
- **独立工具**：`scripts/common/standalone_tool_script/`、`scripts/common/project_tools/`、`scripts/common/ffmpeg-magic/` 等
- **平台特定**：Linux network、Windows windows_scripts

### 配置文件流程

1. `.chezmoi/` 存放配置模板（`dot_*.tmpl`、`run_once_*.sh.tmpl`）
2. `install.sh` / `deploy.sh` → `chezmoi apply` → 部署到 `~/`
3. 跨平台配置 → 所有系统应用
4. `run_on_{linux,darwin,windows}/` → 仅对应平台应用

## 注意事项

1. `.chezmoi/` 目录包含所有配置文件模板，由 chezmoi 统一管理
2. Neovim 为独立项目，由 `run_once_install-neovim-config.sh.tmpl` 克隆到 `~/.config/nvim`
3. 所有配置统一通过 `.chezmoi/*.tmpl` → `chezmoi apply` → `~/.` 流程部署
4. 跨平台通用脚本位于 `scripts/common/` 目录下
5. 所有脚本注释使用中文，打印输出使用英文
6. 脚本遵循 snake_case 命名规范
7. `.gitignore` 已忽略 `logs/`、`chezmoistate.boltdb`、`dotfiles/nvim/` 等
