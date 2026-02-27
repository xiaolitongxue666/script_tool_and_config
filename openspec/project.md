# Project Context

## Purpose

Personal software configuration and scripts collection for cross-platform development environments. This project provides:
- Unified dotfiles management across Linux, macOS, and Windows using chezmoi
- Automated system environment setup and software installation
- Development tool configurations (shells, editors, window managers)
- Reusable utility scripts for common development tasks

## Tech Stack

### Core Technologies
- **Bash Scripting**: Primary scripting language for all automation
- **chezmoi**: Dotfiles management and configuration deployment system
- **Git Submodule**: For managing external configuration repositories (Neovim)

### Platform Support
- **Windows 10/11**: Git Bash, MSYS2, winget, PowerShell
- **macOS 10.15+**: Homebrew, Zsh, Yabai, skhd
- **Linux**:
  - ArchLinux: pacman, yay (AUR), i3wm, dwm
  - Ubuntu/Debian: apt
  - CentOS/RHEL/Fedora: dnf/yum

### Development Tools
- **Shells**: Bash, Zsh, Fish Shell
- **Editors**: Neovim (Lua-based config), IDEA (IdeaVim)
- **Terminal**: Alacritty, Tmux
- **Version Managers**: fnm (Node.js), uv (Python), pyenv
- **CLI Tools**: bat, eza, fd, ripgrep, fzf, lazygit, git-delta, gh

## Project Conventions

### Code Style

#### Shell Scripts
- **Encoding**: UTF-8 (no BOM)
- **Line Endings**: LF (`\n`), except Windows scripts (`.bat`, `.ps1`) use CRLF
- **Indentation**: 4 spaces (no tabs)
- **Shebang**: `#!/usr/bin/env bash`
- **Strict Mode**: Always include `set -euo pipefail`

#### Naming Conventions
- **Constants**: `UPPER_CASE_WITH_UNDERSCORES` (declare with `readonly`)
- **Global Variables**: `lower_case_with_underscores`
- **Local Variables**: `local my_var="$1"`
- **Functions**: `snake_case` (public), `_snake_case` (private)
- **Boolean Checks**: `is_<condition>` or `has_<property>`

#### File Structure
- Scripts follow pattern: `<action>_<object>.sh`
- Installation scripts: `install_<software>.sh`
- Configuration scripts: `configure_<config_name>.sh`
- Test scripts: `test_<functionality>.sh`

#### Comments and Documentation
- All comments and documentation in Chinese
- Section separators: `# ============================================`
- Comments explain purpose, not implementation details
- Function headers include description and parameters

#### Logging Functions
```bash
log_info "信息消息"          # 蓝色
log_success "成功消息"       # 绿色
log_warning "警告消息"       # 黄色 (非致命)
log_error "错误消息"         # 红色
DEBUG=1 log_debug "调试信息" # 青色 (仅 DEBUG=1 时)
```

### Architecture Patterns

#### Configuration Management
- **chezmoi-based**: Single source of truth in `.chezmoi/` directory
- **Template System**: Use `.tmpl` extension for cross-platform configs
- **Platform Separation**: Use `run_on_linux/`, `run_on_darwin/`, `run_on_windows/` directories
- **Conditional Deployment**: chezmoi templates filter by OS detection

#### Script Organization
```
scripts/
├── common.sh              # Shared functions (logging, error handling)
├── manage_dotfiles.sh     # Unified management script
├── linux/                 # Linux-specific scripts
├── darwin/                # macOS-specific scripts
├── windows/               # Windows-specific scripts
└── common/                # Cross-platform scripts
    ├── utils/             # Utility functions
    ├── project_tools/     # Project generation tools
    ├── media_tools/       # Media processing tools
    └── git_templates/     # Git templates
```

#### Common Script Pattern
```bash
#!/usr/bin/env bash
set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Load common library
COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

start_script "脚本名称"
# ... script content ...
end_script
```

#### Error Handling
- Use `set -euo pipefail` for strict error detection
- Trap errors: `trap 'log_error "检测到错误，正在退出脚本"; exit 1' ERR`
- Validate required parameters: `if [[ -z "$1" ]]; then error_exit "参数不能为空"; fi`
- Check command existence: `check_command "wget"`

### Testing Strategy

#### Manual Testing
- No automated test suite
- Manual execution of `test_*.sh` scripts
- Script syntax validation: `bash -n <script>.sh`
- Static analysis with shellcheck when available

#### Validation Tools
```bash
# Check script syntax
bash -n script.sh

# Verify encoding and line endings
./scripts/common/utils/check_and_fix_encoding.sh
./scripts/common/utils/ensure_lf_line_endings.sh

# Test specific functionality
./scripts/linux/system_basic_env/test_mirrors.sh
```

#### Configuration Testing
- Use `chezmoi diff` to preview configuration changes
- Use `chezmoi doctor` to validate chezmoi setup
- Use `chezmoi apply -v` for verbose deployment testing

### Git Workflow

#### Commit Message Format
```
[类型] 简短描述

详细说明 (可选)

类型:
- feat: 新功能
- fix: 修复 bug
- docs: 文档更新
- style: 代码格式 (不影响功能)
- refactor: 重构
- perf: 性能优化
- test: 测试
- chore: 构建/工具变更
```

#### Branch Naming
- Feature branches: `feature/功能名称`
- Bug fixes: `fix/问题描述`
- Documentation: `docs/文档说明`

#### Git Configuration
```bash
# Line ending handling
git config --global core.autocrlf input  # Linux/macOS
git config --global core.autocrlf true   # Windows
git config --global core.safecrlf true
```

#### Neovim Config
- Neovim config is cloned by run_once to `~/.config/nvim` (no submodule in repo)
- Update: `cd ~/.config/nvim && git pull && ./install.sh`

## Domain Context

### chezmoi Configuration System
chezmoi is the core configuration management tool:
- Source directory: `.chezmoi/`
- Mapping rules:
  - `dot_*` → `~/.` (e.g., `dot_zshrc` → `~/.zshrc`)
  - `dot_config/*` → `~/.config/*`
  - `run_once_*.sh` → Execute once (installation scripts)
  - `run_on_<os>/*` → Platform-specific execution

### Template Variable Usage
```bash
{{- if eq .chezmoi.os "linux" -}}
# Linux specific
{{- else if eq .chezmoi.os "darwin" -}}
# macOS specific
{{- else if eq .chezmoi.os "windows" -}}
# Windows specific
{{- end -}}
```

### Package Manager Detection Order
**Linux**:
1. `pacman` (ArchLinux)
2. `apt-get` (Ubuntu/Debian)
3. `dnf` (CentOS 8+/RHEL 8+/Fedora)
4. `yum` (CentOS 7-/RHEL 7-)

**Windows**:
1. `winget` (Windows Package Manager)
2. `pacman.exe` (MSYS2)

**macOS**:
1. `brew` (Homebrew) - required

### Run-once Installation Scripts
- Pattern: `run_once_install-*.sh.tmpl`
- Execute only once per system (chezmoi tracks execution state)
- Use template conditions to filter by platform
- Examples: `run_once_install-neovim.sh.tmpl`, `run_once_install-zsh.sh.tmpl`

## Important Constraints

### Platform-Specific Constraints
1. **ArchLinux Scripts**: Some scripts (e.g., `install_common_tools.sh`, deprecated; cross-platform install via `./install.sh` and run_once, see SOFTWARE_LIST.md) only work on ArchLinux
2. **Windows Path Handling**: Some scripts require path conversion (`cygpath -w`)
3. **Permission Requirements**: Linux installation scripts require `sudo`
4. **Network Requirements**: Initial installation requires network connectivity

### File Format Constraints
- All scripts must have executable permissions: `chmod +x script.sh`
- Windows scripts must use CRLF, others must use LF
- All text files must use UTF-8 encoding (no BOM)
- All files must end with a newline character

### Security Constraints
- Never commit sensitive data (API keys, passwords, private keys)
- Use environment variables for secrets: `export API_KEY="${API_KEY:-}"`
- Secure file permissions:
  - Private keys: `chmod 600 ~/.ssh/id_rsa`
  - SSH directory: `chmod 700 ~/.ssh`
  - Public keys: `chmod 644 ~/.ssh/id_rsa.pub`

### Configuration Constraints
- Modify system config files only after backing up
- Test changes with `chezmoi diff` before applying
- Use `chezmoi apply -v` for verbose logging
- Verify with `chezmoi doctor` before making changes

## External Dependencies

### Package Managers
- **pacman**: Arch Linux package manager
- **apt**: Debian/Ubuntu package manager
- **dnf/yum**: RHEL/CentOS/Fedora package manager
- **brew**: macOS package manager (Homebrew)
- **winget**: Windows Package Manager
- **yay**: AUR helper for Arch Linux

### Configuration Tools
- **chezmoi**: Dotfiles management (https://www.chezmoi.io/)
- **Oh My Zsh**: Zsh framework (https://ohmyz.sh/)
- **Oh My Fish**: Fish framework
- **Oh My Posh**: Cross-shell prompt for Windows

### Development Tools
- **Neovim**: Modern text editor (https://neovim.io/)
- **Tmux**: Terminal multiplexer
- **Alacritty**: GPU-accelerated terminal
- **Git**: Version control system
- **lazygit**: Terminal UI for Git
- **lazydocker**: Terminal UI for Docker

### Version Managers
- **fnm**: Fast Node Manager (https://github.com/Schniz/fnm)
- **uv**: Python package installer (https://github.com/astral-sh/uv)
- **pyenv**: Python version manager
- **rustup**: Rust toolchain installer

### Window Managers
- **i3wm**: Tiling window manager for Linux
- **dwm**: Dynamic window manager for Linux (suckless.org)
- **Yabai**: Tiling window manager for macOS
- **skhd**: Hotkey daemon for macOS

### CLI Tools
- **bat**: `cat` clone with syntax highlighting
- **eza**: Modern replacement for `ls`
- **fd**: Fast alternative to `find`
- **ripgrep**: Fast text search (ripgrep)
- **fzf**: Command-line fuzzy finder
- **git-delta**: Better Git diff viewer
- **starship**: Cross-shell prompt
- **gh**: GitHub CLI tool

### Media Tools
- **FFmpeg**: Multimedia framework
- **VLC Media Player**: Media player

### Documentation
- **Arch Wiki**: https://wiki.archlinux.org/
- **Bash Manual**: https://www.gnu.org/software/bash/manual/
- **ShellCheck**: https://www.shellcheck.net/
