# Project Codex Rules

本文件为 Codex 入口；完整编码指南见仓库根目录 [AGENTS.md](../AGENTS.md)，WSL 排错见 [docs/PROJECT_AGENT_MEMORY.md](../docs/PROJECT_AGENT_MEMORY.md)。

核心原则（与 `.cursor/rules/ai-project-principles.mdc` 一致）：

1. 项目包含一部分独立工具脚本（`scripts/common/standalone_tool_script/` 等），**永不删除**。
2. 项目主要功能是通过 chezmoi + 模板 + 辅助脚本，在不同 OS/WSL 安装和配置所需软件。
3. 部署只能通过 chezmoi 应用模板的方式进行（`./deploy.sh` 或 `./scripts/manage_dotfiles.sh apply`）。
4. **WSL 部署**：在 WSL 内安装/更新 Layer 4 工具（claude / codex / cursor）；**禁止**从 WSL 调用 `cmd.exe` 修改 Windows npm 或卸载 Windows 侧包。**CodeWhale 已从本仓与 agent-config 移除（勿恢复）**；AI Agent 配置见 agent-config（4 agents + CodeGraph）；Pi 仅 Phase 2。
