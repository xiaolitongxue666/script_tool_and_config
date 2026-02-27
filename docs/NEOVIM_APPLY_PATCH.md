# 在 nvim 仓库应用 PROJECT_ROOT/COMMON_LIB 补丁

本仓库提供补丁 [docs/patches/nvim_install_common_lib_env.patch](patches/nvim_install_common_lib_env.patch)，用于在上游 [xiaolitongxue666/nvim](https://github.com/xiaolitongxue666/nvim) 的 `install.sh` 中增加：

- 通过环境变量 `PROJECT_ROOT`、`COMMON_LIB` 注入项目根与 common 库路径（由本仓库 run_once 使用）
- 当 `COMMON_LIB` 不存在时使用脚本内最小实现（log_*、error_exit、ensure_directory 等），便于单独克隆 nvim 时无需本仓库即可运行

## 应用步骤

1. **克隆或进入 nvim 仓库根目录**

   ```bash
   git clone https://github.com/xiaolitongxue666/nvim.git
   cd nvim
   ```

2. **从本仓库复制补丁并应用**

   ```bash
   patch -p0 < /path/to/script_tool_and_config/docs/patches/nvim_install_common_lib_env.patch
   ```

   或在 nvim 仓库根目录下，若补丁已复制到当前目录：

   ```bash
   patch -p0 < nvim_install_common_lib_env.patch
   ```

3. **验证**

   ```bash
   bash -n install.sh
   ```

## 提交到上游

- 若你有 xiaolitongxue666/nvim 的维护权限：将应用补丁后的 `install.sh` 提交并 push，或按项目流程提 PR。
- 若为 fork：在 fork 仓库中应用补丁、提交后，可向上游提 PR 或仅在自己的 fork 中使用；本仓库 run_once 会克隆你配置的 nvim 地址（默认上游），若你使用 fork 需在 run_once 模板中改为 fork 的 clone URL。

## 相关文档

- [NEOVIM_INSTALL_REQUIREMENTS.md](NEOVIM_INSTALL_REQUIREMENTS.md)：上游 install.sh 建议满足的完整行为（环境变量、同源跳过、uv/fnm 按需安装等）；本补丁仅覆盖「PROJECT_ROOT/COMMON_LIB 环境变量与 common 最小 fallback」。
