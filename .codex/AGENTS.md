# Project Codex Rules

本文件为 Codex 入口；完整编码指南见仓库根目录 [AGENTS.md](../AGENTS.md)，WSL 排错见 [docs/PROJECT_AGENT_MEMORY.md](../docs/PROJECT_AGENT_MEMORY.md)。

核心原则（与 `.cursor/rules/ai-project-principles.mdc` 一致）：

1. 项目包含一部分独立工具脚本（`scripts/tools/standalone_tool_script/` 等），**永不删除**。
2. 项目主要功能是通过 chezmoi + 模板 + 辅助脚本，在不同 OS/WSL 安装和配置所需软件。
3. 部署只能通过 chezmoi 应用模板的方式进行（`./deploy.sh` 或 `./scripts/manage_dotfiles.sh apply`）。
4. **WSL 与 Windows 完全独立**：WSL 内 `install.sh` 只装 **WSL 这一套**（完整 Layer：版本管理器 → AI CLI → install-* → run_on_*），与宿主机 npm **无关**。**禁止**从 WSL 调用 `cmd.exe` 或改 `/mnt/c`、`/mnt/host/c` Windows npm。`/mnt/host/wslg/.../fnm_multishells` 是 WSL 本机 fnm。SSH：Windows 只认 `%USERPROFILE%\.ssh`，MSYS2 的 `.ssh` 用 `run_once_windows-link-msys-ssh.sh` 联过去，不另存 config。登录 desktop-pc 的 shell 是 Git Bash（`D:\Program Files\Git\usr\bin\bash.exe`），不是 PowerShell。`Ubuntu-24.04` 的 `/root/.ssh` 保存本机 `desktop-win` 私钥副本，不要软链接到 Windows 盘。本机与 Mac 可登录全部设备；手机与平板只登录本机和 Mac。新设备私钥在该设备上生成。`moicen.com` 用户是 `xiaoli`，`alchemy-studio.cn` 用户是 `leonli`，共用 `id_ed25519_moicen-alchemy-2026-10-Nc`，这也是 GitHub 认证密钥。Mac 的 `github.com` 仍用 `5s`，desktop-pc 仍用 `C4`，`laptop-huawei` 仍用 `5A`。`Nc` 私钥只放在这三台管理机，不拷进 WSL、手机、平板或 Tailscale VPS。两台生产域名都已登录。见 `.cursor/rules/wsl-windows-isolation.mdc`。打洞失败时的 Tailscale 退路是 VPS peer relay，见 `docs/TAILSCALE_PEER_RELAY.md`。生产域名不进尾网。手机 Termux 的 Powerline 符号由本机 `~/.termux/font.ttf` 绘制（Maple Mono NL NF CN Regular），见 `docs/DEVICE_ACCESS.md`「Termux 字体」。**CodeWhale 已移除（勿恢复）**；AI Agent 配置见 agent-config；Pi 仅 Phase 2。
