# Neovim 仓库 install.sh 与本项目协作要求

本仓库的 `run_once_install-neovim-config` 会将 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim) 克隆到 `~/.config/nvim` 并执行其中的 `install.sh`，同时注入 `PROJECT_ROOT` 与 `COMMON_LIB` 环境变量（指向本仓库根目录与 `scripts/common.sh`）。

为使「单独克隆 nvim 仓库使用」与「在本项目 run_once 之后运行」两种方式都可用，上游 nvim 仓库的 `install.sh` 建议满足以下要求。

## 1. PROJECT_ROOT / COMMON_LIB 环境变量

- 若已设置环境变量 `PROJECT_ROOT` 或 `COMMON_LIB`，则优先使用，不依赖 `SCRIPT_DIR/../..` 推导。
- 若未设置或 `COMMON_LIB` 指向的文件不存在：不 source 外部 common.sh，在脚本内提供最小实现（如 `log_info`、`log_error`、`error_exit`、`start_script`、`end_script`、`ensure_directory`），避免依赖本仓库路径。

## 2. 同源时跳过部署与备份

- 在 `backup_existing_config` 与 `deploy_config` 前，用 `pwd -P` 或等价方式比较 `SCRIPT_DIR` 与 `NVIM_CONFIG_DIR` 的规范路径；若指向同一目录，则跳过备份和部署，仅做环境准备（venv、node、lazy 等）。

## 3. check_submodule 放宽

- 当配置即 clone 目录时，不要求「submodule 已初始化」；仅检测 `init.lua` 或 `lua/` 是否存在即可。

## 4. uv / fnm 按需安装

- 将「缺失则 error_exit」改为：先检测 `command -v uv` / `command -v fnm`；若缺失则尝试安装（官方安装脚本或系统包管理器）；安装失败再 error_exit。这样本项目先执行 00-install-version-managers 时已安装则跳过，单独用 nvim 时能自装。

## 5. fnm/uv 所管理的版本与环境

- **fnm**：除检测 fnm 是否存在外，检测当前是否有可用 Node 版本（如 `fnm list` 有 LTS/default 且 `node` 可用）；若无则执行 `fnm install lts/*` 并 `fnm use`。
- **uv**：除检测 uv 是否存在外，检测 nvim 使用的 Python 环境（如 `~/.config/nvim/venv/nvim-python` 及 pynvim）是否存在且完整；若无则用 `uv venv` 创建、`uv pip install` 安装 pynvim 等，并在配置中体现 `python3_host_prog` / `node_host_prog`。

## 6. Nerd Font 检测与按需安装

- 新增一步：检测与 run_once_install-nerd-fonts 相同路径（Linux: `/usr/local/share/fonts/FiraMono-NerdFont`，macOS: `~/Library/Fonts`、`/Library/Fonts` 或 `brew list --cask font-fira-mono-nerd-font`）；未检测到则执行相同安装逻辑（版本/URL 与父项目一致），已安装则跳过。

## 7. fd/ripgrep 可选

- 检测后缺失可 log 提示或按需安装，不强制。

---

以上逻辑已在本项目方案 B 中实现过；因本仓库已移除 `dotfiles/nvim` 子模块，若上游 nvim 仓库尚未包含这些改动，需在 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim) 的 `install.sh` 中按上述要求修改或合并对应 patch。
