# Project Memory (Compact)

1) **职责**：独立工具脚本（`scripts/common/standalone_tool_script/` 等）永不删除；部署仅经 chezmoi + `install.sh` / `deploy.sh` / `manage_dotfiles.sh apply`（**须 `--force`**）。
2) **两阶段**：Phase 1 本仓库 `eval "$(fnm env)" && ./deploy.sh` → Phase 2 agent-config `bash scripts/install-tools.sh`；各 OS/WSL `$HOME` 独立各跑一遍。
3) **Layer 4 CLI（存量）**：claude / codex / codewhale / cursor 由 `run_once_90–93`；**Pi 已迁入 agent-config Phase 2**（本仓勿保留 `run_once_94`/`dot_pi`/PI 文档副本文）。
4) **CodeWhale**：仅 `npm install -g codewhale`（WSL 内 fnm/npm）；禁止 cargo / 从 WSL 改 Windows npm；状态 `~/.codewhale/`（`~/.deepseek/` 只读回退）。
5) **Pi / SSH 终端**：Harness 在 agent-config；本仓 **`~/.pi_ssh_helpers.sh`**（`dot_pi_ssh_helpers.sh.tmpl`）为 SSOT，由 `.zprofile`/Linux `.bashrc` source；SSH 会话设 `TERM=xterm-256color`、TUI cleanup、**`pi-reset`**；诊断：`scripts/common/deploy_utils/diagnose_vps_ssh_pi.sh`。
6) **代理（默认启用）**：唯一入口 `chezmoi_core.sh` → `chezmoi_setup_proxy`；**WSL → 宿主机** `http://<resolv nameserver>:7890`；headless 原生 Linux（VPS）扫描 `PROXY_PROBE_PORTS`（含 **17890**）并注入 override-data；桌面 Linux/macOS/Windows → `127.0.0.1:7890`；禁用 `PROXY=none/false` 或 `NO_PROXY=1`。Pacman/apt 直连国内源；**macOS brew 见 #19**。
7) **WSL CodeWhale/Pi**：已装判定看 WSL 内 `npm root -g` 对应包，勿把 `/mnt/c/.../npm` 当已安装；用户明确 WSL 场景时禁止改 Windows npm / 调 `cmd.exe`。
8) **Windows chezmoi override SSOT**：`chezmoi_build_base_args` + `chezmoi_capture_*` 注入 `windows_git_*`；`deploy.sh`（设 `CHEZMOI_PROJECT_ROOT`）、`manage_dotfiles.sh`、`diagnose_deployment.sh`、`install_helpers.sh` 须走封装；**禁止**裸 `chezmoi status/diff/apply`。Win10 全量安装用 Git Bash **`--noprofile --norc`**（login shell 污染 stdout → override-data 空）。
9) **chezmoi 源与库拆分**：zsh canonical `.chezmoi/dot_zshrc.tmpl`；映射 `config_mappings.sh`。聚合入口 `common_install.sh` / `chezmoi_core.sh`；子模块：`detect_platform.sh`、`packages.conf`+`software_policies.sh`、`package_install.sh`、`brew_macos_network.sh`、`chezmoi_proxy.sh`、`chezmoi_lock.sh`、`chezmoi_apply.sh`。
10) **macOS bash 3.2**：禁止 `declare -A`；`set -u` 下空数组勿 `"${arr[@]}"`；代理禁用用 `case` 勿 `${var,,}`。
11) **验证**：`tests/test_proxy.sh` + `test_syntax.sh` + `test_semver_compare.sh` + `test_software_policies.sh` + `test_install_report_status.sh`；部署后 `verify_installation`。
12) **tmux / OMZ**：Linux/macOS/WSL：`dot_tmux.conf.tmpl`；Catppuccin **v2.3.0**；TPM yank/resurrect/continuum。OMZ/插件：`.chezmoiexternal.toml.tmpl`（linux/darwin）；`deploy.sh` 不内联装 Zsh/OMZ，仅 `check_zsh_omz`。
13) **rmux（仅 Windows）**：v0.5.0；`dot_rmux.conf.tmpl` → `~/.rmux.conf`；**apply 后须 `Prefix+r`**；见 [RMUX_WINDOWS.md](RMUX_WINDOWS.md)。
14) **install 六步**：`[3/6]` apply → `[4/6]` `ensure_platform_software.sh` 补装+默认升级；`--no-upgrade` / `SKIP_SOFTWARE_UPGRADE=1` 可关；全量 `install.sh`，日常 `deploy.sh`。
15) **ensure 策略**：`latest` / `minimum:0.11.0`（Neovim 二进制）/ `pinned:0.5.0`（rmux）/ `skip`；清单 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。Neovim **配置**属用户 `~/.config/nvim` 独立仓，本仓不并入。
16) **ensure 补装**：`run_chezmoi_install_script` 须 `chezmoi execute-template --file <绝对路径>`；禁止无 `--file`。
17) **ensure 升级**：fnm/uv self-update；common-tools 按 `packages.conf`；Layer4 `npm i -g @latest`；代理 `ensure_proxy_for_download`；macOS brew 经 `_brew_macos_prepare_env`。
18) **[5/6] 报告**：`get_software_report_status` 经 **stdout**、函数 **return 0**。别名：`neovim`→`nvim`≥0.11、`windows-terminal`→`wt`、`nerd-fonts`→FiraMono；common-tools **跳过** `packages.conf` 中 `-` 的平台项（如 Win 上 trash/btop）。
19) **Windows winget / common-tools**：install/upgrade/list 须 `--source winget`（避 msstore/`0x8a15005e`）；检查命令 `rg`/`delta`（winget id `BurntSushi.ripgrep.MSVC` / `dandavison.delta`）；失败则 GitHub zip → `~/.local/bin`（**仅 Windows**）；勿默认 BypassCertificatePinning。WSL/Linux/macOS 走各平台包管理器。
20) **macOS Homebrew 网络**：有 7890 时保留代理并切 brew origin 至 GitHub；`HOMEBREW_NO_AUTO_UPDATE=1`；无代理才可用 tuna。详见 [INSTALL_GUIDE.md](INSTALL_GUIDE.md)。
21) **Agent 体系**：Layer 4 四 CLI（存量）；Pi + MCP/Skills 在 agent-config Phase 2；权威长文 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。
22) **全局配置**：中文回复 + 代理（WSL 宿主机 7890 / VPS 17890）；slash/commands canonical 在 agent-config；本仓 `.cursor/rules/` = 项目 rules。
23) **`/commit-push` + `/summary-memory`**：`git-smart-commit` / `summary-project-memory`；写入 `docs/PROJECT_MEMORY.md`；备份 `.project-memory-backups/`（保留 2 份）。
24) **SSH GitHub 密钥**：`github.com` 与 `xiaolitongxue-vps` 均 `id_ed25519_github_personal` 优先；`identity_file` 仅非 GitHub Host。
25) **VPS**：Host `xiaolitongxue-vps`；仅用 git push/pull；dirty 时 `reset --hard` + `clean -fd` → Phase1/2；验收 `diagnose_vps_ssh_pi.sh`。
