# chezmoi 模板优化方案

## 当前实现分析

### 当前方式
1. **使用 `run_on_<os>/` 目录**：将平台特定脚本放在不同目录
2. **脚本内部条件判断**：在 shell 脚本中使用 `if/else` 判断平台
3. **问题**：
   - 即使不匹配平台，脚本仍会执行（只是退出）
   - 需要维护多个目录结构
   - 通用脚本在 Windows 上也会尝试执行（虽然会失败）

### 示例：当前实现
```bash
# .chezmoi/run_once_install-tmux.sh
case "$PLATFORM" in
    macos|linux)
        install_package "tmux"
        ;;
    *)
        echo "[ERROR] 不支持的操作系统"
        exit 1
        ;;
esac
```

**问题**：在 Windows 上也会执行，只是会报错退出。

---

## 优化方案：使用模板条件判断

### 核心思路

chezmoi 的模板引擎支持：
- **如果模板解析后为空或只有空白，脚本不会执行**
- **可以在脚本开头使用条件判断，不符合条件时返回空内容**

### 优化后的实现

#### 方案 1：在脚本开头添加模板条件（推荐）

将脚本改为 `.tmpl` 扩展名，在开头添加条件判断：

```bash
# .chezmoi/run_once_install-tmux.sh.tmpl
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") -}}
#!/bin/bash

# ============================================
# Tmux 安装脚本（chezmoi run_once_）
# 仅支持 Linux/macOS
# ============================================

# ... 脚本内容 ...

{{- end -}}
```

**优势**：
- Windows 上模板解析为空，chezmoi 不会执行脚本
- 不需要 `run_on_<os>/` 目录
- 更清晰的条件判断

#### 方案 2：统一安装脚本使用模板

创建一个统一的安装脚本，使用模板条件：

```bash
# .chezmoi/run_once_install-packages.sh.tmpl
{{- if eq .chezmoi.os "linux" -}}
#!/bin/bash
# Linux 安装逻辑
sudo apt-get update && sudo apt-get install -y tmux zsh fish
{{- else if eq .chezmoi.os "darwin" -}}
#!/bin/bash
# macOS 安装逻辑
brew install tmux zsh fish
{{- else if eq .chezmoi.os "windows" -}}
#!/bin/bash
# Windows 安装逻辑（Git Bash）
# 只安装通用工具，不安装 Fish
# ...
{{- end -}}
```

---

## 具体优化建议

### 1. 将通用脚本改为模板

**当前**：
```
.chezmoi/
├── run_once_install-tmux.sh          # 所有平台都执行，内部判断
├── run_once_install-starship.sh      # 所有平台都执行，内部判断
└── run_once_install-alacritty.sh     # 所有平台都执行，内部判断
```

**优化后**：
```
.chezmoi/
├── run_once_install-tmux.sh.tmpl     # 模板条件：Linux/macOS
├── run_once_install-starship.sh.tmpl # 模板条件：所有平台
└── run_once_install-alacritty.sh.tmpl # 模板条件：Linux/macOS
```

### 2. 合并平台特定脚本

**当前**：
```
.chezmoi/
├── run_on_linux/run_once_install-zsh.sh
├── run_on_linux/run_once_install-fish.sh
├── run_on_darwin/run_once_install-zsh.sh
└── run_on_darwin/run_once_install-fish.sh
```

**优化后**：
```
.chezmoi/
├── run_once_install-zsh.sh.tmpl      # 模板条件：Linux/macOS/Windows
└── run_once_install-fish.sh.tmpl     # 模板条件：Linux/macOS（排除 Windows）
```

### 3. 示例：优化后的 Fish 安装脚本

```bash
# .chezmoi/run_once_install-fish.sh.tmpl
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") -}}
#!/bin/bash

# ============================================
# Fish Shell 安装脚本（chezmoi run_once_）
# 仅支持 Linux/macOS
# ============================================

# 获取 common_install.sh 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd 2>/dev/null || echo "$HOME")"
COMMON_INSTALL="${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

if [ ! -f "$COMMON_INSTALL" ]; then
    COMMON_INSTALL="$HOME/.local/share/chezmoi/scripts/chezmoi/common_install.sh"
fi

# 加载通用函数库
if [ -f "$COMMON_INSTALL" ]; then
    source "$COMMON_INSTALL"
else
    echo "[WARNING] 未找到 common_install.sh，使用基本函数"
    function setup_proxy() { :; }
    function detect_os_and_package_manager() {
        OS="$(uname -s)"
        if [[ "$OS" == "Darwin" ]]; then
            PLATFORM="macos"
            PACKAGE_MANAGER="brew"
        elif [[ "$OS" == "Linux" ]]; then
            PLATFORM="linux"
            if command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
            elif command -v apt-get &> /dev/null; then
                PACKAGE_MANAGER="apt"
            fi
        fi
    }
    function install_package() {
        local pkg="$1"
        if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
            brew install "$pkg"
        elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
            sudo pacman -S --noconfirm "$pkg"
        elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
            sudo apt-get update && sudo apt-get install -y "$pkg"
        fi
    }
fi

# 设置代理
setup_proxy "${PROXY:-http://127.0.0.1:7890}"

# 检测操作系统和包管理器
detect_os_and_package_manager || exit 1

# 检查 Fish 是否已安装
if command -v fish &> /dev/null; then
    echo "[INFO] Fish Shell 已安装: $(fish --version)"
    exit 0
fi

echo "[INFO] 开始安装 Fish Shell..."

# 根据平台安装 Fish
case "$PLATFORM" in
    macos)
        if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
            install_package "fish"
        else
            echo "[ERROR] macOS 需要 Homebrew 来安装 Fish"
            exit 1
        fi
        ;;
    linux)
        install_package "fish"
        ;;
    *)
        echo "[ERROR] 不支持的操作系统"
        exit 1
        ;;
esac

if command -v fish &> /dev/null; then
    echo "[SUCCESS] Fish Shell 安装成功: $(fish --version)"
else
    echo "[ERROR] Fish Shell 安装失败"
    exit 1
fi
{{- end -}}
```

**效果**：
- Windows 上模板解析为空，chezmoi 不会执行
- Linux/macOS 上正常执行
- 不需要 `run_on_<os>/` 目录

### 4. 示例：优化后的 Zsh 安装脚本

```bash
# .chezmoi/run_once_install-zsh.sh.tmpl
{{- if eq .chezmoi.os "linux" -}}
#!/bin/bash
# Linux 安装逻辑
# ... Linux 特定代码 ...
{{- else if eq .chezmoi.os "darwin" -}}
#!/bin/bash
# macOS 安装逻辑
# ... macOS 特定代码 ...
{{- else if eq .chezmoi.os "windows" -}}
#!/bin/bash
# Windows 安装逻辑（通过 MSYS2）
# ... Windows 特定代码 ...
{{- end -}}
```

---

## 优化对比

### 当前方式 vs 优化方式

| 特性 | 当前方式 | 优化方式（模板） |
|------|---------|----------------|
| **目录结构** | 需要 `run_on_<os>/` 目录 | 统一在根目录，使用模板条件 |
| **脚本执行** | 所有平台都执行，内部判断退出 | 不符合条件不执行（模板为空） |
| **维护性** | 需要维护多个目录 | 统一管理，更清晰 |
| **错误处理** | 不匹配平台会报错退出 | 不匹配平台直接跳过 |
| **可读性** | 需要查看脚本内容才知道支持哪些平台 | 模板条件一目了然 |

### 文件结构对比

**当前**：
```
.chezmoi/
├── run_once_install-tmux.sh
├── run_once_install-starship.sh
├── run_once_install-alacritty.sh
├── run_on_linux/
│   ├── run_once_install-zsh.sh
│   └── run_once_install-fish.sh
├── run_on_darwin/
│   ├── run_once_install-zsh.sh
│   └── run_once_install-fish.sh
└── run_on_windows/
    └── run_once_install-zsh.sh
```

**优化后**：
```
.chezmoi/
├── run_once_install-tmux.sh.tmpl          # 条件：Linux/macOS
├── run_once_install-starship.sh.tmpl       # 条件：所有平台
├── run_once_install-alacritty.sh.tmpl      # 条件：Linux/macOS
├── run_once_install-zsh.sh.tmpl            # 条件：所有平台（内容不同）
└── run_once_install-fish.sh.tmpl           # 条件：Linux/macOS（排除 Windows）
```

---

## 实施建议

### 阶段 1：渐进式优化（推荐）

1. **保持现有结构**，只优化通用脚本
   - 将 `run_once_install-tmux.sh` 改为 `run_once_install-tmux.sh.tmpl`
   - 添加模板条件判断

2. **测试验证**
   - 在 Windows 上验证不会执行
   - 在 Linux/macOS 上验证正常执行

### 阶段 2：完全优化

1. **合并平台特定脚本**
   - 将 `run_on_<os>/` 目录中的脚本合并到根目录
   - 使用模板条件区分不同平台

2. **清理目录结构**
   - 删除 `run_on_<os>/` 目录（如果不再需要）
   - 保留平台特定的配置文件（如 `dot_bash_profile`）

---

## 注意事项

### 1. 模板语法

- 使用 `{{- if -}}` 而不是 `{{ if }}`（`-` 会去除空白）
- 确保条件判断正确：`eq .chezmoi.os "linux"`

### 2. 测试

- 使用 `chezmoi execute-template` 测试模板：
  ```bash
  chezmoi execute-template "$(cat .chezmoi/run_once_install-fish.sh.tmpl)"
  ```

### 3. 向后兼容

- 如果已有系统在使用，需要逐步迁移
- 可以先创建 `.tmpl` 版本，测试后再删除旧版本

---

## 总结

**优化优势**：
1. ✅ **更清晰**：模板条件一目了然
2. ✅ **更高效**：不符合条件不执行，不浪费资源
3. ✅ **更简洁**：减少目录结构，统一管理
4. ✅ **更灵活**：可以基于更多条件（主机名、用户名等）

**建议**：
- 对于新脚本，直接使用模板方式
- 对于现有脚本，可以逐步迁移
- 保持 `run_on_<os>/` 目录用于配置文件（如 `dot_bash_profile`）
