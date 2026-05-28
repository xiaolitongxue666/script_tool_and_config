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
| 代理 | `npm` / postinstall 下载 GitHub Releases 前 `setup_proxy`；默认 `127.0.0.1:7890`；WSL 用宿主机 IP:7890 |
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
| WSL 下载 postinstall 失败 | 代理指向 127.0.0.1 而非宿主机 | 脚本内 WSL 检测 nameserver → `http://<host>:7890` |
| 误以为要 commit API Key | config 在用户目录 | chezmoi **不**托管 `~/.codewhale/config.toml` |

### 相关文档与规则

- 用户向说明：[CODEWHALE.md](CODEWHALE.md)（含 WSL 快速流程）
- 软件清单：[SOFTWARE_LIST.md](SOFTWARE_LIST.md) Layer 4
- Cursor 规则：`.cursor/rules/codewhale.mdc`
- 安装检测：`scripts/chezmoi/install_helpers.sh` → `92-install-codewhale`

## 通用 Agent 约束（摘要）

1. 独立工具脚本（`scripts/common/standalone_tool_script/` 等）**永不删除**。
2. 部署变更仅通过 chezmoi 模板 + `manage_dotfiles.sh` / `install.sh` / `deploy.sh`。
3. 运行时日志英文；注释与文档中文。
4. Windows run_once **无管理员**依赖。
5. 用户明确「当前是 WSL」时，Agent 操作范围限定 WSL，不修改 Windows 宿主 npm/包。
