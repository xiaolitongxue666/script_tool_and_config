# 归档补丁说明

本目录下的补丁仅作**历史参考**，当前均**不再使用**。

事实更正（2026-09）：原文称「本仓库仅 clone 并执行 nvim 的 `install.sh`」——**不准确**。
本仓库与 Neovim 的真实关系是：

- `.chezmoi/run_once_install-neovim.sh.tmpl` 仅**安装 nvim 二进制**（按平台取 tarball/deb/winget）；
- Neovim **配置**由用户独立的 `~/.config/nvim` 仓库自行管理，本仓库**不 clone、不注入**任何路径；
- 详见 [NEOVIM_AND_THIS_REPO.md](../../NEOVIM_AND_THIS_REPO.md)。

## 补丁清单

- **nvim_install_common_lib_env.patch**：曾用于让 nvim 的 `install.sh` 支持通过环境变量接收本仓库路径
  并在缺失时使用脚本内最小实现；现已**不再使用**（nvim 配置已完全独立）。
