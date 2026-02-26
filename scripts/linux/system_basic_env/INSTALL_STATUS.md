# 所需软件安装与配置状态清单

本文档为**当前环境验证清单与检查命令**，便于在 WSL/Ubuntu 或 Arch 上核对。完整软件列表与 run_once 对应见 [SOFTWARE_LIST.md](../../../SOFTWARE_LIST.md)。生成/核对环境：**WSL Ubuntu**。

---

## 1. 核心与配置管理

| 软件/配置       | 说明           | 安装状态 | 配置状态 | 备注                         |
|----------------|----------------|----------|----------|------------------------------|
| **chezmoi**    | dotfiles 管理  | 已安装   | 已配置   | ~/.local/bin，sourceDir 已设 |
| **Git**        | 版本控制       | 已安装   | 已配置   | ~/.gitconfig（含代理）       |

---

## 2. 通用工具（run_once_install-common-tools）

| 软件        | 说明           | 安装状态 | 备注                          |
|-------------|----------------|----------|-------------------------------|
| **bat**     | cat 替代       | 已安装   | Ubuntu 下命令为 batcat，已别名 |
| **eza**     | ls 替代        | 已安装   |                               |
| **fd**      | find 替代      | 已安装   | Ubuntu 下为 fdfind，已别名     |
| **ripgrep** | rg 搜索        | 已安装   |                               |
| **fzf**     | 模糊查找       | 已安装   |                               |
| **git-delta** | Git diff 增强 | 已安装   |                               |
| **gh**      | GitHub CLI     | 已安装   |                               |
| **trash-cli** | 回收站        | 已安装   |                               |
| **lazygit** | Git TUI        | 已安装   | 来自 GitHub 二进制，~/.local/bin |

---

## 3. 版本管理器（run_once_install-version-managers）

| 软件   | 说明          | 安装状态 | 备注                    |
|--------|---------------|----------|-------------------------|
| **fnm**| Node 版本管理 | 已安装   | ~/.local/share/fnm      |
| **uv** | Python 包管理 | 已安装   | ~/.local/bin            |
| rustup | Rust 工具链   | 可选     | 未装不影响当前清单      |

---

## 4. Shell 与终端

| 软件/配置     | 说明        | 安装状态 | 配置状态 | 备注                    |
|---------------|-------------|----------|----------|-------------------------|
| **zsh**       | Z shell     | 已安装   | 已配置   | ~/.zshrc                |
| **starship**  | 提示符      | 已安装   | 已配置   | ~/.config/starship/     |
| **tmux**      | 终端复用    | 已安装   | 已配置   | ~/.tmux.conf            |
| **alacritty** | 终端模拟器  | 未安装   | -        | Ubuntu 建议 snap/源码   |

---

## 5. 编辑器与 Neovim

| 软件/配置       | 说明           | 安装状态 | 配置状态 | 备注           |
|----------------|----------------|----------|----------|----------------|
| **neovim**     | 编辑器         | 已安装   | 已配置   | dotfiles/nvim  |
| neovim-config  | Neovim 子模块  | 已应用   | -        | run_once 已跑  |

---

## 6. 配置文件（由 chezmoi 管理）

| 文件/目录                    | 状态     | 说明           |
|-----------------------------|----------|----------------|
| ~/.bashrc                   | 已应用   | 含 Linux bat/fd 别名、fnm、代理 |
| ~/.zshrc                    | 已应用   | 含 Linux bat/fd 别名     |
| ~/.tmux.conf                | 已应用   | tmux 配置      |
| ~/.gitconfig                | 已应用   | 含代理，longpaths 仅 Windows |
| ~/.config/starship/starship.toml | 已应用 | 提示符         |
| ~/.config/fish/config.fish  | 已应用   | Fish（若安装） |

---

## 7. Linux 特有 / 按发行版区分

| 软件/配置 | 说明           | Ubuntu/WSL | Arch | 备注                          |
|-----------|----------------|------------|------|-------------------------------|
| **dwm**   | 动态窗口管理器 | 已排除     | 支持 | 仅 Arch 执行 run_once，见下   |
| i3wm      | 平铺窗口管理器 | 可选       | 支持 | 需 X11，WSL 下通常不装        |
| Pacman/镜像 | Arch 包管理  | 不适用     | 支持 | run_on_linux run_once_configure-pacman |
| AUR 助手  | yay/paru       | 不适用     | 支持 | run_on_linux run_once_install-aur-helper |

- **dwm 排除说明**：`run_once_install-dwm.sh.tmpl` 在检测到 **Ubuntu/Debian** 时会直接退出并提示“仅 Arch Linux 支持本脚本自动安装”，不会安装依赖或编译，避免在 Ubuntu 上报错。

---

## 8. 验证命令（在项目或本机执行）

安装或部署结束后，可运行项目提供的验证脚本生成报告：`./scripts/chezmoi/verify_installation.sh`，报告默认写入 `~/install_verification_report_<时间>.txt`，内容包含字体、默认 Shell、环境变量/PATH、开机启动声明等项。

### WSL SSH 验证（子模块与 run_once 克隆依赖）

在 WSL 中执行：

- `ssh-add -l`：应列出至少一个密钥；若为 “Could not open a connection to your authentication agent”，说明 agent 未启动或未转发。
- `ssh -T git@github.com`：应出现 “Hi xxx! You've successfully authenticated” 或类似成功提示。

宿主机密钥：软链接 `~/.ssh` → `/mnt/c/Users/<User>/.ssh` 时需 `/etc/wsl.conf` 的 `[automount] options = "metadata"` 并 `chmod 600 ~/.ssh/id_rsa`；npiperelay 需在 `.bashrc`/`.zprofile` 中建立 `SSH_AUTH_SOCK` 的 socat 命令在登录时执行。一键自检：`./scripts/linux/system_basic_env/verify_wsl_ssh.sh`。

### 通用验证命令

在 WSL/Ubuntu 下可执行以下命令快速核对（需已 `source ~/.bashrc` 或保证 PATH 含 `~/.local/bin`、`~/.local/share/fnm`）：

```bash
# 核心
command -v chezmoi git bat eza fd rg fzf fnm uv zsh nvim starship tmux lazygit gh

# 配置文件
ls -la ~/.bashrc ~/.zshrc ~/.tmux.conf ~/.gitconfig ~/.config/starship/starship.toml

# 1) 字体是否安装（FiraMono Nerd Font，由 run_once_install-nerd-fonts 安装）
ls -la /usr/local/share/fonts/FiraMono-NerdFont 2>/dev/null || echo "未安装"
fc-list 2>/dev/null | grep -i FiraMono | head -3

# 2) 默认 shell 是否设为 zsh（项目期望 Linux 默认 zsh+oh-my-zsh）
getent passwd "$(id -un)" | cut -d: -f7
# 若显示 /bin/bash，需手动设置后重新登录: chsh -s $(command -v zsh)
```

### Oh My Zsh 插件

- 检查：`bash scripts/common/utils/check_zsh_omz.sh`。若显示已安装插件 0/4，多为 **WSL 下** Git 的 `http.https://github.com.proxy` 指向 127.0.0.1 导致 clone 失败。取消该配置后重试 clone 或执行 [INSTALL_GUIDE.md](../../../INSTALL_GUIDE.md) 中的「Oh My Zsh 插件未安装 故障排除」补救命令。

---

## 9. 更新本清单

- 安装与配置状态以当前环境验证结果为准。
- 在其它机器或发行版上执行 `./scripts/linux/system_basic_env/get_wsl_system_info.sh` 与上述验证命令后，可根据输出更新本表“安装状态”“配置状态”列。

---

## 10. 一键安装验证步骤与问题记录

**适用环境**：全新 WSL Ubuntu 或全新 Arch（或清除 chezmoi state 后）。

**步骤**：

1. 克隆项目并进入根目录：`git clone <repo> && cd <repo>`
2. **（WSL）验证 SSH**：`ssh-add -l`、`ssh -T git@github.com`（详见第 8 节 WSL SSH 验证）；子模块与部分 run_once 依赖 SSH，失败时脚本会回退 HTTPS 并依赖代理。
3. **（可选）开代理**：`h_proxy` 或 `export PROXY=http://127.0.0.1:7890`（WSL 下建议用宿主机 IP:7890）；`./install.sh --proxy ...` 亦可。
4. 执行 `./install.sh`，观察：chezmoi 是否安装成功、apply 是否使用项目源、run_once 是否按预期执行（可结合 `chezmoi state dump` 查看 scriptState）
5. 按上文第 8 节验证命令与本表逐项检查：命令可用、配置文件已应用、代理与 OS 特例符合预期

**成功标准**：单次 `./install.sh` 后，无需手动改 `~/.config/chezmoi`、无需手动执行多个 run_once，即可得到文档中承诺的软件与配置状态（允许个别可选 run_once 如 dwm/i3wm/alacritty 失败并打 WARNING）。

**问题记录**：若某 run_once 失败或某软件未安装，请记录发行版、错误输出与步骤，用于后续迭代；可附于本文件或提交 issue。若 **Oh My Zsh 插件 0/4**：多为 WSL 下 `http.https://github.com.proxy` 指向 127.0.0.1 导致，取消该配置后重试或按 INSTALL_GUIDE 故障排除执行补救命令。
