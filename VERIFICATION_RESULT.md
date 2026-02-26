# 验证结果与安装状态清单

本文档为**验证结果示例/模板**。**实际验证报告**以运行 `./scripts/chezmoi/verify_installation.sh` 生成为准，报告默认写入 `~/install_verification_report_<时间>.txt`，检查项包括：字体、默认 Shell、PATH/关键命令、通用工具（btop、fastfetch）、开机启动说明。完整验证项与检查命令见 [INSTALL_STATUS.md](scripts/linux/system_basic_env/INSTALL_STATUS.md)，软件与 run_once 对应见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。

---

## 1. 环境信息（WSL）

- **内核**: Linux 6.6.87.2-microsoft-standard-WSL2 (x86_64)
- **发行版**: Ubuntu 24.04.2 LTS (Noble Numbat)
- **包管理器**: apt
- **WSL**: 已检测为 WSL 环境

---

## 2. 所需软件验证结果

在 PATH 含 `~/.local/bin`、`~/.local/share/fnm` 的前提下执行 `command -v` 检查：

| 软件       | 状态   | 路径/备注                    |
|------------|--------|------------------------------|
| chezmoi    | 已安装 | ~/.local/bin/chezmoi         |
| git        | 已安装 | /usr/bin/git                 |
| bat/batcat | 已安装 | batcat (Ubuntu)，已别名 bat  |
| eza        | 已安装 | /usr/bin/eza                 |
| fd/fdfind  | 已安装 | fdfind (Ubuntu)，已别名 fd   |
| ripgrep    | 已安装 | /usr/bin/rg                  |
| fzf        | 已安装 | /usr/bin/fzf                 |
| fnm        | 已安装 | ~/.local/share/fnm/fnm       |
| uv         | 已安装 | ~/.local/bin/uv              |
| zsh        | 已安装 | /usr/bin/zsh                 |
| nvim       | 已安装 | /usr/bin/nvim                |
| starship   | 已安装 | /usr/local/bin/starship      |
| tmux       | 已安装 | /usr/bin/tmux                |
| lazygit    | 已安装 | ~/.local/bin/lazygit         |
| gh         | 已安装 | /usr/bin/gh                  |
| git-delta  | 已安装 | /usr/bin/delta               |
| trash-cli  | 已安装 | /usr/bin/trash               |
| btop       | 已安装 | /usr/bin/btop（由 run_once_install-common-tools 安装） |
| fastfetch  | 可选   | Ubuntu 24.10 以下无官方包；脚本会尝试 PPA/Snap/.deb，失败可手动见 INSTALL_GUIDE |

---

## 3. 配置文件验证结果

| 文件/目录                          | 状态   |
|------------------------------------|--------|
| ~/.bashrc                          | 已存在 |
| ~/.zshrc                           | 已存在 |
| ~/.tmux.conf                       | 已存在 |
| ~/.gitconfig                       | 已存在 |
| ~/.config/starship/starship.toml   | 已存在 |

---

## 4. 环境变量与自启动

### 4.1 谁设置环境变量

| 平台   | Shell | 登录/自启动读取顺序 | 负责 PATH 等的主要文件 |
|--------|--------|----------------------|-------------------------|
| Linux  | bash   | 登录: `~/.profile` → `~/.bashrc`；非登录交互: `~/.bashrc` | `~/.bashrc`（含 `~/.local/bin`、`~/.cargo/bin`、fnm、代理别名） |
| Linux  | zsh    | 登录: `~/.zprofile` → `~/.zshrc`；非登录交互: `~/.zshrc`   | `~/.zprofile`（PATH、fnm、uv）；`~/.zshrc`（主题、插件） |
| macOS  | bash   | 登录读 `~/.bash_profile`（内再 `source ~/.bashrc`）        | `~/.bash_profile`（PATH、fnm、代理） |
| Windows| Git Bash | 登录读 `~/.bash_profile`                                   | `~/.bash_profile`（代理、PATH） |

项目通过 chezmoi 管理上述 dotfile 模板，应用后：

- **Linux bash**：`~/.bashrc` 在 Linux 段内已加入 `~/.local/bin`、`~/.cargo/bin` 与 fnm，保证新开终端或 WSL 会话中 PATH 正确。
- **Linux/macOS/Windows zsh**：`~/.zprofile` 已设置 `~/.local/bin`、`~/.cargo/bin` 与 fnm；登录或新开终端会先读 `.zprofile` 再读 `.zshrc`，自启动即正常。

### 4.2 自启动含义（WSL/Linux）

- **WSL**：无“开机”概念，每次新开终端或 `wsl` 进入为一次登录 shell，会读 `~/.profile`（再 source `.bashrc`）或 `~/.zprofile`/`~/.zshrc`（若默认 shell 为 zsh），环境变量和 PATH 由上面文件提供，无需额外服务。
- **本仓库未配置**：systemd 用户服务、`~/.config/autostart` 等图形自启动；若需要可自行添加。

### 4.3 如何验证环境变量与自启动正常

在新开一个终端（或 `wsl -e bash -l -c '...'`）中执行：

```bash
# 应包含 .local/bin、fnm（以及可选 .cargo/bin）
echo "$PATH" | tr ':' '\n' | grep -E '\.local|fnm|cargo'

# 关键命令应可直接调用（说明 PATH 与自启动生效）
command -v chezmoi uv fnm lazygit
```

若上述路径和命令均存在，则环境变量与“自启动”（新终端加载的配置）正常。

---

## 5. 清单与后续检查

- **完整清单（按类别）**：[INSTALL_STATUS.md](scripts/linux/system_basic_env/INSTALL_STATUS.md)  
  含：核心与配置管理、通用工具、版本管理器、Shell 与终端、Neovim、配置文件、Linux 特有、验证命令、一键安装验证步骤与问题记录。

- **软件与 run_once 对应**：[SOFTWARE_LIST.md](SOFTWARE_LIST.md)

- **一键安装与平台说明**：[INSTALL_GUIDE.md](INSTALL_GUIDE.md)

在其它机器或重新安装后，可再次执行：

```bash
./scripts/linux/system_basic_env/get_wsl_system_info.sh
command -v chezmoi git bat eza fd rg fzf fnm uv zsh nvim starship tmux lazygit gh btop
ls -la ~/.bashrc ~/.zshrc ~/.tmux.conf ~/.gitconfig ~/.config/starship/starship.toml
```

根据输出更新本验证结果或 INSTALL_STATUS 中的“安装状态”“配置状态”列。环境变量与自启动说明见上文第 4 节。

---

## 6. 字体与默认 Shell（Linux 默认 zsh+oh-my-zsh）

| 项目 | 说明 | 验证方式 |
|------|------|----------|
| **字体** | FiraMono Nerd Font 由 `run_once_install-nerd-fonts.sh` 安装到 `/usr/local/share/fonts/FiraMono-NerdFont`（Linux） | `ls /usr/local/share/fonts/FiraMono-NerdFont`；`fc-list \| grep -i Fira` |
| **默认 shell** | 项目期望 Linux 默认使用 zsh+oh-my-zsh；`run_once_install-zsh.sh` 会尝试执行 `chsh -s $(command -v zsh)`，若失败需手动执行后**重新登录** | `getent passwd $(id -un) \| cut -d: -f7` 应显示 zsh 路径；若为 `/bin/bash` 则执行 `chsh -s $(command -v zsh)` 并重新登录 |
