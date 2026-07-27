# chezmoi 相关脚本说明

本目录：安装 chezmoi、跨平台安装函数、apply/代理/锁封装。一键安装见 [docs/INSTALL_GUIDE.md](../../docs/INSTALL_GUIDE.md)。

## 模块划分

| 文件 | 职责 |
|------|------|
| `install_chezmoi.sh` | 安装 chezmoi CLI |
| `detect_platform.sh` | 平台 / 包管理器检测 SSOT |
| `packages.conf` | common-tools 包名 SSOT |
| `software_policies.sh` | 升级策略 + 解析 `packages.conf` |
| `brew_macos_network.sh` | 代理辅助 + macOS Homebrew 网络策略 |
| `package_install.sh` | `install_package` / 升级辅助 |
| `common_install.sh` | 聚合入口（source 上述模块）+ `load_run_once_context` |
| `chezmoi_proxy.sh` | 代理检测与设置 |
| `chezmoi_lock.sh` | 锁检测与释放 |
| `chezmoi_apply.sh` | apply/status/diff、override-data、WT 同步 |
| `chezmoi_core.sh` | 核心聚合入口（source proxy/lock/apply） |
| `ensure_platform_software.sh` | 补装缺失 + 按策略升级 |
| `install_helpers.sh` | 安装状态报告 |
| `config_mappings.sh` | 配置路径映射 SSOT |
| `verify_installation.sh` | 安装后验证 |
| `diagnose_chezmoi.sh` / `audit_configs.sh` | 手工诊断 / 审计 |

## 调用约定

```bash
# 日常（推荐）
./scripts/manage_dotfiles.sh apply   # 内含 --force + Windows override-data
./deploy.sh                          # 增量；不内联安装 OMZ
./install.sh                         # 首次六步

# run_once 模板内
source "${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"
export PROXY="${PROXY:-http://127.0.0.1:7890}"
load_run_once_context "$SCRIPT_DIR" "install-xxx"
```

## OMZ / 插件

- **SSOT**：`.chezmoi/.chezmoiexternal.toml.tmpl`（仅 linux/darwin）
- **zsh 二进制**：`run_once_install-zsh.sh.tmpl`
- **诊断**：`scripts/common/deploy_utils/check_zsh_omz.sh`（deploy 末尾）
- **手工修复（次要）**：`manual_zsh_setup.sh` — 非常规路径，优先 `manage_dotfiles.sh apply`

## 注意

- `chezmoi apply` 须 `--force`（由 `chezmoi_run_apply` 注入）
- Windows：禁止裸 `chezmoi status/diff/apply`（缺 `windows_git_*` override）
- CLI 不读 `CHEZMOI_SOURCE_DIR`；`sourceDir` 写在 `~/.config/chezmoi/chezmoi.toml`
