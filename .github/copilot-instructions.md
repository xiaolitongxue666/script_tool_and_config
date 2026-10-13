# script_tool_and_config

## Cross-platform Shell Strategy

Different platforms use different default shells. Template files are maintained separately per platform:

- **macOS / Linux / WSL** → zsh → `.chezmoi/dot_zshrc.tmpl`
- **Windows Terminal** → `.chezmoi/dot_config/windows-terminal/settings.json.tmpl` (host only)
- **Windows Git Bash** → `.chezmoi/dot_bashrc.tmpl` (windows branch) + `_bash_profile_windows.tmpl` (source root, include-only; uv glob + `UV_PYTHON_PREFERENCE=only-managed`, no `PYTHONHOME`, no `alias python=python3.10`)
- **Windows multiplexer** → rmux (`dot_rmux.conf.tmpl`, manual start; no WT auto-attach)
- **Linux/macOS multiplexer** → tmux (`dot_tmux.conf.tmpl` + TPM)
- **Linux (bash fallback)** → bash → `.chezmoi/dot_bashrc.tmpl` (linux branch)

## chezmoi deploy pitfalls

- Use `./scripts/manage_dotfiles.sh apply` or `./deploy.sh`; `CHEZMOI_SOURCE_DIR` env is **not** read by chezmoi CLI
- **`chezmoi apply` must include `--force`** (`chezmoi_run_apply` injects it) to avoid interactive overwrite prompts on Windows
- Windows: `diagnose_deployment.sh` skips `apply --dry-run`; stale lock → `taskkill //F //IM chezmoi.exe` then `fix_chezmoi_lock.sh`
- `sourceDir` in `~/.config/chezmoi/chezmoi.toml` via `chezmoi_ensure_user_config` in `scripts/lib/chezmoi/chezmoi_core.sh`
- Config path map single source: `scripts/lib/chezmoi/config_mappings.sh`
- Windows: `[interpreters.sh]` must point to Git Bash or run_once fails with Win32 error
- Git for Windows may be on **C:** or **D:**; WT Git Bash path via `detect_windows_git_paths.sh` + `chezmoi_run_apply --override-data-file`; WT `0x80070002` → re-apply and restart WT (see `docs/PROJECT_AGENT_MEMORY.md`)
- See `docs/RMUX_WINDOWS.md` for rmux-specific troubleshooting
- SSH keys stay out of git. This PC and the Mac mini can log into every device; the phone and tablet only log into this PC and the Mac. Generate a new device's private key on that device, then install only the public key on machines that are already set up. Logging into desktop-pc uses Git Bash (`D:\Program Files\Git\usr\bin\bash.exe`), not PowerShell; do not set client `RemoteCommand`. On Windows the only SSH directory is `%USERPROFILE%\.ssh`. MSYS2 `ssh` still expands `~` to `C:\msys64\home\<user>` (`db_home: cygwin desc`); `run_once_windows-link-msys-ssh.sh` junctions that `.ssh` onto the profile and does not keep a second config. WSL `/root/.ssh` stays an ext4 copy, not a symlink onto the Windows disk. `moicen.com` logs in as `xiaoli` and `alchemy-studio.cn` as `leonli`. They share `id_ed25519_moicen-alchemy-2026-10-Nc`, which is also a GitHub authentication key. The Mac `github.com` host still uses `5s`, desktop-pc still uses `C4`, and laptop-huawei still uses `5A`. The same `Nc` private key stays on those three admin machines only, not in WSL, on the phone, on the tablet, or on the Tailscale VPS. Both production logins already succeed. Aliases, users, and tests: `docs/DEVICE_ACCESS.md`. Termux on the phone draws Powerline glyphs from `~/.termux/font.ttf` (Maple Mono NL NF CN Regular); a Nerd Font on the Mac or this PC does not change that window. See the Termux font section in that doc. Steps: `docs/SSH_KEY_ROTATION.md`. When hole punching fails, the Tailscale fallback is the VPS peer relay (UDP `40000`, grants use `100.x` addresses): `docs/TAILSCALE_PEER_RELAY.md`. Do not install `derper` or set `OmitDefaultRegions`. Production hostnames stay off the tailnet.

## claude-mem Auto Detection

Shell config templates include claude-mem project memory auto-detection:

- `claude()` wraps the original command, searching upward from `$PWD` for `.claude-mem/settings.json`
- Found → sets `CLAUDE_MEM_DATA_DIR`, uses project memory
- Not found → falls back to global `~/.claude-mem`
- `claude-global()` → forces global memory (**zsh template only**; not defined in `dot_bashrc.tmpl`)

Template mapping:
- `.chezmoi/dot_zshrc.tmpl` — macOS / Linux / WSL (zsh); `claude()` + `claude-global()`
- `.chezmoi/dot_bashrc.tmpl` — Linux bash + Windows Git Bash; `claude()` only

**Not** `.chezmoi/_bash_profile_windows.tmpl` — verified to contain no
claude-mem logic (it only sets login PATH and sources `~/.bashrc`).

## CodeWhale / DeepSeek (removed)

- **CodeWhale is fully removed from this repo and agent-config** (do not restore). Deleted: `run_once_92-install-codewhale`, `docs/CODEWHALE.md`, `.cursor/rules/codewhale.mdc`.
- Do **not** restore `cargo install deepseek` or `run_once_92-install-deepseek` (removed).
- AI Agent config: agent-config (Claude / Cursor / Codex / Pi + CodeGraph).
- WSL and Windows are **fully independent**: WSL `install.sh` installs WSL only; host Clash `:7890` is network egress, not a shared software env. Use WSL fnm/npm inside WSL (`/mnt/host/wslg/.../fnm_multishells` is WSL-local). Do **not** treat `/mnt/c` or `/mnt/host/c` npm as installed in WSL, and do **not** modify Windows npm via `cmd.exe`. See `.cursor/rules/wsl-windows-isolation.mdc`.
- Deploy: `./deploy.sh` or `./scripts/manage_dotfiles.sh apply` — do not pipe apply through `head`/`rg` (SIGPIPE).
- OMZ/plugins: `.chezmoi/.chezmoiexternal.toml.tmpl` (linux/darwin); common-tools packages: `scripts/lib/chezmoi/packages.conf`.
- Agent notes: `docs/PROJECT_AGENT_MEMORY.md`, `docs/PROJECT_MEMORY.md`.
- SSH names follow Tailscale MagicDNS. Key files are `id_ed25519_<name>-<YYYY-MM>-<last two fingerprint chars>`, and only an existing file is written. GitHub keys stay on `Host github.com`; login keys stay on device hosts. Admins `laptop-huawei`, `mac-mini`, and `company-pc-win10` may log in to every device. The phone (`u0_a0`, port 8022) and tablet (`u0_a71`, port 8022) may log in only to those three. GitHub is also allowed for `vps`. `HostName` for `vps` / `xiaolitongxue-vps` is `vps`. This laptop's Git install is `C:\Program Files\Git`; sshd `DefaultShell` is `C:\Program Files\Git\usr\bin\bash.exe` with `-lc`. The path from `detect_windows_git_paths.sh` is `bin\bash.exe` for Windows Terminal, not the sshd shell. Administrator accounts use `C:\ProgramData\ssh\administrators_authorized_keys`, and host private keys must be owned by Administrators. Do not commit `known_hosts` or copy private keys between machines. On company-pc, keep the existing per-target login keys and only append. Details: `docs/PROJECT_AGENT_MEMORY.md`.
- Pi: [agent-config/docs/pi/README.md](../../../AI/agent-config/docs/pi/README.md) (Phase 2 only; not in this repo).
