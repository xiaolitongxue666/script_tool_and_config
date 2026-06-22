# Pi 生态与专属定制指南

面向希望将 Pi 打造成**长期专属 Agent 框架**的用户：生态参考、配置分层、Package/SDK、社区 Skills 移植。安装与排错见 [PI.md](PI.md)；上手练习见 [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md)；**须先完成** [PI_SOURCE_READING.md](PI_SOURCE_READING.md) 本地源码精读。

**阅读顺序（唯一流程）**：

```text
PI.md  →  PI_LEARNING_GUIDE.md  →  PI_SOURCE_READING.md  →  PI_CUSTOMIZATION.md（本文）
```

---

## 1. 设计理念（极简核心，无限扩展）

[Pi](https://github.com/earendil-works/pi) 是 **minimal terminal coding harness**，不是 Cursor 式开箱即用产品。官方哲学：

- **不内置** MCP、sub-agents、plan mode、permission popup、内置 to-do
- 上述能力通过 **Extension**、**Skill**、**Prompt template**、**Pi Package** 自建或安装
- **不 fork 主仓库**——在 `~/.pi/agent/` 与项目 `.pi/` 上定制即可

与本项目关系：v1 仅 chezmoi 部署 Harness 脚手架（[`dot_pi/agent/`](../.chezmoi/dot_pi/agent/)）；`settings.json` 中 `"packages": []`；第三方 packages / 全局 Skills 扩展留 agent-config Phase 2。

上游：[pi.dev](https://pi.dev/) · [Philosophy（README）](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md#philosophy)

---

## 2. 官方生态与参考实现

| 扩展 | 定位 | 参考价值 | 何时装 |
|------|------|----------|--------|
| [pi-review](https://github.com/earendil-works/pi-review) | `/review`、`/end-review` 评审工作流 | `REVIEW_GUIDELINES.md` 注入规范；对标本项目 [COMMANDS.md](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl) 的 Markdown 工作流模式 | 确定日常用 Pi 做 PR review |
| [pi-chat](https://github.com/earendil-works/pi-chat) | Discord/Telegram → 沙箱化 Pi | Gondolin VM、多通道隔离、`memory.md` 持久化 | 部署 7×24 聊天机器人服务 |
| [pi-tutorial](https://github.com/earendil-works/pi-tutorial) | 交互式 TUI 教程 | 事件流与 TUI 组件定制 | `pi -e` 临时体验即可 |

```bash
pi -e https://github.com/earendil-works/pi-tutorial
pi install npm:@earendil-works/pi-review   # 将来需要时
pi list && pi config
```

---

## 3. 社区范式：OpenClaw

[openclaw/openclaw](https://github.com/openclaw/openclaw) 是 Pi **SDK 嵌入**的真实世界案例：在外部用 TypeScript 扩展或 SDK 叠加子智能体、规划等「重型」行为，而非改 Pi 内核。

发现更多 package：npm 搜索 `pi-package` keyword、`pi install git:github.com/...`、上游 Discord 社区。

---

## 4. 四种运行模式

| 模式 | 入口 | 用途 |
|------|------|------|
| Interactive TUI | `pi`（默认） | 日常结对编程 |
| Print / JSON | `pi -p "..."` / `pi --mode json` | 脚本、CI 一次性任务 |
| RPC | `pi --mode rpc` | 非 Node 进程集成（stdin/stdout JSONL） |
| SDK | `createAgentSession` | 自建上层框架或 UI |

SDK 最小示例（上游正确 import）：

```typescript
import {
    AuthStorage,
    createAgentSession,
    ModelRegistry,
    SessionManager,
} from "@earendil-works/pi-coding-agent";

const authStorage = AuthStorage.create();
const modelRegistry = ModelRegistry.create(authStorage);
const { session } = await createAgentSession({
    sessionManager: SessionManager.inMemory(),
    authStorage,
    modelRegistry,
});
await session.prompt("List all .sh files under scripts/");
```

详见 [sdk.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/sdk.md)。

---

## 5. 专属配置：全局 vs 项目

> **勿使用**参考材料中的 `.pi/config.json`、`system_instruction_path`、`temperature`。Pi 使用 `settings.json` + Markdown 上下文文件。

### 配置目录

```text
~/.pi/agent/                 # 全局（本项目 chezmoi 管理，模板见 [dot_pi/agent/](../.chezmoi/dot_pi/agent/)）
├── settings.json
├── models.json
├── AGENTS.md
├── APPEND_SYSTEM.md
├── COMMANDS.md
├── prompts/  skills/  extensions/  themes/
└── auth.json                # 不提交

my-project/
├── AGENTS.md 或 CLAUDE.md   # 启动时向上递归加载（本仓库根 [AGENTS.md](../AGENTS.md)）
└── .pi/                     # 项目级（需 /trust 或 pi -a）
    ├── settings.json        # 覆盖全局 settings（嵌套合并）
    ├── SYSTEM.md            # 可选：替换默认 system prompt
    ├── prompts/  skills/  extensions/
    └── npm/  git/           # pi install -l 本地包
```

项目级 `.pi/settings.json` 覆盖 `~/.pi/agent/settings.json`；嵌套对象（如 `compaction`）按字段合并。见上游 [settings.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/settings.md)。

### 上下文注入方式

| 文件 | 作用 |
|------|------|
| `SYSTEM.md` | **替换**默认 system prompt |
| `APPEND_SYSTEM.md` | **追加**系统规则（本项目已用，模板见 [APPEND_SYSTEM.md.tmpl](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl)） |
| `AGENTS.md` / `CLAUDE.md` | 项目/全局 coding 上下文（自动加载） |
| `COMMANDS.md` | 自定义工作流描述（语义对齐 Cursor；非原生 slash 注册；模板见 [COMMANDS.md.tmpl](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl)） |

Pi **无** settings 级 `temperature`；用 `defaultThinkingLevel`（`low` / `medium` / `high` / `xhigh`）控制推理深度。

### 本项目推荐定制顺序

1. [settings.json.tmpl](../.chezmoi/dot_pi/agent/settings.json.tmpl) — 默认模型、代理、compaction
2. [models.json.tmpl](../.chezmoi/dot_pi/agent/models.json.tmpl) — Flash/Pro 元数据与 1M context
3. [APPEND_SYSTEM.md.tmpl](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) — 行为原则（最小改动、中文、风险确认、测试入口）
4. [AGENTS.md.tmpl](../.chezmoi/dot_pi/agent/AGENTS.md.tmpl) — 全局 coding 上下文
5. [COMMANDS.md.tmpl](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl) — `/commit-push`、`/summary-memory` 工作流
6. 项目根 [AGENTS.md](../AGENTS.md) — 单项目架构（本仓库已有）
7. `~/.pi/agent/prompts/*.md` — 轻量 `/review` 等
8. `.pi/skills/` 或 Extension / Package — 进阶

### 行为原则示例（本仓库技术栈）

可在 [`APPEND_SYSTEM.md`](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) 中追加或微调：

```markdown
# 核心行为原则
1. **最小改动**：不重构无关逻辑；修改 shell 脚本时保持现有风格与 LF 换行。
2. **渐进交付**：复杂改动先输出分步计划，确认后再改文件。
3. **安全至上**：`rm -rf`、`git reset --hard` 等破坏性命令前须确认。
4. **验证证据**：改动后优先 `bash tests/test_syntax.sh`；部署相关用 `./deploy.sh` 或 `./scripts/manage_dotfiles.sh diff`。
5. **技术栈**：chezmoi 模板、bash、Layer 0–5 run_once；勿引入与本仓库无关的框架假设。
```

改模板后：[`./deploy.sh`](../deploy.sh) 或 [`./scripts/manage_dotfiles.sh apply`](../scripts/manage_dotfiles.sh)，Pi 内 `/reload`。相关脚本：[`tests/test_syntax.sh`](../tests/test_syntax.sh)。

---

## 6. Skills 与 Extensions

### Skill（推荐优先）

- 格式：[Agent Skills 标准](https://agentskills.io) — `skills/<name>/SKILL.md` 或单文件 `skills/foo.md`
- 调用：`/skill:name`（`enableSkillCommands` 默认 true）或模型按 description 自动选用
- 机制：**渐进式披露** — 启动只列元数据，执行前再 `read` 全文，节省 Token

路径：`~/.pi/agent/skills/`、`.pi/skills/`、`.agents/skills/`（从 cwd 向上）、项目 package。

### Extension（进阶）

TypeScript 模块，默认导出工厂函数：

```typescript
export default function (pi: ExtensionAPI) {
    pi.registerTool({ name: "run_syntax_check", /* ... */ });
    pi.registerCommand("syntax", { /* handler */ });
    pi.on("tool_call", async (event, ctx) => { /* permission gate */ });
}
```

路径：`~/.pi/agent/extensions/`、`.pi/extensions/` 或 Pi Package。

> **勿使用** `@earendil-works/pi-core` 或 `registerSlashCommand`；正确 API 见 [extensions 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions)。

### Pi Package 安装

```bash
pi install npm:@foo/pi-tools
pi install git:github.com/user/my-pi-config
pi install ./my-local-package
pi remove npm:@foo/pi-tools
pi update --extensions
```

第三方 package 以**完整系统权限**运行；安装前宜审阅源码。见 [packages.md 安全说明](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md)。

---

## 7. 构建专属 Pi Package

`package.json` 示例：

```json
{
  "name": "my-pi-config",
  "keywords": ["pi-package"],
  "pi": {
    "extensions": ["./extensions"],
    "skills": ["./skills"],
    "prompts": ["./prompts"],
    "themes": ["./themes"]
  }
}
```

```bash
pi install ./my-pi-config
pi install git:github.com/yourusername/my-pi-config
```

精读标杆：[pi-review](https://github.com/earendil-works/pi-review) — 体量适中，代表「独立 Package + Markdown 规范注入」范式。

---

## 8. 持久化记忆（memory.md）

| 场景 | 路径 | 说明 |
|------|------|------|
| pi-chat 服务化 | `/shared/memory.md`、`/workspace/memory.md` | 账户级 / 频道级持久记忆 |
| 本地项目（可选） | `.pi/memory.md` | 会话结束写入；下次启动可读 |
| 本仓库约定 | [`PROJECT_MEMORY.md`](PROJECT_MEMORY.md) | `/summary-memory`（[COMMANDS.md.tmpl](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl)）— 可提交的项目级记忆 |

分工：Pi 侧 `memory.md` / handoff 偏**会话交接**；[`PROJECT_MEMORY.md`](PROJECT_MEMORY.md) 偏**仓库级可提交知识**。

---

## 9. 沙盒与安全

| 层级 | 行为 |
|------|------|
| 默认 `pi-coding-agent` | `bash` 在**宿主机**执行；须靠 Extension 做权限门或用户确认 |
| pi-chat + [gondolin](https://github.com/earendil-works/gondolin) | 工具路由进 Alpine micro-VM；服务部署参考 |
| 本项目 Harness | [APPEND_SYSTEM.md.tmpl](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) 要求破坏性命令前确认 |

---

## 10. 与本仓库的落地检查清单

1. 改 [`.chezmoi/dot_pi/agent/`](../.chezmoi/dot_pi/agent/) 模板 → [`./deploy.sh`](../deploy.sh)
2. 验证：`grep contextWindow ~/.pi/agent/models.json` 应为 `1000000`
3. 只读探索：`pi --tools read,grep,find,ls -p "..."`
4. 项目级 Skills：`.pi/skills/` + `/trust` 或 `pi -a`
5. Pi 内 `/reload` 使配置生效

---

## 11. 读源码：动机与导读入口

完成 [PI_SOURCE_READING.md](PI_SOURCE_READING.md) 是进入本文前的**必经第 3 站**。重在**拆解设计哲学**（极简、可扩展），不是 fork 主仓。

### 三个必读动机

| 动机 | 学什么 |
|------|--------|
| Tool Use 与隔离 | 工具注册/分发；默认**宿主机** bash vs pi-chat 的 Gondolin VM |
| 极简 Agent 状态机 | 主循环、流式输出、中断与消息排队 |
| 上下文管理 | [AGENTS.md](../.chezmoi/dot_pi/agent/AGENTS.md.tmpl) 加载、compaction、system prompt 组装 |

### 详细分步与文件链接

**分 7 个阶段、可点击跳转到本地 `../../pi/` 源码**：见 [PI_SOURCE_READING.md](PI_SOURCE_READING.md)（阶段 0–7）。

> 不存在独立 `earendil-works/pi-core` 仓库；核心在本地 `pi/packages/` monorepo。

---

## 12. 社区 Skills 移植：mattpocock/skills + addyosmani/agent-skills

建议先完成 [PI_SOURCE_READING.md](PI_SOURCE_READING.md) **阶段 4**（上下文、Skills、Extensions），再按本节移植社区规范。

### 核心结论

[mattpocock/skills](https://github.com/mattpocock/skills) 与 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 均为**纯 Markdown** 工程规范（[Agent Skills 标准](https://agentskills.io)），与 Pi 渐进式 Skill **天然兼容**——心法（工作流纪律）+ 兵器（Pi TUI/工具），**无需** Claude Code marketplace 或 fork Pi。

### 两仓库定位

| 仓库 | 特化 | 在 Pi 中解决的痛点 | 代表 Skill |
|------|------|-------------------|------------|
| mattpocock/skills | 垂直切片、盘问对齐、Issue/PRD 流 | Agent 写着写着跑偏 | `grilling`、`tdd`、`to-issues`、`handoff`、`setup-matt-pocock-skills` |
| addyosmani/agent-skills | 全生命周期工程纪律、反辩解闸门 | 不写测试、鲁莽重构、单次改动过大 | `using-agent-skills`（meta）、`spec-driven-development`、`incremental-implementation`、`test-driven-development` |

### 与本项目关系

- v1 **不** chezmoi 预装；用户自行维护 `~/.pi/agent/skills/` 或项目 `.pi/skills/`
- 上游 Vitest/Next.js 示例映射为本仓库：`bash [tests/test_syntax.sh](../tests/test_syntax.sh)`、[`./deploy.sh`](../deploy.sh)、[`./scripts/manage_dotfiles.sh diff`](../scripts/manage_dotfiles.sh)
- Matt 包：每仓库须运行一次 `setup-matt-pocock-skills` 配置 Issue tracker / triage labels
- `handoff` skill 与 `/summary-memory`（[`PROJECT_MEMORY.md`](PROJECT_MEMORY.md)）互补

### 方案 A：渐进式披露（推荐）

```text
my-project/.pi/skills/
├── using-agent-skills/SKILL.md    # Addy meta 路由
├── incremental-implementation/SKILL.md
└── tdd/SKILL.md                   # 从 mattpocock 拷贝
```

操作步骤：

1. 克隆上游仓库，或将 `skills/**/SKILL.md` **手动拷贝**到 `.pi/skills/`（也可用 `npx skills add <owner/repo>` 若 CLI 支持你的 Agent）
2. 在 [APPEND_SYSTEM.md.tmpl](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) 或项目 [AGENTS.md](../AGENTS.md) **仅常驻一句路由**：「任务到达时先读 `using-agent-skills` 或 `ask-matt`，再按需加载具体 Skill」
3. 首次加载项目资源：`/trust` 或 `pi -a`
4. `pi` 内 `/reload`；显式调用 `/skill:tdd` 或由模型按 description 选用

### 方案 B：斜杠命令式注入（进阶）

| 手段 | 做法 | 适用 |
|------|------|------|
| Prompt template | `prompts/spec.md` → 输入 `/spec` 展开 | 快速模拟 Addy `/spec`、`/ship` |
| Extension | `pi.registerCommand('spec', handler)` 动态 read `SKILL.md` | 需要固定 slash 体验 |
| 原生 skill | `/skill:spec-driven-development` | 零代码，与方案 A 合一 |

默认引导 **方案 A + `/skill:name`**，不把方案 B 作为唯一路径。

### Claude slash → Pi 映射（示例）

| Claude / Addy 入口 | Pi 等价 |
|--------------------|---------|
| `/spec` | `/skill:spec-driven-development` 或 `prompts/spec.md` → `/spec` |
| `/plan` | `/skill:planning-and-task-breakdown` |
| `/build` | `/skill:incremental-implementation` |
| `/test` | `/skill:test-driven-development` |
| `/review` | `/skill:code-review-and-quality` 或 `prompts/review.md` |
| `/ship` | `/skill:shipping-and-launch` |
| Matt `/grill-me` | `/skill:grilling` 或 `/skill:grill-me` |

### 五条明星铁律

| 铁律 | 含义 | 本仓库 Pi 落地 |
|------|------|----------------|
| Tracer Bullet（垂直切片） | 先打通极细端到端链路 | 单次只改一个 [run_once](../.chezmoi/) 或一个 [`scripts/`](../scripts/) 子目录 |
| Beyoncé Rule | 不信口头完成，要测试日志证据 | 要求贴 `bash [tests/test_syntax.sh](../tests/test_syntax.sh)` 输出 |
| Chesterton's Fence | 重构前说明旧代码存在理由 | 写入 [APPEND_SYSTEM.md.tmpl](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) |
| 100-Line PR Sizing | 单次变更约 100 行内 | 配合 `/commit-push` 小步提交 |
| Handoff | Token 将满时生成交接摘要 | `/compact` + `handoff` skill + `/summary-memory` |

### 安全与维护

- 第三方 Skill 会指导模型执行 bash；遵守本项目破坏性命令确认原则
- **勿**将完整上游 skills 仓库提交进本 dotfiles 仓
- Phase 2 agent-config 全局 skills 可与 `~/.agents/skills` 对齐（见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)）

---

## 延伸阅读

| 文档 | 说明 |
|------|------|
| [PI.md](PI.md) | 安装、Harness、认证、排错 |
| [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) | 新手路径与第 1 天练习 |
| [PI_SOURCE_READING.md](PI_SOURCE_READING.md) | 本地源码分阶段阅读（上一站） |
| [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md) | WSL 部署与 Agent 排错 |
| [pi-coding-agent README](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md) | 上游 CLI 完整文档 |
| [skills.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md) | Pi Skills 机制 |
| [Addy Osmani — Agent Skills 博客](https://addyosmani.com/blog/agent-skills/) | 渐进式披露与 meta-skill 设计 |
