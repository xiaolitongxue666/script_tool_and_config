# 软件安装清单（按 OS × 安装顺序）

本文档以 `.chezmoi/run_once_*.sh.tmpl` 和 `.chezmoi/run_on_*/` 的实际模板条件为准，
按 chezmoi 的字母序执行顺序整理各平台安装的软件。

## 执行顺序总览

```
run_once_00-install-version-managers  ← Layer 0（命名 00 强制最先）
run_once_install-git                  ← Layer 1
run_once_install-common-tools         ← Layer 1
run_once_install-zsh                  ← Layer 2
run_once_install-starship             ← Layer 2
run_once_install-nerd-fonts           ← Layer 2
run_once_install-neovim               ← Layer 3（仅安装二进制）
run_once_90-install-claude-code       ← Layer 4（AI agent CLI，fnm/node 已就绪）
run_once_91-install-codex             ← Layer 4（AI agent CLI，npm @openai/codex）
run_once_92-install-codewhale         ← Layer 4（AI agent CLI，npm codewhale）
run_once_93-install-cursor            ← Layer 4（GUI 检测，有 GUI 才装）
run_once_install-{tmux,i3wm,...} ← Layer 5（平台特有）
run_on_linux/* / run_on_darwin/*      ← Layer 5（平台特有）
run_on_windows/*                      ← Layer 5（平台特有）
```

---

## 跨平台共用（linux / darwin / windows）

| 层级 | 脚本 | 安装项 | 平台 |
|------|------|--------|------|
| Layer 0 | `run_once_00-install-version-managers` | **fnm**（Node/npm）、**uv**（Python）；Windows 另 bootstrap `fnm install lts/*` + `uv python install`（默认 3.12，`UV_DEFAULT_PYTHON` 可覆盖）；rustup（可选） | all |
| Layer 1 | `run_once_install-git` | git, connect-proxy（Linux apt 场景） | all |
| Layer 1 | `run_once_install-common-tools` | bat, eza, fd, rg, fzf, lazygit, delta, gh, trash-cli, btop, fastfetch（包名 SSOT：[`scripts/chezmoi/packages.conf`](../scripts/chezmoi/packages.conf)） | all |
| Layer 2 | `run_once_install-zsh` + `.chezmoiexternal.toml.tmpl` | zsh 二进制；Oh My Zsh 与插件（autosuggestions/history-substring-search/syntax-highlighting/completions）由 chezmoi external（仅 linux/darwin） | all（Windows 跳过 OMZ） |
| Layer 2 | `run_once_install-starship` | starship 提示符 | all |
| Layer 2 | `run_once_install-nerd-fonts` | FiraMono Nerd Font | all |
| Layer 3 | `run_once_install-neovim` | Neovim 二进制（>= 0.11.0） | all |
| Layer 4 | `run_once_90-install-claude-code` | Claude Code CLI（npm i -g @anthropic-ai/claude-code，依赖 fnm/node） | all |
| Layer 4 | `run_once_91-install-codex` | OpenAI Codex CLI（npm i -g @openai/codex） | all |
| Layer 4 | `run_once_92-install-codewhale` | CodeWhale CLI（`npm install -g codewhale`，`codewhale` + `codewhale-tui`；代理默认 7890） | all（含 WSL）；详见 [CODEWHALE.md](CODEWHALE.md) |
| Layer 4 | `run_once_93-install-cursor` | Cursor 编辑器（仅 GUI 环境） | all（检测 GUI） |

> **Pi** 已迁入 [agent-config](../../AI/agent-config)（Phase 2）；本仓库不再包含 `run_once_94` 或 `dot_pi/`。

**Layer 4 职责（存量双路径）**：本仓库 `run_once_90`–`93` 仍安装部分 Agent **二进制**/Cursor GUI；**agent-config** `install-tools.sh` 也会安装全部 Agent CLI（含 Pi）并负责 MCP/Skills/Harness。两侧 CLI 安装为已知冗余，**当前保留**（后续再收敛）；Pi 仅 Phase 2。

### 两阶段部署（本仓库 + agent-config）

1. **本仓库**：`./deploy.sh` 或 `./scripts/manage_dotfiles.sh apply` — 非 AI 基建 + Layer 4 Agent CLI（存量）。
2. **agent-config**：`bash scripts/install-tools.sh` — 全部 Agent CLI（含 Pi）+ 全局 MCP/Skills + 各 Agent 配置。

各 OS / WSL 须在**对应环境**各跑一遍（Windows Git Bash 与 WSL 的 `$HOME` 独立）。

---

## Linux（含 WSL）

| 层级 | 脚本 | 安装项 | 说明 |
|------|------|--------|------|
| Layer 5 | `run_once_install-tmux` | tmux + TPM (Tmux Plugin Manager) | linux + darwin |
| Layer 5 | `run_once_install-alacritty` | alacritty 终端 | linux |
| Layer 5 | `run_once_install-lazyssh` | lazyssh | linux（AUR/apt 回退） |
| Layer 5 | `run_once_install-i3wm` | i3 平铺窗口管理器 | linux |
| Layer 5 | `run_once_install-dwm` | dwm 动态窗口管理器 | **仅 Arch**（Ubuntu/Debian 自动跳过） |
| Layer 5 | `run_on_linux/run_once_configure-pacman` | pacman 配置（中国镜像/archlinuxcn/并行下载） | **仅 Arch** |
| Layer 5 | `run_on_linux/run_once_install-arch-base-packages` | base-devel 等 Arch 基础包 | **仅 Arch** |
| Layer 5 | `run_on_linux/run_once_install-aur-helper` | yay / paru（AUR 助手） | **仅 Arch** |

### WSL 特殊说明

- WSL 视为 Linux 子类型，脚本内通过 `WSL_DISTRO_NAME` 和 `/proc/version` 识别。
- 代理检测：WSL 下从 `/etc/resolv.conf` 的 nameserver 推断宿主机 IP，自动补 :7890。
- **WSL 上不适用**（`ensure` / `[5/6]` 状态检查会跳过，不标 Missing）：`alacritty`、`i3wm`、`dwm`（用 Windows 终端；无本地 WM 需求）。
- **非 Arch 的 Linux/WSL 上不适用**：`configure-pacman`、`arch-base-packages`、`aur-helper`、`dwm`（脚本内也会 skip）。
- Debian/Ubuntu：`bat` / `fd` 包提供的命令名为 `batcat` / `fdfind`；安装检测与 shell alias（bashrc / zshrc）已兼容。
- connect-proxy 依赖：Linux apt 场景需要 `apt install connect-proxy`。

---

## macOS (darwin)

| 层级 | 脚本 | 安装项 | 说明 |
|------|------|--------|------|
| Layer 5 | `run_once_install-tmux` | tmux + TPM | linux + darwin |
| Layer 5 | `run_once_install-maccy` | maccy 剪贴板管理器 | darwin |
| Layer 5 | `run_once_install-yabai` | yabai 平铺窗口管理器 | darwin |
| Layer 5 | `run_once_install-skhd` | skhd 快捷键守护进程 | darwin |
| Layer 5 | `run_on_darwin/run_once_configure-homebrew` | Homebrew 配置与国内源 | darwin |
| Layer 5 | `run_on_darwin/run_once_install-ghostty` | Ghostty 终端 | darwin |
| Layer 5 | `run_on_darwin/run_once_install-connect` | connect（SSH ProxyCommand） | darwin |
| Layer 5 | `run_on_darwin/run_onchange_sync_ghostty_config_to_app_support` | Ghostty 配置同步到 Application Support | darwin（内容变化触发） |
| Cursor 编辑器 settings | **agent-config** | `render-cursor-editor-settings.sh` + `sync-cursor-editor-settings.sh` |

---

## Windows

| 层级 | 脚本 | 安装项 | 说明 |
|------|------|--------|------|
| Layer 5 | `run_on_windows/run_once_install-windows-terminal` | Windows Terminal | windows |
| Layer 5 | `run_on_windows/run_once_install-rmux` | rmux v0.5.0（预编译包 → `~/.local/bin`，cargo 回退） | windows |
| Layer 5 | `run_once_install-oh-my-posh` | Oh My Posh 提示符 | windows |
| Layer 5 | `run_on_windows/run_onchange_sync_windows_terminal_config` | Windows Terminal 配置同步到实际路径 | windows（内容变化触发） |

配置模板（非 run_once）：`dot_config/windows-terminal/settings.json.tmpl` → `~/.config/windows-terminal/settings.json`（Git Bash 默认、PowerShell/CMD/WSL2、`keybindings`、`newTabMenu`、Catppuccin Mocha）；`dot_rmux.conf.tmpl` → `~/.rmux.conf`。

### Windows 特殊说明

- 安装入口：Git Bash（推荐）或 `scripts/windows/install_with_chezmoi.bat`。
- **Node / Python**：Git Bash 内 `node`/`npm` 由 **fnm** 提供，`python`/`uv` 由 **uv** 管理；`_bash_profile_windows` 与 `dot_bashrc` Windows 分支自动 `eval "$(fnm env)"` 并加入 `Roaming/uv/python` PATH。
- **rmux**：Windows Terminal 仍默认进入 Git Bash；需要时在 shell 中手动执行 `rmux new -s <name>` / `rmux a -t <name>`，不修改 WT 默认 profile，也不在 bashrc 中自动 attach。
- 包管理器优先：winget，回退 MSYS2 pacman。
- SSH 代理：使用 Git for Windows 自带的 `connect.exe`（路径 `C:/Program Files/Git/mingw64/bin/connect.exe`）。
- zsh 在 Windows 上为 MSYS2 可选安装。
- chezmoi apply 需要 `[interpreters.sh]` 配置 bash 路径。

---

## 跨平台工具安装差异（包名映射）

| 工具 | macOS (brew) | Linux Arch (pacman) | Linux Ubuntu (apt) | Windows (winget) |
|------|-------------|---------------------|--------------------|-------------------|
| bat | bat | bat | bat | sharkdp.bat |
| eza | eza | eza | eza | eza-community.eza |
| fd | fd | fd | fd-find | sharkdp.fd |
| rg（包名 ripgrep） | ripgrep | ripgrep | ripgrep | BurntSushi.ripgrep.MSVC |
| fzf | fzf | fzf | fzf | junegunn.fzf |
| lazygit | lazygit | lazygit | lazygit | jesseduffield.lazygit |
| delta（包名 git-delta） | git-delta | git-delta | git-delta | dandavison.delta |
| gh | gh | github-cli | gh | GitHub.cli |
| neovim | neovim (brew) | neovim (pacman) | PPA → tarball | Neovim.Neovim |
| starship | starship | starship | starship (cargo) | starship.starship |
| fnm | fnm | fnm | 官方脚本 | Schniz.fnm |
| uv | uv | uv | 官方脚本 | astral-sh.uv |

---

## 补装与升级策略（install.sh）

`install.sh` 在 chezmoi apply 之后执行 [`scripts/chezmoi/ensure_platform_software.sh`](../scripts/chezmoi/ensure_platform_software.sh)：

| 步骤 | 行为 |
|------|------|
| `[3/6] apply` | 首次部署配置；chezmoi `run_once_*` 仅执行一次 |
| `[4/6] ensure` | 按 OS/WSL 补装缺失项；**默认**将已装软件升到最新稳定版 |
| `[5/6] 报告` | 三态：未安装 / 已安装 OK / 部分安装或跳过升级 |
| `[6/6] verify` | 字体、Shell、PATH 等验证 |

**升级策略**（[`software_policies.sh`](../scripts/chezmoi/software_policies.sh)）：

| 策略 | 软件示例 |
|------|----------|
| `latest` | fnm、uv、common-tools、Layer 4 npm CLI、starship、git |
| `minimum:0.11.0` | Neovim（仅低于 0.11 时升级） |
| `pinned:0.5.0` | rmux（Windows） |
| `skip` | nerd-fonts、configure-pacman、configure-homebrew、AUR helper |

**关闭升级**：`./install.sh --no-upgrade` 或 `SKIP_SOFTWARE_UPGRADE=1 ./install.sh`

**代理**：外网下载/npm 默认走 `7890`（WSL 自动解析宿主机 IP）；可 `--proxy http://host:7890`

**与 deploy.sh 分工**：日常 dotfiles 增量用 `deploy.sh`；全量补装/升级请用 `install.sh`

---

## 维护规则

1. 新增/删除安装脚本时，必须同步更新此文档。
2. 脚本的平台条件优先看模板头部的 `{{- if eq .chezmoi.os ... }}`。
3. 同一脚本内有平台分支的，在「跨平台工具安装差异」表中标注包名映射。
4. `run_onchange_` 脚本属于配置同步行为，不计入「首次安装」，但保留在清单中以解释文件来源。