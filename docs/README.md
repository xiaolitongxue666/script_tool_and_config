# 文档索引

本目录集中存放项目说明与指南，根目录仅保留 [README.md](../README.md) 与 [AGENTS.md](../AGENTS.md)。

## 文档清理审计结论（2026-04 / 2026-05）

- `docs/README.md`：保留，作为 docs 目录索引；由根目录 `README.md` 显式链接。
- `docs/patches/archive/README.md`：保留，作为 Neovim 历史补丁说明。
- **2026-05 已删除**：`scripts/linux/system_basic_env/INSTALL_STATUS.md`（内容已并入 `SOFTWARE_LIST.md` + `verify_installation.sh`）。
- **2026-05 已删除**：`OS_SETUP_GUIDE.md`、`TEST_PLAN_NVIM_INDEPENDENT.md`（正文已并入 `INSTALL_GUIDE.md` / `NEOVIM_AND_THIS_REPO.md`）。
- 删除策略：仅在“无外部引用 + 不再承担测试/流程证据”同时满足时再删除。

## 安装与配置

| 文档 | 说明 |
|------|------|
| [INSTALL_GUIDE.md](INSTALL_GUIDE.md) | 一键安装与首次配置入口（推荐先看）；各平台分步与故障排除 |
| [DEPLOY_TWO_PHASE.md](DEPLOY_TWO_PHASE.md) | 两阶段部署（本仓库 Phase 1 + agent-config Phase 2） |
| [SOFTWARE_LIST.md](SOFTWARE_LIST.md) | 完整软件清单与 run_once 脚本对应关系（按 OS / WSL 区分） |
| [PROJECT_MEMORY.md](PROJECT_MEMORY.md) | 项目级紧凑记忆（Agent 快速索引，详情见 PROJECT_AGENT_MEMORY） |
| [CODEWHALE.md](CODEWHALE.md) | CodeWhale 安装、WSL 快速流程与排错 |
| [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md) | 项目 Agent 可提交记忆（含 WSL 部署实测） |
| [RMUX_WINDOWS.md](RMUX_WINDOWS.md) | Windows rmux 安装、手动使用与排错（含 chezmoi 部署陷阱） |
| [TMUX_KEYBINDINGS.md](TMUX_KEYBINDINGS.md) | Tmux (Linux/macOS) 与 rmux (Windows) 快捷键速查 |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | 项目结构说明 |

## Chezmoi 与项目结构

| 文档 | 说明 |
|------|------|
| [CHEZMOI_USE_GUIDE.md](CHEZMOI_USE_GUIDE.md) | chezmoi 详细使用指南（SSH、lazyssh、配置管理） |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | 项目目录结构说明（权威来源） |

## 规范与编码

| 文档 | 说明 |
|------|------|
| [ENCODING_AND_LINE_ENDINGS.md](ENCODING_AND_LINE_ENDINGS.md) | 文件编码（UTF-8）与换行符（LF/CRLF）规范 |

## Neovim 与相关

| 文档 | 说明 |
|------|------|
| [NEOVIM_AND_THIS_REPO.md](NEOVIM_AND_THIS_REPO.md) | Neovim 与本仓库的关系、安装方式与验证清单 |
| [ZSH_STARTUP_TIME.md](ZSH_STARTUP_TIME.md) | Zsh 启动时间相关说明 |
| [patches/archive/README.md](patches/archive/README.md) | 补丁归档说明 |

## 脚本内文档

以下文档位于各脚本目录，从本目录可快速跳转：

- [scripts/common/deploy_utils/DEPLOYMENT_GUIDE.md](../scripts/common/deploy_utils/DEPLOYMENT_GUIDE.md) — 部署流程（Windows / Arch）
- [scripts/common/deploy_utils/MANUAL_ZSH_SETUP_GUIDE.md](../scripts/common/deploy_utils/MANUAL_ZSH_SETUP_GUIDE.md) — 手动 Zsh/Oh My Zsh 配置指南

> 软件安装状态与验证命令见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md) 与 `tests/`、`scripts/chezmoi/verify_installation.sh`（已移除冗余 `INSTALL_STATUS.md`）。

## 多 OS 与 WSL

- **OS**：Win10、macOS（Intel）、Linux（Ubuntu、Arch Linux）
- **WSL**：Ubuntu，视为 Linux 子类型（apt），与原生 Linux 共用 `run_on_linux`，脚本内通过 WSL 检测区分代理与路径
- 详见 [INSTALL_GUIDE.md](INSTALL_GUIDE.md) 与 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。
