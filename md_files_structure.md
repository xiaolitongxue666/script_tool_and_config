# 项目 MD 文件结构

## 根目录文档

### 核心文档（保留）

1. **readme.md** - 项目主文档
   - 项目介绍
   - 快速开始
   - 平台支持说明
   - 详细使用说明
   - 项目结构概览

2. **project_structure.md** - 项目结构说明
   - 完整的树形结构
   - 目录说明
   - 配置文件位置

3. **software_list.md** - 软件清单
   - 所有软件的详细列表
   - 平台支持情况
   - 安装脚本映射
   - 配置文件映射

4. **chezmoi_guide.md** - chezmoi 使用指南
   - chezmoi 安装
   - 基本操作命令
   - 常用工作流程
   - 高级功能
   - 故障排除

5. **macos_setup_guide.md** - macOS 部署指南
   - 前置条件
   - 部署步骤
   - 管理的配置文件
   - 后续操作
   - 日常使用建议
   - 故障排除

### 已删除的临时/过时文档

- ❌ `fix_zsh_ghostty_error.md` - 临时问题修复文档（问题已解决）
- ❌ `macos_chezmoi_status.md` - 临时问题分析文档（问题已解决）
- ❌ `macos_chezmoi_managed_files.md` - 已合并到 `macos_setup_guide.md`
- ❌ `macos_next_steps.md` - 已合并到 `macos_setup_guide.md`

## 子目录文档

### dotfiles/ 目录

- **legacy.md** - Legacy 说明文档
  - 迁移状态说明
  - 迁移映射表
  - 使用建议

### scripts/ 目录

- **readme.md** - scripts 目录说明
  - 目录结构
  - 脚本分类
  - 使用 common.sh
  - 命名规范

### scripts/chezmoi/ 目录

- **readme.md** - chezmoi 脚本说明
  - 脚本职责划分
  - 工作流程
  - 使用场景

### scripts/linux/ 目录

- **system_basic_env/usage.md** - ArchLinux 系统配置脚本使用说明
  - configure_china_mirrors.sh 使用说明
  - install_common_tools.sh 使用说明
  - 环境变量说明
  - 故障排除

- **patch_examples/readme.md** - 补丁使用示例说明
  - diff 命令使用
  - patch 命令使用
  - 示例脚本

### scripts/macos/ 目录

- **system_basic_env/readme.md** - macOS 基础工具安装脚本说明
  - 功能特性
  - 工具列表
  - 使用方法
  - 环境变量说明
  - 故障排除

### scripts/windows/ 目录

- **system_basic_env/readme.md** - Windows 基础工具安装脚本说明
  - 功能特性
  - 工具列表
  - 使用方法
  - 参数说明
  - 常见问题

## 文档分类

### 按用途分类

**入门文档：**
- `readme.md` - 项目主文档
- `macos_setup_guide.md` - macOS 部署指南

**参考文档：**
- `project_structure.md` - 项目结构
- `software_list.md` - 软件清单
- `chezmoi_guide.md` - chezmoi 使用指南

**子目录文档：**
- 各子目录的 `readme.md` 或 `usage.md` - 具体功能说明

### 按平台分类

**通用文档：**
- `readme.md`
- `project_structure.md`
- `software_list.md`
- `chezmoi_guide.md`

**macOS 特定：**
- `macos_setup_guide.md`

**Linux 特定：**
- `scripts/linux/system_basic_env/usage.md`

**Windows 特定：**
- `scripts/windows/system_basic_env/readme.md`

## 文档命名规范

所有 MD 文件已统一为小写命名：
- `readme.md` (不是 `README.md`)
- `software_list.md` (不是 `SOFTWARE_LIST.md`)
- `chezmoi_guide.md` (不是 `CHEZMOI_GUIDE.md`)
- `project_structure.md`
- `macos_setup_guide.md`

## 文档维护建议

1. **保持文档更新**：当项目结构或功能发生变化时，及时更新相关文档
2. **避免重复**：相关内容应合并到主文档，避免创建多个临时文档
3. **删除过时文档**：问题解决后，及时删除临时的问题分析文档
4. **统一命名**：所有新文档使用小写命名

## 当前文档统计

- **根目录文档**: 5 个
- **子目录文档**: 7 个
- **总计**: 12 个 MD 文件

