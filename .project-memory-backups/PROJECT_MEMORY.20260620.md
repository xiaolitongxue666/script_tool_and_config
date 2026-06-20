# Project Memory (Compact)

1) **职责**：独立工具脚本（`scripts/common/standalone_tool_script/` 等）永不删除；部署仅经 chezmoi + `install.sh` / `deploy.sh` / `manage_dotfiles.sh apply`（**须 `--force`**）。
2) **两阶段**：Phase 1 本仓库 `eval "$(fnm env)" && ./deploy.sh` → Phase 2 agent-config `bash scripts/install-tools.sh`；各 OS/WSL `$HOME` 独立各跑一遍。
3) **Layer 4 CLI**：claude / codex / codewhale / cursor / pi 由 `run_once_90–94` 安装；agent-config 只 preflight，不重复装 CLI。
4) **CodeWhale**：仅 `npm install -g codewhale`（WSL 内 fnm/npm）；禁止 cargo / 从 WSL 改 Windows npm；状态 `~/.codewhale/`（`~/.deepseek/` 只读回退）。
5) **Pi**：`run_once_94` + chezmoi `dot_pi/agent/`（默认 v4 flash，`models.json` 覆盖 pro）；`/login` 须 **Use an API key** → DeepSeek（订阅列表无 DeepSeek）；`.gitignore` 忽略 `.pi/` 用户态；Pi ≥0.75 需 Node ≥22.19。
6) **代理（默认启用）**：唯一入口 `chezmoi_core.sh` → `chezmoi_setup_proxy`；WSL → `http://<resolv nameserver>:7890`，其余 `127.0.0.1:7890`；禁用 `PROXY=none/false` 或 `NO_PROXY=1`；Pacman/apt/brew 仍直连国内源。
7) **WSL CodeWhale/Pi**：已装判定看 WSL 内 `npm root -g` 对应包，勿把 `/mnt/c/.../npm` 当已安装。
8) **Windows chezmoi**：apply 须 `--force`；勿 `apply | rg | head`（SIGPIPE）；WT Git 路径用 `detect_windows_git_paths.sh` + override-data-file。
9) **chezmoi 源**：zsh 模板 canonical 为 `.chezmoi/dot_zshrc.tmpl`；映射见 `scripts/chezmoi/config_mappings.sh`。
10) **macOS bash 3.2**：禁止 `declare -A`；`set -u` 下空数组勿 `"${arr[@]}"`；代理禁用用 `case` 勿 `${var,,}`。
11) **验证**：`bash tests/test_proxy.sh` + `test_syntax.sh` + `test_semver_compare.sh` + `test_software_policies.sh`；部署后 `verify_installation`（报告 `install_verification_report_*.txt`）。
12) **tmux（Linux/macOS/WSL）**：`dot_tmux.conf.tmpl` → `~/.tmux.conf`；Catppuccin **v2.3.0** 手动 clone；TPM 仅 yank/resurrect/continuum；键位见 [TMUX_KEYBINDINGS.md](docs/TMUX_KEYBINDINGS.md)。
13) **rmux（仅 Windows）**：v0.5.0（`rmux-0.5.0-windows-x86_64.zip`）；`dot_rmux.conf.tmpl` → `~/.rmux.conf`；**apply 后须 `Prefix+r`** 重载 daemon；详见 [RMUX_WINDOWS.md](docs/RMUX_WINDOWS.md)。
14) **install 六步**：`[3/6]` chezmoi apply（`run_once_*` 每台机仅一次）→ `[4/6]` `scripts/chezmoi/ensure_platform_software.sh` 按 OS/WSL **补装缺失 + 默认升最新稳定版**；`--no-upgrade` 或 `SKIP_SOFTWARE_UPGRADE=1` 关闭升级；全量补装/升级用 `install.sh`，日常 dotfiles 增量用 `deploy.sh`。
15) **ensure 策略**：`software_policies.sh` 定义 `latest` / `minimum:0.11.0`（Neovim）/ `pinned:0.5.0`（rmux）/ `skip`（nerd-fonts、configure-pacman、AUR helper 等）；清单见 [SOFTWARE_LIST.md](docs/SOFTWARE_LIST.md) 补装/升级小节。
16) **ensure 补装实现**：`common_install.sh` → `run_chezmoi_install_script` 须 `chezmoi execute-template --file <绝对模板路径>` 再 pipe bash；**禁止**无 `--file` 把路径当模板字面量（会 `bash: run_once_*.sh.tmpl: command not found`）。
17) **ensure 升级**：fnm/uv self-update；common-tools 逐项包管理器升级；Layer4 `npm install -g @latest`（`CODEWHALE_NPM_VERSION` / `PI_NPM_VERSION` 可 pin）；代理走 `ensure_proxy_for_download` / `chezmoi_setup_proxy`。
18) **install 状态报告**：`install_helpers.sh` 统一 `find run_once_*.sh.tmpl`（含 Layer4 90–94）；common-tools 逐项检查；三态：缺失 / OK / 部分安装或 `--no-upgrade` 跳过升级。
19) **tmux 插件（2026-06）**：tmux 已装时勿 early exit 跳过 TPM/Catppuccin clone；顶栏用 `#W`/`#W*` 非 `#T`；切 pane 为 `Prefix+ijkl`。
20) **rmux 排错（2026-06）**：`Prefix+,` 须 `command-prompt` 带 `NEW_NAME`；`#{window_index}` pill 非裸 `#I`；`rmux show-options -g window-status-format` 对比磁盘配置。
21) **WSL dotfiles（2026-05）**：误留无后缀 `dot_zshrc` 时从 git 恢复 `dot_zshrc.tmpl`；`deploy.sh` 成功后 `chezmoi status` 有 M/R 为正常差异。
