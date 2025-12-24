# SFTP 同步指南

本指南说明如何使用 SFTP 将项目同步到远端 Arch Linux 系统。

## 目录

- [概述](#概述)
- [SFTP 配置说明](#sftp-配置说明)
- [使用方法](#使用方法)
- [同步脚本](#同步脚本)
- [远端初始化](#远端初始化)
- [常见问题](#常见问题)

## 概述

项目支持通过两种方式同步到远端：

1. **VS Code SFTP 扩展**：自动同步（推荐用于开发时实时同步）
2. **rsync 同步脚本**：手动同步（推荐用于完整同步）

## SFTP 配置说明

### 配置文件位置

`.vscode/sftp.json`

### 主要配置项

```json
{
  "name": "Script Tool and Config Sync",
  "host": "192.168.1.109",
  "protocol": "sftp",
  "port": 22,
  "username": "leonli",
  "privateKeyPath": "~/.ssh/id_rsa",
  "remotePath": "/home/leonli/Code/DotfilesAndScript/script_tool_and_config",
  "uploadOnSave": true,
  "concurrency": 3
}
```

### 配置说明

- **host**: 远端服务器地址
- **username**: SSH 用户名
- **privateKeyPath**: SSH 私钥路径
- **remotePath**: 远端项目路径
- **uploadOnSave**: 保存时自动上传
- **concurrency**: 并发连接数（已优化为 3，提高同步速度）

### 忽略规则

SFTP 配置已优化，自动忽略以下文件：

- Git 相关：`.git`, `.gitignore`, `.gitmodules`, `.gitattributes`
- 编辑器配置：`.vscode`, `.claude`, `.idea`
- 临时文件：`*.tmp`, `*.log`, `*.bak`, `*.backup`
- 系统文件：`.DS_Store`, `Thumbs.db`, `Desktop.ini`
- 构建产物：`build/`, `dist/`, `bin/`, `lib/`, `obj/`
- 日志文件：`logs/`, `scripts/**/log`
- 敏感信息：`*.key`, `*.pem`, `*.cert`, `.env*`

**重要**：`.chezmoi/` 目录**必须同步**，这是 chezmoi 的源状态目录。

## 使用方法

### 方法一：VS Code SFTP 扩展（自动同步）

1. **安装扩展**
   - 在 VS Code 中安装 [SFTP 扩展](https://marketplace.visualstudio.com/items?itemName=Natizyskunk.sftp)

2. **配置已就绪**
   - 配置文件已位于 `.vscode/sftp.json`
   - 根据实际情况修改 `host`、`username`、`remotePath` 等参数

3. **使用命令**
   - `Ctrl+Shift+P` (Windows/Linux) 或 `Cmd+Shift+P` (macOS)
   - 输入 `SFTP: Upload Project` - 上传整个项目
   - 输入 `SFTP: Download Project` - 下载整个项目
   - 输入 `SFTP: Sync Local -> Remote` - 同步到远端
   - 输入 `SFTP: Sync Remote -> Local` - 从远端同步

4. **自动同步**
   - `uploadOnSave: true` 已启用，保存文件时自动上传
   - `watcher.autoUpload: true` 已启用，文件变更时自动上传

### 方法二：rsync 同步脚本（手动同步）

使用项目提供的同步脚本进行完整同步：

```bash
# 在项目根目录运行
./scripts/common/utils/sync_to_remote.sh
```

**脚本功能**：
- 使用 rsync 进行高效同步
- 自动排除不需要同步的文件
- 显示同步进度
- 支持 `--delete` 选项（同步删除远端文件）

**环境变量**（可选）：
```bash
export REMOTE_HOST="192.168.1.109"
export REMOTE_USER="leonli"
export REMOTE_PATH="/home/leonli/Code/DotfilesAndScript/script_tool_and_config"

./scripts/common/utils/sync_to_remote.sh
```

## 同步脚本

### sync_to_remote.sh

**功能**：将本地项目同步到远端 Arch Linux

**使用方法**：
```bash
cd /path/to/script_tool_and_config
./scripts/common/utils/sync_to_remote.sh
```

**特点**：
- ✅ 自动检测操作系统（Windows/Linux/macOS）
- ✅ 优先使用 rsync（高效可靠）
- ✅ Windows 备用方案（使用 tar + ssh）
- ✅ 自动排除临时文件、日志、构建产物
- ✅ 显示同步进度
- ✅ 支持 SSH 密钥认证
- ✅ 同步删除远端文件（`--delete`，仅 rsync）

**Windows 环境说明**：

脚本在 Windows Git Bash 中会自动检测并使用备用方案：

1. **如果已安装 rsync**（推荐）
   - 在 MSYS2 中安装：`pacman -S rsync`
   - 脚本会自动使用 rsync 同步

2. **如果未安装 rsync**（备用方案）
   - 脚本会使用 `tar + ssh` 进行同步
   - 功能有限，但仍可完成同步
   - 会提示安装 rsync 或使用 VS Code SFTP 扩展

**推荐方案**：
- **Windows 用户**：推荐使用 VS Code SFTP 扩展（功能最强大）
- **Linux/macOS 用户**：使用 rsync 同步脚本（高效可靠）

**注意事项**：
- 首次同步建议先备份远端文件
- 确保 SSH 密钥已配置
- 确保远端目录存在且有写权限
- Windows 上建议安装 rsync 或使用 VS Code SFTP 扩展

## 远端初始化

### remote_init.sh

在远端 Arch Linux 上运行此脚本初始化项目：

```bash
# 在远端 Arch Linux 上
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config
./scripts/common/utils/remote_init.sh
```

**脚本功能**：
- ✅ 检查操作系统
- ✅ 初始化 Git Submodule（如果需要）
- ✅ 运行 `install.sh` 安装 chezmoi 等工具
- ✅ 验证安装结果
- ✅ 检查配置状态

**或直接运行 install.sh**：
```bash
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config
./install.sh
```

## 完整工作流程

### 首次同步和初始化

1. **在 Windows 上同步项目**
   ```bash
   # 方法一：使用 VS Code SFTP 扩展
   # Ctrl+Shift+P -> SFTP: Upload Project

   # 方法二：使用同步脚本
   ./scripts/common/utils/sync_to_remote.sh
   ```

2. **在远端 Arch Linux 上初始化**
   ```bash
   ssh leonli@192.168.1.109
   cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config
   ./scripts/common/utils/remote_init.sh
   # 或直接运行
   ./install.sh
   ```

3. **验证配置**
   ```bash
   export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
   chezmoi status
   chezmoi diff
   ```

### 日常开发流程

1. **在 Windows 上编辑**
   - 编辑文件后自动同步（`uploadOnSave: true`）
   - 或手动运行同步脚本

2. **在远端 Arch Linux 上应用配置**
   ```bash
   export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
   chezmoi apply -v
   ```

3. **查看配置差异**
   ```bash
   export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
   chezmoi diff
   ```

## 常见问题

### Q1: SFTP 同步失败

**问题**：连接超时或认证失败

**解决**：
1. 检查网络连接
2. 检查 SSH 密钥配置：`ssh -i ~/.ssh/id_rsa leonli@192.168.1.109`
3. 检查 `.vscode/sftp.json` 中的配置
4. 查看 VS Code 输出面板中的 SFTP 日志

### Q2: 某些文件没有同步

**问题**：文件在 ignore 列表中

**解决**：
1. 检查 `.vscode/sftp.json` 中的 `ignore` 规则
2. 确认文件不在忽略列表中
3. 使用 `SFTP: Upload File` 手动上传特定文件

### Q3: .chezmoi 目录未同步

**问题**：`.chezmoi/` 目录必须同步，否则 chezmoi 无法工作

**解决**：
1. 确认 `.chezmoi/` 不在 ignore 列表中
2. 使用 `SFTP: Upload Folder` 手动上传 `.chezmoi/` 目录
3. 或使用同步脚本：`./scripts/common/utils/sync_to_remote.sh`

### Q4: 远端初始化失败

**问题**：install.sh 执行失败

**解决**：
1. 检查网络连接（需要下载 chezmoi）
2. 检查权限：确保有执行权限 `chmod +x install.sh`
3. 检查依赖：确保已安装 bash、git 等基础工具
4. 查看错误日志

### Q5: 同步速度慢

**问题**：大量文件同步耗时

**解决**：
1. 使用 rsync 同步脚本（更高效）
2. 增加 `concurrency` 值（已优化为 3）
3. 减少同步的文件数量（优化 ignore 规则）
4. 使用 `SFTP: Sync Local -> Remote` 只同步变更的文件

## 参考链接

- [VS Code SFTP 扩展文档](https://github.com/Natizyskunk/vscode-sftp/wiki)
- [chezmoi 官方文档](https://www.chezmoi.io/docs/)
- [rsync 文档](https://linux.die.net/man/1/rsync)

