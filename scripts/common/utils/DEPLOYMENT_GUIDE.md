# 部署流程指南

本指南说明如何在 Windows 和 Arch Linux 之间通过脚本进行配置部署和管理。

## 目录

- [快速开始](#快速开始)
- [日常部署流程](#日常部署流程)
- [使用管理脚本](#使用管理脚本)
- [Windows 到 Arch Linux 同步流程](#windows-到-arch-linux-同步流程)
- [常用操作命令](#常用操作命令)
- [环境变量设置](#环境变量设置)

## 快速开始

### 首次部署（Arch Linux）

```bash
# 1. 进入项目目录
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config

# 2. 运行一键安装脚本（带代理）
./install.sh --proxy http://192.168.1.76:7890

# 3. 验证部署
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi status
```

### 日常更新（Arch Linux）

```bash
# 1. 进入项目目录
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config

# 2. 使用管理脚本应用配置
./scripts/manage_dotfiles.sh apply
```

## 日常部署流程

### 方法一：使用管理脚本（推荐）

项目提供了统一的管理脚本 `scripts/manage_dotfiles.sh`，封装了所有常用操作：

```bash
# 查看帮助
./scripts/manage_dotfiles.sh help

# 应用所有配置
./scripts/manage_dotfiles.sh apply

# 查看配置状态
./scripts/manage_dotfiles.sh status

# 查看配置差异
./scripts/manage_dotfiles.sh diff

# 编辑配置文件
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 列出所有受管理的文件
./scripts/manage_dotfiles.sh list
```

### 方法二：直接使用 chezmoi 命令

```bash
# 设置环境变量（重要！）
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 应用所有配置
chezmoi apply -v

# 查看配置状态
chezmoi status

# 查看配置差异
chezmoi diff

# 编辑配置文件
chezmoi edit ~/.zshrc
```

## Windows 到 Arch Linux 同步流程

### 完整工作流程

```
Windows (开发)                    Arch Linux (部署)
    |                                    |
    | 1. 编辑配置文件                    |
    |    (chezmoi edit ~/.zshrc)         |
    |                                    |
    | 2. 提交到 Git                      |
    |    (git add .chezmoi)              |
    |    (git commit)                    |
    |    (git push)                      |
    |                                    |
    | 3. SFTP 同步项目                   |
    |    (VS Code SFTP 扩展)             |
    |    (或 sync_to_remote.sh)          |
    |                                    |
    |                             4. 应用配置
    |                                (chezmoi apply)
    |                                    |
    |                             5. 验证配置
    |                                (chezmoi status)
```

### 详细步骤

#### 步骤 1：在 Windows 上编辑配置

```bash
# 在 Windows Git Bash 中
cd /e/Code/my_code/DotfilesAndScript/script_tool_and_config

# 设置环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 编辑配置文件
chezmoi edit ~/.zshrc

# 或使用管理脚本
./scripts/manage_dotfiles.sh edit ~/.zshrc
```

#### 步骤 2：同步到 Arch Linux

**方法 A：使用 VS Code SFTP 扩展（推荐）**

1. 在 VS Code 中编辑文件后自动同步（`uploadOnSave: true`）
2. 或手动同步：`Ctrl+Shift+P` -> `SFTP: Upload Project`

**方法 B：使用同步脚本**

```bash
# 在 Windows Git Bash 中
./scripts/common/utils/sync_to_remote.sh
```

#### 步骤 3：在 Arch Linux 上应用配置

```bash
# SSH 到 Arch Linux
ssh leonli@192.168.1.109

# 进入项目目录
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config

# 应用配置（使用管理脚本）
./scripts/manage_dotfiles.sh apply

# 或直接使用 chezmoi
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

## 使用管理脚本

### 可用命令

```bash
./scripts/manage_dotfiles.sh <command> [options]
```

**命令列表**：

| 命令 | 说明 | 示例 |
|------|------|------|
| `install` | 安装 chezmoi 并初始化仓库 | `./scripts/manage_dotfiles.sh install` |
| `apply` | 应用所有配置到系统 | `./scripts/manage_dotfiles.sh apply` |
| `update` | 更新配置（拉取仓库后使用） | `./scripts/manage_dotfiles.sh update` |
| `diff` | 查看配置差异 | `./scripts/manage_dotfiles.sh diff` |
| `status` | 查看配置状态 | `./scripts/manage_dotfiles.sh status` |
| `edit <file>` | 编辑配置文件 | `./scripts/manage_dotfiles.sh edit ~/.zshrc` |
| `list` | 列出所有受管理的文件 | `./scripts/manage_dotfiles.sh list` |
| `cd` | 进入 chezmoi 源状态目录 | `./scripts/manage_dotfiles.sh cd` |
| `help` | 显示帮助信息 | `./scripts/manage_dotfiles.sh help` |

### 常用操作示例

```bash
# 1. 应用所有配置
./scripts/manage_dotfiles.sh apply

# 2. 查看哪些文件有变更
./scripts/manage_dotfiles.sh status

# 3. 查看具体差异
./scripts/manage_dotfiles.sh diff

# 4. 编辑 zsh 配置
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 5. 查看所有受管理的文件
./scripts/manage_dotfiles.sh list
```

## 常用操作命令

### 查看配置状态

```bash
# 使用管理脚本
./scripts/manage_dotfiles.sh status

# 或直接使用 chezmoi
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi status
```

### 查看配置差异

```bash
# 使用管理脚本
./scripts/manage_dotfiles.sh diff

# 或直接使用 chezmoi
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi diff

# 查看特定文件的差异
chezmoi diff ~/.zshrc
```

### 应用配置

```bash
# 使用管理脚本
./scripts/manage_dotfiles.sh apply

# 或直接使用 chezmoi
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v

# 预览将要应用的更改（不实际应用）
chezmoi apply --dry-run
```

### 编辑配置

```bash
# 使用管理脚本
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 或直接使用 chezmoi
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi edit ~/.zshrc
```

### 添加新配置

```bash
# 添加新配置文件到管理
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi add ~/.new_config

# 编辑新配置
chezmoi edit ~/.new_config

# 应用配置
chezmoi apply ~/.new_config
```

### 更新配置到仓库

```bash
# 如果配置文件在系统上被修改，更新到仓库
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi re-add ~/.zshrc

# 或重新添加所有文件
chezmoi re-add
```

## 环境变量设置

### 临时设置（当前终端会话）

```bash
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
```

### 永久设置（添加到 Shell 配置）

**Arch Linux (Zsh)**：

```bash
# 添加到 ~/.zshrc
echo 'export CHEZMOI_SOURCE_DIR="$HOME/Code/DotfilesAndScript/script_tool_and_config/.chezmoi"' >> ~/.zshrc
source ~/.zshrc
```

**Windows (Git Bash)**：

```bash
# 添加到 ~/.bash_profile
echo 'export CHEZMOI_SOURCE_DIR="/e/Code/my_code/DotfilesAndScript/script_tool_and_config/.chezmoi"' >> ~/.bash_profile
source ~/.bash_profile
```

### 使用管理脚本（自动设置）

管理脚本会自动设置环境变量，无需手动设置：

```bash
# 所有命令都会自动设置 CHEZMOI_SOURCE_DIR
./scripts/manage_dotfiles.sh apply
./scripts/manage_dotfiles.sh status
```

## 完整部署示例

### 场景：修改 zsh 配置并部署到 Arch Linux

**在 Windows 上**：

```bash
# 1. 进入项目目录
cd /e/Code/my_code/DotfilesAndScript/script_tool_and_config

# 2. 编辑配置
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 3. 应用配置到本地（测试）
./scripts/manage_dotfiles.sh apply

# 4. 同步到远端（VS Code SFTP 自动同步，或手动运行）
# Ctrl+Shift+P -> SFTP: Upload Project
```

**在 Arch Linux 上**：

```bash
# 1. SSH 到 Arch Linux
ssh leonli@192.168.1.109

# 2. 进入项目目录
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config

# 3. 应用配置
./scripts/manage_dotfiles.sh apply

# 4. 验证配置
./scripts/manage_dotfiles.sh status
```

## 自动化部署脚本

### 创建快速部署脚本

可以创建一个简单的部署脚本：

```bash
#!/bin/bash
# deploy.sh - 快速部署脚本

cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

使用方法：

```bash
chmod +x deploy.sh
./deploy.sh
```

## 故障排除

### 问题：chezmoi 找不到源状态目录

**解决**：
```bash
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
```

### 问题：配置没有应用

**解决**：
```bash
# 检查源状态目录是否存在
ls -la .chezmoi/

# 检查环境变量
echo $CHEZMOI_SOURCE_DIR

# 重新应用
./scripts/manage_dotfiles.sh apply
```

### 问题：配置文件冲突

**解决**：
```bash
# 查看差异
./scripts/manage_dotfiles.sh diff ~/.zshrc

# 如果确定要覆盖
chezmoi apply --force ~/.zshrc

# 或先备份
cp ~/.zshrc ~/.zshrc.backup
chezmoi apply ~/.zshrc
```

## 参考文档

- [chezmoi 使用指南](../../docs/chezmoi_use_guide.md)
- [SFTP 同步指南](./SFTP_SYNC_GUIDE.md)
- [项目 README](../../README.md)

