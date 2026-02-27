# 归档补丁说明

本目录下的补丁仅作**历史参考**。当前本仓库与 nvim 的关系为：nvim 为独立项目，本仓库仅 clone 并执行其 `install.sh`，不再注入 `PROJECT_ROOT`/`COMMON_LIB`。一般无需使用这些补丁。

- **nvim_install_common_lib_env.patch**：曾用于让 nvim 的 `install.sh` 支持通过环境变量接收本仓库路径并在缺失时使用脚本内最小实现；现已不再使用。
