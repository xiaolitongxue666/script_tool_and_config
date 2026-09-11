# Project Codex Rules

本文件为 Codex 入口；完整编码指南见仓库根目录 [AGENTS.md](../AGENTS.md)，WSL 排错见 [docs/PROJECT_AGENT_MEMORY.md](../docs/PROJECT_AGENT_MEMORY.md)。

核心原则（与 `.cursor/rules/ai-project-principles.mdc` 一致）：

1. 项目包含一部分独立工具脚本（`scripts/common/standalone_tool_script/` 等），**永不删除**。
2. 项目主要功能是通过 chezmoi + 模板 + 辅助脚本，在不同 OS/WSL 安装和配置所需软件。
3. 部署只能通过 chezmoi 应用模板的方式进行（`./deploy.sh` 或 `./scripts/manage_dotfiles.sh apply`）。
4. **WSL 与 Windows 完全独立**：WSL 内 `install.sh` 只装 WSL Layer 4（claude / codex / cursor），与宿主机 npm **无关**。**禁止**从 WSL 调用 `cmd.exe` 或改 `/mnt/c`、`/mnt/host/c` Windows npm。`/mnt/host/wslg/.../fnm_multishells` 是 WSL 本机 fnm。见 `.cursor/rules/wsl-windows-isolation.mdc`。**CodeWhale 已移除（勿恢复）**；AI Agent 配置见 agent-config；Pi 仅 Phase 2。
