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
- `run_once_94-install-pi` — `pi`（最小 Harness 在 `~/.pi/agent/`，含 `COMMANDS.md`；MCP/packages 留 Phase 2）

**不**写入 `~/.claude/settings.json`、`~/.codewhale/mcp.json` 等 Agent 全局配置（Pi 的 `settings.json`/`AGENTS.md`/`COMMANDS.md` 由本仓库 `dot_pi/agent/` 管理）。

## Phase 2 — agent-config

```bash
cd /path/to/agent-config
bash scripts/install-tools.sh
```

详见 agent-config 仓库 [`docs/DEPLOY_TWO_PHASE.md`](../../AI/agent-config/docs/DEPLOY_TWO_PHASE.md)。

### 全局 Agent 配置与自定义命令

Phase 2 还负责：

- **中文回复**、**7890 代理**（WSL 宿主机 IP）：见 agent-config `common/agents/common-agent-policy.md`
- **Cursor Commands** → `~/.cursor/commands/`（本仓库 `.cursor/rules/` 仅为项目 rules，不含 commands）
- **Slash 命令** → `~/.claude/commands/`、`~/.codewhale/commands/`
- **Codex prompts** → `~/.codex/`（v0.128+ 无 slash；自然语言或 `/commit-push` 同义触发）

**五 Layer 4 Agent 均须具备** `/commit-push` 与 `/summary-memory`（Pi 由 Phase 1 `dot_pi/agent/COMMANDS.md.tmpl` 补齐）。canonical 源：`agent-config/platforms/*/slash-commands/` 与 `platforms/codex/prompts/`。详见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md) § Agent 体系总览。

更新 command 正文后在本机执行：

```bash
cd /path/to/agent-config
bash scripts/apply-config.sh
```

## Windows Git Bash 验收

```bash
fnm --version && node -v && uv --version && python --version
command -v codewhale && codewhale --version
```

- 命令为 **`codewhale`**（全小写），非 `CodeWhale`
- 新开 Git Bash 即可用 fnm/uv，无需手敲 `eval "$(fnm env)"`
- **`chezmoi apply` 须 `--force`**；`./deploy.sh` 与 `./scripts/manage_dotfiles.sh apply` 已处理
- 若 apply 卡住：见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md) § Windows Git Bash chezmoi 部署

## 多 Windows 用户（Administrator + xiaoli 等）

每个账户在**该用户**的 Git Bash 中各执行一遍 Phase 1 与 Phase 2（`AppData` 不共享）。
