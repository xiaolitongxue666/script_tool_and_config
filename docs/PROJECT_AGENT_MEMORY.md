# 项目 Agent 记忆（script_tool_and_config）

本文件为**本仓库专属**的可提交记忆，供 Cursor / Claude Code / Copilot 等 Agent 读取。用户级 claude-mem 数据仍在 `.claude-mem/`（已 gitignore，不提交）。

## CodeWhale 迁移（DeepSeek-TUI → CodeWhale，2026-05）

### 背景

- 上游 [Hmbown/CodeWhale](https://github.com/Hmbown/CodeWhale) 由原 DeepSeek-TUI 更名。
- 命令：`codewhale` + `codewhale-tui`（成对二进制）；**不再**使用 `cargo install deepseek`。
- 项目脚本：`.chezmoi/run_once_92-install-codewhale.sh.tmpl`（已删除 `run_once_92-install-deepseek.sh.tmpl`）。

### 安装约定（Agent 修改代码时必须遵守）

| 项 | 约定 |
|----|------|
| 路径 | 全平台含 WSL **仅** `npm install -g codewhale`（WSL 内 fnm/npm 全局，非 Windows 互操作 npm） |
| 禁止 | run_once 内 cargo / brew / winget / Scoop 安装 CodeWhale |
| 禁止 | **从 WSL 调用 `cmd.exe` / Windows npm 卸载或修改 Windows 侧包**（含 legacy `deepseek`） |
| 前置 | Layer 0 `fnm` + `node`；Layer 4 字母序在 claude-code 之后 |
| 代理 | 统一 `chezmoi_setup_proxy`（`chezmoi_core.sh`）；默认全平台启用：WSL 宿主机 `:7890`（resolv nameserver），其余 `127.0.0.1:7890`；禁用 `PROXY=none/false` 或 `NO_PROXY=1`；导出 `GIT_HTTP_PROXY`/`GIT_HTTPS_PROXY`；检测日志 stderr、stdout 仅 URL |
| 失败 | `[WARNING]` + `exit 0`；无 fnm/node 时 `[ERROR]` + `exit 1` |
| 部署入口 | 增量：`./deploy.sh` 或 `./scripts/manage_dotfiles.sh apply`（**勿**对 apply 使用 `\| rg \| head` 管道，会 SIGPIPE 中断） |

### WSL 专用（2026-05 部署实测）

| 项 | 说明 |
|----|------|
| 安装判定 | `run_once_92` 与 `install_helpers.sh` 要求 WSL 内 `npm root -g` 下存在 `codewhale` 包；`command -v` 指向 `/mnt/c/.../AppData/Roaming/npm` 时**不算**已安装 |
| 推荐流程 | `eval "$(fnm env)"` → `./deploy.sh` 或 `./scripts/manage_dotfiles.sh apply` |
| 状态迁移 | apply 触发 `run_once_92` 后，`~/.deepseek` → `~/.codewhale` 非破坏性复制；legacy 目录保留 |
| 验证 | `npm list -g codewhale`、`which codewhale`（应为 fnm multishell bin）、`codewhale doctor`、`chezmoi status`（空=已同步） |
| Windows 分工 | WSL 只维护 WSL 内 fnm/npm；Windows CodeWhale 在 Windows 终端自行维护，Agent **不要跨平台清理** |

### 状态目录

| 路径 | 角色 |
|------|------|
| `~/.codewhale/` | 默认写入 |
| `~/.deepseek/` | 上游只读回退；迁移后**不删除** |

`run_once_92` 在安装成功或已安装时执行非破坏性复制（目标已存在则跳过）。上游 v0.8.47 **无** `codewhale setup --migrate` 子命令，勿在文档中写该命令。

### 遇到的问题与解决

| 问题 | 原因 | 解决 |
|------|------|------|
| 只改仓库脚本，本机仍无 `codewhale` | chezmoi 模板 ≠ 已执行安装 | WSL：`eval "$(fnm env)"` 后 `./scripts/manage_dotfiles.sh apply` |
| 旧 `run_once_92-install-deepseek` 装不上 | `cargo install deepseek` 包名失效 | 改用 `run_once_92-install-codewhale` + npm |
| WSL apply 后仍无本机 codewhale | PATH 先命中 Windows `/mnt/.../npm/codewhale`，run_once 误判已安装 | 脚本已修复：WSL 须 `npm root -g/codewhale` 存在；或手动 `npm install -g codewhale` |
| 从 WSL 卸载 Windows deepseek | 误用 `cmd.exe npm uninstall` | **禁止**；WSL 任务只装 WSL fnm/npm；Windows 清理在 Windows 终端做 |
| apply 长时间无输出/中断 | `apply \| rg \| head` 导致 SIGPIPE | 直接运行 `./scripts/manage_dotfiles.sh apply`，勿管道截断 |
| npm 装完找不到命令（Windows） | 全局包装在 `~/AppData/Roaming/npm` 未进 PATH | `_bash_profile_windows.tmpl` 已加入该目录 |
| `doctor` 仍显示 `~/.deepseek` | 仅有 legacy 状态根 | 运行 apply 触发 run_once 迁移；primary 应为 `~/.codewhale` |
| WSL 下载 postinstall 失败 | 代理指向 127.0.0.1 而非宿主机 | `chezmoi_setup_proxy` / WSL 检测 nameserver → `http://<host>:7890`（勿在 install/deploy 重复内联逻辑） |
| 误以为要 commit API Key | config 在用户目录 | chezmoi **不**托管 `~/.codewhale/config.toml` |

### 相关文档与规则

- 用户向说明：[CODEWHALE.md](CODEWHALE.md)（含 WSL 快速流程）
- 软件清单：[SOFTWARE_LIST.md](SOFTWARE_LIST.md) Layer 4
- 两阶段部署：[DEPLOY_TWO_PHASE.md](DEPLOY_TWO_PHASE.md)
- Cursor 规则：`.cursor/rules/codewhale.mdc`
- 安装检测：`scripts/chezmoi/install_helpers.sh` → `92-install-codewhale`

## Windows Git Bash chezmoi 部署（2026-05 实测）

| 项 | 约定 |
|----|------|
| apply 参数 | **必须** `-v --force`；`chezmoi_run_apply` 与 `manage_dotfiles.sh apply` 已自动补 `--force` |
| 禁止 | 对 apply 使用 `\| head` / `\| rg`（SIGPIPE）；在 Windows 依赖 `diagnose_deployment.sh` 的 `apply --dry-run` |
| 锁 | 中断 apply 后可能残留 `chezmoi.exe` → `timeout obtaining persistent state lock` |
| 修复 | `taskkill //F //IM chezmoi.exe` → `bash scripts/common/deploy_utils/fix_chezmoi_lock.sh` → 再 apply |
| 交互卡住 | `.gitconfig` / `.ssh/config` 被外部修改时，无 `--force` 会弹出 `overwrite/skip/quit` 并永久等待 |

| 问题 | 原因 | 解决 |
|------|------|------|
| `deploy.sh` 长时间无输出 | 诊断阶段 `chezmoi apply --dry-run` 模拟全部 run_once | Windows 已跳过 dry-run；或直接用 `manage_dotfiles.sh apply` |
| apply 停在 `.gitconfig has changed` | 缺 `--force`，等待交互 | 使用 `chezmoi apply -v --force` 或 `chezmoi_run_apply` |
| 多次 apply 报 lock timeout | 前次 chezmoi 进程未退出 | `taskkill //F //IM chezmoi.exe`，运行 `fix_chezmoi_lock.sh` |
| `manage_dotfiles apply` 曾缺 force | 调用 `chezmoi_run_apply "-v"` 覆盖默认 | 已修复：`chezmoi_core` 自动补 `--force` |

## Windows Terminal：Git Bash 路径 C/D 盘（2026-05 实测）

Git for Windows 可能装在 **C:** 或 **D:**（如 `D:\Program Files\Git`）。WT 启动 Git Bash 报 **`0x80070002`** 时，通常是 profile 仍指向不存在的 `C:\Program Files\Git\bin\bash.exe`。

| 项 | 约定 |
|----|------|
| 检测脚本 | `.chezmoi/detect_windows_git_paths.sh`（参数 `bash` / `icon` / `connect`；优先 D: 再 C:） |
| 注入方式 | **勿**指望 `.chezmoi/chezmoi.toml` 的 `[data]` Go 模板自动求值（`chezmoi data` 不会解析）；`chezmoi_run_apply` 在 Windows 下生成 `--override-data-file` 注入 `windows_git_*` |
| 本地覆盖 | `~/.config/chezmoi/chezmoi.toml.local` 的 `[data]` 可写死路径；**勿**在 `.chezmoidata.toml` 写死 `C:/` |
| WT 同步 | 渲染结果写入 `~/.config/windows-terminal/settings.json` 后，`chezmoi_sync_windows_terminal_config` **apply 后**复制到 `%LOCALAPPDATA%` 下 WT LocalState（override-data 改渲染结果时 `run_onchange` 的 `depends` **不会**触发） |
| 验证 | PowerShell：`Test-Path 'D:\Program Files\Git\bin\bash.exe'`；apply 后检查 WT LocalState 的 `commandline` 是否为 D: 路径 |

| 问题 | 原因 | 解决 |
|------|------|------|
| WT 报 `0x80070002` | WT settings 硬编码 C:，本机 Git 在 D: | `./scripts/manage_dotfiles.sh apply`（含 override + WT 同步） |
| `chezmoi data` 无 `windows_git_bash_path` | 源内 `[data]` 模板不求值；`.chezmoidata.toml` 仅静态键 | 以 apply 后 `~/.config/windows-terminal/settings.json` 为准；或 `chezmoi --override-data-file` 调试 |
| apply 后 chezmoi 源正确、WT 仍 C: | `run_onchange_sync` 仅在源模板变更时触发 | 已修复：`chezmoi_run_apply` 成功后调用 `chezmoi_sync_windows_terminal_config` |
| `.chezmoidata.toml` 写死 C: 覆盖检测 | 静态 data 优先级与注释误导 | 已移除硬编码；检测由 override-data-file 负责 |

## Windows：fnm + uv + Git Bash（2026-05）

| 项 | 约定 |
|----|------|
| Node | **fnm**（Layer 0）；新开 Git Bash 自动 `fnm env`，无需手敲 eval |
| Python | **uv**（Layer 0）；`uv python install` 默认 **3.12**（`UV_DEFAULT_PYTHON` 覆盖） |
| CodeWhale 命令 | **`codewhale`**（全小写），非 `CodeWhale` |
| 多 Windows 用户 | **Administrator / xiaoli** 等各跑一遍 Phase 1 + Phase 2（`AppData` 不共享） |
| WT 配置 | `settings.json.tmpl` + `detect_windows_git_paths.sh` + apply 后 `chezmoi_sync_windows_terminal_config`（C/D 盘 Git 路径） |

| 问题 | 解法 |
|------|------|
| 重启后无 node/codewhale | 确认当前 Windows 用户已 `deploy.sh`；检查 `fnm --version`、`which node` |
| 有 fnm 无 python | `uv python install 3.12` 或重跑 apply 触发 `run_once_00` |
| 旁路 Node（如 D:\\Software\\nodejs）抢 PATH | 以 `which node` 为准；优先 fnm multishell |

## 与 agent-config 职责拆分（2026-05）

| 本仓库 (Phase 1) | agent-config (Phase 2) |
|------------------|------------------------|
| fnm/uv、dotfiles、Layer 4 **CLI**（claude/codex/codewhale/cursor*） | 全局 MCP、Skills、`apply-config` 写入各 Agent 配置 |
| **不**写 `~/.claude/settings.json`、`~/.codewhale/mcp.json` | Cursor 编辑器 `settings.json`：`render-cursor-editor-settings.sh` |
| WT Git Bash 默认 profile（**仅 Windows**） | Cursor 集成终端 Git Bash：`platforms/cursor/settings/editor-settings.jsonc` + `@WINDOWS_GIT_BASH_PATH@`（与 `detect_windows_git_paths.sh` 同源） |
| `run_once_90`–`93` 字母序 | `bash scripts/install-tools.sh` 在对应 OS/WSL 各执行一次 |

\* Cursor 仅 GUI 环境（`run_once_93-install-cursor`）。

| 问题 | 解法 |
|------|------|
| 只改 chezmoi 未装 codewhale | Phase 1：`eval "$(fnm env)" && ./deploy.sh` |
| 只 deploy 无 MCP/全局 skills | Phase 2：agent-config `install-tools.sh` |
| Cursor Remote SSH 主机名进仓库 | 已从 chezmoi `data` 移除；用 agent-config `config/local.env` |

## macOS bash 3.2 兼容（2026-05 部署实测）

macOS 默认 `/bin/bash` 为 **3.2**，不支持 `declare -A` / `local -n`。部署与审计脚本须用平行数组或字符串列表。

| 问题 | 现象 | 解决 |
|------|------|------|
| `deploy.sh` exit 2 | `check_zsh_omz.sh: declare -A: invalid option` | 插件检查改用平行数组（已修复） |
| `diagnose_deployment.sh` 警告 | 同上 + zsh 源文件误报不存在 | `config_mappings.sh` 改平行数组；`dot_zshrc` 统一为 `dot_zshrc.tmpl` |
| agent-config 测试 3 项失败 | `set -u` 下空数组 `"${arr[@]}"` → unbound variable | `git-smart-commit.sh` / `summary-project-memory.sh` 用空格分隔字符串；`test-peon-install.sh` 用无 git 的 PATH |

**脚本约束（新增/修改 deploy 辅助脚本时）**：
- 禁止 `declare -A`；映射用 `config_mappings.sh` 的 `CHEZMOI_MAP_*` 平行数组
- `set -u` 下勿对可能为空的数组做 `"${arr[@]}"` 参数展开；用字符串或 `[[ ${#arr[@]} -gt 0 ]]` 守卫
- 诊断/审计 zsh 源路径以 `config_mappings.sh` 为准，勿硬编码过时文件名

## WSL 两阶段部署实测（2026-05-29）

| 项 | 结果 |
|----|------|
| Phase 1 | `eval "$(fnm env)" && ./deploy.sh` → exit 0；`verify_installation` 通过 5/0/0 |
| Phase 2 | agent-config `bash scripts/install-tools.sh` → exit 0；`validate-quality` 与 `run-all-tests` 通过 |
| 代理 | 默认启用：`chezmoi_setup_proxy`；WSL → resolv nameserver:7890；其余 → 127.0.0.1:7890；禁用 `PROXY=none` / `NO_PROXY=1` |
| Layer 4 | claude / codex / codewhale / cursor 均在 PATH |

| 问题 | 原因 | 解决 |
|------|------|------|
| 工作区缺 `dot_zshrc.tmpl`、仅有 `dot_zshrc` | chezmoi 渲染或误拷入 gitignore 路径 | `git checkout -- .chezmoi/dot_zshrc.tmpl`；删除 `.chezmoi/dot_zshrc` |
| deploy 后 `chezmoi status` 显示 `M`/`R` | 模板与目标有差异或 run_once 重命名 | 非失败；按需再 apply |
| agent-config skills 验证 WARN | 只查 `~/.claude/skills`，实际在 `~/.agents/skills` | agent-config 已修 `verify_global_agent_skills` 多路径 |
| 误以为 Codex 缺 settings.json | v0.128+ 用 `~/.codex/config.toml` | 以 apply-config 与 `codex --version` 为准 |

## 默认代理统一（2026-06-04）

| 项 | 约定 |
|----|------|
| 唯一入口 | `scripts/chezmoi/chezmoi_core.sh` → `chezmoi_detect_proxy` / `chezmoi_setup_proxy` |
| 调用方 | `install.sh`、`deploy.sh`、`manage_dotfiles.sh`（`prepare_chezmoi_session_env`）、`install_chezmoi.sh` |
| 默认行为 | 无 env 时全平台默认代理：WSL → `http://<resolv nameserver>:7890`；Windows/macOS/原生 Linux → `127.0.0.1:7890` |
| 禁用 | `PROXY=none/false` 或 `NO_PROXY=1` → unset 全部代理变量 |
| 日志 | 检测来源写 stderr；`chezmoi_detect_proxy` stdout 仅 URL（避免 `$()` 污染） |
| 测试 | `bash tests/test_proxy.sh`（8 项含 none/NO_PROXY/WSL mock）+ `test_syntax.sh` |
| 不变 | Pacman/apt/brew 直连国内源；chezmoi 模板内 proxy 仍用静态 `awk`/`grep`（无新增 exec） |

| 问题 | 原因 | 解决 |
|------|------|------|
| 非 WSL 平台默认直连 | `install.sh`/`deploy.sh` 内联逻辑仅在 WSL 设 PROXY | 删除重复块，统一 `chezmoi_setup_proxy` |
| Git 克隆未走代理 | deploy 曾单独 export `GIT_*_PROXY` | 迁入 `chezmoi_setup_proxy` |

## chezmoi 源文件命名（2026-05）

| 项 | 约定 |
|----|------|
| zsh 模板 | **必须** `.chezmoi/dot_zshrc.tmpl`（`config_mappings.sh` 映射 `~/.zshrc`） |
| 禁止提交 | `.chezmoi/dot_zshrc` 等非 `*.tmpl` 源（见 `.gitignore`） |
| 恢复 | 若工作区仅有 `dot_zshrc`：`git checkout HEAD -- .chezmoi/dot_zshrc.tmpl` 后删除 `dot_zshrc` |

## 通用 Agent 约束（摘要）

1. 独立工具脚本（`scripts/common/standalone_tool_script/` 等）**永不删除**。
2. 部署变更仅通过 chezmoi 模板 + `manage_dotfiles.sh` / `install.sh` / `deploy.sh`。
3. 运行时日志英文；注释与文档中文。
4. Windows run_once **无管理员**依赖。
5. 用户明确「当前是 WSL」时，Agent 操作范围限定 WSL，不修改 Windows 宿主 npm/包。
6. 紧凑记忆索引：[PROJECT_MEMORY.md](PROJECT_MEMORY.md)；变更时同步 `AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`。
