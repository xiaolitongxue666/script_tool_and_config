# Bash 配置

Bash (Bourne Again Shell) 是大多数 Linux 和 macOS 系统的默认 Shell。

## 配置文件结构

```
bash/
├── config.sh           # 统一配置文件（自动检测系统）
├── install.sh          # 自动安装和配置脚本（支持多平台，包含配置同步和备份）
└── README.md           # 本文件
```

## 使用方法

### 自动安装配置

使用安装脚本自动检测系统并安装对应配置（包含自动备份）：

```bash
cd dotfiles/bash
chmod +x install.sh
./install.sh
```

安装脚本会自动：
- 检测操作系统（macOS/Linux/Windows）
- 备份现有配置文件（如果存在）
- 将配置添加到对应的配置文件（`.bashrc` 或 `.bash_profile`）

### 手动复制配置

统一配置文件会自动检测系统，只需在 `.bashrc` 或 `.bash_profile` 中添加：

```bash
# 在 ~/.bashrc 或 ~/.bash_profile 中添加
source /path/to/dotfiles/bash/config.sh
```

## 配置文件位置

- **统一配置**: `dotfiles/bash/config.sh`（自动检测系统）
- **用户配置**: 
  - **macOS**: `~/.bash_profile` 或 `~/.bashrc`
  - **Linux**: `~/.bashrc`
  - **Windows (Git Bash)**: `~/.bash_profile`

## 统一配置说明

配置文件使用条件判断自动检测操作系统并加载对应配置：
- **macOS**: 自动加载 macOS 特定配置（SDKMAN、NVM、Cargo、Postgres 等）
- **Windows**: 自动加载 Windows 特定配置（Docker 工作区、oh-my-posh、Starship 等）
- **Linux**: 自动加载 Linux 特定配置（可扩展）
- **通用配置**: 所有平台共享的别名和设置

## 重新加载配置

```bash
# 重新加载配置
source ~/.bash_profile  # macOS/Windows
source ~/.bashrc        # Linux
```

## 参考链接

- [Bash 官方文档](https://www.gnu.org/software/bash/manual/)
- [Bash 参考手册](https://www.gnu.org/software/bash/manual/bash.html)

