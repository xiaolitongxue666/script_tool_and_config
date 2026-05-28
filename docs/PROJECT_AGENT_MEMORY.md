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
| 路径 | 全平台含 WSL **仅** `npm install -g codewhale` |
| 禁止 | run_once 内 cargo / brew / winget / Scoop 安装 CodeWhale |
| 前置 | Layer 0 `fnm` + `node`；Layer 4 字母序在 claude-code 之后 |
| 代理 | `npm` / postinstall 下载 GitHub Releases 前 `setup_proxy`；默认 `127.0.0.1:7890`；WSL 用宿主机 IP:7890 |
| 失败 | `[WARNING]` + `exit 0`；无 fnm/node 时 `[ERROR]` + `exit 1` |

### 状态目录

| 路径 | 角色 |
|------|------|
| `~/.codewhale/` | 默认写入 |
| `~/.deepseek/` | 上游只读回退；迁移后**不删除** |

`run_once_92` 在安装成功或已安装时执行非破坏性复制（目标已存在则跳过）。上游 v0.8.47 **无** `codewhale setup --migrate` 子命令，勿在文档中写该命令。

### 遇到的问题与解决

| 问题 | 原因 | 解决 |
|------|------|------|
| 只改仓库脚本，本机仍无 `codewhale` | chezmoi 模板 ≠ 已执行安装 | 运行 `./scripts/manage_dotfiles.sh apply` 或手动 `npm install -g codewhale`（需 7890 代理） |
| 旧 `run_once_92-install-deepseek` 装不上 | `cargo install deepseek` 包名失效 | 改用 `run_once_92-install-codewhale` + npm |
| npm 装完找不到命令（Windows） | 全局包装在 `~/AppData/Roaming/npm` 未进 PATH | `_bash_profile_windows.tmpl` 已加入该目录；或 `export PATH="$HOME/AppData/Roaming/npm:$PATH"` |
| `doctor` 仍显示 `~/.deepseek` | 仅有 legacy 状态根 | 运行 run_once 迁移或手动复制到 `~/.codewhale`；`doctor` 应显示 primary `~/.codewhale` |
| WSL 下载 postinstall 失败 | 代理指向 127.0.0.1 而非宿主机 | 脚本内 WSL 检测 nameserver → `http://<host>:7890` |
| 误以为要 commit API Key | config 在用户目录 | chezmoi **不**托管 `~/.codewhale/config.toml` |

### 相关文档与规则

- 用户向说明：[CODEWHALE.md](CODEWHALE.md)
- 软件清单：[SOFTWARE_LIST.md](SOFTWARE_LIST.md) Layer 4
- Cursor 规则：`.cursor/rules/codewhale.mdc`
- 安装检测：`scripts/chezmoi/install_helpers.sh` → `92-install-codewhale`

## 通用 Agent 约束（摘要）

1. 独立工具脚本（`scripts/common/standalone_tool_script/` 等）**永不删除**。
2. 部署变更仅通过 chezmoi 模板 + `manage_dotfiles.sh` / `install.sh` / `deploy.sh`。
3. 运行时日志英文；注释与文档中文。
4. Windows run_once **无管理员**依赖。
