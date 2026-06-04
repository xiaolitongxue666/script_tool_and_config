# Project Memory (Compact)

> 权威详情：[PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。修改安装/部署/chezmoi 约定时须同步本文件、`AGENTS.md`、`CLAUDE.md`、`.cursor/rules/`、`.github/copilot-instructions.md`。

1. **职责**：独立工具脚本（`scripts/common/standalone_tool_script/` 等）永不删除；部署仅经 chezmoi + `install.sh` / `deploy.sh` / `manage_dotfiles.sh apply`（**须 `--force`**）。
2. **两阶段**：Phase 1 本仓库 `eval "$(fnm env)" && ./deploy.sh` → Phase 2 [agent-config](https://github.com/) `bash scripts/install-tools.sh`（各 OS/WSL `$HOME` 独立各跑一遍）。
3. **Layer 4 CLI**：claude / codex / codewhale / cursor 由 `run_once_90–93` 安装；agent-config 只 preflight，不重复装 CLI。
4. **CodeWhale**：仅 `npm install -g codewhale`（WSL 内 fnm/npm）；禁止 cargo / 从 WSL 改 Windows npm；状态 `~/.codewhale/`（`~/.deepseek/` 只读回退）。
5. **代理（默认启用）**：唯一入口 `scripts/chezmoi/chezmoi_core.sh` → `chezmoi_setup_proxy`（`install.sh` / `deploy.sh` / `manage_dotfiles.sh` / `install_chezmoi.sh`）；WSL → `http://<resolv nameserver>:7890`，其余 OS → `127.0.0.1:7890`；禁用 `PROXY=none/false` 或 `NO_PROXY=1`；Pacman/apt/brew 仍直连国内源。
6. **WSL CodeWhale**：已装判定看 WSL 内 `npm root -g/codewhale`，勿把 `/mnt/c/.../npm` 当已安装。
7. **Windows**：apply 须 `--force`；勿 `apply | rg | head`（SIGPIPE）；WT Git 路径用 `detect_windows_git_paths.sh` + override-data-file。
8. **chezmoi 源**：zsh 模板 canonical 名为 `.chezmoi/dot_zshrc.tmpl`（勿提交无后缀 `dot_zshrc`）；映射见 `scripts/chezmoi/config_mappings.sh`。
9. **macOS bash 3.2**：禁止 `declare -A`；`set -u` 下空数组勿 `"${arr[@]}"` 传参；代理禁用检测用 `case "$proxy" in none|false|...)` 勿用 `${var,,}`。
10. **验证**：`bash tests/test_proxy.sh` + `bash tests/test_syntax.sh`；部署后 `verify_installation`（报告 `install_verification_report_*.txt`）。

## 对话归纳（2026-06-04 默认代理统一）

| 问题 | 解法 |
|------|------|
| macOS/Windows/原生 Linux 未设 PROXY 时走直连 | `install.sh`/`deploy.sh` 内联逻辑仅 WSL 设默认；改为统一调用 `chezmoi_setup_proxy` |
| 入口脚本代理逻辑重复 | 检测/设置收敛至 `chezmoi_core.sh`；`chezmoi_detect_proxy` stdout 仅 URL，日志写 stderr |
| 需临时直连 | `PROXY=none ./deploy.sh` 或 `NO_PROXY=1 ./install.sh` |

## 对话归纳（2026-05-29 WSL 部署）

| 问题 | 解法 |
|------|------|
| 工作区仅有 `.chezmoi/dot_zshrc` 无 `.tmpl` | 从 git 恢复 `dot_zshrc.tmpl`，删除误留的 `dot_zshrc`（已在 `.gitignore`） |
| `deploy.sh` 成功但 `chezmoi status` 有 `M`/`R` | 正常差异；需同步时再 `manage_dotfiles.sh apply` |
| Phase 2 skills 验证 WARN | agent-config 校验路径已扩展为 `~/.agents/skills` 优先（见 agent-config `PROJECT_MEMORY.md` #9） |
| Codex 无 `~/.codex/settings.json` | v0.128+ 使用 `config.toml`；由 apply-config 同步 prompts，非 settings.json |
