# 脚本重命名计划

## 系统安装脚本（移动到 system/archlinux/）
- archlinux_environment_auto_install.sh -> system/archlinux/install_environment.sh
- add_china_source_for_archlinux_pacman_config.sh -> system/archlinux/configure_china_mirrors.sh
- auto_install_neovim_for_archlinux.sh -> system/archlinux/install_neovim.sh
- auto_install_common_software_for_archlinux.sh -> system/archlinux/install_common_software.sh
- auto_install_dwm_for_centos_stream.sh -> system/centos/install_dwm.sh
- auto_install_gnome_for_archlinux.sh -> system/archlinux/install_gnome.sh
- auto_install_net_control_for_archlinux.sh -> system/archlinux/install_network_manager.sh

## 项目工具（移动到 project_tools/）
- clion_cmakelists_create.sh -> project_tools/generate_cmake_lists.sh (已创建，删除旧文件)
- create_c_file.sh -> project_tools/create_c_source_file.sh (已创建，删除旧文件)
- construct_logs.sh -> project_tools/generate_log4c_config.sh (已创建，删除旧文件)
- ar_multi_static_lib_to_one.sh -> project_tools/merge_static_libraries.sh (已创建，删除旧文件)
- cpp_project_generator/ -> project_tools/cpp_project_generator/ (移动目录)

## 工具脚本（移动到 utils/）
- append_txt_to_file.sh -> utils/append_text_to_file.sh (已创建，删除旧文件)
- append_multi_lines_to_file.sh -> utils/append_lines_to_file.sh (已创建，删除旧文件)
- replace_text_in_files.sh -> utils/replace_text_in_files.sh (已创建，删除旧文件)
- delete_first_three_char_each_line.sh -> utils/remove_prefix_from_lines.sh (已创建，删除旧文件)
- cut_string_between_special_begin_and_end.sh -> utils/extract_text_between_markers.sh (已创建，删除旧文件)
- ls_all_dirs_name.sh -> utils/list_all_directories.sh (已创建，删除旧文件)
- ls_all_files_and_dirs_name.sh -> utils/list_all_files_and_directories.sh (已创建，删除旧文件)
- get_dir_name.sh -> utils/get_directory_name.sh (已创建，删除旧文件)
- get_openresty_config_path.sh -> utils/get_openresty_path.sh
- get_cflags_and_libs_for_makefile.sh -> utils/get_pkg_config_flags.sh
- svn_revision.sh -> utils/get_svn_revision.sh
- printf_format_output.sh -> utils/demo_printf_formatting.sh (示例脚本)
- show_multi_lines.sh -> utils/demo_heredoc.sh (示例脚本)

## 网络和系统配置（移动到 network/）
- eth_name_mac_config.sh -> network/configure_ethernet_mac.sh
- deploy_openresty_locally.sh -> network/deploy_openresty.sh
- send_srt.sh -> network/send_srt_stream.sh

## 媒体工具（保持在 media_tools/，重命名文件）
- open_multi_ffmpeg_srt.sh -> media_tools/open_multiple_ffmpeg_srt.sh
- open_multi_ffmpeg_udp.sh -> media_tools/open_multiple_ffmpeg_udp.sh
- concat_audio/concat_audio.sh -> media_tools/concat_audio/concat_audio.sh (保持)
- mix_audio/ffmpeg_script.sh -> media_tools/mix_audio/mix_audio.sh

## 其他工具
- open_multi_terminal_and_exec.sh -> utils/open_multiple_terminals.sh
- auto_write_ts_key_pair.sh -> utils/update_ts_key_pair.sh
- compare_object_file_name.sh -> utils/compare_static_lib_objects.sh
- t4xx_quick_installer_china.sh -> hardware/install_netint_t4xx.sh

