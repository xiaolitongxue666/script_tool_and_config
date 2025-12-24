# 同步脚本快速使用指南

## Windows 用户

### 方法一：使用 VS Code SFTP 扩展（推荐）

1. 安装 [SFTP 扩展](https://marketplace.visualstudio.com/items?itemName=Natizyskunk.sftp)
2. 配置文件已就绪：`.vscode/sftp.json`
3. 使用命令：
   - `Ctrl+Shift+P` -> `SFTP: Upload Project` - 上传整个项目
   - `Ctrl+Shift+P` -> `SFTP: Sync Local -> Remote` - 同步到远端

### 方法二：使用同步脚本

```bash
# 在 Git Bash 中运行
./scripts/common/utils/sync_to_remote.sh
```

**如果提示 rsync 未安装**：
- 脚本会自动使用备用方案（tar + ssh）
- 或安装 rsync：在 MSYS2 中运行 `pacman -S rsync`

## Linux/macOS 用户

### 使用同步脚本（推荐）

```bash
# 确保已安装 rsync
# Arch Linux: sudo pacman -S rsync
# Ubuntu/Debian: sudo apt-get install rsync
# macOS: brew install rsync

./scripts/common/utils/sync_to_remote.sh
```

## 配置参数

可以通过环境变量自定义：

```bash
export REMOTE_HOST="192.168.1.109"
export REMOTE_USER="leonli"
export REMOTE_PATH="/home/leonli/Code/DotfilesAndScript/script_tool_and_config"

./scripts/common/utils/sync_to_remote.sh
```

## 远端初始化

同步完成后，在远端 Arch Linux 上运行：

```bash
cd /home/leonli/Code/DotfilesAndScript/script_tool_and_config
./scripts/common/utils/remote_init.sh
# 或直接运行
./install.sh
```

## 详细文档

查看完整文档：`scripts/common/utils/SFTP_SYNC_GUIDE.md`

