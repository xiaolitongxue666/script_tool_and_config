# Neovim 与本仓库的关系

## 关系说明

- **nvim**：完全独立项目（独立仓库）。本仓库**只负责安装 Neovim 二进制**，不管理 nvim 的配置文件。
- **本仓库职责**：通过 `run_once_install-neovim.sh.tmpl` 安装 Neovim 二进制（>= 0.11.0）。
- **nvim 配置管理**：由相邻仓库或用户自行管理的 `~/.config/nvim` 负责，不在本仓库范围内。

## 安装顺序

```
Layer 0: fnm + uv（版本管理器，为 Neovim 提供 node/python 环境）
Layer 3: run_once_install-neovim（仅安装 Neovim 二进制）
```

Neovim 具体的配置、插件、语言服务器由 `~/.config/nvim` 项目自行管理。

## 更新 nvim 配置

```bash
cd ~/.config/nvim && git pull && ./install.sh
```
