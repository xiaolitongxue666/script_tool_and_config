# Pi（终端 Coding Harness，Layer 4）

[Pi](https://github.com/earendil-works/pi) 是极简终端 coding agent CLI（**minimal harness**：极简核心、无限扩展，不 fork 主仓库即可定制）。本项目通过 chezmoi [`run_once_94-install-pi`](../.chezmoi/run_once_94-install-pi.sh.tmpl) 安装二进制，并通过 [`dot_pi/agent/`](../.chezmoi/dot_pi/agent/) 模板部署最小 Harness 脚手架（默认 DeepSeek v4 Flash）。

**文档阅读顺序（唯一流程）**：`PI.md`（本文）→ [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) → [PI_SOURCE_READING.md](PI_SOURCE_READING.md) → [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md)。说明见 [PI_LEARNING_GUIDE § 文档阅读顺序](PI_LEARNING_GUIDE.md#本项目-pi-文档阅读顺序)。

## 设计理念与运行模式

Pi 默认只提供 `read` / `write` / `edit` / `bash` 四工具；MCP、sub-agents、plan mode 等通过 Extension 或 Package 自建。源码精读见 [PI_SOURCE_READING.md](PI_SOURCE_READING.md)（流程第 3 站）。

| 模式 | 入口 | 用途 |
|------|------|------|
| Interactive TUI | `pi` | 日常结对编程（默认） |
| Print / JSON | `pi -p` / `--mode json` | 脚本、CI |
| RPC | `pi --mode rpc` | 进程集成 |
| SDK | `createAgentSession` | 自建上层应用 |

可选社区工程规范（mattpocock / addyosmani Skills）移植见 [PI_CUSTOMIZATION.md §12](PI_CUSTOMIZATION.md#12-社区-skills-移植mattpocockskills--addyosmaniagent-skills)。

## WSL 快速流程（推荐）

在仓库根目录执行 [`deploy.sh`](../deploy.sh) 或 [`scripts/manage_dotfiles.sh`](../scripts/manage_dotfiles.sh)：

```bash
cd /path/to/script_tool_and_config
eval "$(fnm env)"
./deploy.sh
# 或轻量：./scripts/manage_dotfiles.sh apply
```

验证：

```bash
command -v pi && pi --version
test -f ~/.pi/agent/settings.json
grep -q deepseek-v4-flash ~/.pi/agent/settings.json
npm list -g @earendil-works/pi-coding-agent   # WSL：应指向 fnm 全局，非 /mnt/.../npm
```

**注意**：WSL 内安装/更新 Pi 只通过上述项目脚本 + WSL fnm/npm；**不要**从 WSL 用 `cmd.exe` 修改 Windows npm。排错见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。

## 安装（项目默认）

| 项 | 说明 |
|----|------|
| 脚本 | [`.chezmoi/run_once_94-install-pi.sh.tmpl`](../.chezmoi/run_once_94-install-pi.sh.tmpl) |
| 方式 | **全平台含 WSL**：`npm install -g --ignore-scripts @earendil-works/pi-coding-agent` |
| 前置 | [`run_once_00-install-version-managers`](../.chezmoi/run_once_00-install-version-managers.sh.tmpl)（fnm / node） |
| 命令 | `pi` |
| 网络 | 安装前 `setup_proxy`；默认 `http://127.0.0.1:7890`；WSL 为 `http://<宿主机IP>:7890` |
| 失败 | 非致命 `[WARNING]`，可手动重试安装命令 |

可选环境变量：

- `PI_NPM_VERSION` — 钉扎 npm 版本（默认 latest）
- `PROXY` / `http_proxy` — 覆盖默认 7890
- `DEEPSEEK_API_KEY` — 与 CodeWhale 共用；Pi 通过 `auth.json` 或环境变量读取

## Harness 配置（本仓库 chezmoi 管理）

| 路径 | 模板 | 说明 |
|------|------|------|
| `~/.pi/agent/settings.json` | [`.chezmoi/dot_pi/agent/settings.json.tmpl`](../.chezmoi/dot_pi/agent/settings.json.tmpl) | 默认 Flash；Ctrl+P 在 Flash/Pro 间切换 |
| `~/.pi/agent/models.json` | [`.chezmoi/dot_pi/agent/models.json.tmpl`](../.chezmoi/dot_pi/agent/models.json.tmpl) | V4 Flash/Pro 的 `modelOverrides`（思考链、**contextWindow 1M**） |
| `~/.pi/agent/AGENTS.md` | [`.chezmoi/dot_pi/agent/AGENTS.md.tmpl`](../.chezmoi/dot_pi/agent/AGENTS.md.tmpl) | 全局 coding 上下文 |
| `~/.pi/agent/APPEND_SYSTEM.md` | [`.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl`](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) | 行为规则（中文回复、代理、命令引用） |
| `~/.pi/agent/COMMANDS.md` | [`.chezmoi/dot_pi/agent/COMMANDS.md.tmpl`](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl) | **`/commit-push`**、**`/summary-memory`** 流程（与四 Agent 对齐） |

可选目录（当前**未** chezmoi 模板化，可自行添加）：`~/.pi/agent/prompts/`、`skills/`、`extensions/`、`themes/`。项目级覆盖见 `.pi/settings.json`（需 `/trust` 或 `pi -a`）；本仓库 v1 **不** chezmoi 管理各项目 `.pi/`。

**不** chezmoi 管理：`auth.json`（run_once 按需创建）、sessions、`/login` OAuth 产物。

### DeepSeek V4 Flash / Pro

Pi 内置 `deepseek` provider（**无需**自建 `openai_compatible` 端点）。本仓库约定：

| 模型 | 定位 | 典型场景 |
|------|------|----------|
| `deepseek-v4-flash` | 默认；低延迟、高性价比 | 单文件修改、快速查代码、简单测试 |
| `deepseek-v4-pro` | 强推理（`reasoning` + `xhigh`） | 跨文件重构、复杂编译/运行时错误 |

`models.json` 的 `modelOverrides` 会覆盖 pi 框架层模型元数据；本仓库将 Flash/Pro 的 `contextWindow` 设为 **1M**（`1000000`）。勿保留 `64000`，否则长会话会被框架提前截断（与 DeepSeek API 实际上下文无关）。模板见 [models.json.tmpl](../.chezmoi/dot_pi/agent/models.json.tmpl)。

调度方式：

```bash
# CLI 一次性
pi --model deepseek-v4-flash -p "List all .sh files under scripts/"
pi --model deepseek-v4-pro -p "Refactor this module and fix build errors"

# 交互式 TUI
pi
/model deepseek-v4-flash    # 或 Ctrl+L / Ctrl+P 在两者间切换
/model deepseek-v4-pro
```

`Shift+Tab` 切换 thinking level；Pro 推荐 `high`/`xhigh`，Flash 可用 `low`/`medium`。

### 认证

**方式 1 — `/login`（推荐，密钥持久化）**

```
/login
→ Use an API key          ← 勿选 Use a subscription
→ DeepSeek
→ 粘贴 sk-...
```

订阅列表（Anthropic/Codex/Copilot）**不含** DeepSeek。

**方式 2 — 环境变量**

```bash
export DEEPSEEK_API_KEY="sk-..."    # 与 CodeWhale 共用
pi
```

[`run_once_94`](../.chezmoi/run_once_94-install-pi.sh.tmpl) 在 `auth.json` 缺失、为空 `{}`、或尚无 `deepseek` 条目时写入（**不**覆盖含其他 provider 的已有配置）：

```json
{ "deepseek": { "type": "api_key", "key": "$DEEPSEEK_API_KEY" } }
```

已存在则跳过，不覆盖 `/login` 结果。API Key **不**写入本仓库模板。

## 与 Claude Code / Codex / CodeWhale / Cursor 的关系

| 工具 | 角色 |
|------|------|
| Claude Code / Codex / Cursor | 主项目 IDE/订阅流 |
| CodeWhale | [DeepSeek TUI 终端代理](CODEWHALE.md) |
| **Pi** | 可扩展 Harness 微内核；侧项目、coding 实验、多模型切换 |

Layer 4 字母序：`90` [claude](../.chezmoi/run_once_90-install-claude-code.sh.tmpl) → `91` [codex](../.chezmoi/run_once_91-install-codex.sh.tmpl) → `92` [codewhale](../.chezmoi/run_once_92-install-codewhale.sh.tmpl) → `93` [cursor](../.chezmoi/run_once_93-install-cursor.sh.tmpl) → **`94` [pi](../.chezmoi/run_once_94-install-pi.sh.tmpl)**。

v1 **不**预装 pi packages（pi-web-access、pi-cursor-sdk 等）；MCP/Skills 扩展留 agent-config Phase 2。

## 自定义命令（`/commit-push`、`/summary-memory`）

Pi 无原生 slash 注册；Harness 通过 `~/.pi/agent/COMMANDS.md`（chezmoi [`dot_pi/agent/COMMANDS.md.tmpl`](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl)）提供与 Cursor / Claude / CodeWhale **语义一致**的两条命令。

| 命令 | 核心描述 |
|------|----------|
| `/commit-push` | 分析改动 → 按需更新 `.gitignore` → Conventional Commit → `git-smart-commit` → push |
| `/summary-memory` | 清理冗余 → 会话提炼 → 更新 [`PROJECT_MEMORY.md`](PROJECT_MEMORY.md)；控制 memory 文件大小/日期 |

底层脚本在 agent-config：`scripts/git-smart-commit.sh`、`scripts/summary-project-memory.sh`。Phase 2 安装后可用全局包装器 `git-smart-commit`、`summary-project-memory`。

## 故障排查

| 现象 | 处理 |
|------|------|
| WSL `command -v pi` 指向 `/mnt/c/.../npm` | 在 WSL 内 `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` |
| 模型 ID 无效 | `pi` 内 `/model` 选择；或编辑 `settings.json` 的 `defaultModel` |
| 无 API Key | `export DEEPSEEK_API_KEY` 或 `/login` → **Use an API key** → DeepSeek |
| 上下文被限制 ~64K | `models.json` `contextWindow` 误为 64000 | [models.json.tmpl](../.chezmoi/dot_pi/agent/models.json.tmpl) 改为 `1000000` 后 [`manage_dotfiles.sh apply`](../scripts/manage_dotfiles.sh) |
| npm 安装失败 | 确认 7890 代理；手动重试安装命令 |

卸载：`npm uninstall -g @earendil-works/pi-coding-agent`（`~/.pi/agent/` 保留，符合上游文档）。
