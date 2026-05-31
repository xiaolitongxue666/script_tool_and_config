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

所有快捷键默认带前缀。前缀键：**`Ctrl+B`**

---

### 面板操作

#### 分屏

| 快捷键 | 操作 |
|--------|------|
| `Prefix + \|` | 垂直分屏（左右） |
| `Prefix + -` | 水平分屏（上下） |

> 取消了 tmux 默认的 `Prefix + %` 和 `Prefix + "`，改用更直观的 `|` 和 `-`。

#### 切换面板

| 快捷键 | 操作 |
|--------|------|
| `Prefix + h` | 切换到**左**侧面板 |
| `Prefix + j` | 切换到**下**侧面板 |
| `Prefix + k` | 切换到**上**侧面板 |
| `Prefix + l` | 切换到**右**侧面板 |

#### 选择面板（第二套方向）

| 快捷键 | 操作 |
|--------|------|
| `Prefix + i` | 选择**上方**面板 |
| `Prefix + k` | 选择**下方**面板 |
| `Prefix + j` | 选择**左方**面板 |
| `Prefix + l` | 选择**右方**面板 |

> 两套 hjkl 的区别：`h/j/k/l` 按**方向**（左/下/上/右）切换；`i/k/j/l` 按**位置**（上/下/左/右）选择。

#### 调整面板大小

| 快捷键 | 操作 |
|--------|------|
| `Prefix + H` | 向左扩大 5 格（可重复按住） |
| `Prefix + J` | 向下扩大 5 格 |
| `Prefix + K` | 向上扩大 5 格 |
| `Prefix + L` | 向右扩大 5 格 |
| `Prefix + I` | 向上扩大 10 格 |
| `Prefix + K` | 向下扩大 10 格 |
| `Prefix + J` | 向左扩大 10 格 |
| `Prefix + L` | 向右扩大 10 格 |

---

### 窗口操作

| 快捷键 | 操作 |
|--------|------|
| `Prefix + Ctrl+h` | 切换到**上一个**窗口 |
| `Prefix + Ctrl+l` | 切换到**下一个**窗口 |
| 拖拽状态栏标签 | 重新排序窗口 |

> 窗口和面板索引均从 **1** 开始（非 tmux 默认的 0）。

---

### 会话管理

| 快捷键 / 命令 | 操作 |
|--------------|------|
| `Prefix + d` | 分离当前会话（tmux 默认） |
| `tmux new -s <name>` | 新建会话 |
| `tmux a -t <name>` | 恢复会话 |
| `tmux ls` | 列出所有会话 |

---

### 剪贴板（Linux 需 xclip，macOS 用 pbcopy）

| 快捷键 | 操作 |
|--------|------|
| `Prefix + Ctrl+c` | 将 tmux 缓冲区内容复制到系统剪贴板 |
| `Prefix + Ctrl+v` | 从系统剪贴板粘贴到 tmux |
| 复制模式下拖选文本 | 选中文本自动复制到系统剪贴板 |
| 鼠标中键点击面板 | 从系统剪贴板粘贴 |

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

### 插件：tmux-yank（复制模式内）

| 快捷键 | 操作 |
|--------|------|
| 复制模式中按 `y` | 复制选中文本到系统剪贴板 |
| 复制模式中按 `Y` | 复制整行到系统剪贴板 |
| `Prefix + y` | 复制最后一个命令的输出 |

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
| 垂直分屏 | `Prefix + \|` | `Prefix + \|` 或 `%` |
| 水平分屏 | `Prefix + -` | `Prefix + -` 或 `"` |
| 切换面板 | `Prefix + h/j/k/l` 或 `i/k/j/l` | `Prefix + h/j/k/l` |
| 调整大小 | `Prefix + H/J/K/L`(5格) + `I/K/J/L`(10格) | `Prefix + H/J/K/L`(5格) |
| 保存/恢复会话 | `Prefix + Ctrl+s/r` | 不支持 |
| 自动保存/恢复 | 每 15 分钟自动 | 不支持 |
| 剪贴板集成 | `Prefix + Ctrl+c/v` + 鼠标自动 | 不支持 |
| 安装插件 | `Prefix + I` | 无插件 |
