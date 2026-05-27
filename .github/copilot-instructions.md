# script_tool_and_config

## Cross-platform Shell Strategy

Different platforms use different default shells. Template files are maintained separately per platform:

- **macOS / Linux / WSL** → zsh → `.chezmoi/dot_zshrc.tmpl`
- **Windows Terminal** → `.chezmoi/dot_config/windows-terminal/settings.json.tmpl` (host only)
- **Windows Git Bash** → `.chezmoi/dot_bashrc.tmpl` (windows branch) + `run_on_windows/_bash_profile_windows.tmpl`
- **Windows multiplexer** → rmux (`dot_rmux.conf.tmpl`, manual start; no WT auto-attach)
- **Linux/macOS multiplexer** → tmux (`dot_tmux.conf.tmpl` + TPM)
- **Linux (bash fallback)** → bash → `.chezmoi/dot_bashrc.tmpl` (linux branch)

## chezmoi deploy pitfalls

- Use `./scripts/manage_dotfiles.sh apply` or `./deploy.sh`; `CHEZMOI_SOURCE_DIR` env is **not** read by chezmoi CLI
- `sourceDir` in `~/.config/chezmoi/chezmoi.toml` via `chezmoi_ensure_user_config` in `scripts/chezmoi/chezmoi_core.sh`
- Config path map single source: `scripts/chezmoi/config_mappings.sh`
- Windows: `[interpreters.sh]` must point to Git Bash or run_once fails with Win32 error
- See `docs/RMUX_WINDOWS.md` for rmux-specific troubleshooting

## claude-mem Auto Detection

Shell config templates include claude-mem project memory auto-detection:

- `claude()` wraps the original command, searching upward from `$PWD` for `.claude-mem/settings.json`
- Found → sets `CLAUDE_MEM_DATA_DIR`, uses project memory
- Not found → falls back to global `~/.claude-mem`
- `claude-global()` → forces global memory

Template mapping:
- `.chezmoi/dot_zshrc.tmpl` — macOS / Linux / WSL (zsh)
- `.chezmoi/dot_bashrc.tmpl` — Linux bash + Windows Git Bash
- `.chezmoi/run_on_windows/_bash_profile_windows.tmpl` — Windows login shell
