# Project Memory (Compact)

1) **职责**：独立工具脚本（`scripts/common/standalone_tool_script/` 等）永不删除；部署仅经 chezmoi + `install.sh` / `deploy.sh` / `manage_dotfiles.sh apply`（**须 `--force`**）。
2) **两阶段**：Phase 1 本仓库 `eval "$(fnm env)" && ./deploy.sh` → Phase 2 agent-config `bash scripts/install-tools.sh`；各 OS/WSL `$HOME` 独立各跑一遍。
3) **Layer 4 CLI（存量）**：claude / codex / codewhale / cursor 由 `run_once_90–93`；**Pi 已迁入 agent-config Phase 2**（本仓勿保留 `run_once_94`/`dot_pi`/PI 文档副本文）。
4) **CodeWhale**：仅 `npm install -g codewhale`（WSL 内 fnm/npm）；禁止 cargo / 从 WSL 改 Windows npm；状态 `~/.codewhale/`（`~/.deepseek/` 只读回退）。
5) **Pi / SSH 终端**：Harness 在 agent-config；本仓 **`~/.pi_ssh_helpers.sh`**（`dot_pi_ssh_helpers.sh.tmpl`）为 SSOT，由 `.zprofile`/Linux `.bashrc` source；SSH 会话设 `TERM=xterm-256color`、TUI cleanup、**`pi-reset`**；诊断：`scripts/common/deploy_utils/diagnose_vps_ssh_pi.sh`。
6) **代理（默认启用）**：唯一入口 `chezmoi_core.sh` → `chezmoi_setup_proxy`；WSL → `http://<resolv nameserver>:7890`；**headless 原生 Linux（VPS）** 扫描 `PROXY_PROBE_PORTS`（含 **17890**）并注入 chezmoi override-data；其余桌面 Linux/macOS/Windows → `127.0.0.1:7890`；禁用 `PROXY=none/false` 或 `NO_PROXY=1`。Pacman/apt 仍直连国内源；**macOS brew 见 #19**。
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
17) **ensure 升级**：fnm/uv self-update；common-tools 逐项包管理器升级；Layer4 `npm install -g @latest`；代理走 `ensure_proxy_for_download`；macOS brew 经 `_brew_macos_prepare_env`（保留代理 + `HOMEBREW_NO_AUTO_UPDATE=1`）。
18) **install 状态报告**：`install_helpers.sh` 统一 `find run_once_*.sh.tmpl`（含 Layer4 90–93）；common-tools 逐项检查；三态（缺失/OK/部分安装+跳过升级）。`get_software_report_status` 状态经 **stdout** 输出、函数 **return 0**（`set -e` 下 `$()` 捕获 return 1 中断 macOS step4）。
19) **macOS Homebrew 网络**：有 7890 时**保留代理**并切 `brew` origin 至 GitHub（`_brew_macos_prefer_github_remote`）；清华 tuna 高峰 `Waiting in queue` 会卡死 `brew update`；`HOMEBREW_NO_AUTO_UPDATE=1` 防 upgrade 隐式 update；无代理才可用 tuna remote。详见 [INSTALL_GUIDE.md](INSTALL_GUIDE.md)。tmux 已装时勿 early exit 跳过 TPM；rmux `Prefix+,` 须 `command-prompt` 带 `NEW_NAME`。
20) **Agent 体系**：Layer 4 四 Agent CLI（存量）；Pi + 全局 MCP/Skills 在 agent-config Phase 2；详见 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。
21) **全局配置**：中文回复 + 代理（WSL 7890 / VPS 17890，见 #6）；自定义 slash/commands canonical 在 agent-config。
22) **`/commit-push` + `/summary-memory`**：机械层 `summary-project-memory.sh`（gather/validate/apply）；**写入 `docs/PROJECT_MEMORY.md`**（apply 时 cwd 指向 `docs/` 或手动 cp）；备份 `.project-memory-backups/`（保留 2 份）。
23) **Cursor 分工**：本仓库 `.cursor/rules/` = 项目 rules；`~/.cursor/commands/` = 全局 Cursor Commands（Phase 2 apply）。
24) **SSH GitHub 密钥**：`.chezmoi/dot_ssh/config.tmpl` 的 `github.com` 与 **`xiaolitongxue-vps`** 均 `id_ed25519_github_personal` 优先 + `id_ed25519`/`id_rsa` 回退，`IdentitiesOnly yes`；`identity_file` 仅用于 `ci.moicen.com` 等非 GitHub Host。
25) **VPS 部署**：Host `xiaolitongxue-vps`（`VM-0-8-ubuntu`，user `ubuntu`）；仓库 `~/Code/DotfilesAndScript/script_tool_and_config` + `~/Code/AI/agent-config`；**仅用 git push/pull**（勿 tar 同步）；pull 若 dirty：`git reset --hard origin/master && git clean -fd` → Phase1 `./deploy.sh` → Phase2 `install-tools.sh` + `APPLY_TARGETS=pi apply-config`；验收 `diagnose_vps_ssh_pi.sh`（10 项）。
