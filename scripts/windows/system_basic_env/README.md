# Windows 基础工具安装脚本

用于在新装 Windows 系统上自动安装基础开发工具的 PowerShell 脚本。

## 功能特性

- 支持 **winget** 和 **chocolatey** 两种包管理器（优先使用 winget）
- 支持**安装**、**更新**、**卸载**三种操作模式
- 支持**自动模式**和**交互式模式**两种操作方式
- 支持**单独操作**某个工具（类似 winutil）
- 自动检测并安装包管理器（如果未安装）
- 自动检测已安装工具，避免重复安装
- 自动安装 Nerd Fonts 字体（如果未安装）
- 详细的安装进度和结果报告（包含版本号、安装方式）
- 自动检测中国大陆环境并设置代理
- **日志记录功能**：所有输出自动保存到 `log` 文件（与控制台输出完全一致）
- **PATH 环境变量管理**：自动刷新 PATH，确保安装的工具立即可用
- **PATH 备份功能**：在修改 PATH 前自动备份到 `path.bak` 文件

## 工具列表

### 版本管理器
- **fnm** - Fast Node Manager (Node.js 版本管理)
- **uv** - Python 包管理器
- **rustup** - Rust 工具链

### 终端工具
- **alacritty** - GPU 加速终端模拟器
- **注意**：tmux 在 Windows 上不支持，使用 Windows Terminal 或 WSL

### 系统监控工具
- **bottom** - 跨平台系统监控工具（btop 的 Windows 替代）
- **fastfetch** - 系统信息展示工具（neofetch 替代）
- **eza** - ls 替代工具

### 文件工具
- **bat** - cat 替代工具（语法高亮）
- **fd** - find 替代工具（快速文件查找）
- **ripgrep (rg)** - grep 替代工具（快速文本搜索）
- **fzf** - 模糊查找工具
- **注意**：trash-cli 在 Windows 上可能不可用，Windows 有 Recycle Bin

### 提示符工具
- **oh-my-posh** - PowerShell 提示符工具
  - **注意**：Windows 下使用 alacritty + git bash + oh-my-posh，不使用 starship

### 开发工具
- **gcc** - MinGW-w64 GCC 编译器（C/C++ 开发，与 Linux GCC 行为一致）
- **make** - GNU Make for Windows（构建自动化工具，与 Linux Makefile 兼容）
- **cmake** - CMake 跨平台构建系统（支持 CMakeLists.txt，与 Linux 无缝共享）
- **git-delta** - Git diff 增强工具
- **lazygit** - Git TUI 工具
- **direnv** - 环境变量管理工具
- **gh (GitHub CLI)** - 不作为默认安装工具（可选）

### 其他工具
- **dust** - du 替代工具（磁盘使用分析）
- **procs** - ps 替代工具（进程查看增强）
- **bottom** - 系统监控工具

### 字体
- **Nerd Fonts FiraMono** - 编程字体（支持图标）

## 使用方法

### 如何运行

**重要：必须以管理员身份运行！**

#### 方法 1：使用批处理文件（推荐，最简单）

直接双击 `install_common_tools.bat` 文件，或右键选择"以管理员身份运行"。

批处理文件会自动：
- 检查管理员权限
- 绕过执行策略限制
- 启动 PowerShell 脚本

#### 方法 2：使用 PowerShell（需要先设置执行策略）

**步骤 1：以管理员身份运行 PowerShell**

- **方法 A：右键菜单**
  1. 右键点击开始菜单
  2. 选择 "Windows PowerShell (管理员)" 或 "终端 (管理员)"

- **方法 B：快捷键**
  1. 按 `Win + X`
  2. 选择 "Windows PowerShell (管理员)" 或 "终端 (管理员)"

- **方法 C：运行对话框**
  1. 按 `Win + R`
  2. 输入 `powershell`
  3. 按 `Ctrl + Shift + Enter`（以管理员身份运行）

**步骤 2：设置执行策略（仅需一次）**

```powershell
# 临时设置（推荐，仅当前会话有效）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# 或永久设置（当前用户）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**步骤 3：运行脚本**

```powershell
cd E:\Code\my_code\DotfilesAndScript\script_tool_and_config\scripts\windows\system_basic_env
.\install_common_tools.ps1
```

#### 方法 3：绕过执行策略（无需设置）

```powershell
# 以管理员身份运行 PowerShell，然后执行：
powershell -ExecutionPolicy Bypass -File .\install_common_tools.ps1
```

### 基本使用

#### 安装工具

```powershell
# 自动安装所有工具（默认模式）
.\install_common_tools.ps1

# 交互式选择安装
.\install_common_tools.ps1 -Interactive

# 指定包管理器
.\install_common_tools.ps1 -PackageManager winget
.\install_common_tools.ps1 -PackageManager chocolatey

# 跳过字体安装
.\install_common_tools.ps1 -SkipFonts
```

#### 更新工具

```powershell
# 更新所有已安装的工具
.\install_common_tools.ps1 -Action Update

# 交互式选择要更新的工具
.\install_common_tools.ps1 -Action Update -Interactive

# 更新指定包管理器安装的工具
.\install_common_tools.ps1 -Action Update -PackageManager winget
```

#### 卸载工具

```powershell
# 卸载所有已安装的工具（谨慎使用）
.\install_common_tools.ps1 -Action Uninstall

# 交互式选择要卸载的工具
.\install_common_tools.ps1 -Action Uninstall -Interactive
```

#### 单独操作某个工具

```powershell
# 单独操作某个工具（会显示详细菜单）
.\install_common_tools.ps1 -ToolName fnm
.\install_common_tools.ps1 -ToolName alacritty
.\install_common_tools.ps1 -ToolName bottom

# 结合操作类型
.\install_common_tools.ps1 -Action Update -ToolName fnm
.\install_common_tools.ps1 -Action Uninstall -ToolName alacritty
```

### 参数说明

| 参数 | 说明 | 可选值 | 默认值 |
|------|------|--------|--------|
| `-Interactive` | 启用交互式模式，让用户选择要操作的工具 | 开关 | False |
| `-PackageManager` | 指定包管理器 | `winget`, `chocolatey`, `auto` | `auto` |
| `-SkipFonts` | 跳过字体安装 | 开关 | False |
| `-Action` | 操作类型 | `Install`, `Update`, `Uninstall` | `Install` |
| `-ToolName` | 指定要单独操作的工具名称 | 工具名称（如 `fnm`, `alacritty`） | 空 |
| `-Msys2Mirror` | 指定 MSYS2 pacman 镜像源（pacman 在代理失败时会自动切换） | 例如 `https://mirrors.tuna.tsinghua.edu.cn/msys2` | 空 |
| `-GccPreset` | GCC 安装方案：`minimal` 仅安装 gcc/g++/gdb/make 等核心组件，`toolchain` 为完整套件 | `toolchain`, `minimal` | `minimal` |

### 使用示例

```powershell
# 示例 1: 自动安装所有工具
.\install_common_tools.ps1

# 示例 2: 交互式安装，使用 winget
.\install_common_tools.ps1 -Interactive -PackageManager winget

# 示例 3: 更新所有已安装的工具
.\install_common_tools.ps1 -Action Update

# 示例 4: 交互式更新，只更新选中的工具
.\install_common_tools.ps1 -Action Update -Interactive

# 示例 5: 单独操作 fnm 工具
.\install_common_tools.ps1 -ToolName fnm

# 示例 6: 单独更新 uv 工具
.\install_common_tools.ps1 -Action Update -ToolName uv

# 示例 7: 卸载 alacritty
.\install_common_tools.ps1 -Action Uninstall -ToolName alacritty

# 示例 8: 安装所有工具但跳过字体
.\install_common_tools.ps1 -SkipFonts

# 示例 9: 使用清华镜像并安装完整 GCC toolchain
.\install_common_tools.ps1 -Msys2Mirror "https://mirrors.tuna.tsinghua.edu.cn/msys2" -GccPreset toolchain
```

### 运行要求

- **管理员权限**：脚本需要管理员权限运行
- **PowerShell 5.1+**：Windows 10/11 默认已安装
- **网络连接**：需要下载工具和字体文件

## 操作流程

### 安装流程

1. **检查管理员权限** - 确保以管理员身份运行
2. **检测中国大陆环境** - 如果检测到，自动设置代理（localhost:7890）
3. **检测包管理器** - 自动检测 winget 或 chocolatey
4. **安装包管理器** - 如果未安装，自动安装（优先安装 winget）
5. **选择操作模式** - 自动模式或交互式模式
6. **检测已安装工具** - 自动检测已安装的工具，避免重复安装
7. **安装工具** - 按分类安装所有选定的工具
8. **安装字体** - 下载并安装 Nerd Fonts FiraMono（如果未跳过）
9. **显示详细报告** - 显示每个工具的状态、版本号、安装方式
10. **用户确认** - 询问是否关闭窗口

### 更新流程

1. **检查管理员权限**
2. **检测包管理器和代理**
3. **检测已安装的工具** - 只更新已安装的工具
4. **执行更新** - 使用包管理器更新工具
5. **显示更新报告** - 显示已更新、已是最新、失败的工具

### 卸载流程

1. **检查管理员权限**
2. **检测已安装的工具** - 只卸载已安装的工具
3. **执行卸载** - 使用包管理器卸载工具
4. **显示卸载报告** - 显示已卸载、失败的工具

### 单独操作流程

1. **检查管理员权限**
2. **查找指定工具**
3. **显示工具详细信息** - 名称、描述、安装状态、版本号
4. **显示操作菜单** - 安装/更新/卸载选项
5. **执行操作**
6. **显示操作结果**

## 注意事项

### Windows 特定配置

- **提示符工具**：Windows 下使用 **oh-my-posh** 而非 starship
- **终端组合**：推荐使用 alacritty + git bash + oh-my-posh
- **GitHub CLI**：gh 不作为默认安装工具，如需安装请使用交互式模式

### 包管理器优先级

- 默认优先使用 **winget**（Windows 官方包管理器）
- 如果 winget 不可用，自动回退到 **chocolatey**
- 可以通过 `-PackageManager` 参数手动指定

### 字体安装

- 字体文件从 GitHub Releases 下载
- 自动解压并安装到 `C:\Windows\Fonts\` 目录
- 如果字体已存在，会跳过安装

### 已安装工具检测

- 脚本会自动检测工具是否已安装
- 已安装的工具会显示为 "Already Exists"，不会重复安装
- 更新/卸载模式下，只显示已安装的工具
- 每个工具都会显示版本号和安装方式

### PATH 环境变量管理

- **自动刷新 PATH**：安装/更新工具后自动刷新 PATH 环境变量
- **PATH 备份**：在首次修改 PATH 前，自动备份到 `path.bak` 文件（与脚本同目录）
- **多重刷新机制**：使用多种方法确保 PATH 更新生效（注册表、Win32 API、.NET 方法）
- **Git Bash 兼容**：确保安装的工具在 Git Bash 中也可用
- **PATH 验证**：安装后自动验证工具是否在 PATH 中可用

### 日志记录功能

- **自动日志记录**：所有脚本输出（包括控制台输出）自动保存到 `log` 文件
- **日志位置**：`scripts\windows\system_basic_env\log`（与脚本同目录）
- **日志格式**：与控制台输出完全一致（无时间戳，保持原始格式）
- **日志内容**：包括所有信息、成功、警告、错误消息，以及外部命令（如 winget）的输出
- **返回值记录**：函数返回值（True/False）也会记录到日志
- **自动清理**：每次运行脚本时，会清空旧日志，开始新会话

### 代理设置

- 脚本会自动检测是否在中国大陆环境
- 检测方法：系统区域设置、时区、语言
- 如果检测到，自动设置代理：`http://127.0.0.1:7890`
- 代理会自动应用于所有网络请求（下载、安装等）

### 错误处理

- 操作失败的工具会被记录
- 脚本会继续操作其他工具，不会因单个工具失败而中断
- 最后会显示完整的操作结果报告
- 报告包含：工具名称、版本号、状态、安装方式

## 常见问题

### Q: 如何以管理员身份运行 PowerShell？

**方法 1：右键菜单**
1. 右键点击开始菜单
2. 选择 "Windows PowerShell (管理员)" 或 "终端 (管理员)"

**方法 2：搜索**
1. 按 `Win + X`
2. 选择 "Windows PowerShell (管理员)" 或 "终端 (管理员)"

**方法 3：运行对话框**
1. 按 `Win + R`
2. 输入 `powershell`
3. 按 `Ctrl + Shift + Enter`（以管理员身份运行）

### Q: 遇到"禁止运行脚本"错误怎么办？

如果看到类似以下错误：
```
无法加载文件 ... 因为在此系统上禁止运行脚本
```

这是因为 PowerShell 的执行策略限制了脚本运行。

**最简单的解决方法：使用批处理文件**

直接使用 `install_common_tools.bat` 文件，它会自动绕过执行策略限制。

**其他解决方法：**

**方法 1：临时允许（推荐）**
```powershell
# 以管理员身份运行 PowerShell，然后执行：
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```
当提示是否更改执行策略时，输入 `Y` 确认。

**方法 2：永久允许（当前用户）**
```powershell
# 以管理员身份运行 PowerShell，然后执行：
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
当提示是否更改执行策略时，输入 `Y` 确认。

**方法 3：绕过执行策略（仅本次运行）**
```powershell
# 以管理员身份运行 PowerShell，然后执行：
powershell -ExecutionPolicy Bypass -File .\install_common_tools.ps1
```

**方法 4：检查当前执行策略**
```powershell
# 查看当前执行策略
Get-ExecutionPolicy

# 查看所有作用域的执行策略
Get-ExecutionPolicy -List
```

**执行策略说明：**
- `Restricted` - 默认策略，禁止所有脚本运行
- `RemoteSigned` - 允许本地脚本运行，远程脚本需要签名（推荐）
- `Unrestricted` - 允许所有脚本运行（不推荐，安全性较低）
- `Bypass` - 绕过所有策略（仅用于测试）

**推荐设置：**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**注意：** 如果使用 `Set-ExecutionPolicy` 命令时出现确认提示，输入 `Y` 或 `A`（全是）来确认更改。

### Q: 遇到中文字符乱码错误怎么办？

如果看到类似以下错误（中文字符显示为乱码）：
```
Unexpected token '妫€娴嬪埌宸插畨瑁?' in expression or statement
```

这是因为 PowerShell 脚本文件的编码问题。解决方法：

**方法 1：修复文件编码（推荐，必须执行）**

在运行脚本之前，先修复文件编码。以管理员身份运行 PowerShell，然后执行：

```powershell
cd E:\Code\my_code\DotfilesAndScript\script_tool_and_config\scripts\windows\system_basic_env

# 备份原文件
Copy-Item install_common_tools.ps1 install_common_tools.ps1.backup

# 转换为 UTF-8 with BOM
$content = Get-Content install_common_tools.ps1 -Raw -Encoding UTF8
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText("install_common_tools.ps1", $content, $utf8WithBom)

Write-Host "Encoding fixed! You can now run install_common_tools.bat" -ForegroundColor Green
```

**重要：** 这个步骤只需要执行一次。修复后，批处理文件就可以正常工作了。

**方法 2：直接运行 PowerShell 脚本**

跳过批处理文件，直接运行 PowerShell 脚本：
```powershell
# 以管理员身份运行 PowerShell
cd E:\Code\my_code\DotfilesAndScript\script_tool_and_config\scripts\windows\system_basic_env
.\install_common_tools.ps1
```

**方法 3：使用 Bypass 参数**

```powershell
powershell -ExecutionPolicy Bypass -File .\install_common_tools.ps1
```

### Q: winget 未安装怎么办？

脚本会自动尝试安装 winget。如果自动安装失败，可以：

1. 从 Microsoft Store 安装 "App Installer"
2. 或手动安装 chocolatey 作为替代

### Q: 如何只安装/更新/卸载特定工具？

**方法 1：交互式模式**
```powershell
# 交互式安装
.\install_common_tools.ps1 -Interactive

# 交互式更新
.\install_common_tools.ps1 -Action Update -Interactive

# 交互式卸载
.\install_common_tools.ps1 -Action Uninstall -Interactive
```

**方法 2：单独操作**
```powershell
# 单独操作某个工具（会显示详细菜单）
.\install_common_tools.ps1 -ToolName fnm
```

### Q: 如何更新已安装的工具？

```powershell
# 更新所有已安装的工具
.\install_common_tools.ps1 -Action Update

# 交互式选择要更新的工具
.\install_common_tools.ps1 -Action Update -Interactive

# 更新特定工具
.\install_common_tools.ps1 -Action Update -ToolName fnm
```

### Q: 如何卸载工具？

```powershell
# 卸载所有已安装的工具（谨慎使用）
.\install_common_tools.ps1 -Action Uninstall

# 交互式选择要卸载的工具
.\install_common_tools.ps1 -Action Uninstall -Interactive

# 卸载特定工具
.\install_common_tools.ps1 -Action Uninstall -ToolName alacritty
```

### Q: 字体安装失败怎么办？

可以手动下载并安装：
1. 访问：https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraMono.zip
2. 下载 ZIP 文件
3. 解压后，右键点击 `.ttf` 文件，选择 "安装"

### Q: 安装后工具无法使用？

脚本已自动处理 PATH 刷新，但某些情况下可能需要：

1. **重启终端**：关闭并重新打开 PowerShell/终端（推荐）
2. **检查 PATH 备份**：如果 PATH 出现问题，可以查看 `path.bak` 文件恢复
3. **重启系统**：某些工具可能需要重启系统才能生效（极少情况）

### Q: PATH 备份文件在哪里？

PATH 备份文件保存在脚本所在目录，文件名为 `path.bak`。

- **位置**：`scripts\windows\system_basic_env\path.bak`
- **内容**：包含 Machine PATH、User PATH 和 Current Process PATH
- **用途**：如果 PATH 出现问题，可以查看此文件恢复

### Q: 如何恢复 PATH？

如果 PATH 出现问题，可以：

1. **查看备份文件**：打开 `path.bak` 文件查看备份的 PATH
2. **手动恢复**：复制备份文件中的 PATH 值，手动设置环境变量
3. **系统还原**：如果问题严重，可以使用系统还原点

### Q: 日志文件在哪里？如何查看？

日志文件保存在脚本所在目录，文件名为 `log`。

- **位置**：`scripts\windows\system_basic_env\log`
- **内容**：包含所有脚本执行输出，与控制台输出完全一致
- **格式**：纯文本格式，UTF-8 编码
- **用途**：用于追踪安装过程、排查问题、查看详细执行记录
- **自动管理**：每次运行脚本时自动清空旧日志，开始新会话

**查看日志**：
```powershell
# 使用 PowerShell 查看
Get-Content .\log

# 使用文本编辑器打开
notepad .\log
```

**注意**：日志文件包含完整的执行记录，包括 winget 的中文输出、返回值等信息，便于问题排查。日志文件已添加到 `.gitignore`，不会被提交到版本控制。

### Q: GCC 安装后如何使用？

GCC（MinGW-w64）安装后会自动添加到 PATH 环境变量中。

**验证安装**：
```powershell
# 在 PowerShell 中验证
gcc --version

# 在 Git Bash 中验证
gcc --version
```

**使用示例**：
```bash
# 在 Git Bash 中编译 C 程序
echo -e '#include <stdio.h>\nint main(){puts("Hello, World!");}' > hello.c
gcc hello.c -o hello
./hello
```

**VS Code 配置**：
如果使用 VS Code 进行 C/C++ 开发，需要配置编译器路径：
- 设置 `C_Cpp › Default: Compiler Path` 为 `C:\Program Files\mingw64\bin\gcc.exe`
- 或者使用 `C:\Program Files (x86)\mingw64\bin\gcc.exe`（如果安装在 x86 目录）

**升级 GCC**：
```powershell
winget upgrade --id mingw-w64.mingw-w64
```

**卸载 GCC**：
```powershell
winget uninstall --id mingw-w64.mingw-w64
```

**注意**：
- GCC 默认安装到 `C:\Program Files\mingw64\bin` 或 `C:\Program Files (x86)\mingw64\bin`
- 脚本会自动检测并添加到 PATH 环境变量
- MinGW-w64 的 GCC 与 Linux GCC 行为一致，生成零依赖的 exe 文件
- 支持 C/C++ 开发，跨平台源码零改动

### Q: Make 和 CMake 安装后如何使用？

Make 和 CMake 安装后会自动添加到 PATH 环境变量中。

**验证安装**：
```powershell
# 在 PowerShell 中验证
make --version
cmake --version

# 在 Git Bash 中验证
make --version
cmake --version
```

**使用示例**：
```bash
# 在 Git Bash 中使用 Make
make
make clean
make install

# 使用 CMake
cmake -B build
cmake --build build
cmake --install build
```

**路径信息**：
- **Make**: 默认安装到 `C:\Program Files (x86)\GnuWin32\bin`
- **CMake**: 默认安装到 `C:\Program Files\CMake\bin`
- 脚本会自动检测并添加到 PATH 环境变量

**升级**：
```powershell
winget upgrade --id GnuWin32.Make
winget upgrade --id Kitware.CMake
```

**卸载**：
```powershell
winget uninstall --id GnuWin32.Make
winget uninstall --id Kitware.CMake
```

**注意**：
- GNU Make for Windows 与 Linux Makefile 兼容，可直接使用 Linux 项目的 Makefile
- CMake 支持跨平台构建，CMakeLists.txt 可在 Windows 和 Linux 之间无缝共享
- 配合 GCC，可实现完整的 C/C++ 开发环境，与 Linux 端命令 100% 对齐

## 参考

- [winutil 项目](https://github.com/ChrisTitusTech/winutil) - 参考了 winutil 的安装方式
- [MULTI_OS_COMMON_TOOLS.md](../../../MULTI_OS_COMMON_TOOLS.md) - 工具清单来源
- [Winget 文档](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [Chocolatey 文档](https://chocolatey.org/docs)

## 许可证

本项目遵循项目根目录的 LICENSE 文件。

