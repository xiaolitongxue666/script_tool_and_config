# 安装与配置指南

本指南为一键安装与首次配置的入口，各平台分步说明见 [os_setup_guide.md](os_setup_guide.md)。

## 一键安装（推荐）

在项目根目录执行：

```bash
./install.sh
```

脚本会：检测 OS、安装 chezmoi（若未安装）、**自动写入** `~/.config/chezmoi/chezmoi.toml` 的 `sourceDir` 指向项目、执行 `chezmoi apply` 并运行各 run_once 安装脚本（Neovim 由 run_once_install-neovim-config 克隆到 ~/.config/nvim）；最后执行 **[5/5] 验证与确认**（字体、默认 Shell、环境变量、开机启动声明）并生成报告文件（默认 `~/install_verification_report_<时间>.txt`）。

### 代理

- 使用方式：`./install.sh --proxy http://127.0.0.1:7890` 或 `export PROXY=...` 后执行 `./install.sh`。
- run_once 脚本通过环境变量 `http_proxy` 使用代理，与 install.sh 导出一致。
- **Pacman（Arch）**：镜像与 pacman 配置**不使用**代理，直连国内源；其他下载（GitHub、官方安装脚本等）使用上述代理。

**WSL 与代理**：项目会区分 **WSL2 内的 Linux** 与 **原生 Linux**。在 WSL2 中，`127.0.0.1` 无法访问 Windows 宿主机上的代理，因此 `.bashrc`/`.zshrc` 在检测到 WSL 时，会将默认代理地址设为 `http://<宿主机IP>:7890`（宿主机 IP 来自 `/etc/resolv.conf` 的 nameserver）。你只需在 Windows 端代理软件中开启「允许局域网连接」，在 WSL 终端执行 `h_proxy` 或 `proxy_on` 即可启用代理。一键安装前若需代理，可先执行 `h_proxy` 再执行 `./install.sh`，或 `export PROXY=http://$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):7890` 后执行 `./install.sh`。

## WSL / Linux 建议步骤

1. **（WSL）验证 SSH**：子模块与部分 run_once 使用 `git clone`（SSH）。在 WSL 中执行：
   - `ssh-add -l`：应列出至少一个密钥；若为 “Could not open a connection to your authentication agent”，说明 agent 未启动或未转发。
   - `ssh -T git@github.com`：应出现 “Hi xxx! You've successfully authenticated” 或类似成功提示。
   - 若使用宿主机密钥：软链接 `~/.ssh` → `/mnt/c/Users/<User>/.ssh` 时需在 `/etc/wsl.conf` 设置 `[automount] options = "metadata"` 并执行 `chmod 600 ~/.ssh/id_rsa`；若用 npiperelay，需确保 `.bashrc`/`.zprofile` 中建立 `SSH_AUTH_SOCK` 的 socat 命令在登录时执行。自检脚本：`./scripts/linux/system_basic_env/verify_wsl_ssh.sh`。
   - **SSH 走 443 与代理**：项目内 `~/.ssh/config` 已配置 GitHub 使用 `ssh.github.com:443`（避免代理/防火墙封 22 端口）。WSL 下代理在宿主机，需：① 安装 `connect-proxy`（`sudo apt install connect-proxy`；或执行 `./install.sh` 时由 run_once_install-git 自动安装）；② 使用 `./install.sh` 时脚本会自动检测 WSL 并设置 PROXY、导出 PROXY_HOST/PROXY_PORT，apply 后 `~/.ssh/config` 会使用宿主机地址；若直接执行 `chezmoi apply` 则需手动 `export PROXY_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')` 或在 `~/.config/chezmoi/chezmoi.toml.local` 中设置 `proxy_host = "192.168.x.x"`（与 `h_proxy` 使用的 IP 一致）；③ Windows 端代理开启「允许局域网连接」。
   - **提示 "<no hostip for proxy command>"**：经 ProxyCommand 连接时，SSH 可能显示 `The authenticity of host '[ssh.github.com]:443 (<no hostip for proxy command>)'`，多为代理上下文下的显示问题，认证成功可忽略。若 **WSL 内 ~/.ssh 软链接到宿主机**，则读到的 config 为 Windows 版，其中 127.0.0.1 在 WSL 中指向本机无法连到宿主机代理；需在 WSL 内使用独立 config 并设置 ProxyCommand 为宿主机 IP，或运行 `./install.sh` 让 chezmoi 管理 WSL 独立 ~/.ssh。

2. **可选开代理**：`h_proxy`（对 run_once 内 HTTPS、子模块 SSH 失败时的 HTTPS 回退、以及 SSH 经 ProxyCommand 走代理均有帮助）。

3. **一键安装**：  
   `./install.sh`  
   若需 root（如 Arch 下配置 Pacman）：`sudo chezmoi apply -v`。  
   Neovim 配置由 run_once_install-neovim-config 克隆到 ~/.config/nvim；先尝试 SSH，失败则 HTTPS+代理，需已执行 `h_proxy` 时更稳。

4. **获取环境信息**（可选）：  
   `./scripts/linux/system_basic_env/get_wsl_system_info.sh`  
   可将输出保存便于排查。

5. **一键安装即覆盖所需软件与配置**：所有软件均通过 **run_once** 脚本安装（通用工具、Arch 镜像与基础包、lazyssh、字体、zsh 等），**不再需要**独立脚本 `install_common_tools.sh`（已废弃，职责已拆分到 run_once，各脚本内区分 **OS** 与 **WSL**）。详见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md) 与 [INSTALL_STATUS.md](scripts/linux/system_basic_env/INSTALL_STATUS.md)。

## 平台与发行版说明

- **项目主要目标**：一键安装所需软件和配置；**区分不同 OS**（linux/darwin/windows）与 **WSL**（Linux 下通过日志区分 WSL 与原生）。
- **Windows**：`core.longpaths = true` 仅在本平台生效；SSH 等见 os_setup_guide。
- **macOS**：Homebrew、connect 路径、yabai/skhd 等见 run_on_darwin 与 os_setup_guide。
- **Linux**（按发行版与是否 WSL 区分）：
  - **通用工具**（bat, eza, fd, btop, fastfetch, lazygit, gh 等）：由 **run_once_install-common-tools** 安装，适用于**所有** Linux（含 **Arch**、**Ubuntu/Debian**、**WSL**）与 macOS。
  - **Ubuntu/Debian / WSL**：bat→batcat、fd→fdfind 别名已配置；**fastfetch** 在 Ubuntu 24.10 之前官方源无此包，脚本会依次尝试 **apt → PPA（zhangsongcui3371/fastfetch）→ Snap → GitHub .deb** 安装；Pacman/AUR 等**仅 Arch 执行的** run_once 会**自动跳过**；代理在 WSL 下为宿主机 IP（见上文 WSL SSH 小节）。
  - **Arch**：run_on_linux 下 Pacman 镜像、Arch 基础包、AUR 助手、dwm/i3wm 等执行；镜像与 pacman 直连国内源、禁用代理。

部分 run_once（如 dwm、i3wm、alacritty）在部分环境下可能未安装成功，会打 WARNING 并继续 apply，属预期；详见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md) 与 [scripts/linux/system_basic_env/INSTALL_STATUS.md](scripts/linux/system_basic_env/INSTALL_STATUS.md)。

- **macOS 终端**：使用 **Ghostty** + zsh（由 `run_on_darwin/run_once_install-ghostty.sh.tmpl` 安装，配置在 `~/.config/ghostty/config`，指定 zsh 为 shell）。Alacritty 仅 Linux 安装。

### Linux 默认 Shell 与字体

- **默认 Shell**：项目期望 Linux 下默认使用 **zsh + Oh My Zsh**。`run_once_install-zsh.sh` 会在安装后尝试执行 `chsh -s $(command -v zsh)`；若因权限/交互未生效，请**手动执行** `chsh -s $(command -v zsh)` 后**重新登录**（或新开 WSL 窗口），登录 shell 才会变为 zsh。
- **Oh My Zsh 插件**：同一 run_once 脚本会安装 zsh-autosuggestions、zsh-syntax-highlighting、zsh-completions、zsh-history-substring-search（需可访问 GitHub）。若首次 apply 时网络失败导致插件未装上，脚本会自动用「临时清空 GitHub proxy」重试一次；仍失败时可按下方故障排除处理。检查：`bash scripts/common/utils/check_zsh_omz.sh`。

  **Oh My Zsh 插件未安装（0/4）故障排除**  
  - **现象**：run_once 已执行但 `check_zsh_omz.sh` 显示 4 个插件 0/4。  
  - **常见原因**：WSL 下 `~/.gitconfig` 中 `http.https://github.com.proxy` 被设为 `http://127.0.0.1:7890`，WSL 内 127.0.0.1 指本机无法访问宿主机代理，导致 `git clone` GitHub 失败。  
  - **解决**：  
    1. 取消 Git 对 GitHub 的代理后再 clone 或重跑 apply：  
       `git config --global --unset http.https://github.com.proxy`  
       `git config --global --unset https.https://github.com.proxy`  
    2. 或在一键安装前在 `.chezmoi.toml.local` 中设置 `proxy` 为宿主机代理（如 `http://$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):7890`），使 dot_gitconfig 写入正确地址。  
    3. **补救**（手动安装 4 个插件，建议先执行上面两条 `--unset` 再执行）：  
       ```bash
       ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom/plugins" && mkdir -p "$ZSH_CUSTOM"
       for name in zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting zsh-completions; do
         [ -d "$ZSH_CUSTOM/$name" ] && continue
         git clone --depth=1 "https://github.com/zsh-users/$name" "$ZSH_CUSTOM/$name"
       done
       ```

- **字体**：FiraMono Nerd Font 由 `run_once_install-nerd-fonts.sh` 安装（Linux 下为 `/usr/local/share/fonts/FiraMono-NerdFont`）。下载自 [GitHub nerd-fonts  releases](https://github.com/ryanoasis/nerd-fonts/releases)，**下载若失败可设置代理**（如 `export http_proxy=http://127.0.0.1:7890` 后再次 `chezmoi apply`，或手动执行渲染后的脚本）。更多字体与安装方式见 [nerd-fonts](https://github.com/ryanoasis/nerd-fonts) 与 [nerdfonts.com 下载页](https://www.nerdfonts.com/font-downloads)。验证：`fc-list | grep -i Fira` 或查看 [INSTALL_STATUS.md](scripts/linux/system_basic_env/INSTALL_STATUS.md) 第 8 节。

### Cursor/VS Code 连接 WSL 后终端无 Starship 美化

在宿主机 Alacritty 中执行 `wsl` 会得到登录 shell 并加载 zsh/Starship，而 Cursor「Connect to WSL」打开的终端可能默认使用 bash 且为非登录 shell，因此无 Starship。可选做法：

1. **设置默认 Shell 为 zsh**：在 WSL 中执行 `chsh -s $(command -v zsh)` 并重新打开 Cursor 的 WSL 终端；或在该发行版中确保默认 shell 为 zsh，使 Cursor 继承。
2. **在 Cursor 中指定 WSL 终端 profile**：设置中将 `terminal.integrated.defaultProfile.linux`（或 WSL 对应项）设为 zsh（若已配置 zsh profile）。
3. **由 .bashrc 在交互式下切到 zsh**：项目 Linux 用 `.bashrc` 模板在「交互式且非 Cursor Agent」时自动 `exec zsh`，这样 Cursor 普通终端会进入 zsh 并加载 Starship；Cursor Agent 模式仍使用 bash 以免影响其脚本行为。

### WSL 下 Git 访问 GitHub 与代理

项目在 `~/.gitconfig` 中为 GitHub 配置了 proxy（由 dot_gitconfig 模板写入），默认 `http://127.0.0.1:7890`。在 WSL 中 **127.0.0.1 指 WSL 本机**，无法连到 Windows 宿主机上的代理，且 Git 的 URL 作用域配置 `http.https://github.com.proxy` **优先于** 环境变量 `http_proxy`，因此即使 shell 里设置了宿主机代理，`git clone` 访问 GitHub 仍可能走 127.0.0.1:7890 导致失败。  
**建议**：WSL 用户要么在 apply 前通过 data 设置 `proxy` 为宿主机地址（见上文），要么 apply 后在 WSL 内执行 `git config --global --unset http.https://github.com.proxy` 与 `https.https://github.com.proxy`，再执行需访问 GitHub 的 git 操作（如插件 clone、nvim 配置克隆等）。
