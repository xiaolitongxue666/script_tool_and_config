# nvim 独立化改动测试计划

本文档针对「nvim 为独立项目、本仓库仅 clone 并执行 install.sh、已存在则跳过」相关改动的测试项，按优先级与可自动化程度组织。

---

## 1. 静态与语法检查（必做，可自动化）

| 序号 | 项 | 命令/方法 | 通过标准 |
|------|----|-----------|----------|
| 1.1 | 修改过的 shell 脚本语法 | `bash -n scripts/macos/system_basic_env/install_common_tools.sh`，同法检查 `scripts/linux/system_basic_env/install_common_tools.sh`、`install_neovim.sh`、`scripts/common/container_dev_env/container_install.sh`、`scripts/chezmoi/audit_configs.sh` | 全部 exit 0 |
| 1.2 | run_once 模板渲染后语法 | 在项目根执行 `chezmoi execute-template < .chezmoi/run_once_install-neovim-config.sh.tmpl > /tmp/run_once_nvim.sh && bash -n /tmp/run_once_nvim.sh`（可选：对 linux/darwin/windows 各渲染一次） | `bash -n` 通过 |
| 1.3 | 编码与换行符（可选） | `./scripts/common/utils/check_and_fix_encoding.sh`、`./scripts/common/utils/ensure_lf_line_endings.sh` | 无新增告警 |

---

## 2. run_once_install-neovim-config 行为（核心）

### 2.1 场景 A：~/.config/nvim 不存在或为空

| 序号 | 步骤 | 预期 |
|------|------|------|
| 2.1.1 | 确保 `~/.config/nvim` 不存在（备份后删除或使用临时 HOME） | - |
| 2.1.2 | 执行 run_once 脚本（前置 uv、fnm、nvim 已就绪） | 克隆 nvim 到 `~/.config/nvim`，执行 `install.sh`，引导 Lazy 插件 |
| 2.1.3 | 检查 | 存在 `~/.config/nvim/.git`、`install.sh` 已执行过（如存在 venv 或 lazy 状态） |

### 2.2 场景 B：~/.config/nvim 已存在且为 git 仓库（应跳过）

| 序号 | 步骤 | 预期 |
|------|------|------|
| 2.2.1 | 保证 `~/.config/nvim` 已存在且含 `.git`（可先跑一次 2.1 或手动 clone） | - |
| 2.2.2 | 再次执行 run_once 脚本 | 日志出现「Neovim 配置已存在，跳过（独立项目由使用者自行维护）」；**不**执行 git pull、**不**执行 `install.sh`、**不**引导插件 |
| 2.2.3 | 检查 | 本地未提交修改或本地 commit 未被改动；无二次 clone/pull |

### 2.3 场景 C：~/.config/nvim 存在但非 git 仓库

| 序号 | 步骤 | 预期 |
|------|------|------|
| 2.3.1 | 构造「有内容但无 .git」的目录（如 `mkdir -p ~/.config/nvim && touch ~/.config/nvim/foo`） | - |
| 2.3.2 | 执行 run_once 脚本 | 原目录被备份为 `~/.config/nvim.backup.<时间戳>`，然后克隆新仓库并执行 `install.sh` |

---

## 3. 其他脚本对 nvim 的调用（不注入本仓库路径）

以下脚本在「存在 `~/.config/nvim/install.sh`」时会执行该脚本；验证其**不**传递 `PROJECT_ROOT`/`COMMON_LIB`，仅传递代理或运行环境变量。

| 脚本 | 建议验证方式 | 通过标准 |
|------|----------------|----------|
| `scripts/macos/system_basic_env/install_common_tools.sh`（install_neovim） | 阅读代码或 grep：无 `PROJECT_ROOT`/`COMMON_LIB` 传入 `env` 或 `bash install.sh` | 仅代理等环境变量 |
| `scripts/linux/system_basic_env/install_common_tools.sh`（install_neovim） | 同上 | 仅代理、USE_SYSTEM_NVIM_VENV、INSTALL_USER 等 |
| `scripts/linux/system_basic_env/install_neovim.sh` | 同上 | 仅 `bash "$NEOVIM_INSTALL_SCRIPT"`，无 PROJECT_ROOT/COMMON_LIB |
| `scripts/common/container_dev_env/container_install.sh`（install_neovim_config） | 同上 | 仅 PATH、代理、USE_SYSTEM_NVIM_VENV、INSTALL_USER |

可选：在测试环境实际执行上述脚本之一，确认 `~/.config/nvim/install.sh` 被调用且无本仓库路径注入（如在上游 nvim 的 install.sh 中临时 `echo "PROJECT_ROOT=$PROJECT_ROOT"` 验证为空或未设置）。

---

## 4. audit_configs.sh

| 序号 | 项 | 预期 |
|------|----|------|
| 4.1 | 执行 `./scripts/chezmoi/audit_configs.sh` | 仅检查 `run_once_install-neovim-config.sh.tmpl` 存在性，不依赖 `~/.config/nvim` 或 nvim 内部路径 |
| 4.2 | 若模板存在 | 日志包含「run_once_install-neovim-config.sh.tmpl 存在」，无 MISSING |

---

## 5. 文档与链接

| 序号 | 项 | 方法 | 通过标准 |
|------|----|------|----------|
| 5.1 | 合并文档存在 | `test -f docs/NEOVIM_AND_THIS_REPO.md` | 文件存在 |
| 5.2 | 无对已删文档的引用 | `grep -r "NEOVIM_INSTALL_REQUIREMENTS\|NEOVIM_SCENARIOS_AND_VERIFICATION\|NEOVIM_APPLY_PATCH" --include="*.md" .` | 无匹配（或仅历史/归档说明） |
| 5.3 | README/AGENTS 中 nvim 表述 | 阅读 README.md、AGENTS.md 中 nvim 相关句 | 为「独立项目、仅 clone 并执行 install.sh、已存在则跳过」 |
| 5.4 | 补丁归档 | `test -f docs/patches/archive/nvim_install_common_lib_env.patch` 且 `docs/patches/archive/README.md` 说明为历史参考 | 存在且说明正确 |

---

## 6. 可选：全流程与多 OS

| 序号 | 场景 | 说明 |
|------|------|------|
| 6.1 | 全新一键安装（无既有 nvim） | 在干净环境执行 `./install.sh`，确认 run_once_install-neovim-config 克隆并执行 install.sh，nvim 可用 |
| 6.2 | 已有 nvim 后再次 apply | 已有 `~/.config/nvim/.git` 时再次 `chezmoi apply` 或触发 run_once，确认跳过且本地 nvim 未被覆盖 |
| 6.3 | 多 OS / WSL | 若有条件，在 Linux、macOS、WSL 各做一次 2.1 / 2.2 或 6.1 / 6.2，确保行为一致且无平台专属错误 |

---

## 7. 执行顺序建议

1. **先做 1、4、5**（静态检查、audit、文档），再跑 2、3（run_once 与各脚本行为）。
2. **2.2（已存在则跳过）** 与 **2.1（未 clone 则克隆）** 建议至少各测一次。
3. 6 视环境与时间选做。

---

## 8. 快速检查命令汇总

```bash
# 1. 语法
bash -n scripts/macos/system_basic_env/install_common_tools.sh
bash -n scripts/linux/system_basic_env/install_common_tools.sh
bash -n scripts/linux/system_basic_env/install_neovim.sh
bash -n scripts/common/container_dev_env/container_install.sh
bash -n scripts/chezmoi/audit_configs.sh

# 2. run_once 模板语法（需在项目根）
chezmoi execute-template < .chezmoi/run_once_install-neovim-config.sh.tmpl > /tmp/run_once_nvim.sh && bash -n /tmp/run_once_nvim.sh

# 3. 确认无注入
grep -n "PROJECT_ROOT\|COMMON_LIB" .chezmoi/run_once_install-neovim-config.sh.tmpl scripts/macos/system_basic_env/install_common_tools.sh scripts/linux/system_basic_env/install_common_tools.sh scripts/linux/system_basic_env/install_neovim.sh scripts/common/container_dev_env/container_install.sh
# 预期：run_once 与 4 个脚本中均无向 nvim install 传递 PROJECT_ROOT/COMMON_LIB 的代码

# 4. audit
./scripts/chezmoi/audit_configs.sh

# 5. 文档与归档
test -f docs/NEOVIM_AND_THIS_REPO.md && echo "OK"
test -f docs/patches/archive/nvim_install_common_lib_env.patch && echo "OK"
```
