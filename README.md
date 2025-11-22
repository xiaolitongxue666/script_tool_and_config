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
│   ├── bash_config/                # Bash 配置
│   │   ├── macos/                  # macOS 版本
│   │   └── windows/                # Windows 版本
│   ├── fish_config/                # Fish Shell 配置
│   │   ├── linux/                  # Linux 版本
│   │   └── macos/                  # macOS 版本
│   ├── i3wm_config/                # i3 窗口管理器配置
│   ├── secure_crt/                 # SecureCRT 配置和脚本
│   ├── skhd/                       # skhd (macOS 快捷键配置)
│   ├── tmux_config/                # Tmux 配置
│   ├── yabai/                      # Yabai (macOS 窗口管理)
│   ├── zsh_install_and_config/      # Zsh 安装和配置
│   ├── no_more_use_alacritty/       # 已废弃的 Alacritty 配置
│   └── no_more_use_cmder_config/    # 已废弃的 Cmder 配置
│
└── scripts/                        # 脚本工具集合
    ├── cpp_project_generator/       # C/C++ 项目自动创建工具
    ├── auto_edit_redis_config/      # Redis 配置自动编辑
    ├── media_tools/                 # 媒体处理工具（FFmpeg 相关）
    │   ├── concat_audio/            # 音频连接
    │   ├── mix_audio/               # 音频混合
    │   ├── open_multi_ffmpeg_srt.sh # 打开多个 FFmpeg SRT 流
    │   └── open_multi_ffmpeg_udp.sh  # 打开多个 FFmpeg UDP 流
    ├── git_templates/               # Git 相关模板和参考
    ├── patch_examples/              # diff 和 patch 使用示例
    ├── shc/                         # Shell 脚本加密工具示例
    ├── windows_scripts/             # Windows 批处理脚本
    └── [各种实用脚本]               # 详见下方脚本说明
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

#### Shell 配置
- **Fish Shell**
  - `fish_config/linux/`: Linux 平台 Fish Shell 配置
  - `fish_config/macos/`: macOS 平台 Fish Shell 配置
  - 包含常用别名、路径配置、NVM、Pyenv 等工具集成

- **Bash/Zsh**
  - `bash_config/`: Bash 配置文件
  - `zsh_install_and_config/`: Zsh 安装和配置指南

#### 终端和窗口管理
- `i3wm_config/`: i3 窗口管理器配置
- `tmux_config/`: Tmux 终端复用器配置
- `yabai/`: macOS 窗口管理器 Yabai 配置
- `skhd/`: macOS 快捷键配置工具

#### 其他工具配置
- `secure_crt/`: SecureCRT SSH 客户端配置和自动化脚本
- `no_more_use_alacritty/`: 已废弃的 Alacritty 终端配置
- `no_more_use_cmder_config/`: 已废弃的 Cmder 配置

### 3. 脚本工具 (scripts)

#### 项目创建和管理
- `cpp_project_generator/`: C/C++ 项目自动创建工具
  - `generate_project.sh`: 自动创建项目结构（CMake、.gitignore 等）
  - `cmake_all_project.sh`: 使用 CMake 构建项目
  - `ls_dirs_name.sh`: 递归列出目录名称
- `clion_cmakelists_create.sh`: 为 CLion IDE 自动生成 CMakeLists.txt
- `create_c_file.sh`: 创建新的 C 代码文件（自动添加头文件保护等）

#### 系统环境配置
- `archlinux_environment_auto_install.sh`: ArchLinux 环境自动安装
- `auto_install_common_software_for_archlinux.sh`: ArchLinux 常用软件安装
- `auto_install_gnome_for_archlinux.sh`: ArchLinux GNOME 桌面环境安装
- `auto_install_dwm_for_centos_stream.sh`: CentOS Stream 上安装 DWM
- `auto_install_net_control_for_archlinux.sh`: ArchLinux 网络控制工具安装

#### 开发工具
- `auto_edit_redis_config/`: Redis 配置文件自动编辑
- `get_cflags_and_libs_for_makefile.sh`: 获取 Makefile 所需的 CFLAGS 和 LIBS
- `svn_revision.sh`: 获取 SVN 版本号
- `compare_object_file_name.sh`: 比较目标文件名

#### 文件操作
- `append_multi_lines_to_file.sh`: 向文件追加多行内容
- `append_txt_to_file.sh`: 向文件追加文本
- `replace_text_in_files.sh`: 在文件中替换文本
- `cut_string_between_special_begin_and_end.sh`: 截取特殊标记之间的字符串
- `delete_first_three_char_each_line.sh`: 删除每行前三个字符
- `ls_all_dirs_name.sh`: 列出所有目录名
- `ls_all_files_and_dirs_name.sh`: 列出所有文件和目录名
- `get_dir_name.sh`: 获取目录名

#### 媒体处理 (media_tools)
- `media_tools/concat_audio/`: 音频连接脚本（concat_audio.sh）
- `media_tools/mix_audio/`: 音频混合脚本（支持多文件混合、重采样等）
- `media_tools/open_multi_ffmpeg_srt.sh`: 打开多个 FFmpeg SRT 流
- `media_tools/open_multi_ffmpeg_udp.sh`: 打开多个 FFmpeg UDP 流
- `send_srt.sh`: 发送 SRT 流

#### 网络和部署
- `deploy_openresty_locally.sh`: 本地部署 OpenResty
- `get_openresty_config_path.sh`: 获取 OpenResty 配置路径
- `eth_name_mac_config.sh`: 以太网名称和 MAC 地址配置

#### 工具和实用脚本
- `common.sh`: 通用脚本函数库（颜色输出、脚本开始/结束函数等）
- `construct_logs.sh`: 构建日志目录结构（log4c 配置）
- `printf_format_output.sh`: 格式化输出
- `show_multi_lines.sh`: 显示多行内容
- `open_multi_terminal_and_exec.sh`: 打开多个终端并执行命令
- `auto_write_ts_key_pair.sh`: 自动生成 TypeScript 密钥对
- `ar_multi_static_lib_to_one.sh`: 合并多个静态库为一个
- `t4xx_quick_installer_china.sh`: T4xx 快速安装器（中国版）

#### 脚本加密
- `shc/`: Shell 脚本加密工具 (shc) 使用示例
  - 演示如何使用 shc 将 Shell 脚本编译为二进制文件

#### 版本控制和补丁
- `patch_examples/`: diff 和 patch 工具使用示例和说明
  - `create_patch.sh`: 创建补丁文件
  - `use_patch.sh`: 应用补丁文件
  - `README.md`: 详细使用说明

#### Git 相关
- `git_templates/`: Git 相关模板和参考
  - `github_common_config.sh`: GitHub 常用配置
  - `default_gitignore_files/`: 默认 .gitignore 文件模板

#### Windows 脚本
- `windows_scripts/`: Windows 批处理脚本
  - `open_multi_vlc.bat`: 打开多个 VLC 播放器实例
  - `open_16_vlc.bat`: 打开 16 个 VLC 播放器实例

## 使用说明

### 基本使用

大多数脚本都可以直接运行，但某些脚本可能需要：
1. 执行权限：`chmod +x script_name.sh`
2. 特定环境：某些脚本针对特定操作系统（如 ArchLinux）
3. 依赖工具：确保已安装所需工具（如 ffmpeg、cmake 等）

### 示例

#### 创建 C/C++ 项目
```bash
cd scripts/cpp_project_generator
./generate_project.sh c    # 创建 C 项目
./generate_project.sh cpp  # 创建 C++ 项目
```

#### 配置 ArchLinux 镜像源
```bash
cd scripts
sudo ./add_china_source_for_archlinux_pacman_config.sh
```

#### 安装 Fish Shell 和 Oh My Fish
```bash
cd scripts
sudo ./auto_install_fish_and_omf.sh
```

## 注意事项

1. **已废弃的配置**: 标记为 `no_more_use_*` 的目录包含已不再使用的配置，仅供参考
2. **权限要求**: 某些脚本需要 root 权限（使用 `sudo`）
3. **平台特定**: 部分脚本仅适用于特定操作系统，请根据实际情况使用
4. **备份**: 修改系统配置文件前，建议先备份原文件

## 许可证

详见 [LICENSE](LICENSE) 文件

## 更新日志

### 2024 整理
- ✅ 重新分析整个项目结构
- ✅ 整理重复冗余的代码和配置
- ✅ 将所有注释翻译为中文
- ✅ 重命名拼写错误的文件和目录
- ✅ 根据功能和作用重命名文件和文件夹
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
