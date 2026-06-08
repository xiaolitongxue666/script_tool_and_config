# Windows 下 rmux 安装与排错

本文档记录在本仓库中集成 [rmux](https://github.com/Helvesec/rmux) v0.3.1 时的设计选择、遇到的问题与解决方法。与 Linux/macOS 的 tmux（`dot_tmux.conf.tmpl` + TPM）**并行**，互不替代。

## 设计边界

| 项 | 选择 |
|----|------|
| 平台 | 仅 Windows（`chezmoi.os == windows`） |
| 安装 | `run_on_windows/run_once_install-rmux.sh.tmpl` → `~/.local/bin/rmux.exe` |
| 配置 | `dot_rmux.conf.tmpl` → `~/.rmux.conf`（无 TPM/插件/`run-shell`） |
| 终端 | WT 仍默认 **Git Bash**，**不**新增 profile、**不**在 bashrc 自动 attach |
| 使用 | 手动：`rmux new -s work`、`rmux a -t work` |

## 推荐部署命令

在仓库根目录（Git Bash）：

```bash
./install.sh                    # 首次：写 chezmoi 用户配置 + apply + run_once
./deploy.sh                     # 增量
./scripts/manage_dotfiles.sh apply   # 日常仅应用配置（推荐）
```

**不要**仅设置 `CHEZMOI_SOURCE_DIR` 后直接 `chezmoi apply`：chezmoi **不读取**该环境变量，须以 `~/.config/chezmoi/chezmoi.toml` 的 `sourceDir` 为准（由 `install.sh` / `chezmoi_ensure_user_config` 写入）。

## 遇到的问题与解决方法

### 1. 新模板未应用到 `~/.rmux.conf`

**现象**：`deploy.sh` 跑完但 `~/.rmux.conf` 不存在；`chezmoi apply` 无输出。

**原因**：

- `~/.config/chezmoi/chezmoi.toml` 的 `sourceDir` 未指向本仓库 `.chezmoi`，或仍指向 `~/.local/share/chezmoi`。
- 仅 `export CHEZMOI_SOURCE_DIR=...` 对 chezmoi CLI **无效**。

**解决**：

1. 运行 `./install.sh` 或 `./scripts/manage_dotfiles.sh apply`（会调用 `chezmoi_ensure_user_config`）。
2. 确认 `~/.config/chezmoi/chezmoi.toml` 含：`sourceDir = "D:/.../script_tool_and_config/.chezmoi"`（盘符以本机为准）。
3. 或显式（须带用户 config，否则 Windows 上 run_once 可能 Win32 失败）：
   `chezmoi --config="$HOME/.config/chezmoi/chezmoi.toml" apply -v --force`

**勿**在已配置 `sourceDir` 时仅用 `chezmoi --source=/d/Code/.../.chezmoi apply`（Git Bash 的 `/d/` 路径 + 缺 `[interpreters.sh]` 易触发 Win32 错误）。项目脚本 `chezmoi_run_apply` 已改为优先 `--config`。

### 2. run_once 报错「%1 is not a valid Win32 application」

**现象**：`chezmoi apply` 执行 `run_once_*.sh` 失败。

**原因**：Windows 上 chezmoi 直接执行 `.sh` 而未通过 Git Bash。

**解决**：在 `chezmoi.toml` 配置：

```toml
[interpreters.sh]
    command = "C:/Program Files/Git/usr/bin/bash.exe"
```

由 `install.sh` / `scripts/chezmoi/chezmoi_core.sh` 的 `chezmoi_ensure_user_config` 自动写入。

### 3. `force_apply_configs.sh` 跳过 tmux / 找不到源文件

**现象**：日志出现 `跳过 .tmux.conf: 源文件不存在`（旧映射为 `dot_tmux.conf` 无 `.tmpl`）。

**原因**：`force_apply_configs.sh` 与 `audit_configs.sh` 映射表不一致且路径过时。

**解决**：已统一到 `scripts/chezmoi/config_mappings.sh`；Windows 校验 `~/.rmux.conf`，Linux/macOS 校验 `~/.tmux.conf`。

### 4. 预编译包解压路径

**现象**：zip 内为 `rmux-v0.3.1-x86_64-pc-windows-msvc/rmux.exe` 子目录。

**解决**：安装脚本使用 `find ... -name rmux.exe`，勿假定 zip 根目录即二进制。

### 5. 用户主目录重复的 `~/chezmoi.toml`

**现象**：`~/chezmoi.toml` 与 `~/.config/chezmoi/chezmoi.toml` 并存，易混淆。

**解决**：以 **`~/.config/chezmoi/chezmoi.toml`** 为准；可删除仓库外的 `~/chezmoi.toml` 副本（勿提交到本仓库）。

## 配置说明（相对 tmux）

`dot_rmux.conf.tmpl` 已对齐 `dot_tmux.conf.tmpl` 的可移植部分：

- **状态栏**：`status-position top`；Catppuccin Mocha **静态 hex**（session 绿色 pill、window `#W` / 当前 `#W*` mauve、`status-right` 空）
- **键位**：与 tmux 相同（`Prefix+ijkl` 切 pane、`Ctrl+方向键` resize 3 格、`Prefix+z`/`=`、分屏 `-c "#{pane_current_path}"`）
- **复制**：`copy-command clip.exe` + vi 复制模式（替代 tmux-yank）
- **剔除**：TPM、Catppuccin 插件、`run-shell`、resurrect/continuum
- **默认 shell**：`windows_git_bash_path`（与 WT Git Bash 一致；apply 时由 `detect_windows_git_paths.sh` 检测 C/D 盘）

键位速查见 [TMUX_KEYBINDINGS.md](TMUX_KEYBINDINGS.md#rmuxwindows)。

### 部署后验证清单（Git Bash + rmux）

```bash
./scripts/manage_dotfiles.sh apply
rmux new -s verify-test
```

在 rmux 会话内逐项确认：

1. 状态栏在**顶部**；左侧 session 名；window 标签 `#W`，当前窗 `#W*` 为 mauve；右侧无内容
2. `Prefix + %` / `"` 分屏后新 pane **cwd 不变**
3. `Prefix + i/k/j/l` 按方向切换 pane；`Ctrl+方向键` 调整大小（3 格）
4. `Prefix + z` zoom；`Prefix + =` 均分 pane
5. `Prefix + [` → `v` 选择 → `y` 复制到 Windows 剪贴板
6. `Prefix + r` 重载配置无报错

## 日常命令

```bash
rmux -V
rmux ls
rmux new -s mywork
rmux new -d -s mywork
rmux a -t mywork
# 会话内：Ctrl+B d 分离；Ctrl+B % / " 分屏
```

## 相关文件

| 文件 | 作用 |
|------|------|
| `.chezmoi/run_on_windows/run_once_install-rmux.sh.tmpl` | 安装 |
| `.chezmoi/dot_rmux.conf.tmpl` | 配置模板 |
| `scripts/chezmoi/config_mappings.sh` | 审计/强制应用映射单一来源 |
| `scripts/chezmoi/chezmoi_core.sh` | `chezmoi_ensure_user_config`、`chezmoi_run_apply` |
| `docs/SOFTWARE_LIST.md` | 安装清单 |
