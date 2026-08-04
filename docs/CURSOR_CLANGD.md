# Cursor + clangd（多 OS / WSL）

本仓库对 **Cursor GUI** 与 **clangd（语言服务）** 分层处理：无 GUI 不装 Cursor；clangd 二进制可在 headless / WSL 无显示环境下安装，供跳转与诊断使用。

相关脚本：[`scripts/common/cursor_clangd/`](../scripts/common/cursor_clangd/)。  
Cursor 编辑器 User settings 仍由 **agent-config** 管理（见 [CHEZMOI_USE_GUIDE.md](CHEZMOI_USE_GUIDE.md)「Cursor 用户设置」）。

---

## 职责划分

| 组件 | 安装入口 | 无 GUI（无 DISPLAY/WAYLAND） | 说明 |
|------|----------|------------------------------|------|
| Cursor 编辑器 | `run_once_93-install-cursor` | **跳过** | macOS/Windows 默认有 GUI；Linux/WSL 需 `DISPLAY`/`WAYLAND_DISPLAY`（含 WSLg） |
| clangd 二进制 | `run_once_install-clangd` → `install_clangd.sh` | **可装** | 不依赖 Cursor；Neovim / CLI `--check` 也可用 |
| clangd Cursor 扩展 | `install_cursor_clangd_extension.sh` | 仅当已有 `cursor` CLI | **不安装 Cursor 本身**；扩展装在「当前 CLI 所在环境」 |

---

## 一键脚本

在仓库根目录：

```bash
# 1) 仅装 clangd（全平台；无 Cursor 也可）
bash scripts/common/cursor_clangd/install_clangd.sh

# 2) 仅装 Cursor 扩展（需已有 cursor CLI；装不到 Cursor 本体）
bash scripts/common/cursor_clangd/install_cursor_clangd_extension.sh

# 3) 组合：clangd +（若有 cursor CLI）扩展
bash scripts/common/cursor_clangd/setup_cursor_clangd.sh

# 冒烟
bash scripts/common/cursor_clangd/verify_clangd.sh
```

chezmoi apply / `install.sh` / `deploy.sh` 会经 `run_once_install-clangd` 安装 **clangd 二进制**；扩展需在已打开 Cursor（含 WSL Remote）后跑步骤 2，或手动从扩展市场安装。

---

## 推荐扩展与冲突规避

| 项 | 值 |
|----|-----|
| 扩展 ID | `llvm-vs-code-extensions.vscode-clangd` |
| 扩展市场名 | clangd（LLVM） |

与 Microsoft **C/C++**（`ms-vscode.cpptools`）并存时，建议在工作区禁用其 IntelliSense，避免抢跳转：

```json
{
  "C_Cpp.intelliSenseEngine": "disabled",
  "C_Cpp.autocomplete": "disabled",
  "C_Cpp.errorSquiggles": "disabled",
  "clangd.path": "clangd",
  "clangd.arguments": [
    "--compile-commands-dir=${workspaceFolder}",
    "--header-insertion=never",
    "--background-index",
    "--query-driver=**/gcc,**/gcc.exe,**/g++,**/g++.exe,**/clang,**/clang++,**/clang.exe,**/clang++.exe,**/mingw64/**/gcc.exe"
  ]
}
```

项目侧可在 `.vscode/extensions.json` 推荐：

```json
{
  "recommendations": ["llvm-vs-code-extensions.vscode-clangd"]
}
```

---

## 按平台安装 clangd 二进制

脚本 `install_clangd.sh` 已封装；手工对照：

| 平台 | 方式 |
|------|------|
| Ubuntu / Debian / WSL(apt) | `sudo apt-get install -y clangd`（或版本包如 `clangd-18`） |
| Arch | `sudo pacman -S --noconfirm clang`（提供 `clangd`） |
| Fedora | `sudo dnf install -y clang-tools-extra` |
| macOS | 优先 Xcode CLT：`xcode-select --install`（常有 `/usr/bin/clangd`）；或 `brew install llvm` 并用 `$(brew --prefix llvm)/bin/clangd` |
| Windows (winget) | `winget install -e --id LLVM.LLVM --source winget` |
| Windows (MSYS2) | `pacman -S --noconfirm mingw-w64-x86_64-clang-tools-extra` |

---

## WSL 专坑（扩展装在哪一侧）

Cursor 从 Windows 打开 **WSL 远程** 工作区时：

1. **Windows 本机**已装 clangd 扩展 ≠ **WSL 远程**已装。  
2. 命令面板搜不到 `clangd: Restart language server` → 当前窗口（多为 WSL Remote）未加载该扩展。  
3. 在 **WSL 内**执行（Remote CLI 可用时）：

   ```bash
   cursor --install-extension llvm-vs-code-extensions.vscode-clangd
   ```

   或扩展面板搜索 clangd → **Install in WSL: \<distro\>**。  
4. 然后 `Developer: Reload Window`，再执行 `clangd: Restart language server`。  
5. 无 GUI 的纯 WSL 终端跑 `run_once_93` **不会**装 Cursor（设计如此）；用 Windows 侧 Cursor 连 WSL 即可。

---

## 项目侧 LSP（compile_commands）

clangd 跳转依赖工作区根目录的 `compile_commands.json`（及可选 `.clangd`）。本仓库**不**生成具体 C 项目的编译数据库；各项目自行提供，例如：

| 项目示例 | 命令 |
|----------|------|
| cstl | `bash scripts/setup-lsp.sh` → `verify-lsp.sh`；一键见 `build-test-lsp.sh` |

通用约定：

1. 根目录存在 `compile_commands.json`（或 `.clangd` 指向 CompilationDatabase）。  
2. Include 路径与真实构建一致；LSP 库勿带 `-Werror` 以免诊断刷屏。  
3. WSL ↔ MSYS2 切换后须按项目要求重建 LSP/build 树（勿混用错误平台的 compile_commands）。  
4. 跳转请点**调用处**；在定义行本身 Ctrl+点击常无可见跳转。

重启语言服务：

```text
Ctrl+Shift+P → clangd: Restart language server
```

---

## 验证清单

```bash
command -v clangd && clangd --version
bash scripts/common/cursor_clangd/verify_clangd.sh

# 已装 Cursor CLI 时
cursor --list-extensions 2>/dev/null | grep -i clangd
```

Cursor UI：

1. 命令面板能搜到 `clangd: Restart language server`  
2. 打开 C/C++ 文件后状态栏出现 clangd  
3. 从调用处 Go to Definition 可跳到声明/定义  

---

## 与本仓其它文档的关系

| 文档 | 内容 |
|------|------|
| [SOFTWARE_LIST.md](SOFTWARE_LIST.md) | `run_once_93` / `run_once_install-clangd` 清单行 |
| [CHEZMOI_USE_GUIDE.md](CHEZMOI_USE_GUIDE.md) | Cursor User settings / Remote SSH |
| [NEOVIM_AND_THIS_REPO.md](NEOVIM_AND_THIS_REPO.md) | 本仓只装 nvim 二进制；LSP 配置归 nvim 仓（可用系统 `clangd`） |
| agent-config | Cursor User `settings.json`、Commands、MCP |
