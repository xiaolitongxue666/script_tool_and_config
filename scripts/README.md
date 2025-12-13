# Scripts 目录

本目录包含按操作系统分类的脚本工具集合。

## 目录结构

```
scripts/
├── common.sh                    # 通用函数库（所有脚本共享）
├── PROJECT_HISTORY.md           # 项目优化历史记录
├── readme.md                    # 本文件
│
├── windows/                     # Windows 专用脚本
│   └── windows_scripts/         # Windows 批处理脚本
│       ├── open_multi_vlc.bat   # 打开多个 VLC 播放器
│       └── open_16_vlc.bat      # 打开 16 个 VLC 播放器
│
├── macos/                       # macOS 专用脚本（预留）
│
└── linux/                       # Linux 专用脚本和跨平台脚本
    ├── system_basic_env/        # 系统基础环境安装脚本（ArchLinux）
    │   ├── configure_china_mirrors.sh
    │   ├── install_environment.sh
    │   ├── install_neovim.sh
    │   ├── install_common_software.sh
    │   ├── install_gnome.sh
    │   └── install_network_manager.sh
    │
    ├── network/                 # 网络配置脚本
    │   ├── configure_ethernet_mac.sh
    │   ├── deploy_openresty.sh
    │   └── send_srt_stream.sh
    │
    ├── hardware/                # 硬件安装脚本
    │   └── install_netint_t4xx.sh
    │
    ├── utils/                    # 通用工具脚本（跨平台）
    │   ├── append_text_to_file.sh
    │   ├── append_lines_to_file.sh
    │   ├── replace_text_in_files.sh
    │   ├── list_all_directories.sh
    │   ├── get_directory_name.sh
    │   └── [其他工具脚本]
    │
    ├── project_tools/            # 项目生成和管理工具（跨平台）
    │   ├── create_c_source_file.sh
    │   ├── generate_cmake_lists.sh
    │   ├── generate_log4c_config.sh
    │   ├── merge_static_libraries.sh
    │   └── cpp_project_generator/
    │
    ├── media_tools/             # 媒体处理工具（跨平台）
    │   ├── open_multiple_ffmpeg_srt.sh
    │   ├── open_multiple_ffmpeg_udp.sh
    │   ├── concat_audio/
    │   └── mix_audio/
    │
    ├── git_templates/           # Git 模板（跨平台）
    │   ├── github_common_config.sh
    │   └── default_gitignore_files/
    │
    ├── patch_examples/          # 补丁示例（跨平台）
    │   ├── create_patch.sh
    │   └── use_patch.sh
    │
    ├── shc/                     # Shell 脚本编译器示例（跨平台）
    │   ├── echo_hello_world.sh
    │   ├── shc_test.sh
    │   └── source_shc.sh
    │
    └── auto_edit_redis_config/  # Redis 配置编辑（跨平台）
        └── auto_edit_redis_config.sh
```

## 脚本分类说明

### Windows 专用脚本

位于 `windows/` 目录，包含 Windows 批处理脚本（.bat 文件）。

### macOS 专用脚本

位于 `macos/` 目录（预留，目前为空）。

### Linux 专用脚本

位于 `linux/` 目录，包含：
- **system_basic_env/**: 系统基础环境安装脚本（ArchLinux）
- **network/**: 网络配置脚本
- **hardware/**: 硬件安装脚本

### 跨平台脚本

跨平台脚本默认放在 `linux/` 目录下，包括：
- **utils/**: 通用工具脚本（可在多个系统使用）
- **project_tools/**: 项目生成和管理工具
- **media_tools/**: 媒体处理工具
- **git_templates/**: Git 模板和配置
- **patch_examples/**: 补丁使用示例
- **shc/**: Shell 脚本编译器示例
- **auto_edit_redis_config/**: Redis 配置编辑工具

## 使用 common.sh

所有脚本可以使用 `common.sh` 通用函数库。引用方式：

```bash
# 加载通用函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh" 2>/dev/null || {
    echo "错误: 无法加载 common.sh"
    exit 1
}

# 使用函数
start_script "脚本名称"
log_info "这是一条信息"
log_success "操作成功"
log_warning "这是一条警告"
log_error "这是一条错误"
end_script
```

**注意**: 从 `linux/` 子目录引用时，路径为 `../../common.sh`（向上两级到 scripts 根目录）。

## 命名规范

1. **系统安装脚本**: `install_<软件名>.sh` 或 `configure_<配置名>.sh`
2. **工具脚本**: `<动作>_<对象>.sh` (如: `get_<名称>.sh`, `list_<对象>.sh`)
3. **项目工具**: `<动作>_<对象>.sh` (如: `generate_<名称>.sh`, `create_<名称>.sh`)
4. **网络工具**: `<动作>_<协议/服务>.sh` (如: `send_<协议>_stream.sh`, `deploy_<服务>.sh`)
5. **示例脚本**: `demo_<功能>.sh`

## 注意事项

- 所有脚本注释已翻译为中文
- 所有脚本遵循统一的命名规范
- 优化后的脚本使用 `common.sh` 中的函数
- `common.sh` 放在 `scripts/` 根目录，便于所有子目录引用
- 脚本按操作系统分类组织，跨平台脚本默认放在 `linux/` 目录

