# Neovim 独立化测试计划（已合并）

> **2026-05 更新**：测试项已并入 [NEOVIM_AND_THIS_REPO.md](NEOVIM_AND_THIS_REPO.md) § 验证清单。  
> 本仓库仅通过 `run_once_install-neovim.sh.tmpl` 安装 Neovim 二进制，不再使用 `run_once_install-neovim-config`。

请执行：

```bash
bash scripts/chezmoi/audit_configs.sh
bash tests/test_syntax.sh
./scripts/manage_dotfiles.sh apply
```

详见 [NEOVIM_AND_THIS_REPO.md](NEOVIM_AND_THIS_REPO.md)。
