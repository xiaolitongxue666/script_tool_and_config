# Zsh 启动时间测试与记录

本文档用于记录新开终端时 zsh 的启动耗时，作为基线便于日后优化对比。

## 测量命令

- **登录 shell**：`time zsh -l -c exit`
- **交互式模拟**：`time zsh -i -c exit`

建议多次运行（如 3～5 次）取平均或中位数以减少方差。

## 记录模板

| 项目 | 说明 |
|------|------|
| 测试环境 | OS、是否 WSL、Linux 发行版 ID（若适用）、机器简要信息 |
| 命令 | 使用的测量命令（如 `time zsh -i -c exit`） |
| 次数 | 测量次数 |
| 测得时间 | real / user / sys（或仅记录 real） |
| 备注 | 如「首次 apply 后」「未做 compinit 优化」等 |

## 基线说明

启动耗时主要来自：

- `.zprofile`：brew shellenv、fnm、pyenv 的 eval
- `.zshrc`：Oh My Zsh 全量加载、多插件同步加载、compinit

## 已做优化（dot_zshrc.tmpl）

- **ZSH_DISABLE_COMPFIX=1**：跳过 Oh My Zsh 的 compaudit 安全检查，减少启动时间。
- **去掉重复 compinit**：原先在「自动补全配置」中再次执行了 `compinit`，与 OMZ 内部 compinit 重复，已删除，现仅由 OMZ 执行一次。

后续可考虑：compinit 缓存（需改 OMZ 或在其前自管 compinit）、OMZ 插件延迟加载等。

## 示例记录

```text
日期: YYYY-MM-DD
OS: darwin / linux (WSL: 否 / 是, ID: ubuntu)
命令: time zsh -i -c exit
次数: 5
real: 0.45s (平均)
备注: 首次 apply 后，未做 compinit 优化
```
