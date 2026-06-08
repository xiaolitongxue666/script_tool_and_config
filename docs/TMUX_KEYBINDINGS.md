# Tmux / rmux 快捷键速查

本项目有两个终端多路复用方案并行：

| 平台 | 程序 | 配置文件 | 插件 | 安装脚本 |
|------|------|---------|------|---------|
| **Linux / macOS / WSL** | tmux | `~/.tmux.conf`（来自 `dot_tmux.conf.tmpl`） | TPM + 4 插件 | `run_once_install-tmux.sh.tmpl` |
| **Windows** | rmux v0.5.0 | `~/.rmux.conf`（来自 `dot_rmux.conf.tmpl`） | 无 | `run_once_install-rmux.sh.tmpl` |

> Windows 排错详见 [RMUX_WINDOWS.md](RMUX_WINDOWS.md)。

---

## tmux（Linux / macOS / WSL）

### 前缀键

带前缀的快捷键需先按 **`Ctrl+B`**，再按后续键。

---

### 面板操作

#### 分屏

| 快捷键 | 操作 |
|--------|------|
| `Prefix + "` | **水平分屏**（上下）；新 pane 保持当前工作目录 |
| `Prefix + %` | **垂直分屏**（左右）；新 pane 保持当前工作目录 |

#### 切换面板

与 nvim `<leader> i/k/j/l` 一致（按**方向**上/下/左/右）：

| 快捷键 | 操作 |
|--------|------|
| `Prefix + i` | 切换到**上**方面板 |
| `Prefix + k` | 切换到**下**方面板 |
| `Prefix + j` | 切换到**左**方面板 |
| `Prefix + l` | 切换到**右**方面板 |

#### 调整面板大小

与 nvim `window_control.lua` 步长一致，**无需 Prefix**：

| 快捷键 | 操作 |
|--------|------|
| `Ctrl+↑` | 当前 pane 向上扩大 3 格（可连按） |
| `Ctrl+↓` | 向下扩大 3 格 |
| `Ctrl+←` | 向左扩大 3 格 |
| `Ctrl+→` | 向右扩大 3 格 |

> tmux 侧为固定 3 格（无 nvim terminal 限高 smart 逻辑）。shell pane 内 `Ctrl+方向键` 仍可能由 readline/终端处理。

#### 布局

| 快捷键 | 操作 |
|--------|------|
| `Prefix + z` | 放大/还原当前 pane（zoom） |
| `Prefix + =` | 均分所有 pane 大小 |

> 状态栏**左侧**为 **session 名**；中间 **window 标签** 格式为 `编号 window-name*`（当前 window 带 `*` 且 mauve 高亮）。标签显示 **window 名**（`#W`），`Prefix + ,` 改名后即时生效。

---

### 窗口操作

| 快捷键 | 操作 |
|--------|------|
| `Prefix + c` | 新建窗口 |
| `Prefix + p` / `n` | 上一个 / 下一个窗口 |
| `Prefix + ,` | 重命名窗口 |
| `Prefix + 数字` | 跳到指定窗口（索引从 **1** 起） |
| `Prefix + Ctrl+h` | 切换到**上一个**窗口 |
| `Prefix + Ctrl+l` | 切换到**下一个**窗口 |
| 拖拽状态栏标签 | 重新排序窗口 |

---

### 会话管理

| 快捷键 / 命令 | 操作 |
|--------------|------|
| `Prefix + d` | 分离当前会话（tmux 默认） |
| `tmux new -s <name>` | 新建会话 |
| `tmux a -t <name>` | 恢复会话 |
| `tmux ls` | 列出所有会话 |

---

### 剪贴板（tmux-yank）

Linux 需 `xclip`/`xsel`；macOS 用 `pbcopy`；WSL 依赖 WSLg 或 `@override_copy_command`。

| 快捷键 | 操作 |
|--------|------|
| `Prefix + [` | 进入复制模式（vi 键位） |
| 复制模式中 `v` | 开始选择 |
| 复制模式中 `y` | 复制选中文本到系统剪贴板 |
| 复制模式中 `Y` | 复制整行到系统剪贴板 |
| `Prefix + y` | 复制最后一个命令的输出 |
| 鼠标拖选 | 自动复制到系统剪贴板（`@yank_with_mouse on`） |

---

### 配置重载

| 快捷键 | 操作 |
|--------|------|
| `Prefix + r` | 重新加载 `~/.tmux.conf` |

---

### 插件管理（TPM）

| 快捷键 | 操作 |
|--------|------|
| `Prefix + I`（大写 i） | **安装**所有插件 |
| `Prefix + U`（大写 u） | **更新**所有插件 |
| `Prefix + Alt + u`（小写 u） | **卸载**插件 |

---

### 插件：tmux-resurrect（会话持久化）

| 快捷键 | 操作 |
|--------|------|
| `Prefix + Ctrl+s` | **保存**当前会话（窗口、面板、工作目录） |
| `Prefix + Ctrl+r` | **恢复**上次保存的会话 |

---

### 插件：tmux-continuum（自动保存/恢复）

| 功能 | 行为 |
|------|------|
| 自动保存 | 每 **15 分钟**自动保存一次 |
| 自动恢复 | tmux 启动时自动恢复上次会话 |

> 无需手动按键。依赖 resurrect 的保存数据。

---

## rmux（Windows）

键位与状态栏已与 tmux 对齐（`dot_rmux.conf.tmpl` ← `dot_tmux.conf.tmpl` 可移植部分）。以下与 tmux 章节结构一致；差异见文末。

### 与 tmux 的主要差异

- 无 TPM、无插件（resurrect / continuum / tmux-yank）
- 无 `run-shell` 动态 shell 检测；默认 shell 为 `windows_git_bash_path`（chezmoi 变量）
- 状态栏为 **Catppuccin Mocha 静态 hex**（非 Catppuccin 插件）
- 剪贴板：`copy-command clip.exe` + vi 复制模式（无 tmux-yank 的 `Prefix+y`、鼠标自动复制）
- 无状态栏拖拽重排窗口

### 前缀键

同上：**`Ctrl+B`**

### 面板操作

#### 分屏

| 快捷键 | 操作 |
|--------|------|
| `Prefix + "` | **水平分屏**（上下）；新 pane 保持当前工作目录 |
| `Prefix + %` | **垂直分屏**（左右）；新 pane 保持当前工作目录 |

#### 切换面板

与 nvim `<leader> i/k/j/l` 一致（按**方向**上/下/左/右）：

| 快捷键 | 操作 |
|--------|------|
| `Prefix + i` | 切换到**上**方面板 |
| `Prefix + k` | 切换到**下**方面板 |
| `Prefix + j` | 切换到**左**方面板 |
| `Prefix + l` | 切换到**右**方面板 |

#### 调整面板大小

**无需 Prefix**（与 tmux 相同，3 格）：

| 快捷键 | 操作 |
|--------|------|
| `Ctrl+↑` / `↓` / `←` / `→` | 向对应方向扩大 3 格（可连按） |

#### 布局

| 快捷键 | 操作 |
|--------|------|
| `Prefix + z` | 放大/还原当前 pane（zoom） |
| `Prefix + =` | 均分所有 pane 大小 |

> 状态栏在**顶部**；**左侧** session 名（绿色 pill）；中间 window 为「序号 pill + 名称 pill」（如 `1` `bash*`），当前窗 mauve 高亮；**右侧为空**。改配置后须 `Prefix + r` 重载。

### 窗口操作

| 快捷键 | 操作 |
|--------|------|
| `Prefix + c` | 新建窗口 |
| `Prefix + p` / `n` | 上一个 / 下一个窗口 |
| `Prefix + ,` | 重命名窗口 |
| `Prefix + Ctrl+h` | 切换到**上一个**窗口 |
| `Prefix + Ctrl+l` | 切换到**下一个**窗口 |

### 会话管理

| 快捷键 / 命令 | 操作 |
|--------------|------|
| `Prefix + d` | 分离当前会话 |
| `rmux new -s <name>` | 新建会话 |
| `rmux a -t <name>` | 恢复会话 |
| `rmux ls` | 列出所有会话 |

### 剪贴板（rmux copy-command）

| 快捷键 | 操作 |
|--------|------|
| `Prefix + [` | 进入复制模式（vi 键位） |
| 复制模式中 `v` | 开始选择 |
| 复制模式中 `y` | 复制选中文本到 Windows 剪贴板（`clip.exe`） |

### 配置重载

| 快捷键 | 操作 |
|--------|------|
| `Prefix + r` | 重新加载 `~/.rmux.conf` |

---

## 两平台差异速查

| 操作 | tmux (Linux/macOS/WSL) | rmux (Windows) |
|------|------------------------|----------------|
| 新建会话 | `tmux new -s work` | `rmux new -s work` |
| 分屏 / 切 pane / resize / 布局 | 见上表 | **与 tmux 相同** |
| 状态栏 | Catppuccin 插件 + 顶栏 | 静态 Mocha hex + 顶栏 |
| 保存/恢复会话 | `Prefix + Ctrl+s/r` | 不支持 |
| 自动保存/恢复 | 每 15 分钟（continuum） | 不支持 |
| 剪贴板 | tmux-yank + 鼠标拖选 | `copy-command` + vi 复制模式 |
| 安装插件 | `Prefix + I` | 无插件 |
