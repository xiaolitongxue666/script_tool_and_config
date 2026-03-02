# 文档索引

本目录集中存放项目说明与指南，根目录仅保留 [README.md](../README.md) 与 [AGENTS.md](../AGENTS.md)。

## 安装与配置

| 文档 | 说明 |
|------|------|
| [INSTALL_GUIDE.md](INSTALL_GUIDE.md) | 一键安装与首次配置入口（推荐先看）；各平台分步与故障排除 |
| [os_setup_guide.md](os_setup_guide.md) | Windows / macOS / Linux 分步安装指南与前置条件 |
| [SOFTWARE_LIST.md](SOFTWARE_LIST.md) | 完整软件清单与 run_once 脚本对应关系（按 OS / WSL 区分） |
| [VERIFICATION_RESULT.md](VERIFICATION_RESULT.md) | 验证结果示例/模板；实际报告由 `scripts/chezmoi/verify_installation.sh` 生成；安装后 SSH 验证见 [INSTALL_GUIDE.md](INSTALL_GUIDE.md) 或 WSL/Linux 下运行 `scripts/linux/system_basic_env/verify_wsl_ssh.sh` |

## Chezmoi 与项目结构

| 文档 | 说明 |
|------|------|
| [chezmoi_use_guide.md](chezmoi_use_guide.md) | chezmoi 详细使用指南（SSH、lazyssh、配置管理） |
| [project_structure.md](project_structure.md) | 项目目录结构说明（权威来源） |

## 规范与编码

| 文档 | 说明 |
|------|------|
| [ENCODING_AND_LINE_ENDINGS.md](ENCODING_AND_LINE_ENDINGS.md) | 文件编码（UTF-8）与换行符（LF/CRLF）规范 |

## Neovim 与相关

| 文档 | 说明 |
|------|------|
| [NEOVIM_AND_THIS_REPO.md](NEOVIM_AND_THIS_REPO.md) | Neovim 与本仓库的关系、安装方式 |
| [TEST_PLAN_NVIM_INDEPENDENT.md](TEST_PLAN_NVIM_INDEPENDENT.md) | Neovim 独立化相关手动验证计划 |
| [ZSH_STARTUP_TIME.md](ZSH_STARTUP_TIME.md) | Zsh 启动时间相关说明 |
| [patches/archive/README.md](patches/archive/README.md) | 补丁归档说明 |

## 脚本内文档

以下文档位于各脚本目录，从本目录可快速跳转：

- [scripts/linux/system_basic_env/INSTALL_STATUS.md](../scripts/linux/system_basic_env/INSTALL_STATUS.md) — 当前环境验证清单与检查命令（WSL/Ubuntu、Arch）
- [scripts/common/utils/DEPLOYMENT_GUIDE.md](../scripts/common/utils/DEPLOYMENT_GUIDE.md) — 部署流程（Windows / Arch）
- [scripts/common/utils/MANUAL_ZSH_SETUP_GUIDE.md](../scripts/common/utils/MANUAL_ZSH_SETUP_GUIDE.md) — 手动 Zsh/Oh My Zsh 配置指南

## 多 OS 与 WSL

- **OS**：Win10、macOS（Intel）、Linux（Ubuntu、Arch Linux）
- **WSL**：Ubuntu，视为 Linux 子类型（apt），与原生 Linux 共用 `run_on_linux`，脚本内通过 WSL 检测区分代理与路径
- 详见 [INSTALL_GUIDE.md](INSTALL_GUIDE.md) 与 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。
