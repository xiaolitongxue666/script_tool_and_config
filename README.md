# script_tool_and_config

个人软件配置和常用脚本集合

本项目包含我在日常开发中使用的各种脚本工具和软件配置文件，涵盖 Linux、macOS 和 Windows 平台。

## 项目结构

```
script_tool_and_config/
├── environment_setup/              # 环境构建和配置脚本
│   ├── linux/                      # Linux 相关配置
│   │   ├── archlinux_nvim_dockerfile/          # ArchLinux Neovim Dockerfile
│   │   ├── archlinux_pacman_config/            # ArchLinux Pacman 配置
│   │   ├── archlinux_software_auto_install/    # ArchLinux 软件自动安装
│   │   ├── i3wm_config/                         # i3 窗口管理器配置
│   │   ├── no_more_use_nvim_config_and_plug_install/  # 已废弃的 Neovim 配置
│   │   └── no_more_use_nvim_vim_config/         # 已废弃的 Vim 配置
│   └── windows/                    # Windows 相关配置
│       ├── keyboard_exchange_esc_and_tab/      # 键盘 ESC 和 TAB 交换
│       └── no_more_use_cmder_config/           # 已废弃的 Cmder 配置
│
├── dotfiles/                       # 点配置文件（各种工具的配置文件）
│   │                               # 每个工具遵循统一结构：工具名/配置文件/README.md/install.sh
│   ├── alacritty/                  # Alacritty 终端配置
│   │   ├── alacritty.toml          # Alacritty 配置文件（TOML 格式）
│   │   ├── install.sh              # 自动安装脚本（macOS）
│   │   └── README.md               # 配置说明
│   ├── bash/                       # Bash 配置
│   │   ├── macos/                  # macOS 平台配置
│   │   ├── windows/                # Windows 平台配置
│   │   ├── install.sh              # 自动安装脚本
│   │   ├── config_loader.sh       # 配置加载脚本（自动检测系统）
│   │   └── README.md               # 配置说明
│   ├── fish/                       # Fish Shell 配置
│   │   ├── linux/                  # Linux 平台配置
│   │   ├── macos/                  # macOS 平台配置
│   │   ├── install.sh              # 自动安装脚本（支持多平台）
│   │   ├── config_loader.sh       # 配置加载脚本（自动检测系统）
│   │   └── README.md               # 配置说明
│   ├── i3wm/                       # i3 窗口管理器配置
│   │   ├── config                  # i3 配置文件
│   │   ├── install.sh              # 自动安装脚本（仅 Linux）
│   │   └── README.md               # 配置说明
│   ├── secure_crt/                 # SecureCRT 配置和脚本
│   │   ├── SecureCRTV8_VM_Login_TOP.vbs  # VBScript 自动化脚本
│   │   ├── windows7_securecrt_config.xml   # SecureCRT 配置文件
│   │   ├── install.sh              # 自动安装脚本（Windows）
│   │   └── README.md               # 配置说明
│   ├── skhd/                       # skhd (macOS 快捷键配置)
│   │   ├── skhdrc                  # skhd 配置文件
│   │   ├── install.sh              # 自动安装脚本（仅 macOS）
│   │   └── README.md               # 配置说明
│   ├── tmux/                       # Tmux 配置
│   │   ├── tmux.conf               # Tmux 配置文件
│   │   ├── install.sh              # 自动安装脚本（支持多平台）
│   │   └── README.md               # 配置说明
│   ├── yabai/                      # Yabai (macOS 窗口管理)
│   │   ├── yabairc                 # Yabai 配置文件
│   │   ├── install.sh              # 自动安装脚本（仅 macOS）
│   │   └── README.md               # 配置说明
│   └── zsh/                        # Zsh 安装和配置
│       ├── .zshrc                 # 统一配置文件（自动检测系统）
│       ├── install.sh              # 自动安装脚本（支持多平台，包含配置同步功能）
│       └── README.md               # 配置说明
│
└── scripts/                        # 脚本工具集合（按系统分类）
    ├── common.sh                    # 通用函数库（所有脚本共享）
    ├── README.md                    # 脚本目录说明
    ├── PROJECT_HISTORY.md           # 项目优化历史记录
    ├── windows/                     # Windows 专用脚本
    │   └── windows_scripts/         # Windows 批处理脚本
    │       ├── open_multi_vlc.bat  # 打开多个 VLC 播放器
    │       └── open_16_vlc.bat      # 打开 16 个 VLC 播放器
    ├── macos/                       # macOS 专用脚本（预留）
    └── linux/                       # Linux 专用脚本和跨平台脚本
        ├── system_basic_env/        # 系统基础环境安装脚本（ArchLinux）
        ├── network/                 # 网络配置脚本
        ├── hardware/                # 硬件安装脚本
        ├── utils/                   # 通用工具脚本（跨平台）
        ├── project_tools/           # 项目生成和管理工具（跨平台）
        ├── media_tools/             # 媒体处理工具（跨平台）
        ├── git_templates/           # Git 相关模板（跨平台）
        ├── patch_examples/          # 补丁使用示例（跨平台）
        ├── shc/                     # Shell 脚本编译器示例（跨平台）
        └── auto_edit_redis_config/  # Redis 配置编辑（跨平台）
```

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

#### Windows
- `keyboard_exchange_esc_and_tab/`: 键盘 ESC 和 TAB 键交换配置

### 2. 点配置文件 (dotfiles)

所有工具配置遵循统一的结构：**工具名/配置文件/README.md/install.sh**

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
- **SecureCRT** (`secure_crt/`): SSH 客户端配置和自动化脚本
  - `SecureCRTV8_VM_Login_TOP.vbs`: VBScript 自动化脚本
  - `install.sh`: 自动安装脚本（Windows）

### 3. 脚本工具 (scripts)

脚本按操作系统分类组织，详见 `scripts/README.md`。

#### Windows 专用脚本 (`scripts/windows/`)
- **windows_scripts/**: Windows 批处理脚本
  - `open_multi_vlc.bat`: 打开多个 VLC 播放器实例
  - `open_16_vlc.bat`: 打开 16 个 VLC 播放器实例

#### macOS 专用脚本 (`scripts/macos/`)
- 预留目录，用于 macOS 专用脚本

#### Linux 专用脚本和跨平台脚本 (`scripts/linux/`)

**系统基础环境安装脚本 (`system_basic_env/`)**
- ArchLinux 系统基础环境安装和配置脚本
  - `configure_china_mirrors.sh`: 配置中国镜像源
  - `install_environment.sh`: 安装开发环境
  - `install_neovim.sh`: 安装 Neovim
  - `install_common_software.sh`: 安装常用软件
  - `install_gnome.sh`: 安装 GNOME 桌面环境
  - `install_network_manager.sh`: 安装网络管理器

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
- `README.md`: 详细使用说明

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

### 基本使用

大多数脚本都可以直接运行，但某些脚本可能需要：
1. 执行权限：`chmod +x script_name.sh`
2. 特定环境：某些脚本针对特定操作系统（如 ArchLinux）
3. 依赖工具：确保已安装所需工具（如 ffmpeg、cmake 等）

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

**注意**: dwm 的配置通过编辑源代码（`config.h`）完成，需要重新编译。详见 `dotfiles/dwm/README.md`。

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
└── README.md             # 配置说明和使用指南
```

### 多系统配置工具

对于支持多系统的工具（如 Fish、Bash），使用**统一配置文件**，通过条件判断自动检测系统并加载对应配置：

```
工具名/
├── config.fish 或 config.sh  # 统一配置文件（自动检测系统）
├── completions/             # 补全脚本目录（如适用）
├── install.sh               # 自动安装脚本（自动检测系统，包含配置同步和备份）
└── README.md                # 配置说明
```

**优势**：
- ✅ 只需维护一个配置文件
- ✅ 自动检测操作系统
- ✅ 条件判断加载平台特定配置
- ✅ 减少配置重复和冗余
- ✅ 结构更简洁清晰

## 注意事项

1. **统一结构**: 所有工具配置遵循统一的结构，便于管理和使用
2. **自动检测**: 安装脚本和配置加载脚本会自动检测操作系统
3. **权限要求**: 某些脚本需要 root 权限（使用 `sudo`）
4. **平台特定**: 部分脚本仅适用于特定操作系统，请根据实际情况使用
5. **备份**: 修改系统配置文件前，建议先备份原文件

## 许可证

详见 [LICENSE](LICENSE) 文件

## 更新日志

### 2024 整理
- ✅ 重新分析整个项目结构
- ✅ 整理重复冗余的代码和配置
- ✅ 将所有注释翻译为中文
- ✅ 重命名拼写错误的文件和目录
- ✅ 根据功能和作用重命名文件和文件夹
- ✅ 添加 Alacritty 终端安装脚本和配置文件
- ✅ 统一工具配置结构（工具名/配置文件/README.md/install.sh）
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
