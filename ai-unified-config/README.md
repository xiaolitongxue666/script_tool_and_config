# AI Unified Config

基于 `chezmoi + 模板 + 脚本` 的 AI 配置模块（初级版），目标是统一维护 Cursor/Codex/OpenCode 可复用的 agent 与 skill 资源，并兼容 Linux/macOS/Windows(Git Bash)/WSL。

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
│       └── config.json
└── scripts/
    ├── install.sh
    ├── sync-global.sh
    └── sync-project.sh
```

## 部署目标落点

- 全局公共配置：`~/.config/aiconfig/`
- OpenCode 差异配置：`~/.config/opencode/oh-my-opencode/config.json`
- 项目级下发（按需）：`<project>/.aiconfig/`

## 与 chezmoi 的映射关系

- 源目录：
  - `ai-unified-config/.aiconfig`
  - `ai-unified-config/opencode/oh-my-opencode/config.json`
- chezmoi 入口：
  - `.chezmoi/run_once_install-ai-unified-config.sh.tmpl`（调用安装脚本）
  - `.chezmoi/dot_config/aiconfig/manifest.json.tmpl`（模板化元信息）
  - `.chezmoi/dot_config/opencode/oh-my-opencode/config.json.tmpl`（OpenCode 差异模板）
- 渲染目标：
  - `~/.config/aiconfig/manifest.json`
  - `~/.config/opencode/oh-my-opencode/config.json`

## 使用方式

1. 一键安装链路（推荐）：运行仓库根目录 `./install.sh`，由 chezmoi 在 `run_once` 阶段触发模块安装。
2. 手动全局同步：`./ai-unified-config/scripts/sync-global.sh`
3. 手动项目同步：`./ai-unified-config/scripts/sync-project.sh /path/to/project`
4. 进行项目级 smoke test 时，建议使用系统临时目录作为目标路径，避免在仓库根目录残留测试目录。

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
