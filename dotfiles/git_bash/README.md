# Git Bash 配置

Git Bash 是 Windows 上的 Bash 环境，提供类 Unix 的命令行体验。

## 配置文件结构

```
git_bash/
├── .bash_profile      # Git Bash 主配置文件（登录 shell，仅 Windows）
├── .bashrc            # Git Bash 非登录 shell 配置文件（仅 Windows）
├── install.sh         # 自动安装脚本（仅 Windows，自动检测系统）
└── README.md          # 本文件
```

## 安装方法

### 方法 1: 使用安装脚本（推荐）

在 Git Bash 中运行：

```bash
cd dotfiles/git_bash
chmod +x install.sh
./install.sh
```

安装脚本会自动：
- 检测 Windows Git Bash 环境
- 备份现有配置文件（`.bash_profile` 和 `.bashrc`）
- 同步配置文件到用户目录
- 确保 `.bashrc` 正确加载 `.bash_profile`

### 方法 2: 手动复制配置

```bash
# 复制配置文件
cp dotfiles/git_bash/.bash_profile ~/.bash_profile

# 确保 .bashrc 加载 .bash_profile
if [ ! -f ~/.bashrc ]; then
    cat > ~/.bashrc << 'EOF'
if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi
EOF
fi
```

## 配置文件位置

- **主配置**: `~/.bash_profile`（登录 shell 配置，Windows Git Bash）
- **非登录配置**: `~/.bashrc`（非登录交互 shell 配置，自动加载 `.bash_profile`）

### 配置文件关系

- `.bash_profile`: 登录 shell 时加载，包含所有主要配置
- `.bashrc`: 非登录交互 shell 时加载，会先加载 `.bash_profile`，然后加载 inshellisense 等工具

## 配置说明

### 历史记录配置

- 自动追加历史记录到文件
- 历史记录大小：10000 条
- 忽略重复命令

### 代理配置

- **默认代理**: `http://127.0.0.1:7890`（自动启用）
- **快速启用代理**: `h_proxy`
- **关闭代理**: `unset_h`

### 环境变量

- **Google Cloud 项目**: `GOOGLE_CLOUD_PROJECT`
- **PostgreSQL 路径**: `CARGO_ENCODED_RUSTFLAGS`、`C_INCLUDE_PATH`
- **Python 环境**: 使用 `uv` 管理的 Python 3.10
- **字符编码**: UTF-8 中文环境

### 别名

- `open` → `explorer`（在 Git Bash 中用 `open` 打开文件管理器）
- `make` → `mingw32-make`（在 Git Bash 中使用 make 命令）
- `python` → `python3.10`

### Shell 增强工具

- **inshellisense**: 自动补全增强（在 `.bashrc` 中加载，如果已安装）
- **Oh My Posh**: 终端主题美化（在 `.bash_profile` 中加载，如果已安装）
- **Starship**: 可选提示符（已注释，如需使用请取消注释并注释 Oh My Posh）

### 配置文件说明

- **`.bash_profile`**: 登录 shell 配置，包含环境变量、别名、主题等主要配置
- **`.bashrc`**: 非登录交互 shell 配置，加载 `.bash_profile` 和 inshellisense 等工具

## 重新加载配置

```bash
source ~/.bash_profile
```

或重新打开 Git Bash。

## 配置项说明

### PostgreSQL 路径配置

配置文件已修复路径中的空格问题，使用引号包裹路径：

```bash
export CARGO_ENCODED_RUSTFLAGS="-L /d/Program Files/PostgreSQL/17/lib"
export C_INCLUDE_PATH="/d/Program Files/PostgreSQL/17/include"
```

### 代理配置

默认启用代理（`localhost:7890`），可通过别名快速切换：

```bash
# 启用代理
h_proxy

# 关闭代理
unset_h
```

### Oh My Posh 主题

如果已安装 Oh My Posh，配置文件会自动加载 Montys 主题。主题文件位置：

```
~/AppData/Local/Programs/oh-my-posh/themes/montys.omp.json
```

如需更换主题，修改配置文件中的主题路径。

## 问题排查

### 配置文件不生效

1. 检查配置文件路径是否正确
2. 确认 `.bashrc` 中已加载 `.bash_profile`
3. 重新加载配置：`source ~/.bash_profile`

### 路径问题

如果遇到路径相关错误（如 PostgreSQL 路径），检查：
1. 路径是否正确（注意空格）
2. 路径是否使用引号包裹
3. 环境变量是否正确设置

### 代理问题

如果代理不工作：
1. 检查代理服务是否运行（默认 `localhost:7890`）
2. 使用 `h_proxy` 手动启用代理
3. 使用 `unset_h` 关闭代理测试

### Oh My Posh 不显示

1. 检查 Oh My Posh 是否已安装：`which oh-my-posh`
2. 检查主题文件是否存在
3. 确认配置文件在最后加载 Oh My Posh（不要在其他工具之后）

## 注意事项

1. **仅 Windows**: 此配置仅适用于 Windows Git Bash 环境
2. **系统检测**: 配置文件会自动检测系统，非 Windows 环境不会加载
3. **备份**: 安装脚本会自动备份现有配置
4. **路径格式**: Windows 路径使用正斜杠（`/`）而非反斜杠（`\`）

## 参考链接

- [Git Bash 官方文档](https://git-scm.com/docs/git-bash)
- [Oh My Posh](https://ohmyposh.dev/)
- [Starship](https://starship.rs/)

