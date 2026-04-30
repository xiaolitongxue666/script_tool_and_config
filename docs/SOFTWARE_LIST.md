# 软件清单（按 OS / WSL）

本文档以仓库内实际安装脚本为准，整理 `install.sh` 触发的 run_once / run_on_* 安装项。

- 事实来源：`install.sh`、`scripts/chezmoi/install_helpers.sh`、`.chezmoi/run_once_*.sh.tmpl`、`.chezmoi/run_on_*/run_once_*.sh.tmpl`
- 平台口径：`linux`（含 WSL）、`darwin`（macOS）、`windows`
- 目标：明确跨平台共用项、平台专有项、WSL 差异项，避免重复与冲突描述

---

## 按 OS 汇总（一览）

### 跨平台共用（Linux / macOS / Windows）

| 类别 | 软件/能力 | 主要脚本 |
|------|------|------|
| 版本管理 | fnm, uv, rustup（可选） | `run_once_00-install-version-managers.sh.tmpl` |
| 文件/搜索与通用 | bat, eza, fd, ripgrep, fzf, lazygit, git-delta, gh（另含平台差异：trash-cli、btop、fastfetch） | `run_once_install-common-tools.sh.tmpl` |
| 开发 | git, neovim, neovim-config | `run_once_install-git.sh.tmpl`, `run_once_install-neovim.sh.tmpl`, `run_once_install-neovim-config.sh.tmpl` |
| 终端提示符 | starship | `run_once_install-starship.sh.tmpl` |
| 字体 | Nerd Fonts (FiraMono) | `run_once_install-nerd-fonts.sh.tmpl` |
| 系统基础 | system-basic-env | `run_once_install-system-basic-env.sh.tmpl` |
| OpenCode | opencode | `run_once_install-opencode.sh.tmpl` |
| AI 配置桥接 | ai-unified-config, opencode-aiconfig-bridge | `run_once_install-ai-unified-config.sh.tmpl`, `run_once_install-opencode-aiconfig-bridge.sh.tmpl` |

### Linux（含 WSL）

| 类别 | 软件/能力 | 主要脚本 |
|------|------|------|
| 终端/Shell | zsh, oh-my-zsh, fish, tmux, TPM, alacritty | `run_once_install-zsh.sh.tmpl`, `run_once_install-fish.sh.tmpl`, `run_once_install-tmux.sh.tmpl`, `run_once_install-alacritty.sh.tmpl` |
| 开发 | lazyssh | `run_once_install-lazyssh.sh.tmpl` |
| Linux 专属 | i3wm, dwm | `run_once_install-i3wm.sh.tmpl`, `run_once_install-dwm.sh.tmpl` |
| Arch 专属 | pacman 配置、arch-base-packages、AUR helper | `run_on_linux/run_once_configure-pacman.sh.tmpl`, `run_on_linux/run_once_install-arch-base-packages.sh.tmpl`, `run_on_linux/run_once_install-aur-helper.sh.tmpl` |

### macOS

| 类别 | 软件/能力 | 主要脚本 |
|------|------|------|
| 终端/Shell | zsh, oh-my-zsh, fish, tmux, TPM, ghostty | `run_once_install-zsh.sh.tmpl`, `run_once_install-fish.sh.tmpl`, `run_once_install-tmux.sh.tmpl`, `run_on_darwin/run_once_install-ghostty.sh.tmpl` |
| macOS 专属 | homebrew 配置, connect, yabai, skhd, maccy | `run_on_darwin/run_once_configure-homebrew.sh.tmpl`, `run_on_darwin/run_once_install-connect.sh.tmpl`, `run_once_install-yabai.sh.tmpl`, `run_once_install-skhd.sh.tmpl`, `run_once_install-maccy.sh.tmpl` |

### Windows

| 类别 | 软件/能力 | 主要脚本 |
|------|------|------|
| 终端/Shell | windows-terminal, oh-my-posh, zsh（MSYS2 可选） | `run_on_windows/run_once_install-windows-terminal.sh.tmpl`, `run_once_install-oh-my-posh.sh.tmpl`, `run_once_install-zsh.sh.tmpl` |
| 配置同步 | Windows Terminal settings 同步到实际路径（内容变化时） | `run_on_windows/run_onchange_sync_windows_terminal_config.sh.tmpl` |

---

## WSL 特殊说明（相对 Linux 原生）

- WSL 视为 Linux 子类型，复用 Linux 安装脚本与分类。
- `run_once_install-common-tools.sh.tmpl` 会识别 WSL 并输出 `Linux (WSL, <pkg>)` 日志。
- `run_once_install-git.sh.tmpl` 与 `scripts/chezmoi/ensure_ssh_prereqs.sh` 对 apt/WSL 场景会处理 `connect-proxy` 依赖。
- Arch 专属脚本（`run_on_linux/run_once_configure-pacman.sh.tmpl`、`run_once_install-arch-base-packages.sh.tmpl`、`run_once_install-aur-helper.sh.tmpl`）仅在 Arch 语义下执行，不适用于常见 WSL Ubuntu。

---

## 按 run_once / run_on 脚本索引

| 脚本 | 软件/作用 | 适用平台 |
|------|------|------|
| `run_once_00-install-version-managers.sh.tmpl` | fnm, uv, rustup（可选） | Linux, macOS, Windows |
| `run_once_install-common-tools.sh.tmpl` | bat/eza/fd/rg/fzf/lazygit/git-delta/gh 等通用工具（含平台差异项） | Linux, macOS, Windows |
| `run_once_install-starship.sh.tmpl` | starship | Linux, macOS, Windows |
| `run_once_install-git.sh.tmpl` | git（Linux 侧含 connect-proxy 逻辑） | Linux, macOS, Windows |
| `run_once_install-neovim.sh.tmpl` | neovim | Linux, macOS, Windows |
| `run_once_install-neovim-config.sh.tmpl` | 克隆并初始化独立 nvim 仓库 | Linux, macOS, Windows |
| `run_once_install-nerd-fonts.sh.tmpl` | FiraMono Nerd Font | Linux, macOS, Windows |
| `run_once_install-zsh.sh.tmpl` | zsh / oh-my-zsh（Windows 为 MSYS2 可选） | Linux, macOS, Windows |
| `run_once_install-system-basic-env.sh.tmpl` | 系统基础环境检查与准备 | Linux, macOS, Windows |
| `run_once_install-opencode.sh.tmpl` | opencode | Linux, macOS, Windows |
| `run_once_install-ai-unified-config.sh.tmpl` | 安装 ai-unified-config | Linux, macOS, Windows |
| `run_once_install-claude-code.sh.tmpl` | Claude Code CLI（`npm i -g @anthropic-ai/claude-code`，在 `run_once_00` 之后） | Linux, macOS, Windows |
| `run_once_install-opencode-aiconfig-bridge.sh.tmpl` | 同步/桥接 opencode、cursor、codex 配置 | Linux, macOS, Windows |
| `run_once_install-fish.sh.tmpl` | fish | Linux, macOS |
| `run_once_install-tmux.sh.tmpl` | tmux + TPM | Linux, macOS |
| `run_once_install-alacritty.sh.tmpl` | alacritty | Linux |
| `run_once_install-lazyssh.sh.tmpl` | lazyssh | Linux |
| `run_once_install-i3wm.sh.tmpl` | i3wm | Linux |
| `run_once_install-dwm.sh.tmpl` | dwm | Linux |
| `run_on_linux/run_once_configure-pacman.sh.tmpl` | pacman 与 archlinuxcn 配置 | Linux（Arch） |
| `run_on_linux/run_once_install-arch-base-packages.sh.tmpl` | Arch 基础包 | Linux（Arch） |
| `run_on_linux/run_once_install-aur-helper.sh.tmpl` | AUR helper | Linux（Arch） |
| `run_on_darwin/run_once_configure-homebrew.sh.tmpl` | Homebrew 配置 | macOS |
| `run_on_darwin/run_once_install-connect.sh.tmpl` | connect（SSH 代理） | macOS |
| `run_on_darwin/run_once_install-ghostty.sh.tmpl` | ghostty | macOS |
| `run_on_darwin/run_onchange_sync_ghostty_config_to_app_support.sh.tmpl` | Ghostty 配置同步（内容变化时） | macOS |
| `run_once_install-yabai.sh.tmpl` | yabai | macOS |
| `run_once_install-skhd.sh.tmpl` | skhd | macOS |
| `run_once_install-maccy.sh.tmpl` | maccy | macOS |
| `run_on_windows/run_once_install-windows-terminal.sh.tmpl` | Windows Terminal | Windows |
| `run_on_windows/run_onchange_sync_windows_terminal_config.sh.tmpl` | Windows Terminal 配置同步（内容变化时） | Windows |
| `run_once_install-oh-my-posh.sh.tmpl` | oh-my-posh | Windows |

---

## 维护规则

- 新增/删除安装脚本时，必须同步更新本文档与 `scripts/chezmoi/install_helpers.sh` 的分类逻辑。
- 涉及平台差异时，优先写“同一脚本内分支”与“run_on_* 目录约束”，避免重复列出同一软件。
- `run_onchange_` 脚本属于配置同步行为，不计入“首次安装软件”统计，但需保留在脚本索引中。
