# AI Unified Config

基于 `chezmoi + 模板 + 脚本` 的 AI 配置模块，统一维护 Cursor/Codex/OpenCode 可复用的 agents 与 skills，兼容 Linux/macOS/Windows(Git Bash)/WSL。

## 目录结构

```text
ai-unified-config/
├── .aiconfig/
│   ├── agents/
│   ├── skills/
│   │   ├── common/
│   │   └── special/
│   ├── templates/
│   └── resources/
│       ├── langs/
│       └── shared/
├── opencode/
│   └── oh-my-opencode/
└── scripts/
    ├── install.sh
    ├── sync-global.sh
    ├── sync-project.sh
    ├── sync-opencode.sh
    ├── sync-cursor.sh
    └── sync-codex.sh
```

## 部署目标落点

- 全局公共配置：`~/.config/aiconfig/`
- OpenCode 目录化扩展：`~/.config/opencode/.opencode/agents`、`~/.config/opencode/.opencode/skills`
- 项目级下发（按需）：`<project>/.aiconfig/`

## 与 chezmoi 的映射关系

- 模板来源（仓库内可追溯）：
  - `.chezmoi/run_once_install-ai-unified-config.sh.tmpl`
  - `.chezmoi/run_once_install-opencode-aiconfig-bridge.sh.tmpl`
  - `.chezmoi/dot_config/aiconfig/manifest.json.tmpl`
  - `.chezmoi/dot_config/opencode/opencode.json.tmpl`
  - `.chezmoi/dot_config/opencode/oh-my-opencode/config.json.tmpl`
- 渲染目标：
  - `~/.config/aiconfig/manifest.json`
  - `~/.config/opencode/opencode.json`
  - `~/.config/opencode/oh-my-opencode/config.json`

## OpenCode 轻量配置策略

- `opencode.json` 保持精简，仅保留 `$schema`、`default_agent`、基础 `instructions` 与 agent 映射。
- agent/skill 正文文件不内联在 JSON 中，通过 `.opencode/agents`、`.opencode/skills` 目录分发。
- OpenCode 特化配置（主题与快捷键）通过 `oh-my-opencode/config.json.tmpl` 下发：
  - 主题：`Catppuccin Mocha`
  - 换行：`Ctrl+J`
  - 清空输入：`Ctrl+C`
- `sync-opencode.sh` 负责把 `~/.config/aiconfig` 中的 agents/skills 同步到 OpenCode 可识别目录。

## 使用方式

1. 一键安装链路（推荐）：运行仓库根目录 `./install.sh`，由 `install.sh -> chezmoi apply` 在 `run_once` 阶段自动完成模板渲染与桥接同步。
2. 手动全局同步：`./ai-unified-config/scripts/sync-global.sh`
3. 手动 OpenCode 同步：`./ai-unified-config/scripts/sync-opencode.sh`
4. 手动项目同步：`./ai-unified-config/scripts/sync-project.sh /path/to/project`
5. 进行项目级 smoke test 时，建议使用系统临时目录作为目标路径，避免在仓库根目录残留测试目录。

## 平台兼容策略

- Linux/macOS：直接使用 POSIX 路径。
- Windows Git Bash：允许 `/c/Users/...` 与 `C:/Users/...` 两种输入形式。
- WSL：保持 Linux 路径语义，不写入 Windows 专属路径。

## 扩展约定

- 新增 agent：放到 `.aiconfig/agents/`，文件名使用 `kebab-case.md`。
- 新增通用 skill：放到 `.aiconfig/skills/common/`。
- 新增领域 skill：放到 `.aiconfig/skills/special/`。
- 新增 prompt 模板：放到 `.aiconfig/templates/`，文件名建议 `kebab-case.md`。
- 多 skill 占位统一使用 `{{skills}}`，输入格式为逗号分隔（例如 `common/code-review,special/bash-devops`）。
- Cursor/Codex/OpenCode 推荐显式引用模板文件路径，例如 `~/.config/aiconfig/templates/multi-skill-review-template.md`。
- 可复用模板统一放到 `.aiconfig/resources/`，避免在 agent/skill 内重复定义。
