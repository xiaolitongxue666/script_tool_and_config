# 项目结构

```
script_tool_and_config/
├── .editorconfig                    # 编辑器配置
├── .vscode/                          # VS Code 配置
│   └── settings.json
├── LICENSE                           # 许可证
├── install.sh                        # 一键安装脚本
│
├── README.md                         # 项目主文档
├── project_structure.md              # 项目结构说明（本文件）
├── SOFTWARE_LIST.md                  # 软件清单
├── ENCODING_AND_LINE_ENDINGS.md      # 文件编码和换行符规范
├── chezmoi_use_guide.md              # chezmoi 使用指南
├── os_setup_guide.md                 # 操作系统设置指南
│
├── dotfiles/                         # Git Submodule（仅 nvim 配置）
│   └── nvim/                         # Neovim 配置（Git Submodule）
│
├── scripts/                          # 脚本工具集合
│   ├── common.sh                     # 通用函数库
│   ├── manage_dotfiles.sh           # dotfiles 管理脚本
│   ├── readme.md                     # scripts 目录说明
│   │
│   ├── chezmoi/                      # chezmoi 相关脚本
│   │   ├── readme.md                 # chezmoi 脚本说明
│   │   ├── install_chezmoi.sh       # 安装 chezmoi 工具
│   │   ├── common_install.sh        # 通用安装函数库
│   │   └── helpers.sh                # 辅助函数
│   │
│   ├── migration/                    # 迁移脚本
│   │   └── migrate_to_chezmoi.sh    # 迁移到 chezmoi
│   │
│   ├── common/                       # 跨平台脚本
│   │   ├── container_dev_env/        # Docker 容器开发环境
│   │   │   ├── Dockerfile            # Docker 镜像定义
│   │   │   ├── build.sh              # 构建脚本
│   │   │   ├── run.sh                # 运行脚本
│   │   │   ├── container_install.sh  # 容器内安装脚本
│   │   │   ├── configure_mirrors.sh  # 镜像源配置脚本
│   │   │   └── README.md             # 使用说明
│   │   │
│   │   ├── utils/                    # 通用工具脚本
│   │   │   ├── append_text_to_file.sh
│   │   │   ├── append_lines_to_file.sh
│   │   │   ├── replace_text_in_files.sh
│   │   │   ├── list_all_directories.sh
│   │   │   ├── list_all_files_and_directories.sh
│   │   │   ├── get_directory_name.sh
│   │   │   ├── get_openresty_path.sh
│   │   │   ├── get_pkg_config_flags.sh
│   │   │   ├── get_svn_revision.sh
│   │   │   ├── update_ts_key_pair.sh
│   │   │   ├── open_multiple_terminals.sh
│   │   │   ├── compare_static_lib_objects.sh
│   │   │   ├── demo_printf_formatting.sh
│   │   │   ├── demo_heredoc.sh
│   │   │   ├── extract_text_between_markers.sh
│   │   │   ├── check_and_fix_encoding.sh  # 检查文件编码和换行符
│   │   │   └── ensure_lf_line_endings.sh  # 规范化换行符
│   │   │
│   │   ├── project_tools/            # 项目生成和管理工具
│   │   │   ├── create_c_source_file.sh
│   │   │   ├── generate_cmake_lists.sh
│   │   │   ├── generate_log4c_config.sh
│   │   │   ├── merge_static_libraries.sh
│   │   │   └── cpp_project_generator/
│   │   │       ├── generate_project.sh
│   │   │       ├── cmake_all_project.sh
│   │   │       ├── ls_dirs_name.sh
│   │   │       └── src/
│   │   │
│   │   ├── media_tools/              # 媒体处理工具
│   │   │   ├── open_multiple_ffmpeg_srt.sh
│   │   │   ├── open_multiple_ffmpeg_udp.sh
│   │   │   ├── concat_audio/
│   │   │   └── mix_audio/
│   │   │
│   │   ├── git_templates/            # Git 模板
│   │   │   ├── github_common_config.sh
│   │   │   └── default_gitignore_files/
│   │   │
│   │   ├── patch_examples/           # 补丁使用示例
│   │   │   ├── readme.md
│   │   │   ├── create_patch.sh
│   │   │   └── use_patch.sh
│   │   │
│   │   ├── shc/                      # Shell 脚本编译器示例
│   │   │   └── [示例脚本和编译产物]
│   │   │
│   │   └── auto_edit_redis_config/   # Redis 配置编辑
│   │       └── auto_edit_redis_config.sh
│   │
│   ├── linux/                        # Linux 专用脚本
│   │   ├── system_basic_env/        # 系统基础环境安装（ArchLinux）
│   │   │   ├── README.md             # 使用说明
│   │   │   ├── configure_china_mirrors.sh
│   │   │   ├── install_common_tools.sh
│   │   │   ├── install_environment.sh
│   │   │   ├── install_neovim.sh
│   │   │   ├── install_common_software.sh
│   │   │   ├── install_gnome.sh
│   │   │   └── install_network_manager.sh
│   │   │
│   │   ├── network/                  # 网络配置脚本
│   │   │   ├── configure_ethernet_mac.sh
│   │   │   ├── deploy_openresty.sh
│   │   │   └── send_srt_stream.sh
│   │   │
│   │   └── hardware/                 # 硬件安装脚本
│   │       └── install_netint_t4xx.sh
│   │
│   ├── macos/                        # macOS 专用脚本
│   │   └── system_basic_env/
│   │       ├── readme.md
│   │       └── install_common_tools.sh
│   │
│   └── windows/                      # Windows 专用脚本
│       ├── system_basic_env/
│       │   ├── readme.md
│       │   ├── install_common_tools.ps1
│       │   ├── install_common_tools.bat
│       │   └── fix_encoding_simple.ps1
│       └── windows_scripts/
│           ├── open_multi_vlc.bat
│           └── open_16_vlc.bat
│
└── logs/                             # 日志目录
    └── system_basic_env/
```

## 目录说明

### 根目录文件

- **readme.md**: 项目主文档，包含快速开始、使用说明等
- **project_structure.md**: 项目结构说明（本文件）
- **software_list.md**: 完整的软件清单和安装说明
- **chezmoi_use_guide.md**: chezmoi 使用指南
- **install.sh**: 一键安装脚本

### dotfiles/ 目录

Legacy 目录，所有配置已迁移到 `.chezmoi/` 目录。保留作为参考。

### scripts/ 目录

按操作系统分类的脚本工具集合：

- **common.sh**: 通用函数库，所有脚本共享
- **manage_dotfiles.sh**: dotfiles 管理脚本
- **chezmoi/**: chezmoi 相关脚本
- **migration/**: 迁移脚本
- **linux/**: Linux 专用脚本和跨平台脚本
- **macos/**: macOS 专用脚本
- **windows/**: Windows 专用脚本

### 脚本分类

#### 系统基础环境安装

- **Linux**: `scripts/linux/system_basic_env/`
- **macOS**: `scripts/macos/system_basic_env/`
- **Windows**: `scripts/windows/system_basic_env/`

#### 跨平台工具脚本

位于 `scripts/common/` 目录下，可在多个平台使用：

- **utils/**: 通用工具脚本
- **project_tools/**: 项目生成和管理工具
- **media_tools/**: 媒体处理工具
- **git_templates/**: Git 模板
- **patch_examples/**: 补丁使用示例
- **shc/**: Shell 脚本编译器示例
- **auto_edit_redis_config/**: Redis 配置编辑工具

#### 平台特定脚本

- **network/**: 网络配置脚本（Linux）
- **hardware/**: 硬件安装脚本（Linux）
- **windows_scripts/**: Windows 批处理脚本

## 配置文件位置

### chezmoi 管理

所有配置文件由 chezmoi 管理，位于 `.chezmoi/` 目录（不在版本控制中，由 chezmoi 管理）。

### Legacy 配置

Legacy 配置文件位于 `dotfiles/` 目录，仅作为参考。

## 日志目录

- **logs/**: 脚本执行日志
  - `logs/system_basic_env/`: 系统基础环境安装日志

## 注意事项

1. `.chezmoi/` 目录包含所有配置文件模板，由 chezmoi 统一管理
2. `dotfiles/` 目录仅用于 Git Submodule（nvim 配置）
3. 所有配置统一通过 `.chezmoi/*.tmpl` → `chezmoi apply` → `~/.` 流程部署
4. 跨平台脚本位于 `scripts/common/` 目录下
5. 所有脚本注释已翻译为中文
6. 脚本遵循统一的命名规范

