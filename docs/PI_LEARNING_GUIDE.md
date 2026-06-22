# Pi 学习建议（新手向）

面向 Pi 新手：在**不预装第三方 pi package** 的前提下，如何上手使用与本项目已部署的 Harness 配置。安装与排错见 [PI.md](PI.md)。源码精读见 [PI_SOURCE_READING.md](PI_SOURCE_READING.md)。进阶定制见 [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md)。

## 本项目 Pi 文档阅读顺序（唯一流程）

按下列顺序线性阅读，**不要跳站或倒序**。

```text
PI.md  →  PI_LEARNING_GUIDE.md  →  PI_SOURCE_READING.md  →  PI_CUSTOMIZATION.md
运维        上手与练习                本地源码精读              进阶定制
```

| 顺序 | 文档 | 读完应能 |
|------|------|----------|
| 1 | [PI.md](PI.md) | 部署 Pi、配置 DeepSeek、理解 Harness 文件位置、日常排错 |
| 2 | [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md)（本文） | 会用 TUI、理解配置分层、完成第 1 天练习 |
| 3 | [PI_SOURCE_READING.md](PI_SOURCE_READING.md) | 读懂本地 `pi` monorepo 核心循环、工具与扩展机制 |
| 4 | [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) | Skills/Package、社区规范移植、生态参考 |

### 四篇文档一句话定位

| 文档 | 定位 |
|------|------|
| [PI.md](PI.md) | **运维手册** — 装得上、配得对、查得着 |
| [PI_LEARNING_GUIDE.md](PI_LEARNING_GUIDE.md) | **新手教程** — 练会基本操作 |
| [PI_SOURCE_READING.md](PI_SOURCE_READING.md) | **源码导读** — 本地仓库分阶段精读（可点击文件链接） |
| [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) | **架构与定制** — 生态、深度配置、工程规范移植 |

---

## 结论速览

| 官方扩展 | 新手是否必装 | 建议 |
|----------|-------------|------|
| [pi-tutorial](https://github.com/earendil-works/pi-tutorial) | 否 | 可用 `pi -e` 临时体验一次交互教程 |
| [pi-review](https://github.com/earendil-works/pi-review) | 否 | 确定日常用 Pi 做 code review 再装 |
| [pi-chat](https://github.com/earendil-works/pi-chat) | 否 | 仅在做 Discord/Telegram 机器人服务时考虑 |

**优先路线**：裸 `pi` + 本项目 `~/.pi/agent/` Harness → prompt template → skill → extension → 第三方 package。

---

## 本项目已提供的 Harness

v1 **不**预装 pi packages（`settings.json` 中 `"packages": []`），但通过 chezmoi 已部署最小脚手架：

| 路径 | 模板 | 作用 |
|------|------|------|
| `~/.pi/agent/settings.json` | [`.chezmoi/dot_pi/agent/settings.json.tmpl`](../.chezmoi/dot_pi/agent/settings.json.tmpl) | 默认 DeepSeek Flash/Pro、代理、compaction |
| `~/.pi/agent/models.json` | [`.chezmoi/dot_pi/agent/models.json.tmpl`](../.chezmoi/dot_pi/agent/models.json.tmpl) | 模型元数据（含 1M context） |
| `~/.pi/agent/AGENTS.md` | [`.chezmoi/dot_pi/agent/AGENTS.md.tmpl`](../.chezmoi/dot_pi/agent/AGENTS.md.tmpl) | 全局 coding 上下文 |
| `~/.pi/agent/APPEND_SYSTEM.md` | [`.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl`](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) | 行为规则（中文、代理、风险确认） |
| `~/.pi/agent/COMMANDS.md` | [`.chezmoi/dot_pi/agent/COMMANDS.md.tmpl`](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl) | `/commit-push`、`/summary-memory` 流程 |

修改 Pi 行为时，优先改 [`.chezmoi/dot_pi/agent/`](../.chezmoi/dot_pi/agent/) 下模板，再执行 [`./deploy.sh`](../deploy.sh) 或 [`./scripts/manage_dotfiles.sh apply`](../scripts/manage_dotfiles.sh)。

**不**由 chezmoi 管理：`auth.json`（API Key）、sessions、`/login` OAuth 产物。

---

## 与 Cursor / CodeWhale 的分工

| 工具 | 更适合 |
|------|--------|
| **Cursor** | 主 IDE、日常改代码、项目级规则 |
| **CodeWhale** | DeepSeek 终端 TUI 对话 |
| **Pi** | 可扩展 Harness：侧项目、实验多模型、自定义工作流 |

Pi 的核心价值是**按需扩展**；若一上来安装 pi-review / pi-chat，容易把「学 Pi」变成「学别人的成品工作流」。

---

## 推荐学习路径

### 第 1 步：确认环境

```bash
command -v pi && pi --version
test -f ~/.pi/agent/settings.json
grep -q deepseek-v4-flash ~/.pi/agent/settings.json
```

认证（二选一）：

```bash
export DEEPSEEK_API_KEY="sk-..."   # 与 CodeWhale 共用
pi
```

或在 Pi 内：`/login` → **Use an API key**（勿选 subscription）→ **DeepSeek** → 粘贴 Key。

WSL 注意：须在 WSL 内用 fnm/npm 安装；`command -v pi` 指向 `/mnt/c/.../npm` 时见 [PI.md](PI.md) 故障排查。

### 第 2 步：掌握内置交互（无需扩展）

在任意项目目录启动 `pi`：

| 能力 | 命令 / 操作 |
|------|-------------|
| 换模型 | `/model` 或 `Ctrl+P`（Flash ↔ Pro） |
| 思考深度 | `Shift+Tab` |
| 引用文件 | 输入 `@` 模糊搜索项目文件 |
| 会话分支 | `/tree`、`/fork` |
| 压缩上下文 | `/compact` |
| 快捷键列表 | `/hotkeys` |
| 重载配置 | `/reload` |

一次性格式：

```bash
pi --model deepseek-v4-flash -p "List all .sh files under scripts/"
pi --model deepseek-v4-pro -p "Refactor this module and fix build errors"
```

只读探索（不执行写操作）：

```bash
pi --tools read,grep,find,ls -p "Review the scripts/ layout"
```

### 第 3 步：理解 Harness 配置分层

Pi 的「专属配置」由浅入深：

```
settings.json       → 模型、代理、compaction、packages（全局 ~/.pi/agent/；项目 .pi/settings.json 覆盖）
AGENTS.md           → 项目/全局指令（启动时自动加载）
APPEND_SYSTEM.md    → 追加系统规则（不替换默认 system prompt）
COMMANDS.md         → 自定义工作流描述（语义对齐 Cursor/Claude，非原生 slash 注册）
prompts/*.md        → 输入 /模板名 展开（轻量，适合新手）
skills/*/SKILL.md   → /skill:name 按需能力
extensions/*.ts     → 注册工具、命令、TUI（进阶）
packages            → 打包上述资源，npm/git 分发
```

本项目已在用 **[AGENTS.md](../.chezmoi/dot_pi/agent/AGENTS.md.tmpl) + [APPEND_SYSTEM.md](../.chezmoi/dot_pi/agent/APPEND_SYSTEM.md.tmpl) + [COMMANDS.md](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl)** 注入领域规范——这与 pi-review 通过 `REVIEW_GUIDELINES.md` 加载评审规范的模式相同，只是尚未做 code review 专用版。

### 第 4 步：轻量自定义（优先于装 package）

建议顺序：

1. **Prompt template** — 在 `~/.pi/agent/prompts/` 放 `review.md`，输入 `/review` 展开评审提示
2. **Skills** — 把重复流程写成 `SKILL.md`（[Agent Skills 标准](https://agentskills.io)）
3. **Extensions** — 需要自定义工具、权限门、TUI 组件时再写 TypeScript 扩展

官方文档：[pi.dev](https://pi.dev/) · [packages.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md) · [extensions 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions)

### 第 5 步（可选）：体验 pi-tutorial

实验性交互教程，**不必**写入 `settings.json`：

```bash
pi -e https://github.com/earendil-works/pi-tutorial
```

有可用模型、网络可达即可；学完基础交互后可不再使用。

### 第 6 步（可选）：社区 Skills

完成第 1–5 步后，可在项目 `.pi/skills/` 试装 [using-agent-skills](https://github.com/addyosmani/agent-skills)（meta 路由）+ 一个 Matt 或 Addy skill（如 `tdd`、`incremental-implementation`）。拷贝 `SKILL.md` 目录 → `/trust` 或 `pi -a` → `/reload`。详见 [PI_CUSTOMIZATION.md §12](PI_CUSTOMIZATION.md#12-社区-skills-移植mattpocockskills--addyosmaniagent-skills)。

---

## 官方扩展是否值得装

### pi-tutorial

- **定位**：实验性 TUI / 事件流引导
- **安装**：临时 `pi -e`，无需 `pi install`
- **何时用**：想快速感受 Pi 扩展能力时试一次即可

### pi-review

- **定位**：`/review`、`/end-review` 代码评审工作流；通过 `REVIEW_GUIDELINES.md` 注入评审规范
- **参考价值**：学习如何用 Markdown 文件为 Agent 注入领域规范（与本项目 [COMMANDS.md](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl) 思路一致）
- **何时装**：已习惯 Pi 日常开发，且希望**固定用 Pi 做 PR review**；否则 Cursor + prompt template 通常够用

### pi-chat

- **定位**：Discord / Telegram 桥接到沙箱化 Pi 实例
- **依赖**：QEMU、Gondolin micro-VM、tmux、Bot Token
- **参考价值**：多账户/多通道隔离、持久化 `memory.md`、把 Agent 部署为服务
- **何时装**：明确要把 Pi 做成 7×24 聊天机器人服务时；本地学习 Pi **不需要**

安装第三方 package 前请知悉：扩展以完整系统权限运行，安装前宜审阅源码。见上游 [packages.md 安全说明](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md)。

```bash
# 将来需要时再装（示例）
pi install npm:@earendil-works/pi-review
pi list
pi config    # 启用/禁用扩展、skill、prompt
```

**下一站**：完成练习后进入 [PI_SOURCE_READING.md](PI_SOURCE_READING.md)（阶段 0–2 起步）；全部读完后进入 [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md)。

---

## 第 1 天练习清单（建议在本仓库内完成）

1. **验证安装** — 执行上文「第 1 步」命令
2. **交互会话** — `cd` 到本仓库，`pi`，用 `@` 引用 [docs/PI.md](PI.md) 并提问
3. **换模型** — `/model` 在 Flash 与 Pro 间切换，观察延迟与推理差异
4. **分支会话** — 同一任务用 `/tree` 回到较早节点换思路继续
5. **自定义命令语义** — 对 Pi 说「按 [COMMANDS.md](../.chezmoi/dot_pi/agent/COMMANDS.md.tmpl) 执行 /commit-push」（需有未提交改动；Phase 2 脚本未装时可能仅走描述流程）
6. **只读评审** — 对 [scripts/chezmoi/chezmoi_core.sh](../scripts/chezmoi/chezmoi_core.sh)：`pi --tools read,grep,find,ls -p "Summarize scripts/chezmoi/chezmoi_core.sh responsibilities"`
7. **（可选）教程** — `pi -e https://github.com/earendil-works/pi-tutorial`
8. **进入源码阅读** — [PI_SOURCE_READING.md](PI_SOURCE_READING.md) 阶段 0–2（地图 + Agent 循环 + CLI 启动）

练习完成后继续 SOURCE 阶段 3–7，再读 [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md)。

---

## 常见问题

| 问题 | 处理 |
|------|------|
| 不知道先学什么 | 按本文「文档阅读顺序」从 [PI.md](PI.md) 第 1 站开始 |
| 想加 code review | 先 `prompts/review.md`，再考虑 pi-review |
| 想把 Pi 接到 Discord | 那是 pi-chat + Gondolin 范畴，与本地 Harness 学习无关 |
| 改配置不生效 | 改 chezmoi 模板后 [`manage_dotfiles.sh apply`](../scripts/manage_dotfiles.sh)；Pi 内 `/reload` |
| 上下文突然变短 | 检查 [models.json.tmpl](../.chezmoi/dot_pi/agent/models.json.tmpl) 的 `contextWindow` 是否为 `1000000`，见 [PI.md](PI.md) |

---

## 延伸阅读

| 文档 | 说明 |
|------|------|
| [PI.md](PI.md) | 本项目 Pi 安装、Harness、认证、排错 |
| [PI_SOURCE_READING.md](PI_SOURCE_READING.md) | 本地 `pi` 仓库分阶段源码阅读（下一站） |
| [PI_CUSTOMIZATION.md](PI_CUSTOMIZATION.md) | 生态、专属定制、社区 Skills |
| [CODEWHALE.md](CODEWHALE.md) | 同层 DeepSeek TUI 工具对比参考 |
| [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md) | WSL 部署与 Agent 排错 |
| [pi-coding-agent README](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md) | 上游完整 CLI 与扩展文档 |
