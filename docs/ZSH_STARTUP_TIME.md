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

当前配置下未做 lazy loading / compinit 缓存等优化，启动耗时主要来自：

- `.zprofile`：brew shellenv、fnm、pyenv 的 eval
- `.zshrc`：Oh My Zsh 全量加载、多插件同步加载、compinit

优化（如 compinit -C、OMZ 延迟加载）可作为后续任务，本记录作为优化前基线。

## 示例记录

```text
日期: YYYY-MM-DD
OS: darwin / linux (WSL: 否 / 是, ID: ubuntu)
命令: time zsh -i -c exit
次数: 5
real: 0.45s (平均)
备注: 首次 apply 后，未做 compinit 优化
```
