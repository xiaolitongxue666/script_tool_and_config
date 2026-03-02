# Scripts 目录

本目录包含按操作系统分类的脚本工具集合。一键安装与首次使用见项目根目录 [docs/INSTALL_GUIDE.md](../docs/INSTALL_GUIDE.md)。

## 目录结构

- **common.sh**、**README.md**（本文件）
- **common/**：跨平台脚本（utils、project_tools、ffmpeg-magic、git_templates、patch_examples、shc、auto_edit_redis_config、container_dev_env 等）
- **linux/**：Linux 专用（system_basic_env、network、hardware）
- **macos/**：macOS 专用
- **windows/**：Windows 专用（windows_scripts、system_basic_env）
- **chezmoi/**、**migration/**

完整目录树与脚本列表见 [project_structure.md](../docs/project_structure.md)。

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

跨平台脚本位于 `common/` 目录下，可在多个系统使用：
- **utils/**: 通用工具脚本
- **project_tools/**: 项目生成和管理工具
- **ffmpeg-magic/**: FFmpeg 相关脚本（多路推流、音频拼接/混音、SRT 推流、Netint 安装等）
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

**注意**:
- 从 `common/` 子目录引用时，路径为 `../../../common.sh`（向上三级到 scripts 根目录）
- 从 `linux/` 子目录引用时，路径为 `../../common.sh`（向上两级到 scripts 根目录）

命名规范与示例见 [AGENTS.md](../AGENTS.md#脚本分类和命名规范)。

## 注意事项

- 所有脚本注释已翻译为中文
- 所有脚本遵循统一的命名规范
- 优化后的脚本使用 `common.sh` 中的函数
- `common.sh` 放在 `scripts/` 根目录，便于所有子目录引用
- 脚本按操作系统分类组织，跨平台脚本位于 `common/` 目录，平台特定脚本位于对应平台目录

