# script_tool_and_config

## Cross-platform Shell Strategy

Different platforms use different default shells. Template files are maintained separately per platform:

- **macOS / Linux / WSL** → zsh → `.chezmoi/dot_zshrc.tmpl`
- **Windows Git Bash** → bash → `.chezmoi/run_on_windows/dot_bashrc.tmpl`
- **Linux (bash fallback)** → bash → `.chezmoi/dot_bashrc.tmpl`

## claude-mem Auto Detection

Shell config templates include claude-mem project memory auto-detection:

- `claude()` wraps the original command, searching upward from `$PWD` for `.claude-mem/settings.json`
- Found → sets `CLAUDE_MEM_DATA_DIR` and `CLAUDE_MEM_SETTINGS_PATH`, uses project memory
- Not found → falls back to global `~/.claude-mem`
- `claude-global()` → forces global memory

Template mapping:
- `.chezmoi/dot_zshrc.tmpl` — macOS / Linux / WSL (zsh)
- `.chezmoi/dot_bashrc.tmpl` — Linux bash
- `.chezmoi/run_on_windows/dot_bashrc.tmpl` — Windows Git Bash
