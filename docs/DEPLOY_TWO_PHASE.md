# 两阶段部署（本仓库 + agent-config）

## 职责边界（SSOT）

| 仓库 | 职责 |
|------|------|
| **script_tool_and_config（本仓库）** | **非 AI** 软件：fnm/uv、git、shell、终端、tmux/rmux 等 dotfiles |
| **[agent-config](../../AI/agent-config)** | **全部 AI Agent**：CLI、MCP、Skills、Harness（含 **Pi**） |

> 存量双路径：本仓库 Layer 4 `run_once_90` / `91` / `93` 与 agent-config `install-tools.sh` 均可安装部分 Agent CLI（功能重复）；**当前保留两侧**，后续再收敛。**Pi 仅 agent-config Phase 2**；**CodeWhale 已从本仓与 agent-config 移除（勿恢复）**。

## Phase 1 — 本仓库（非 AI + fnm）

```bash
eval "$(fnm env)"
./deploy.sh
```

Layer 4（存量，可选）：`90` claude → `91` codex → `93` cursor（GUI）。Pi 仅 Phase 2。

**不**写入 `~/.claude/settings.json`、`~/.pi/agent/` 等 Agent 全局配置。

## Phase 2 — agent-config（全部 AI）

```bash
cd /path/to/agent-config
bash scripts/install-tools.sh
```

负责：全部 Agent CLI（Claude / Cursor / Codex / **Pi**）、MCP、Skills、CodeGraph、`/commit-push` 与 `/summary-memory` 全局包装器。

- Pi 文档：[agent-config/docs/PI.md](../../AI/agent-config/docs/PI.md)
- 四 Agent 自定义命令 canonical 源：`agent-config/platforms/*/slash-commands/` 与 `platforms/codex/prompts/`、`platforms/pi/harness/COMMANDS.md`

## Windows Git Bash 验收

```bash
fnm --version && node -v
command -v claude && command -v codex
# Phase 2 后（agent-config）：
command -v pi && test -f ~/.pi/agent/settings.json
```

- **`chezmoi apply` 须 `--force`**；`./deploy.sh` 已处理

## 多环境

各 OS / WSL 须在对应环境各执行一遍 Phase 1 与 Phase 2（`$HOME` 独立）。
