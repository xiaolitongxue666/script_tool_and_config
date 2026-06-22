# Pi 本地源码阅读指南

在 [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) 完成上手练习后，按本文**分阶段精读**本地 [earendil-works/pi](https://github.com/earendil-works/pi) monorepo。读完再进入 [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) 做 Skills / Package / 社区规范移植。

**预计耗时**：1–2 晚（可按阶段拆到多天）。

## 前置条件

| 项 | 说明 |
|----|------|
| 本地 clone | `E:\Code\my_code\DotfilesAndScript\pi`（与 [`script_tool_and_config`](../) 同级） |
| 工作区 | Cursor 须同时打开 `script_tool_and_config` 与 `pi`，下文链接方可点击跳转 |
| 链接格式 | 相对路径 `../../pi/...`（从本 `docs/` 目录出发） |
| 已完成 | [PI.md](PI.md) 安装验证 + [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) 第 1 天练习 |

## 在整体学习流程中的位置

```text
PI.md  →  PI_LEARNING_GUIDE.md  →  PI_SOURCE_READING.md  →  PI_CUSTOMIZATION.md
运维        上手与练习                本地源码精读（本文）        进阶定制
```

---

## 阶段 0 — 地图（约 15 分钟）

先建立 monorepo 包关系，再进 `src/`。

| 文件 | 关注点 |
|------|--------|
| [packages/coding-agent/README.md](../../pi/packages/coding-agent/README.md) | Philosophy、四种运行模式、CLI 概览 |
| [packages/coding-agent/docs/index.md](../../pi/packages/coding-agent/docs/index.md) | 官方文档索引 |
| [packages/agent/package.json](../../pi/packages/agent/package.json) | npm 包 `@earendil-works/pi-agent-core` |
| [packages/coding-agent/package.json](../../pi/packages/coding-agent/package.json) | CLI 包依赖：`pi-agent-core`、`pi-ai`、`pi-tui` |

**包分工速记**：

- `packages/agent` — Agent 循环与 Harness 抽象
- `packages/coding-agent` — CLI、内置工具、Skills/Extensions、会话
- `packages/ai` — 多 Provider 与模型层（阶段 7 可选）
- `packages/tui` — 终端 UI 组件（交互模式底层）

---

## 阶段 1 — Agent 核心循环（`packages/agent`）

**目标**：理解「极简 Agent 状态机」——流式输出、tool 调用、事件边界。

| 顺序 | 文件 | 关注点 |
|------|------|--------|
| 1 | [types.ts](../../pi/packages/agent/src/types.ts) | `AgentMessage`、`AgentTool`、`AgentEvent`、`AgentLoopConfig` |
| 2 | [agent-loop.ts](../../pi/packages/agent/src/agent-loop.ts) | `agentLoop()`、`runAgentLoop`、LLM 与 tool 往返 |
| 3 | [agent.ts](../../pi/packages/agent/src/agent.ts) | `Agent` 类封装、对外 prompt 接口 |
| 4 | [harness/agent-harness.ts](../../pi/packages/agent/src/harness/agent-harness.ts) | Harness 抽象与扩展点 |
| 5 | [harness/system-prompt.ts](../../pi/packages/agent/src/harness/system-prompt.ts) | system prompt 组装（对照本项目 [APPEND_SYSTEM.md.tmpl](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl)） |

**对照练习**：在 [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) 里用过的 `/tree`、`Escape` 中断，对应 `agent-loop` 里的事件与 abort signal 处理。

---

## 阶段 2 — CLI 启动与会话（`packages/coding-agent`）

**目标**：从 `pi` 命令到 `AgentSession` 的启动链。

| 顺序 | 文件 | 关注点 |
|------|------|--------|
| 1 | [cli.ts](../../pi/packages/coding-agent/src/cli.ts) | Node 进程入口、`main()` 调用 |
| 2 | [main.ts](../../pi/packages/coding-agent/src/main.ts) | 解析参数、选模式、`createAgentSession` / Runtime |
| 3 | [cli/args.ts](../../pi/packages/coding-agent/src/cli/args.ts) | `--mode`、`-p`、`--tools`、`-e`、`--no-context-files` |
| 4 | [core/sdk.ts](../../pi/packages/coding-agent/src/core/sdk.ts) | `createAgentSession()` 选项、默认内置工具注册 |
| 5 | [core/agent-session.ts](../../pi/packages/coding-agent/src/core/agent-session.ts) | 交互会话、`pi.registerCommand` 调度、流式 UI 事件 |
| 6 | [core/session-manager.ts](../../pi/packages/coding-agent/src/core/session-manager.ts) | JSONL 会话树、`/tree` `/fork` 数据模型 |

**对照练习**：`pi --tools read,grep,find,ls` 对应 `sdk.ts` 里工具 allowlist；`pi -p` 走 [print-mode.ts](../../pi/packages/coding-agent/src/modes/print-mode.ts)（阶段 6）。

---

## 阶段 3 — 内置四工具

**目标**：理解 Tool Use 如何在**宿主机**执行（默认无 Gondolin VM）。

| 文件 | 关注点 |
|------|--------|
| [core/tools/read.ts](../../pi/packages/coding-agent/src/core/tools/read.ts) | 读文件、与 `@` 文件引用配合 |
| [core/tools/write.ts](../../pi/packages/coding-agent/src/core/tools/write.ts) | 创建/覆盖文件 |
| [core/tools/edit.ts](../../pi/packages/coding-agent/src/core/tools/edit.ts) | 精确片段替换 |
| [core/tools/bash.ts](../../pi/packages/coding-agent/src/core/tools/bash.ts) | **宿主机** shell；输出截断与超时 |
| [core/tools/index.ts](../../pi/packages/coding-agent/src/core/tools/index.ts) | `createCodingTools`、`createReadOnlyTools` 组合 |

**安全要点**：bash 在宿主机运行；服务化沙盒见 [pi-chat](https://github.com/earendil-works/pi-chat) + Gondolin，不在本仓库默认路径内。

---

## 阶段 4 — 上下文、Skills、Extensions

**目标**：弄清 `AGENTS.md`、Skill 渐进式披露、Extension 注册——与 [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) §5–§6、§12 直接衔接。

| 顺序 | 文件 | 关注点 |
|------|------|--------|
| 1 | [core/resource-loader.ts](../../pi/packages/coding-agent/src/core/resource-loader.ts) | `loadContextFileFromDir`、`AGENTS.md` 向上递归加载 |
| 2 | [core/system-prompt.ts](../../pi/packages/coding-agent/src/core/system-prompt.ts) | 上下文文件拼入最终 system prompt |
| 3 | [core/skills.ts](../../pi/packages/coding-agent/src/core/skills.ts) | `loadSkills`、`SKILL.md` 发现与元数据 |
| 4 | [core/extensions/loader.ts](../../pi/packages/coding-agent/src/core/extensions/loader.ts) | jiti 加载扩展、`registerTool` / `registerCommand` |
| 5 | [core/extensions/types.ts](../../pi/packages/coding-agent/src/core/extensions/types.ts) | `ExtensionAPI`、`RegisteredCommand` 类型 |
| 6 | [examples/extensions/protected-paths.ts](../../pi/packages/coding-agent/examples/extensions/protected-paths.ts) | 路径保护 / 权限门示例 |

**对照文档**（同仓库内）：

- [docs/skills.md](../../pi/packages/coding-agent/docs/skills.md)
- [docs/extensions.md](../../pi/packages/coding-agent/docs/extensions.md)
- [docs/prompt-templates.md](../../pi/packages/coding-agent/docs/prompt-templates.md)

**读完本阶段后**：可开始 [PI_CUSTOMIZATION.md §12](PI_CUSTOMIZATION.md#12-社区-skills-移植mattpocockskills--addyosmaniagent-skills) 的 mattpocock / addyosmani Skills 移植。

---

## 阶段 5 — Compaction 与上下文窗口

**目标**：理解长会话如何压缩；对照本项目 [models.json.tmpl](../.chezmoi/dot_pi/agent/models.json.tmpl) 的 `contextWindow: 1000000`。

| 文件 | 关注点 |
|------|--------|
| [core/compaction/compaction.ts](../../pi/packages/coding-agent/src/core/compaction/compaction.ts) | 自动/手动 compaction 触发与摘要 |
| [docs/compaction.md](../../pi/packages/coding-agent/docs/compaction.md) | 机制与配置项说明 |
| [core/compaction/branch-summarization.ts](../../pi/packages/coding-agent/src/core/compaction/branch-summarization.ts) | `/tree` 跳转时的分支摘要 |

**对照练习**：Pi 内 `/compact`；本项目 [PI.md](PI.md) 故障排查「上下文被限制 ~64K」。

---

## 阶段 6 — 四种运行模式实现

| 模式 | 入口文件 | 关注点 |
|------|----------|--------|
| Interactive TUI | [modes/interactive/interactive-mode.ts](../../pi/packages/coding-agent/src/modes/interactive/interactive-mode.ts) | 编辑器、快捷键、`/hotkeys` |
| Print | [modes/print-mode.ts](../../pi/packages/coding-agent/src/modes/print-mode.ts) | `pi -p` 一次性输出 |
| RPC | [modes/rpc/rpc-mode.ts](../../pi/packages/coding-agent/src/modes/rpc/rpc-mode.ts) | `pi --mode rpc` JSONL 协议 |
| SDK 示例 | [examples/sdk/01-minimal.ts](../../pi/packages/coding-agent/examples/sdk/01-minimal.ts) | 最小 `createAgentSession` 嵌入 |

更多 SDK 示例见 [examples/sdk/README.md](../../pi/packages/coding-agent/examples/sdk/README.md)。

---

## 阶段 7 — Provider 层（可选扫读）

**目标**：理解 DeepSeek 等模型如何注册到 CLI；非必读。

| 文件 | 关注点 |
|------|--------|
| [packages/ai/src/models.ts](../../pi/packages/ai/src/models.ts) | Provider 与模型元数据 |
| [core/model-registry.ts](../../pi/packages/coding-agent/src/core/model-registry.ts) | `models.json` 覆盖、`ModelRegistry` |
| [core/model-resolver.ts](../../pi/packages/coding-agent/src/core/model-resolver.ts) | `--model`、`Ctrl+P` 作用域解析 |

对照本项目：[`.chezmoi/dot_pi/agent/models.json.tmpl`](../.chezmoi/dot_pi/agent/models.json.tmpl) 中 Flash/Pro 的 `contextWindow`。

---

## 阶段完成后

1. 进入 [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) — §1–§7 定制路径、§12 社区 Skills
2. 扩展标杆（外部仓库）：[pi-review](https://github.com/earendil-works/pi-review) — Package 注入 + `REVIEW_GUIDELINES.md` 工作流
3. 遇安装/Harness 问题回 [PI.md](PI.md)；WSL 排错见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)

## 延伸阅读

| 文档 | 说明 |
|------|------|
| [PI.md](PI.md) | 运维与 Harness |
| [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) | 上手练习（上一站） |
| [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) | 进阶定制（下一站） |
| [packages/coding-agent/docs/sdk.md](../../pi/packages/coding-agent/docs/sdk.md) | SDK API 参考 |
| [packages/agent/docs/agent-harness.md](../../pi/packages/agent/docs/agent-harness.md) | Harness 设计说明 |
