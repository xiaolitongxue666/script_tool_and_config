# chezmoi 相关脚本说明

本目录脚本：安装 chezmoi 本身（`install_chezmoi.sh`）、通用安装函数库（`common_install.sh`）。一键安装与首次使用见项目根目录 [docs/INSTALL_GUIDE.md](../../docs/INSTALL_GUIDE.md)。

## 脚本职责划分

### 1. `install_chezmoi.sh` - 安装 chezmoi 工具本身

**职责**：在系统上安装 chezmoi 这个 dotfiles 管理工具

**用途**：
- 首次使用项目时，需要先安装 chezmoi
- 支持多平台（Windows、macOS、Linux）
- 自动检测包管理器并安装

**调用方式**：
```bash
# 直接运行
bash scripts/chezmoi/install_chezmoi.sh

# 或通过一键安装脚本
./install.sh

# 或通过管理脚本
./scripts/manage_dotfiles.sh install
```

**特点**：
- 独立脚本，不依赖其他函数库
- 只负责安装 chezmoi 工具本身
- 安装完成后，chezmoi 就可以管理配置了

---

### 2. `common_install.sh` - 通用安装函数库

**职责**：提供跨平台的软件安装函数库

**用途**：
- 被 `.chezmoi/run_once_install-*.sh` 脚本引用
- 提供统一的包安装接口（`install_package`）
- 提供操作系统和包管理器检测（`detect_os_and_package_manager`）
- 提供代理配置函数（`setup_proxy`）

**调用方式**：
```bash
# 在 run_once_install-*.sh 脚本中
source "${PROJECT_ROOT}/scripts/chezmoi/common_install.sh"

# 然后使用函数
detect_os_and_package_manager
install_package "zsh"
```

**特点**：
- 函数库，不直接执行
- 被多个安装脚本复用
- 提供统一的跨平台安装接口

---

## 工作流程

### 完整流程

```
1. 安装 chezmoi 工具
   └─> install_chezmoi.sh
       └─> 安装完成后，chezmoi 可用

2. 应用配置
   └─> chezmoi apply
       └─> 执行 .chezmoi/run_once_install-*.sh
           └─> source common_install.sh
               └─> 使用 install_package() 安装软件

3. 管理配置文件
   └─> chezmoi apply/diff/edit
       └─> 管理 dot_* 配置文件
```

### 分离的好处

1. **职责单一**
   - `install_chezmoi.sh` 只负责安装 chezmoi
   - `common_install.sh` 只提供安装函数

2. **可复用性**
   - `common_install.sh` 可以被多个 `run_once_install-*.sh` 脚本复用
   - 不需要在每个安装脚本中重复实现平台检测和包安装逻辑

3. **清晰性**
   - 职责分离，易于理解和维护
   - 修改安装逻辑只需更新 `common_install.sh`

4. **灵活性**
   - 可以单独安装 chezmoi（不安装其他软件）
   - 可以单独使用 `common_install.sh` 的函数

---

## 使用场景

### 场景 1：首次使用项目

```bash
# 1. 安装 chezmoi
bash scripts/chezmoi/install_chezmoi.sh

# 2. 应用配置（会自动安装软件）
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
# 此时会执行 run_once_install-*.sh，使用 common_install.sh 的函数
```

### 场景 2：只安装 chezmoi，不安装其他软件

```bash
# 只运行 install_chezmoi.sh
bash scripts/chezmoi/install_chezmoi.sh

# 然后手动管理配置，不执行 run_once 脚本
chezmoi apply --dry-run
```

### 场景 3：在其他脚本中使用安装函数

```bash
# 在自定义脚本中
source scripts/chezmoi/common_install.sh

detect_os_and_package_manager
install_package "vim"
```

---

## 为什么不合并？

### 如果合并的问题：

1. **职责混乱**
   - 一个脚本既要安装 chezmoi，又要提供安装函数
   - 难以理解脚本的主要目的

2. **复用困难**
   - `run_once_install-*.sh` 脚本需要 source 整个安装脚本
   - 可能会执行不必要的代码

3. **维护困难**
   - 修改安装函数可能影响 chezmoi 安装逻辑
   - 代码耦合度高

### 分离的优势：

1. **单一职责原则**
   - 每个脚本只做一件事
   - 易于理解和维护

2. **高内聚低耦合**
   - `common_install.sh` 专注于安装函数
   - `install_chezmoi.sh` 专注于安装 chezmoi
   - 两者通过标准接口交互

3. **易于测试**
   - 可以单独测试每个脚本
   - 可以单独测试函数库

---

## 总结

**推荐：保持分离**

- ✅ `install_chezmoi.sh` - 安装 chezmoi 工具
- ✅ `common_install.sh` - 提供安装函数库
- ✅ 职责清晰，易于维护
- ✅ 符合单一职责原则

**不推荐：合并**

- ❌ 职责混乱
- ❌ 难以复用
- ❌ 维护困难
