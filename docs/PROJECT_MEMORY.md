# Project Memory (Compact)

1) **职责**：独立工具脚本（`scripts/common/standalone_tool_script/` 等）永不删除；部署仅经 chezmoi + `install.sh` / `deploy.sh` / `manage_dotfiles.sh apply`（**须 `--force`**）。
2) **两阶段**：Phase 1 本仓库 `eval "$(fnm env)" && ./deploy.sh` → Phase 2 agent-config `bash scripts/install-tools.sh`；各 OS/WSL `$HOME` 独立各跑一遍。
3) **Layer 4 CLI（存量）**：claude / codex / codewhale / cursor 由 `run_once_90–93`；**Pi 已迁入 agent-config Phase 2**（本仓勿保留 `run_once_94`/`dot_pi`/PI 文档副本文）。
4) **CodeWhale**：仅 `npm install -g codewhale`（WSL 内 fnm/npm）；禁止 cargo / 从 WSL 改 Windows npm；状态 `~/.codewhale/`（`~/.deepseek/` 只读回退）。
5) **Pi**：不在本仓库；见 [agent-config/docs/PI.md](../../AI/agent-config/docs/PI.md)。
6) **代理（默认启用）**：唯一入口 `chezmoi_core.sh` → `chezmoi_setup_proxy`；WSL → `http://<resolv nameserver>:7890`，其余 `127.0.0.1:7890`；禁用 `PROXY=none/false` 或 `NO_PROXY=1`；**brew 操作在 `upgrade_brew_package/upgrade_brew_cask` 中临时 unset 代理**（`common_install.sh`），避免 brew 因全局代理不可用而挂起。
7) **WSL CodeWhale/Pi**：已装判定看 WSL 内 `npm root -g` 对应包，勿把 `/mnt/c/.../npm` 当已安装。
8) **Windows chezmoi override SSOT**：`chezmoi_core.sh` 的 `chezmoi_build_base_args` + `chezmoi_capture_status|diff` 注入 `windows_git_*`；`deploy.sh`（启动设 `CHEZMOI_PROJECT_ROOT`）、`manage_dotfiles.sh`、`diagnose_deployment.sh`、`install_helpers.sh` 须走 `chezmoi_run_apply`/capture；**禁止**裸 `chezmoi status/diff/apply`（缺 override 时 WT 模板报 `windows_git_bash_path`）。
9) **chezmoi 源**：zsh 模板 canonical 为 `.chezmoi/dot_zshrc.tmpl`；映射见 `scripts/chezmoi/config_mappings.sh`。
10) **macOS bash 3.2**：禁止 `declare -A`；`set -u` 下空数组勿 `"${arr[@]}"`；代理禁用用 `case` 勿 `${var,,}`。
11) **验证**：`bash tests/test_proxy.sh` + `test_syntax.sh` + `test_semver_compare.sh` + `test_software_policies.sh` + `test_install_report_status.sh`（macOS `[5/6]` set -e）；部署后 `verify_installation`（报告 `install_verification_report_*.txt`）。
12) **tmux（Linux/macOS/WSL）**：`dot_tmux.conf.tmpl` → `~/.tmux.conf`；Catppuccin **v2.3.0** 手动 clone；TPM 仅 yank/resurrect/continuum；键位见 [TMUX_KEYBINDINGS.md](TMUX_KEYBINDINGS.md)。
13) **rmux（仅 Windows）**：v0.5.0；`dot_rmux.conf.tmpl` → `~/.rmux.conf`；**apply 后须 `Prefix+r`** 重载 daemon；详见 [RMUX_WINDOWS.md](RMUX_WINDOWS.md)。
14) **install 六步**：`[3/6]` chezmoi apply（`run_once_*` 每台机仅一次）→ `[4/6]` `ensure_platform_software.sh` 补装缺失 + 默认升最新；`--no-upgrade` 或 `SKIP_SOFTWARE_UPGRADE=1` 关闭；全量用 `install.sh`，日常增量用 `deploy.sh`。
15) **ensure 策略**：`software_policies.sh` 定义 `latest` / `minimum:0.11.0`（Neovim）/ `pinned:0.5.0`（rmux）/ `skip`；清单见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。
16) **ensure 补装**：`run_chezmoi_install_script` 须 `chezmoi execute-template --file <绝对模板路径>` 再 pipe bash；禁止无 `--file` 把路径当模板字面量。
17) **ensure 升级**：fnm/uv self-update；common-tools 逐项包管理器升级；Layer4 `npm install -g @latest`；代理走 `ensure_proxy_for_download`；brew 升级操作自动 unset 代理防挂起。
18) **install 状态报告**：`install_helpers.sh` 统一 `find run_once_*.sh.tmpl`（含 Layer4 90–93）；common-tools 逐项检查；三态（缺失/OK/部分安装+跳过升级）。`get_software_report_status` 状态经 **stdout** 输出、函数 **return 0**（`set -e` 下 `$()` 捕获 return 1 中断 macOS step4）。
19) **brew/tmux 排错**：brew `upgrade` 在全局代理下可能挂起 → `upgrade_brew_package/upgrade_brew_cask` 临时 unset 代理；tmux 已装时勿 early exit 跳过 TPM/Catppuccin；顶栏 `#W`/`#W*`；rmux `Prefix+,` 须 `command-prompt` 带 `NEW_NAME`。
20) **Agent 体系**：Layer 4 四 Agent CLI（存量）；Pi + 全局 MCP/Skills 在 agent-config Phase 2；详见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。
21) **全局配置**：中文回复 + 7890 代理（WSL 宿主机）；自定义 slash/commands canonical 在 agent-config。
22) **`/commit-push` + `/summary-memory`**：全 Agent 必备；机械层 `summary-project-memory.sh`（gather/validate/apply）；**写入 `docs/PROJECT_MEMORY.md`**（脚本默认查根目录，apply 须写 docs/）。
23) **Cursor 分工**：本仓库 `.cursor/rules/` = 项目 rules；`~/.cursor/commands/` = 全局 Cursor Commands（Phase 2 apply）。
24) **SSH GitHub 密钥**：`.chezmoi/dot_ssh/config.tmpl` 的 `github.com` 须 `id_ed25519_github_personal` 优先 + `id_rsa` 回退，并设 `IdentitiesOnly yes`；`identity_file` 仅用于 `ci.moicen.com` 等非 GitHub Host。
25) **部署排错**：`deploy.sh`/`manage_dotfiles.sh apply` 须经 `chezmoi_run_apply`；apply 后 `chezmoi status` 的 M/R 可为正常差异；winget msstore 证书警告非致命；**VPS（`VM-0-8-ubuntu`）仅 `id_ed25519_github_personal`**，`install.sh` 单密钥 `id_rsa` 会导致 `git pull` Permission denied。
