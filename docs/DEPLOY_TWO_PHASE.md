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

## Windows Git Bash 验收

```bash
fnm --version && node -v && uv --version && python --version
command -v codewhale && codewhale --version
```

- 命令为 **`codewhale`**（小写），非 `CodeWhale`
- 新开 Git Bash 即可用 fnm/uv，无需手敲 `eval "$(fnm env)"`

## 多 Windows 用户（Administrator + xiaoli 等）

每个账户在**该用户**的 Git Bash 中各执行一遍 Phase 1 与 Phase 2（`AppData` 不共享）。
