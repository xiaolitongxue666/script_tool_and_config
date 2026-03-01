# Arch Linux 系统配置脚本使用说明

本目录脚本用途：**Arch 专用**镜像与基础环境；通用一键安装见项目根目录 [INSTALL_GUIDE.md](../../../INSTALL_GUIDE.md)。

- **get_wsl_system_info.sh**：获取 WSL/Linux 版本与环境信息（只读）。
- **configure_china_mirrors.sh**：配置 Arch 中国镜像源。
- **install_common_tools.sh**：Arch 完整环境（镜像 + 基础包 + AUR + Neovim 等）。**已废弃**：通用一键安装请使用项目根目录 `./install.sh`，软件与 run_once 对应见 [SOFTWARE_LIST.md](../../../SOFTWARE_LIST.md)。

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

## 2. install_common_tools.sh（已废弃，仅 Arch 本地可选）

该脚本已废弃，职责已拆分到 run_once。**推荐使用项目根目录 `./install.sh`** 完成跨平台一键安装，软件与 run_once 对应见 [SOFTWARE_LIST.md](../../../SOFTWARE_LIST.md)。仅在 Arch 上需要本地执行完整环境安装时，可运行：`sudo ./install_common_tools.sh`（需 root，支持 `USE_PROXY`、`HTTP_PROXY` 等环境变量，详见脚本内注释）。

---

## 使用示例

### 示例 1：仅配置镜像源

```bash
cd ~/Code/DotfilesAndScript/script_tool_and_config/scripts/linux/system_basic_env
sudo ./configure_china_mirrors.sh
```

### 示例 2：Arch 本地完整安装（已废弃，可选）

```bash
sudo ./install_common_tools.sh   # 可选 USE_PROXY=1 或 HTTP_PROXY=... 见脚本内注释
```

---

## 脚本依赖

- `configure_china_mirrors.sh` / `install_common_tools.sh` 需 root，依赖 `scripts/common.sh`
- 系统要求：Arch Linux、网络连接、足够磁盘空间

---

## 更新说明

### 2025年11月更新

- 移除已停止服务的清华 TUNA archlinuxcn 镜像
- 更新为可用的镜像源（USTC、阿里云、腾讯云）
- 优化镜像源优先级
- 改进代理配置逻辑（默认不使用代理）

---

## 相关文件

- `get_wsl_system_info.sh` - 获取 WSL/Linux 详细版本与环境信息（只读）
- `configure_china_mirrors.sh` - 镜像源配置脚本
- `install_common_tools.sh` - 完整安装脚本（已废弃，仅 Arch 本地可选；推荐 `./install.sh`）
- `scripts/common.sh` - 通用脚本库
- `logs/system_basic_env/` - 日志目录
- `~/.config/system_basic_env/path.env` - PATH 环境变量配置

