# Neovim 场景梳理与验证状态

依据此前「移除 nvim 子模块、run_once 克隆到 ~/.config/nvim」的改造与补丁方案，本文档梳理 **script_tool_and_config 与 nvim** 的关系、run_once 依赖、使用场景及每个场景的测试验证是否通过。

---

## script_tool_and_config 与 nvim 的关系

| 维度 | script_tool_and_config（本仓库） | nvim（上游 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim)） |
|------|----------------------------------|----------------------------------------------------------------------------------|
| **职责** |  dotfiles + 安装/配置脚本；负责「把 nvim 克隆到目标位置并执行其 install.sh」 | 纯 Neovim 配置（lua、Lazy、venv、node 等）；负责「在任意克隆位置可自举安装」 |
| **克隆关系** | 本仓库 **不** 包含 nvim 子模块；run_once 将 nvim 仓库克隆到 `~/.config/nvim` | 独立仓库，可被本仓库克隆，也可被用户单独克隆使用 |
| **执行入口** | `run_once_install-neovim-config.sh.tmpl` 渲染后：克隆 nvim → 调用 `~/.config/nvim/install.sh` 并注入 `PROJECT_ROOT`、`COMMON_LIB` | `install.sh`：若收到 `PROJECT_ROOT`/`COMMON_LIB` 则 source 本仓库 `scripts/common.sh`；否则用脚本内最小实现（fallback） |
| **共用能力** | 提供 `scripts/common.sh`（log_*、error_exit 等）；可选提供 uv/fnm/字体等（run_once 先执行则 nvim 检测到即跳过） | 安装逻辑中「先检测、没有再装」uv/fnm/字体等，保证单独克隆时也能用 |
| **补丁** | 提供 [patches/nvim_install_common_lib_env.patch](patches/nvim_install_common_lib_env.patch)，供上游或 fork 应用后支持 env + fallback | 上游若未合并补丁，单独使用前需在 nvim 仓库根目录 `patch -p0` 应用该补丁 |

**结论**：本仓库只做「克隆 nvim 到系统目标位置 + 执行 nvim 的 install.sh」；nvim 相关前置与版本管理逻辑尽量放在 nvim 仓库，两仓库通过「环境变量注入 + common 可选」协作，保证「先跑本仓库再跑 nvim」与「只跑 nvim」两种用法都可行。

---

## Neovim run_once 依赖顺序

执行顺序（字母序下需保证的依赖）：

1. **run_once_00-install-version-managers** — 安装 uv、fnm（及可选 rustup）
2. **run_once_install-neovim** — 安装 Neovim 二进制（0.11+）
3. **run_once_install-neovim-config** — 将 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim) 克隆到 `~/.config/nvim`，注入 `PROJECT_ROOT`/`COMMON_LIB` 后执行其 `install.sh`（Lazy、venv、node 等）

详见 [SOFTWARE_LIST.md](../SOFTWARE_LIST.md) 与 [.chezmoi/run_once_install-neovim-config.sh.tmpl](../.chezmoi/run_once_install-neovim-config.sh.tmpl)。

---

## 场景与验证状态

**全场景重测日期**：2026-02-27（顺序 B → C → D → E → A，完整一键最后）

| 场景 | 描述 | 是否测试验证通过 | 备注 |
|------|------|------------------|------|
| **A** | 完整一键安装：`./install.sh`（含 chezmoi apply 与所有 run_once） | 是 | 重测通过；install.sh 正常结束，~/.config/nvim 就绪，日志见 `install_*.log` |
| **B** | 仅执行 install-neovim-config：前置（uv、fnm、nvim）已就绪，run_once 渲染后只跑 install-neovim-config | 是 | 重测通过；TEST_HOME=/tmp/nvim-test-b 渲染脚本并执行，克隆成功；克隆体需先应用补丁后注入 PROJECT_ROOT/COMMON_LIB 执行 install.sh 成功 |
| **C** | 单独克隆 nvim：不依赖本项目，不设 PROJECT_ROOT/COMMON_LIB，直接 `git clone … nvim && ./install.sh` | 是 | 重测通过；应用 [patches/nvim_install_common_lib_env.patch](patches/nvim_install_common_lib_env.patch) 后 HOME=/tmp/nvim-test-c 运行，fallback 生效，无「Common script library not found」，venv 等正常 |
| **D** | 更新流程：已存在 `~/.config/nvim`（已是 git 仓库），再次执行 run_once_install-neovim-config | 是 | 重测通过；再次执行 run_once 时识别「已有 git 仓库，执行 git pull」，pull 因本地修改失败但继续，install.sh 再次执行成功 |
| **E** | 容器内克隆并执行 nvim install | 未执行 | 可选；宿主机已验证 C 等价逻辑，容器内 E1 已启动但耗时长（拉镜像+apt+clone），本次标记未执行 |

### 补丁相关验证（针对场景 C 与 run_once 注入）

| 验证项 | 结果 |
|--------|------|
| 全新克隆 nvim 后 `patch -p0 < nvim_install_common_lib_env.patch` | 通过 |
| `bash -n install.sh` 语法检查 | 通过 |
| 独立运行 install.sh（无 PROJECT_ROOT/COMMON_LIB） | 通过（fallback 生效） |
| 注入 PROJECT_ROOT/COMMON_LIB 运行 install.sh | 通过（正确 source 本仓库 common.sh） |
| `patch -p0 -R --dry-run` 可逆 | 通过 |

---

## 是否每个场景都测试验证通过

- **2026-02-27 全场景重测**：**A、B、C、D** 均已按顺序（B→C→D→E→A）执行并通过；**E** 为可选，本次未执行。
- **补丁相关**：全新克隆应用补丁、语法检查、独立运行（fallback）、注入运行（source common.sh）、可逆性均通过。

因此：**除可选场景 E 外，所有场景（A、B、C、D）均已重测并通过**。

上游 nvim 若未合并本仓库补丁，单独使用（场景 C）前需在 nvim 仓库根目录应用 [docs/patches/nvim_install_common_lib_env.patch](patches/nvim_install_common_lib_env.patch)，见 [NEOVIM_APPLY_PATCH.md](NEOVIM_APPLY_PATCH.md)。
