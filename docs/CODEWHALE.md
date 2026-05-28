# CodeWhale（终端 AI 编码代理）

原 DeepSeek-TUI 已更名为 [CodeWhale](https://github.com/Hmbown/CodeWhale)。本项目通过 chezmoi `run_once_92-install-codewhale` 安装，与 `install.sh` / `deploy.sh` 流程一致。

## WSL 快速流程（推荐）

```bash
cd /path/to/script_tool_and_config
eval "$(fnm env)"
# 可选：确认宿主机 7890 代理已开；deploy.sh 会自动推断 WSL 宿主机 IP
./deploy.sh
# 或轻量：./scripts/manage_dotfiles.sh apply
```

验证：

```bash
npm list -g codewhale
which codewhale codewhale-tui    # 应指向 WSL fnm bin，而非 /mnt/.../AppData/Roaming/npm
test -d ~/.codewhale && codewhale doctor
./scripts/manage_dotfiles.sh status   # 无输出 = 已同步
```

**注意**：WSL 内安装/更新 CodeWhale 只通过上述项目脚本 + WSL fnm/npm；**不要**从 WSL 用 `cmd.exe` 修改 Windows npm。Agent 排错详见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。

## 安装（项目默认）

| 项 | 说明 |
|----|------|
| 脚本 | `.chezmoi/run_once_92-install-codewhale.sh.tmpl` |
| 方式 | **全平台含 WSL**：`npm install -g codewhale`（上游官方推荐；WSL 为 fnm 全局） |
| 前置 | `run_once_00-install-version-managers`（fnm / node） |
| 命令 | `codewhale`（dispatcher）+ `codewhale-tui`（TUI 运行时，npm postinstall 一并安装） |
| 网络 | 安装前 `setup_proxy`；默认 `http://127.0.0.1:7890`；WSL 为 `http://<宿主机IP>:7890` |
| 失败 | 非致命 `[WARNING]`，可手动 `npm install -g codewhale`（需 7890 代理可达 GitHub Releases） |

可选环境变量：

- `CODEWHALE_NPM_VERSION` — 钉扎 npm 版本（默认 latest）
- `PROXY` / `http_proxy` — 覆盖默认 7890
- `DEEPSEEK_TUI_RELEASE_BASE_URL` — 上游 postinstall 二进制镜像（历史 env 名，见 [INSTALL.md](https://github.com/Hmbown/CodeWhale/blob/main/docs/INSTALL.md)）
- `NO_PROXY=1` — 跳过代理（与 `common_install.sh` 一致）

大陆 npm 较慢时可使用：`npm config set registry https://registry.npmmirror.com`（主路径仍为 npm）。

## 状态目录

| 路径 | 角色 |
|------|------|
| `~/.codewhale/` | **默认写入**（config、skills、sessions 等） |
| `~/.deepseek/` | **只读回退**（上游兼容；首次 apply 后保留，不自动删除） |

首次安装成功后，`run_once_92` 会将 `~/.deepseek` 中**目标尚不存在**的条目非破坏性复制到 `~/.codewhale`（不覆盖已有新路径文件）。

工作区 overlay：`./.codewhale/config.toml` 优先，`.deepseek/config.toml` 为上游回退（均已 gitignore）。

## 认证与验证

```bash
codewhale auth set --provider deepseek   # 写入 ~/.codewhale/config.toml
export DEEPSEEK_API_KEY="..."            # 或使用环境变量
codewhale doctor
codewhale auth status
```

API Key **不**通过本仓库 chezmoi 模板下发。

## 与 Claude Code / Cursor 的关系

Layer 4 字母序：`90-install-claude-code` → `91-install-codex` → `92-install-codewhale` → `93-install-cursor`。仅安装 CLI；配置见 agent-config。

## 迁移与排错

完整问题表见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。常见项：

| 现象 | 处理 |
|------|------|
| WSL 有 Windows 的 codewhale 但 apply 未装本机版 | PATH 互操作误判；已修复 run_once；手动 `eval "$(fnm env)" && npm install -g codewhale` |
| apply 卡住/无输出 | 勿对 apply 使用 `\| head` / `\| rg` 管道 |
| 仓库已更新但本机无 `codewhale` | `./scripts/manage_dotfiles.sh apply`（7890 代理开启） |
| `doctor` 仅识别 `~/.deepseek` | 运行 apply 触发 run_once 迁移 |
| 误用 `codewhale setup --migrate` | v0.8.47 无此参数；由 run_once 脚本复制状态 |

## 故障排查

1. 确认 WSL 宿主机 **7890** 代理已启动。
2. WSL 测试 GitHub：`curl -x http://$(awk '/^nameserver / {print $2; exit}' /etc/resolv.conf):7890 -I https://github.com`
3. 检查命令：`npm list -g codewhale`、`command -v codewhale codewhale-tui`
4. legacy `deepseek` CLI：WSL 内改用 `codewhale`；Windows 侧清理仅在 Windows 终端进行。
