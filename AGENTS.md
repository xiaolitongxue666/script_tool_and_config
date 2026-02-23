# 仓库编码代理指南

本文件包含面向该 shell 脚本和 dotfiles 仓库的编码代理指南。

## 构建/检查/测试命令

### 脚本验证

```bash
# 检查脚本语法
bash -n <script>.sh

# 验证编码和换行符
./scripts/common/utils/check_and_fix_encoding.sh

# 规范化换行符为 LF（Windows 脚本除外）
./scripts/common/utils/ensure_lf_line_endings.sh

# 测试特定功能
./scripts/linux/system_basic_env/test_mirrors.sh
```

### 配置管理

```bash
chezmoi diff              # 预览
chezmoi apply -v           # 应用更改
./scripts/chezmoi/diagnose_chezmoi.sh  # 验证配置
```

### 测试

无自动化测试。手动运行 `test_*.sh` 脚本。

## 代码风格指南

### 文件格式

- **编码**: UTF-8（无 BOM）
- **换行符**: LF (`\n`)，Windows 脚本（`.bat`, `.ps1`, `.cmd`）使用 CRLF
- **缩进**: 4 个空格（不用制表符）
- **末尾换行**: 所有文件必须以换行符结尾

### Shell 脚本结构

```bash
#!/usr/bin/env bash
set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# 引入公共库
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
# ... 脚本内容 ...
end_script
```

### 命名规范

- **常量**: `UPPER_CASE_WITH_UNDERSCORES`（用 `readonly` 声明）
- **全局变量**: `lower_case_with_underscores`
- **局部变量**: `local my_var="$1"`
- **函数**: `snake_case`（公共），`_snake_case`（私有）
- **布尔检查**: `is_<condition>` 或 `has_<property>`

### 错误处理

```bash
set -euo pipefail
trap 'log_error "检测到错误，正在退出脚本"; exit 1' ERR
check_command "wget"
if [[ -z "$1" ]]; then
    error_exit "参数不能为空"
fi
```

### 日志函数

```bash
log_info "信息消息"          # 蓝色
log_success "成功消息"       # 绿色
log_warning "警告消息"       # 黄色（非致命）
log_error "错误消息"         # 红色
DEBUG=1 log_debug "调试信息" # 青色（仅 DEBUG=1 时）
```

### Chezmoi 模板语法

```bash
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") -}}
#!/bin/bash
# Linux/macOS 特定
{{- else if eq .chezmoi.os "windows" -}}
# Windows 特定
{{- end -}}
```

### OS 检测和包管理

```bash
detect_os_and_package_manager() {
    OS="$(uname -s)"
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="macos"; PACKAGE_MANAGER="brew"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        command -v pacman &> /dev/null && PACKAGE_MANAGER="pacman"
        command -v apt-get &> /dev/null && PACKAGE_MANAGER="apt"
        command -v dnf &> /dev/null && PACKAGE_MANAGER="dnf"
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        command -v winget &> /dev/null && PACKAGE_MANAGER="winget"
    fi
}

install_package() {
    local pkg="$1"
    case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        apt) sudo apt-get install -y "$pkg" ;;
        brew) brew install "$pkg" ;;
        winget) winget install -e --id "$pkg" ;;
    esac
}
```

### 文件操作

```bash
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "文件已备份: ${backup}"
    fi
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "目录已创建: ${dir}"
    fi
}
```

### 引入和源文件

- 始终引入 `common.sh`: `source "${PROJECT_ROOT}/scripts/common.sh"`
- 引入动态路径时使用 `# shellcheck disable=SC1090`
- 引入前检查文件是否存在
- 优先使用 `${BASH_SOURCE[0]}` 而不是 `$0`

### 注释

- 所有注释和文档使用中文
- 主要章节分隔使用 `# ============================================`
- 注释说明函数目的，而非实现细节

### 平台特定代码

- 平台特定配置使用 `run_on_linux/`、`run_on_darwin/`、`run_on_windows/`
- 安装脚本中的平台特定逻辑使用模板条件判断

### Git 子模块

- Neovim 配置位于 `dotfiles/nvim/`，是 Git 子模块
- 初始化: `git submodule update --init dotfiles/nvim`
- 更新: `git submodule update --remote dotfiles/nvim`

### 重要说明

- 所有脚本应可执行: `chmod +x script.sh`
- Windows 脚本必须用 CRLF，其他必须用 LF
- 绝不提交敏感数据（API 密钥、密码、私钥）
- 提交前使用 `chezmoi apply` 测试配置更改
- 修改系统配置文件前始终备份

## 项目结构

```
.
├── AGENTS.md                   # 本文件
├── README.md                   # 项目说明
├── chezmoi.yaml               # Chezmoi 主配置
├── scripts/                   # 所有脚本
│   ├── common.sh              # 公共函数库
│   ├── linux/                 # Linux 特定脚本
│   │   ├── system_basic_env/  # 系统基础环境配置
│   │   ├── dev_tools/         # 开发工具安装
│   │   └── user_config/       # 用户配置
│   ├── darwin/                # macOS 特定脚本
│   ├── windows/               # Windows 特定脚本
│   ├── chezmoi/               # Chezmoi 相关工具
│   └── common/                # 平台无关通用脚本
│       └── utils/             # 工具函数
├── dotfiles/                  # 点文件（通过 chezmoi 管理）
│   ├── run_on_linux/          # Linux 特定配置
│   ├── run_on_darwin/         # macOS 特定配置
│   ├── run_on_windows/        # Windows 特定配置
│   └── nvim/                  # Neovim 配置（Git 子模块）
└── docs/                      # 文档目录
```

## 常用工具函数

### 检查命令是否存在

```bash
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "未找到命令: ${cmd}"
    fi
}
```

### 确认用户操作

```bash
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    local prompt="${message} [y/N]"
    
    if [[ "$default" == "y" ]]; then
        prompt="${message} [Y/n]"
    fi
    
    read -r -p "${prompt} " response
    case "${response:-$default}" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
```

### 下载文件

```bash
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v wget &> /dev/null; then
        wget -q -O "$output" "$url"
    elif command -v curl &> /dev/null; then
        curl -s -o "$output" "$url"
    else
        error_exit "需要 wget 或 curl 来下载文件"
    fi
}
```

### 获取发行版信息

```bash
get_distro_info() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        DISTRO="$DISTRIB_ID"
        DISTRO_VERSION="$DISTRIB_RELEASE"
    fi
}
```

## 安全最佳实践

### 敏感数据处理

```bash
# 不记录敏感命令到历史
set +o history  # 关闭历史记录
export SECRET="your_secret"
set -o history  # 重新启用

# 使用环境变量而非硬编码
export API_KEY="${API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
    error_exit "未设置 API_KEY 环境变量"
fi
```

### 权限检查

```bash
check_root() {
    if [[ $EUID -ne 0 ]] && [[ -n "$NEED_ROOT" ]]; then
        error_exit "此脚本需要 root 权限"
    fi
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_warning "可能需要 sudo 权限"
    fi
}
```

### 文件权限设置

```bash
# 设置安全的文件权限
chmod 600 ~/.ssh/id_rsa         # 私钥仅所有者可读写
chmod 644 ~/.ssh/id_rsa.pub     # 公钥所有者可读写，其他人只读
chmod 700 ~/.ssh                # SSH 目录仅所有者可访问
```

## 性能优化

### 避免不必要的子 shell

```bash
# 不推荐
for i in $(seq 1 1000); do
    echo "$i"
done

# 推荐
for ((i=1; i<=1000; i++)); do
    echo "$i"
done
```

### 使用内置命令

```bash
# 不推荐 - 调用外部命令
external_basename=$(basename "$file")
external_dirname=$(dirname "$file")

# 推荐 - 使用内置参数扩展
internal_basename="${file##*/}"
internal_dirname="${file%/*}"
```

### 缓存命令结果

```bash
if ! command -v apt-get &> /dev/null; then
    HAS_APT=false
else
    HAS_APT=true
fi

# 后续直接使用变量而非重复调用
if $HAS_APT; then
    sudo apt-get update
fi
```

### 批量操作

```bash
# 不推荐 - 多次调用
install_package "vim"
install_package "git"
install_package "curl"

# 推荐 - 批量安装
case "$PACKAGE_MANAGER" in
    apt) sudo apt-get install -y vim git curl ;;
    pacman) sudo pacman -S --noconfirm vim git curl ;;
    brew) brew install vim git curl ;;
esac
```

## 调试技巧

### 启用调试模式

```bash
# 方式 1: 在脚本顶部
set -x  # 调试模式
set +x  # 关闭调试

# 方式 2: 使用 DEBUG 环境变量
if [[ "${DEBUG:-0}" == "1" ]]; then
    set -x
fi
```

### 打印变量值

```bash
debug_var() {
    local var_name="$1"
    echo "${var_name}=${!var_name}"
}

debug_var "PROJECT_ROOT"
```

### 追踪函数调用

```bash
trap 'echo "函数调用栈: ${FUNCNAME[*]}"' DEBUG
```

### 检查脚本语法

```bash
bash -n script.sh      # 语法检查
shellcheck script.sh   # 静态分析
```

## 配置文件管理

### Chezmoi 配置结构

```yaml
# chezmoi.yaml
data:
  name: "Your Name"
  email: "your.email@example.com"
  git:
    user_name: "{{ .data.name }}"
    user_email: "{{ .data.email }}"
```

### 使用模板变量

```bash
# .chezmoi.toml.tmpl
[user]
name = "{{ .data.name }}"
email = "{{ .data.email }}"
```

### 环境特定配置

```bash
{{- if eq .chezmoi.hostname "workstation" -}}
# 工作站特定配置
{{- else if eq .chezmoi.hostname "laptop" -}}
# 笔记本特定配置
{{- end -}}
```

## 跨平台兼容性

### 路径处理

```bash
# 获取脚本目录的跨平台方式
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 路径拼接
join_path() {
    local base="$1"
    local rel="$2"
    echo "${base}/${rel}" | sed 's|//|/|g'
}
```

### 检测平台特定功能

```bash
check_sed_compatibility() {
    if echo "test" | sed -nE 's/test/replaced/p' &> /dev/null; then
        SED_EXTENDED="-E"
    else
        SED_EXTENDED="-r"
    fi
}
```

### 处理 Windows 路径

```bash
# 在 Windows Git Bash 中转换路径
if [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    WINDOWS_PATH=$(cygpath -w "$linux_path")
fi
```

## 版本控制最佳实践

### 提交信息格式

```
[类型] 简短描述

详细说明（可选）

类型:
- feat: 新功能
- fix: 修复 bug
- docs: 文档更新
- style: 代码格式（不影响功能）
- refactor: 重构
- perf: 性能优化
- test: 测试
- chore: 构建/工具变更
```

### 分支命名

```
feature/功能名称
fix/问题描述
docs/文档说明
```

### Git 配置

```bash
# 设置正确的换行符处理
git config --global core.autocrlf input  # Linux/macOS
git config --global core.autocrlf true   # Windows
git config --global core.safecrlf true
```

### 忽略文件

```
# .gitignore 示例
*.backup
*.swp
*~
.chezmoi.toml.local
.chezmoi.yaml.local
.DS_Store
```

## 常见问题解决

### 脚本无法执行

```bash
# 检查文件权限
ls -l script.sh

# 添加执行权限
chmod +x script.sh

# 检查 shebang
head -n1 script.sh  # 应该是 #!/usr/bin/env bash
```

### 换行符问题

```bash
# 检查换行符
file script.sh  # 应该显示 "with CRLF line terminators" 或 "with LF line terminators"

# 转换换行符
dos2unix script.sh  # Windows -> Unix
unix2dos script.sh  # Unix -> Windows
```

### 权限被拒绝

```bash
# 检查所有权
ls -l ~/.ssh/config

# 修复所有权
sudo chown $USER:$USER ~/.ssh/config
chmod 600 ~/.ssh/config
```

### Chezmoi 应用失败

```bash
# 查看详细输出
chezmoi apply -v

# 查看差异
chezmoi diff

# 检查配置
chezmoi doctor
```

## 开发工作流程

### 1. 创建新脚本

```bash
# 创建脚本文件
touch scripts/linux/system_basic_env/install_new_software.sh
chmod +x scripts/linux/system_basic_env/install_new_software.sh
```

### 2. 编写脚本

```bash
# 遵循模板结构，使用中文注释
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../common.sh"

start_script "新软件安装"
# ... 脚本逻辑 ...
end_script
```

### 3. 测试脚本

```bash
# 语法检查
bash -n scripts/linux/system_basic_env/install_new_software.sh

# 运行测试（可能需要 sudo）
sudo ./scripts/linux/system_basic_env/install_new_software.sh
```

### 4. 验证编码和换行符

```bash
./scripts/common/utils/check_and_fix_encoding.sh
./scripts/common/utils/ensure_lf_line_endings.sh
```

### 5. 提交更改

```bash
git add .
git commit -m "feat: 添加新软件安装脚本"
git push
```

## 详细目录结构

项目完整目录结构见 [project_structure.md](project_structure.md)。

脚本目录概览：`scripts/` 下为 `common/`（utils、project_tools、ffmpeg-magic、git_templates 等）、`linux/`、`macos/`、`windows/`、`chezmoi/`、`migration/`。

## 脚本分类和命名规范


| 类别         | 目录                         | 命名模式                 | 示例                            |
| ---------- | -------------------------- | -------------------- | ----------------------------- |
| 系统安装       | `linux/system_basic_env/`  | `install_<软件名>.sh`   | `install_neovim.sh`           |
| 系统配置       | `linux/system_basic_env/`  | `configure_<配置名>.sh` | `configure_china_mirrors.sh`  |
| 工具脚本       | `common/utils/`            | `<动作>_<对象>.sh`       | `get_directory_name.sh`       |
| 项目工具       | `common/project_tools/`    | `<动作>_<对象>.sh`       | `generate_cmake_lists.sh`     |
| FFmpeg 工具    | `common/ffmpeg-magic/`     | 见目录内脚本               | `open_multiple_ffmpeg_srt.sh`  |
| 测试脚本       | 各目录                        | `test_<功能>.sh`       | `test_mirrors.sh`             |
| Windows 脚本 | `windows/windows_scripts/` | `<功能描述>.bat`         | `open_multi_vlc.bat`          |


## 参考资源

### 官方文档

- [Chezmoi 文档](https://www.chezmoi.io/) - Chezmoi 官方文档
- [Bash 手册](https://www.gnu.org/software/bash/manual/) - Bash 官方手册
- [ShellCheck](https://www.shellcheck.net/) - Shell 脚本静态分析工具

### 编程规范

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Google Shell 脚本规范
- [Bash Best Practices](https://github.com/alexanderepstein/Bash-Snippets) - Bash 最佳实践示例

### 相关工具

- [Git 文档](https://git-scm.com/doc) - Git 版本控制
- [Arch Wiki](https://wiki.archlinux.org/) - Arch Linux 官方文档
- [Homebrew 文档](https://docs.brew.sh/) - macOS 包管理器

