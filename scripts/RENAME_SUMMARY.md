# 脚本重命名总结

## ✅ 已完成的重命名操作

### 系统安装脚本（system/）
- `archlinux_environment_auto_install.sh` → `system/archlinux/install_environment.sh`
- `add_china_source_for_archlinux_pacman_config.sh` → `system/archlinux/configure_china_mirrors.sh`
- `auto_install_neovim_for_archlinux.sh` → `system/archlinux/install_neovim.sh`
- `auto_install_common_software_for_archlinux.sh` → `system/archlinux/install_common_software.sh`
- `auto_install_gnome_for_archlinux.sh` → `system/archlinux/install_gnome.sh`
- `auto_install_net_control_for_archlinux.sh` → `system/archlinux/install_network_manager.sh`
- `auto_install_dwm_for_centos_stream.sh` → `system/centos/install_dwm.sh`

### 网络配置脚本（network/）
- `eth_name_mac_config.sh` → `network/configure_ethernet_mac.sh`
- `deploy_openresty_locally.sh` → `network/deploy_openresty.sh`
- `send_srt.sh` → `network/send_srt_stream.sh`

### 硬件安装脚本（hardware/）
- `t4xx_quick_installer_china.sh` → `hardware/install_netint_t4xx.sh`

### 工具脚本（utils/）
- `get_openresty_config_path.sh` → `utils/get_openresty_path.sh`
- `get_cflags_and_libs_for_makefile.sh` → `utils/get_pkg_config_flags.sh`
- `svn_revision.sh` → `utils/get_svn_revision.sh`
- `printf_format_output.sh` → `utils/demo_printf_formatting.sh`
- `show_multi_lines.sh` → `utils/demo_heredoc.sh`
- `open_multi_terminal_and_exec.sh` → `utils/open_multiple_terminals.sh`
- `auto_write_ts_key_pair.sh` → `utils/update_ts_key_pair.sh`
- `compare_object_file_name.sh` → `utils/compare_static_lib_objects.sh`

### 项目工具（project_tools/）
- `clion_cmakelists_create.sh` → `project_tools/generate_cmake_lists.sh` (已优化)
- `create_c_file.sh` → `project_tools/create_c_source_file.sh` (已优化)
- `construct_logs.sh` → `project_tools/generate_log4c_config.sh` (已优化)
- `ar_multi_static_lib_to_one.sh` → `project_tools/merge_static_libraries.sh` (已优化)
- `cpp_project_generator/` → `project_tools/cpp_project_generator/` (目录移动)

### 媒体工具（media_tools/）
- `open_multi_ffmpeg_srt.sh` → `media_tools/open_multiple_ffmpeg_srt.sh`
- `open_multi_ffmpeg_udp.sh` → `media_tools/open_multiple_ffmpeg_udp.sh`
- `mix_audio/ffmpeg_script.sh` → `media_tools/mix_audio/mix_audio.sh`

### 已删除的旧文件（新版本已在对应目录）
- `append_txt_to_file.sh` → 已替换为 `utils/append_text_to_file.sh`
- `append_multi_lines_to_file.sh` → 已替换为 `utils/append_lines_to_file.sh`
- `replace_text_in_files.sh` → 已替换为 `utils/replace_text_in_files.sh`
- `delete_first_three_char_each_line.sh` → 已替换为 `utils/remove_prefix_from_lines.sh`
- `cut_string_between_special_begin_and_end.sh` → 已替换为 `utils/extract_text_between_markers.sh`
- `ls_all_dirs_name.sh` → 已替换为 `utils/list_all_directories.sh`
- `ls_all_files_and_dirs_name.sh` → 已替换为 `utils/list_all_files_and_directories.sh`
- `get_dir_name.sh` → 已替换为 `utils/get_directory_name.sh`

## 📁 新的目录结构

```
scripts/
├── system/              # 系统安装脚本
│   ├── archlinux/      # ArchLinux 相关
│   └── centos/         # CentOS 相关
├── network/            # 网络配置脚本
├── hardware/           # 硬件安装脚本
├── utils/              # 通用工具脚本
├── project_tools/      # 项目生成和管理工具
├── media_tools/        # 媒体处理工具
├── auto_edit_redis_config/  # Redis 配置编辑
├── git_templates/      # Git 模板
├── patch_examples/    # 补丁示例
├── shc/               # Shell 脚本加密示例
├── windows_scripts/   # Windows 批处理脚本
└── common.sh          # 通用函数库
```

## 🎯 命名规范

1. **系统安装脚本**: `install_<软件名>.sh` 或 `configure_<配置名>.sh`
2. **工具脚本**: `<动作>_<对象>.sh` (如: `get_<名称>.sh`, `list_<对象>.sh`)
3. **项目工具**: `<动作>_<对象>.sh` (如: `generate_<名称>.sh`, `create_<名称>.sh`)
4. **网络工具**: `<动作>_<协议/服务>.sh` (如: `send_<协议>_stream.sh`, `deploy_<服务>.sh`)
5. **示例脚本**: `demo_<功能>.sh`

所有脚本名称都使用下划线分隔，清晰描述功能。
