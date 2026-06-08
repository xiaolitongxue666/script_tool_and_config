# Tmux / rmux 快捷键速查

本项目有两个终端多路复用方案并行：

| 平台 | 程序 | 配置文件 | 插件 | 安装脚本 |
|------|------|---------|------|---------|
| **Linux / macOS / WSL** | tmux | `~/.tmux.conf`（来自 `dot_tmux.conf.tmpl`） | TPM + 4 插件 | `run_once_install-tmux.sh.tmpl` |
| **Windows** | rmux v0.3.1 | `~/.rmux.conf`（来自 `dot_rmux.conf.tmpl`） | 无 | `run_once_install-rmux.sh.tmpl` |

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

### 与 tmux 的主要差异

- 无 TPM、无插件
- 无 `run-shell` 动态检测
- 无剪贴板集成脚本
- 无 resurrect / continuum
- 状态栏为**硬编码** Catppuccin Mocha 色值（非插件主题）
- 默认 shell 为 `windows_git_bash_path`（chezmoi 变量）

### 前缀键

同上：**`Ctrl+B`**

### 面板操作

| 快捷键 | 操作 |
|--------|------|
| `Prefix + \|` | 垂直分屏（左右） |
| `Prefix + -` | 水平分屏（上下） |
| `Prefix + %` | 垂直分屏（保留 tmux 默认） |
| `Prefix + "` | 水平分屏（保留 tmux 默认） |
| `Prefix + h` | 切换到左侧面板 |
| `Prefix + j` | 切换到下侧面板 |
| `Prefix + k` | 切换到上侧面板 |
| `Prefix + l` | 切换到右侧面板 |
| `Prefix + H` | 向左扩大 5 格 |
| `Prefix + J` | 向下扩大 5 格 |
| `Prefix + K` | 向上扩大 5 格 |
| `Prefix + L` | 向右扩大 5 格 |

### 窗口操作

| 快捷键 | 操作 |
|--------|------|
| `Prefix + c` | 新建窗口 |
| `Prefix + ,` | 重命名窗口 |
| `Prefix + p` | 上一个窗口 |
| `Prefix + n` | 下一个窗口 |
| `Prefix + Ctrl+h` | 上一个窗口 |
| `Prefix + Ctrl+l` | 下一个窗口 |

### 会话管理

| 命令 | 操作 |
|------|------|
| `rmux new -s <name>` | 新建会话 |
| `rmux a -t <name>` | 恢复会话 |
| `rmux ls` | 列出会话 |
| `Prefix + d` | 分离当前会话 |

### 配置重载

| 快捷键 | 操作 |
|--------|------|
| `Prefix + r` | 重新加载 `~/.rmux.conf` |

---

## 两平台键位差异速查

| 操作 | tmux (Linux/macOS) | rmux (Windows) |
|------|-------------------|----------------|
| 新建会话 | `tmux new -s work` | `rmux new -s work` |
| 垂直分屏 | `Prefix + %` | `Prefix + %` 或 `\|` |
| 水平分屏 | `Prefix + "` | `Prefix + "` 或 `-` |
| 切换面板 | `Prefix + i/k/j/l`（上/下/左/右） | `Prefix + h/j/k/l` |
| 调整大小 | `Ctrl+方向键`（3 格）+ `Prefix + z`/`=` | `Prefix + H/J/K/L`（5 格） |
| 保存/恢复会话 | `Prefix + Ctrl+s/r` | 不支持 |
| 自动保存/恢复 | 每 15 分钟自动 | 不支持 |
| 剪贴板集成 | tmux-yank + vi 复制模式 | 不支持 |
| 安装插件 | `Prefix + I` | 无插件 |
