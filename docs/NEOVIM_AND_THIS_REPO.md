# Neovim 与本仓库的关系

## 关系说明

- **nvim**：完全独立项目（独立仓库 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim)），本仓库不修改 nvim 仓库内任何代码。
- **本仓库职责**：一键安装时将 nvim 仓库克隆到目标位置（如 `~/.config/nvim`），然后调用其中的 `install.sh`，**不注入**本仓库路径（如 `PROJECT_ROOT`、`COMMON_LIB`）。
- **所有 OS 与 WSL**：上述规则在 Linux、macOS、Windows、WSL 上一致。

## run_once 执行顺序

依赖顺序（字母序需保证）：

1. **run_once_00-install-version-managers** — 安装 uv、fnm（及可选 rustup）
2. **run_once_install-neovim** — 安装 Neovim 二进制（0.11+）
3. **run_once_install-neovim-config** — 若 `~/.config/nvim` 尚未 clone：克隆后执行其 `install.sh` 并引导插件；若已存在（已是 git 仓库）则**直接跳过**，由使用者自行维护版本与更新

详见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md) 与 [.chezmoi/run_once_install-neovim-config.sh.tmpl](../.chezmoi/run_once_install-neovim-config.sh.tmpl)。

## 使用方式

- **一键安装后**：Neovim 配置位于 `~/.config/nvim`，直接运行 `nvim` 即可；插件在一键安装时已引导（若跳过则首次启动时会继续安装）。
- **更新 nvim 配置**：`cd ~/.config/nvim && git pull && ./install.sh`

## 历史说明（可选）

历史上本仓库曾通过环境变量向 nvim 的 `install.sh` 注入 `PROJECT_ROOT`/`COMMON_LIB`，并曾提供补丁 [patches/archive/nvim_install_common_lib_env.patch](patches/archive/nvim_install_common_lib_env.patch) 供上游或 fork 使用。当前已改为「nvim 独立、本仓库仅 clone 并执行 install.sh」，不再注入；该补丁仅作历史参考，一般无需使用。nvim 的 `install.sh` 请在上游仓库内自行维护。
