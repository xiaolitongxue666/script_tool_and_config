# 两阶段部署（本仓库 + agent-config）

## Phase 1 — 本仓库（二进制 + dotfiles）

```bash
eval "$(fnm env)"
./deploy.sh
```

Layer 4 安装（字母序）：

- `run_once_90-install-claude-code` — `claude`
- `run_once_91-install-codex` — `codex`
- `run_once_92-install-codewhale` — `codewhale` + `codewhale-tui`
- `run_once_93-install-cursor` — Cursor 编辑器（仅 GUI）

**不**写入 `~/.claude/settings.json`、`~/.codewhale/mcp.json` 等 Agent 全局配置。

## Phase 2 — agent-config

```bash
cd /path/to/agent-config
bash scripts/install-tools.sh
```

详见 agent-config 仓库 [`docs/DEPLOY_TWO_PHASE.md`](../../AI/agent-config/docs/DEPLOY_TWO_PHASE.md)。
