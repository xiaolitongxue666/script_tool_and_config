# Alacritty 配置

Alacritty 是一款使用 GPU 加速的跨平台终端模拟器，具有高性能和可定制性。

**参考**: [Alacritty GitHub 仓库](https://github.com/alacritty/alacritty)

## 重要提示

⚠️ **配置文件格式变更**: 从 Alacritty 0.13.0 版本开始，配置文件格式从 YAML 改为 **TOML**。

- ✅ **新格式**: `alacritty.toml` (当前使用)
- ❌ **旧格式**: `alacritty.yml` (已废弃，不再支持)

## 配置文件位置

Alacritty 会按以下顺序查找配置文件（按优先级）：

1. `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
2. `$XDG_CONFIG_HOME/alacritty.toml`
3. `$HOME/.config/alacritty/alacritty.toml` ⭐ **推荐**
4. `$HOME/.alacritty.toml`
5. `/etc/alacritty/alacritty.toml` (系统级配置)

**Windows**:
- `%APPDATA%\alacritty\alacritty.toml`

## 安装方法

### macOS

#### 方法 1: Homebrew (推荐)
```bash
brew install --cask alacritty
```

#### 方法 2: 使用安装脚本
```bash
cd dotfiles/alacritty
bash install.sh
```

#### 方法 3: 从 GitHub 下载预编译版本
从 [GitHub Releases](https://github.com/alacritty/alacritty/releases) 下载 `.dmg` 文件安装

### Linux

#### Arch Linux
```bash
sudo pacman -S alacritty
```

#### Ubuntu/Debian
```bash
sudo apt install alacritty
```

#### 其他发行版
参考 [官方安装文档](https://github.com/alacritty/alacritty/blob/master/INSTALL.md)

### Windows

从 [GitHub Releases](https://github.com/alacritty/alacritty/releases) 下载 `.exe` 安装程序

**要求**: Windows 10 版本 1809 或更高（需要 ConPTY 支持）

## 使用方法

### 脚本说明

本目录包含两个脚本，用途不同：

#### `install.sh` - 完整安装脚本

**功能**：
- ✅ 安装 Alacritty（macOS: Homebrew, Windows: winget）
- ✅ 处理 terminfo 文件冲突
- ✅ 安装配置文件到部署位置
- ✅ 自动下载并安装主题文件
- ✅ 自动检测并修复 shell 路径问题（macOS）
- ✅ 安装 Shell 自动补全
- ✅ 移除 macOS Gatekeeper 隔离属性
- ✅ 自动配置 zsh 路径（macOS）

**使用场景**：
- 首次安装 Alacritty
- 需要完整安装和配置

**使用方法**：
```bash
cd dotfiles/alacritty
bash install.sh
```

#### `copy_config.sh` - 配置文件复制脚本

**功能**：
- ✅ 复制配置文件到部署位置
- ✅ 检查并下载主题文件（如果不存在）
- ✅ 自动检测并修复 shell 路径问题（macOS）
- ✅ 跨平台支持（macOS/Linux/Windows）

**使用场景**：
- Alacritty 已安装，只需更新配置
- 在多台机器上同步配置
- 快速部署配置文件
- 修复 shell 路径导致的闪退问题

**使用方法**：
```bash
cd dotfiles/alacritty
bash copy_config.sh
```

### 1. 使用安装脚本（推荐，首次安装）

```bash
# 运行安装脚本，会自动安装 Alacritty、配置文件和主题
cd dotfiles/alacritty
bash install.sh
```

### 2. 使用复制脚本（仅更新配置）

```bash
# 只复制配置文件，不进行安装（适用于已安装 Alacritty 的情况）
cd dotfiles/alacritty
bash copy_config.sh
```

### 3. 手动复制配置文件

```bash
# macOS/Linux
mkdir -p ~/.config/alacritty
cp dotfiles/alacritty/alacritty.toml ~/.config/alacritty/

# Windows
mkdir %APPDATA%\alacritty
copy dotfiles\alacritty\alacritty.toml %APPDATA%\alacritty\
```

### 4. 安装 Terminfo (可选但推荐)

确保终端类型正确识别：

```bash
# macOS/Linux
# 如果通过 Homebrew 安装，通常已自动配置
# 如果从源码编译，需要手动安装：
sudo tic -xe alacritty,alacritty-direct <path-to-alacritty.info>
```

### 5. 重启 Alacritty

配置更改后重启 Alacritty 以应用新设置。

## 配置说明

配置文件 (`alacritty.toml`) 包含以下主要部分：

- **通用配置** (`[general]`): 实时配置重载、主题导入等
- **环境变量** (`[env]`): TERM 等环境变量设置
- **窗口设置** (`[window]`): 尺寸、位置、填充、装饰、透明度等
- **滚动设置** (`[scrolling]`): 历史记录行数、滚动倍数
- **字体配置** (`[font]`): 字体族、大小、偏移等（包含 Windows Powerline 修复）
- **颜色主题** (`[colors]`): 通过 import 导入 Dracula 主题
- **光标设置** (`[cursor]`): 样式、闪烁等
- **Shell 设置** (`[terminal.shell]`): 默认 Shell 和启动目录（跨平台自动适配）
- **键盘绑定** (`[[key_bindings]]`): 快捷键配置（大部分已注释，可按需启用）
- **鼠标配置** (`[mouse]`): 鼠标行为设置

## 主题配置

### falcon 主题

配置文件默认使用 falcon 主题，通过 `import` 导入：

```toml
[general]
  import = [
    "~/.config/alacritty/themes/falcon.toml",
  ]
```

**主题文件位置**:
- macOS/Linux: `~/.config/alacritty/themes/falcon.toml`
- Windows: `%APPDATA%\alacritty\themes\falcon.toml`

**主题颜色**:
- 背景: `#020221` (深蓝黑)
- 前景: `#b4b4b9` (浅灰)
- 特点: 深色主题，文件夹背景色和文字颜色对比度较低

**参考**: [Alacritty Theme](https://github.com/alacritty/alacritty-theme)

**主题文件自动安装**：
- `install.sh` 和 `copy_config.sh` 会自动检测并下载主题文件
- 如果主题文件不存在，脚本会提示并自动下载

### 使用其他主题

1. 从 [Alacritty Theme](https://github.com/alacritty/alacritty-theme) 下载主题文件
2. 保存到 `~/.config/alacritty/themes/` 目录（Windows: `%APPDATA%\alacritty\themes\`）
3. 更新 `import` 配置

### 自定义主题

如果需要在使用 Dracula 主题的同时自定义某些颜色，可以在 `alacritty.toml` 中主题导入之后添加覆盖配置：

```toml
import = [
  "~/.config/alacritty/themes/dracula.toml",
]

# 覆盖主题中的某些颜色
[colors.cursor]
  text = "CellBackground"
  cursor = "#f8f8f2"
```

## macOS 特定配置

### Zsh + Oh My Zsh 配置

配置文件默认配置使用 zsh + Oh My Zsh。安装脚本会自动检测并配置正确的 zsh 路径。

**自动检测路径**（按优先级）：
1. `/opt/homebrew/bin/zsh` - Homebrew 安装的 zsh（Apple Silicon Mac）
2. `/bin/zsh` - 系统默认的 zsh（Intel Mac 或未通过 Homebrew 安装）

**安装脚本自动配置**：
- 运行 `install.sh` 时，脚本会自动检测 macOS 平台
- 自动检测 zsh 路径并更新配置文件
- 如果未找到 zsh，会显示警告信息

**手动配置**：
如果需要手动修改 zsh 路径，编辑 `~/.config/alacritty/alacritty.toml`：

```toml
[terminal.shell]
  program = "/opt/homebrew/bin/zsh"  # 或 "/bin/zsh"
  args = ["-l"]
```

**与系统默认 Shell 的关系**：
- Alacritty 配置的 zsh 路径独立于系统默认 shell
- 即使系统默认 shell 不是 zsh，Alacritty 也会使用配置的 zsh
- 建议同时将系统默认 shell 设置为 zsh（通过 `chsh -s /bin/zsh`）

## Windows 特定配置

### Git Bash 配置

配置文件会自动适配 Windows 系统，使用 Git Bash 作为默认 shell。配置使用 `[terminal.shell]` 格式（Alacritty 0.16.1 推荐，无警告）。

**自动检测路径**（按优先级）：
1. `D:\Program Files\Git\usr\bin\bash.exe`
2. `D:\Program Files\Git\bin\bash.exe`
3. `C:\Program Files\Git\usr\bin\bash.exe`
4. `C:\Program Files\Git\bin\bash.exe`
5. `C:\msys64\usr\bin\bash.exe`
6. `D:\msys64\usr\bin\bash.exe`

如果以上路径都不存在，Windows 将使用默认的 PowerShell。

### Powerline 符号溢出修复

配置文件已包含针对 Windows + Git Bash + Powerline/Oh My Posh 主题的修复：

- **`font.offset.y`**: 设置为 2（减少行距，避免溢出）
- **`font.glyph_offset.y`**: 设置为 1（修复 Powerline 字符宽度计算错误）

如果仍有溢出问题，可以调整 `glyph_offset.y` 的值（常见有效值：0, 1, 2）。

## 故障排除

### 配置文件不生效

1. 检查配置文件路径是否正确
2. 确认文件名为 `alacritty.toml`（不是 `.yml`）
3. 检查 TOML 语法是否正确
4. 查看 Alacritty 日志：`alacritty --print-events`

### Terminfo 问题

如果遇到终端类型识别问题：

```bash
# 检查 terminfo 是否安装
infocmp alacritty

# 如果未安装，手动安装
sudo tic -xe alacritty,alacritty-direct <path-to-alacritty.info>
```

**macOS 用户目录安装**（不需要 sudo）：

```bash
# 创建用户 terminfo 目录
mkdir -p ~/.terminfo/61

# 下载并编译到用户目录
cd /tmp
curl -L -o alacritty.info "https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info"
tic -xe alacritty,alacritty-direct -o ~/.terminfo alacritty.info
```

### Windows 调试

#### 查看启动日志

```bash
# 查看所有事件和详细日志
alacritty.exe --print-events -vvv

# 或者只查看错误信息
alacritty.exe -vvv 2>&1 | tee alacritty_debug.log
```

#### 常见问题

**1. 闪退问题**

- 检查 Shell 路径配置是否正确
- 验证配置文件语法：`alacritty.exe --config-file "%APPDATA%\alacritty\alacritty.toml" --print-events -vvv`
- 临时使用默认配置：备份当前配置后删除配置文件，使用默认配置启动

**2. Shell 路径格式错误**

TOML 配置文件中，Windows 路径的反斜杠需要转义为双反斜杠：

```toml
# 错误示例
[terminal.shell]
  program = "C:\msys64\usr\bin\bash.exe"  # ❌ 错误

# 正确示例
[terminal.shell]
  program = "C:\\msys64\\usr\\bin\\bash.exe"  # ✅ 正确
```

**3. 使用 PowerShell 作为默认 Shell**

如果 Git Bash 有问题，可以临时使用 PowerShell：

```toml
[terminal.shell]
  program = "powershell.exe"
  args = []
```

或者完全注释掉 `[terminal.shell]` 部分，让 Alacritty 使用默认的 PowerShell。

#### 调试命令速查

```bash
# 1. 查看 Alacritty 版本
alacritty.exe --version

# 2. 查看帮助信息
alacritty.exe --help

# 3. 使用调试模式启动
alacritty.exe --print-events -vvv

# 4. 指定配置文件启动
alacritty.exe --config-file "C:\path\to\alacritty.toml" -vvv

# 5. 验证配置文件语法
alacritty.exe --config-file "%APPDATA%\alacritty\alacritty.toml" --print-events 2>&1 | head -50

# 6. 检查 shell 路径是否存在
where.exe bash.exe
test -f "C:\msys64\usr\bin\bash.exe" && echo "存在" || echo "不存在"
```

### 配置警告修复

#### 已修复的配置项

- ✅ `live_config_reload`: 已移至 `[general]` 部分
- ✅ 所有废弃的配置项已注释（如 `use_thin_strokes`、`decorations` 等）

#### 配置迁移

如果从旧版本升级，可以使用 `alacritty migrate` 命令自动迁移配置：

```bash
# macOS
/Applications/Alacritty.app/Contents/MacOS/alacritty migrate

# Linux/Windows
alacritty migrate
```

### 主题未生效

1. 检查主题文件是否存在：
   ```bash
   ls ~/.config/alacritty/themes/dracula.toml
   ```

2. 检查配置文件语法：
   ```bash
   alacritty --print-events 2>&1 | grep -i error
   ```

3. 确认导入路径正确（支持 `~` 和绝对路径）

4. 恢复默认主题：删除或注释掉 `import` 行

## 系统要求

- **OpenGL**: 至少需要 OpenGL ES 2.0 支持
- **Windows**: Windows 10 版本 1809 或更高（需要 ConPTY 支持）

## 参考链接

- [Alacritty 官方仓库](https://github.com/alacritty/alacritty)
- [官方安装文档](https://github.com/alacritty/alacritty/blob/master/INSTALL.md)
- [配置文件文档](https://github.com/alacritty/alacritty/blob/master/alacritty.toml)
- [Alacritty 主题库](https://github.com/alacritty/alacritty-theme)
- [官方网站](https://alacritty.org)
- [Dracula Theme](https://draculatheme.com/alacritty)
