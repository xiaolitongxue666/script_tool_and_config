# Arch Linux 系统配置脚本使用说明

本文档说明如何使用 `configure_china_mirrors.sh` 和 `install_common_tools.sh` 两个脚本。

---

## 1. configure_china_mirrors.sh - 配置中国镜像源

### 功能说明
快速配置 Arch Linux 的中国镜像源，包括：
- 主仓库镜像（core, extra, community）
- archlinuxcn 社区仓库镜像（2025年11月最新可用镜像）

### 使用方法

```bash
# 需要 root 权限
sudo ./configure_china_mirrors.sh
```

### 配置内容

**主仓库镜像（按优先级排序）：**
1. 阿里云 (HTTPS)
2. 中科大 USTC (HTTPS)
3. 清华大学 (HTTPS)
4. 163 (HTTP)
5. 腾讯云 (HTTPS)

**archlinuxcn 仓库镜像：**
- 中科大 USTC
- 阿里云
- 腾讯云

> **注意**：清华 TUNA 的 archlinuxcn 镜像已停止服务（2025年10月底），已从配置中移除。

### 备份说明
脚本会自动备份：
- `/etc/pacman.d/mirrorlist.backup`
- `/etc/pacman.conf.backup`

### 执行后操作
脚本会自动执行 `pacman -Syy` 强制同步数据库。

---

## 2. install_common_tools.sh - 安装常用工具

### 功能说明
完整的 Arch Linux 系统工具安装脚本，包括：
- 配置中国镜像源
- 优化 pacman 配置
- 安装基础开发工具
- 安装 AUR 助手（yay/paru）
- 安装编程语言工具（uv, fnm）
- 安装 Neovim 及 Python 工具
- 安装字体和 Shell 工具

### 使用方法

#### 基本用法

```bash
# 需要 root 权限
sudo ./install_common_tools.sh
```

#### 使用代理（可选）

如果需要使用代理，设置环境变量：

```bash
# 启用代理（使用默认代理地址 192.168.1.76:7890）
USE_PROXY=1 sudo ./install_common_tools.sh

# 或指定自定义代理地址
HTTP_PROXY=http://your-proxy:port USE_PROXY=1 sudo ./install_common_tools.sh
```

#### 自定义代理地址

```bash
# 设置自定义代理
export DEFAULT_PROXY_URL=http://your-proxy:port
USE_PROXY=1 sudo ./install_common_tools.sh
```

### 环境变量说明

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `USE_PROXY` | 是否启用代理 | `0` (禁用) |
| `HTTP_PROXY` | HTTP 代理地址 | - |
| `HTTPS_PROXY` | HTTPS 代理地址 | - |
| `DEFAULT_PROXY_URL` | 默认代理地址 | `http://192.168.1.76:7890` |

### 安装内容

#### 基础工具
- `base-devel` - 基础开发工具
- `git`, `curl`, `wget`, `aria2` - 网络工具
- `tmux`, `starship` - 终端工具
- `fzf`, `ripgrep`, `fd`, `bat`, `eza` - 文件搜索和查看工具
- `neovim` - 编辑器
- `gcc`, `make`, `cmake` - 编译工具

#### AUR 助手
- 自动检测并安装 `yay` 或 `paru`（优先 yay）

#### 编程语言工具
- **uv** - Python 包管理器
- **fnm** - Node.js 版本管理器

#### Neovim 配置
- 自动安装 Neovim 配置（如果存在 Git Submodule）
- 创建 Python 虚拟环境并安装工具：
  - `pynvim`, `pyright`, `ruff-lsp`, `debugpy`
  - `black`, `isort`, `flake8`, `mypy`

#### 字体
- FiraMono Nerd Font

#### Shell 工具
- `zsh` 和 `oh-my-zsh`

### 日志和状态

脚本会创建以下目录和文件：

- **日志目录**: `~/Code/DotfilesAndScript/script_tool_and_config/logs/system_basic_env/`
- **状态目录**: `~/.local/share/system_basic_env/`
- **配置目录**: `~/.config/system_basic_env/`
- **PATH 环境文件**: `~/.config/system_basic_env/path.env`

### 执行流程

1. 检查系统（Arch Linux）
2. 检测安装用户（用于 AUR 构建）
3. 配置镜像源
4. 优化 pacman 配置
5. 更新系统
6. 安装 archlinuxcn-keyring（如果配置了 archlinuxcn 源）
7. 安装软件包
8. 安装 AUR 助手
9. 安装编程工具
10. 安装 Neovim 配置
11. 安装字体和 Shell 工具

### 注意事项

1. **需要 root 权限**：脚本会修改系统配置，必须使用 `sudo` 运行
2. **网络连接**：需要稳定的网络连接下载软件包
3. **时间消耗**：完整安装可能需要较长时间，请耐心等待
4. **代理设置**：默认不使用代理，如需使用请设置 `USE_PROXY=1`
5. **archlinuxcn 源**：如果 archlinuxcn 源无法访问，脚本会继续执行，但相关软件包可能无法安装

### 故障排除

#### 如果 archlinuxcn 源无法访问

脚本会自动处理，但如果需要手动修复：

```bash
# 编辑 pacman.conf，确保只使用可用的镜像
sudo nano /etc/pacman.conf

# 手动安装 keyring
sudo pacman -Sy archlinuxcn-keyring
```

#### 如果代理测试失败

```bash
# 禁用代理
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

# 或设置 NO_PROXY=1
NO_PROXY=1 sudo ./install_common_tools.sh
```

#### 查看详细日志

```bash
# 日志文件位置
ls -lh ~/Code/DotfilesAndScript/script_tool_and_config/logs/system_basic_env/
```

---

## 使用示例

### 示例 1：仅配置镜像源

```bash
cd ~/Code/DotfilesAndScript/script_tool_and_config/scripts/linux/system_basic_env
sudo ./configure_china_mirrors.sh
```

### 示例 2：完整安装（不使用代理）

```bash
cd ~/Code/DotfilesAndScript/script_tool_and_config/scripts/linux/system_basic_env
sudo ./install_common_tools.sh
```

### 示例 3：完整安装（使用代理）

```bash
cd ~/Code/DotfilesAndScript/script_tool_and_config/scripts/linux/system_basic_env
USE_PROXY=1 sudo ./install_common_tools.sh
```

### 示例 4：使用自定义代理

```bash
cd ~/Code/DotfilesAndScript/script_tool_and_config/scripts/linux/system_basic_env
HTTP_PROXY=http://192.168.1.100:8080 USE_PROXY=1 sudo ./install_common_tools.sh
```

---

## 脚本依赖

### install_common_tools.sh 依赖

- `scripts/common.sh` - 通用脚本库（必须存在）
- Git 仓库结构（用于 Neovim 配置安装）

### 系统要求

- Arch Linux 系统
- root 权限
- 网络连接
- 足够的磁盘空间

---

## 更新说明

### 2025年11月更新

- 移除已停止服务的清华 TUNA archlinuxcn 镜像
- 更新为可用的镜像源（USTC、阿里云、腾讯云）
- 优化镜像源优先级
- 改进代理配置逻辑（默认不使用代理）

---

## 相关文件

- `configure_china_mirrors.sh` - 镜像源配置脚本
- `install_common_tools.sh` - 完整安装脚本
- `scripts/common.sh` - 通用脚本库
- `logs/system_basic_env/` - 日志目录
- `~/.config/system_basic_env/path.env` - PATH 环境变量配置

