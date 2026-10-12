# 设备访问清单

核对日期：2026-10-12。尾网 `tail926022.ts.net`，账号 `leonpa1987@gmail.com`。

这里只记录地址、用户、端口、密钥文件名和指纹。私钥、公钥全文和 token 不入库。

`100.x` 是 Tailscale 地址，改 MagicDNS 名不会改这些地址。系统主机名也不会因为 `tailscale set --hostname` 改变。

## Tailscale 设备

| 设备 | 系统主机名 | 目标 MagicDNS | 当前 MagicDNS | IP | 状态 |
|---|---|---|---|---|---|
| 本机 Windows | `LeonLi-DESKTOP` | `desktop-win` | `company-pc-win10.tail926022.ts.net` | `100.110.122.106` | 客户端主机名已设为 `desktop-win`。管理后台里的手动名仍是 `company-pc-win10`，MagicDNS 未跟着变。本次没有 Tailscale API token，管理后台需要登录，所以没有改掉这个显示名 |
| VPS | `vps` | `vps` | `vps.tail926022.ts.net` | `100.74.201.82` | 2026-10-12 已改名。本机 `ssh vps` 经 Tailscale 登录成功（源地址 `100.110.122.106`）。ICMP 仍无回复 |
| Mac mini | 李勇的Mac mini | `mac-mini` | `mac-mini.tail926022.ts.net` | `100.114.18.98` | 在线。`leonli` 公钥登录失败。本次不远程改名、不远程改密钥 |
| 笔记本 | `LAPTOP-ANFCJ3NJ` | `laptop-win` | `laptop-huawei.tail926022.ts.net` | `100.124.252.108` | 离线约 142 天。只登记目标名 |
| 平板 | `Xiaomi Pad 6S Pro 12` | `pad-android` | `personal-pad-android.tail926022.ts.net` | `100.109.45.51` | 离线约 142 天。只登记目标名 |
| 手机 | `Redmi K70` | `phone-android` | `phone-personal-android.tail926022.ts.net` | `100.65.16.28` | Termux 用户 `u0_a0`，SSH 端口 `8022`。打开 Termux 时 `~/.bashrc` 会启动 `sshd`。密码登录已关闭 |

离线设备不要只在管理后台改显示名。设备下次上线可能用自己的主机名盖回去。上线后在设备上执行：

```bash
tailscale set --hostname=<目标名>
```

名称只能是小写字母、数字和连字符。

## 密钥与登录关系

文件名是 `id_ed25519_<Tailscale 名>-<YYYY-MM>-<指纹末两位>`。末两位取指纹字符串的最后两个字符。

- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-C4` 只登录 GitHub 账号 `xiaolitongxue666`。Host 名 `github.com`，实际地址 `ssh.github.com:443`。GitHub 标题同为 `desktop-win-2026-10-C4`。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-j0` 只登录 VPS。Host 名 `vps`（`xiaolitongxue-vps` 是同一条）。这把私钥不加到 GitHub。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-6c` 只登录手机 Termux。Host 名 `phone-personal-android`，端口 `8022`，用户 `u0_a0`。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-A8` 只登录 Mac mini。Host 名 `mac-mini`，用户 `leonli`。公钥还没写进 Mac。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-Tg` 只登录平板。平板用户名还不知道，Host 先不写。公钥还没写进平板。
- 手机 `~/.ssh/id_ed25519_phone-personal-android-2026-10-dM` 登录本机和 Mac。Host 名 `desktop-win` 的实际地址是 `company-pc-win10`，用户 `Administrator`。`mac-mini` 别名已写，公钥还没写进 Mac。
- 本机与 Mac mini 同一档，可以登录本机、Mac、手机、平板、VPS、GitHub。手机与平板同一档，只登录本机和 Mac。新设备的私钥在那台设备上生成，只把公钥追加到已经配好的机器。步骤见 [SSH_KEY_ROTATION.md](SSH_KEY_ROTATION.md)。
- VPS 自己的 `~/.ssh/id_ed25519_vps-2026-10-JM` 只登录同一个 GitHub 账号。私钥不复制到本机。GitHub 标题同为 `vps-2026-10-JM`。
- GitHub 上仍保留标题 `mac mini` 的公钥。Mac mini 还没轮换，删掉会把那台机器锁在 GitHub 外面。
- VPS `authorized_keys` 里的 `SHA256:rmAlw93NjZFtTHiTRAqJlNbmMfb4zVzoSMZxleCbyLc` 能登录 VPS，本机没有对应私钥，设备未识别。
- `ci.moicen.com`、`alchemy-vnc`、`moicen-vnc` 已从 chezmoi 的 SSH 模板删掉。

## SSH 与 Git

| 用途 | 地址 | 用户 | 端口 | 密钥文件 | 状态 |
|---|---|---|---|---|---|
| GitHub | `ssh.github.com` | `git` | `443` | 本机 `id_ed25519_desktop-win-2026-10-C4`；VPS `id_ed25519_vps-2026-10-JM` | 账号 `xiaolitongxue666`。每台设备各自生成，不复制私钥 |
| 登录 VPS | Tailscale `vps` / `100.74.201.82` | `ubuntu` | `22` | 本机 `id_ed25519_desktop-win-2026-10-j0` | Host 名 `vps`。公网名 `xiaolitongxue.com.cn` 仍接受同一把密钥 |
| 登录本机 | Tailscale `company-pc-win10` / `100.110.122.106` | `Administrator` | `22` | 手机 `id_ed25519_phone-personal-android-2026-10-dM` | 公钥在 `C:\ProgramData\ssh\administrators_authorized_keys`。手机别名 `desktop-win` 已测通 |
| 登录手机 | Tailscale `phone-personal-android` / `100.65.16.28` | `u0_a0` | `8022` | 本机 `id_ed25519_desktop-win-2026-10-6c` | 密码登录已关闭。划掉 Termux 后 `sshd` 会停 |
| 登录 Mac | Tailscale `mac-mini` / `100.114.18.98` | `leonli` | `22` | 本机 `id_ed25519_desktop-win-2026-10-A8`；手机 `id_ed25519_phone-personal-android-2026-10-dM` | 公钥都还没写入 Mac |
| 登录平板 | Tailscale `personal-pad-android` / `100.109.45.51` | 回家后 `whoami` | `8022` | 本机 `id_ed25519_desktop-win-2026-10-Tg` | 平板密钥尚未生成。公钥还没写入平板 |

## 指纹

当前密钥：

- 本机 GitHub `id_ed25519_desktop-win-2026-10-C4`：`SHA256:JvlWYJhbN2XqE8Nee1H6PmNGlEl55CKZdbl++BVhRC4`。GitHub 标题 `desktop-win-2026-10-C4`（id `166149938`）
- 本机登录 VPS `id_ed25519_desktop-win-2026-10-j0`：`SHA256:DZJ19Ia0hOQPD0CL0TpFPPYJNcxma/LIJTLge6Mddj0`
- 本机登录手机 `id_ed25519_desktop-win-2026-10-6c`：`SHA256:QG42wuukVk+SwHs6hBWSNu5RtpGvsQbaIalVW0ph+6c`
- 本机登录 Mac `id_ed25519_desktop-win-2026-10-A8`：`SHA256:C0tE4jNB8pEh4i847nxu0Y/ZBFVvv7LLLBlyM66EPA8`
- 本机登录平板 `id_ed25519_desktop-win-2026-10-Tg`：`SHA256:08+p0yDspInT0d7JnU7+RyHLZhq5pTX4qkBcm7C3QTg`
- 手机登录本机 `id_ed25519_phone-personal-android-2026-10-dM`：`SHA256:56gmjE1TyWhlEqa9phBsq3WX9E+rHGId3xCtA2SyEdM`。私钥只在手机上
- VPS GitHub `id_ed25519_vps-2026-10-JM`：`SHA256:nEhVyEo0fs1q/tfxDCjDShSAT2E6MydxteWK9KjsgJM`。私钥只在 VPS 上。GitHub 标题 `vps-2026-10-JM`（id `166149945`）

已从本机删除、备份仍在 `~/.ssh-key-backup-20261012`（仓库外）：

- `id_ed25519_github_personal`：`SHA256:iD2pVkbJt/cJfY2TcUYBl1WEuJZxAsa9cPQnXVoR9BM`。已从 GitHub 删除（原标题 `VPS RSS personal leonpa1987 2026-05-21`）
- `id_ed25519`（tencent-cloud）：`SHA256:VnzXG8fdsIHdxlQE2hd+HVeof6NXuBebj5BIvN9WB1E`
- `id_rsa`：`SHA256:SpqzZfj+gI3OeL+4ykMk1tc04jV6iSAlLnTOSaG4LIg`。GitHub 标题 `Work_company_key` 已于 2026-10-12 删除

VPS `ubuntu` 的 `authorized_keys` 现在只剩：

- `SHA256:rmAlw93NjZFtTHiTRAqJlNbmMfb4zVzoSMZxleCbyLc`：本机没有对应私钥。未识别，未删除
- `SHA256:DZJ19Ia0hOQPD0CL0TpFPPYJNcxma/LIJTLge6Mddj0`：本机 `id_ed25519_desktop-win-2026-10-j0`

GitHub 上另外保留的认证公钥：`mac mini`（`SHA256:YebAJXn40LJ4I0vm4k/YUySEr0PseF2k86j40UZFmNA`）。`Work_company_key` 已删除。

MSYS2 的 `ssh` 经目录联接使用 `%USERPROFILE%\.ssh`（本机 `C:\Users\Administrator\.ssh`），不再另维护一份 config。`run_once_windows-link-msys-ssh.sh` 把 `C:\msys64\home\<用户>\.ssh` 接到该目录；原来的 MSYS 目录改名为同级 `.ssh.bak-日期`，不删除。其中曾有 `192.168.1.211`（Gitblit，用户 `liyong`，端口 `29418`），2026-10-12 用已删除的 `id_ed25519` 和 `id_rsa` 登录被拒绝，未并入 chezmoi 模板。

WSL `Ubuntu-24.04` 的默认用户是 `root`，家目录 `/root`。2026-10-12 已把本机 GitHub、VPS、手机、Mac、平板这几把私钥和渲染后的 `~/.ssh/config` 复制进去（权限 600）。平板 Host 还没写，因为用户名未知。旧的 `id_rsa`（`SHA256:SpqzZfj+gI3OeL+4ykMk1tc04jV6iSAlLnTOSaG4LIg`）和 `id_ed25519`（`SHA256:VnzXG8fdsIHdxlQE2hd+HVeof6NXuBebj5BIvN9WB1E`）已从该目录删除。

## 本次轮换状态

- 本机：完成。密钥文件已改成 `desktop-win-2026-10-C4` / `desktop-win-2026-10-j0`
- VPS：完成。GitHub 密钥文件已改成 `id_ed25519_vps-2026-10-JM`。复制来的 `id_ed25519_github_personal` 已删除
- 本机 → VPS：2026-10-12 联接后重测。`ssh vps` 与 `ssh xiaolitongxue-vps` 都登录成功（`100.110.122.106 → 100.74.201.82:22`，主机名 `VM-0-8-ubuntu`）
- WSL → VPS：已测通，出口仍是本机 Tailscale 地址
- 手机 → 本机：`ssh desktop-win` 已测通。公钥在 `administrators_authorized_keys`
- 本机 → 手机：2026-10-12 重测 `ssh phone-personal-android` 连接 `8022` 超时。Tailscale 显示离线，约 1 小时前最后在线。密码登录仍关闭
- VPS → 本机、WSL → 本机：22 端口通。这两边还没有登录本机的密钥
- 本机 → WSL、VPS → WSL：WSL 没有 `sshd`，`192.168.205.215:22` 连不上
- 本机、WSL、VPS 访问 GitHub：`ssh -T git@github.com` 都返回 `Hi xiaolitongxue666!`
- 手机 → Mac mini：别名 `mac-mini` 已写，公钥还没放进 Mac
- 本机 → Mac：2026-10-12 重测时 Tailscale 在线，SSH 有应答。`known_hosts` 没有 `mac-mini` 的 ED25519 主机钥，严格校验停在登录前。公钥仍未装到 `leonli`
- 本机 → 平板：密钥已生成，公钥还没装到平板。2026-10-12 Tailscale 仍离线约 142 天，且没有 Host
- Mac、平板自己的密钥：回家后在设备上生成，再把公钥装进已经配好的机器。见 [SSH_KEY_ROTATION.md](SSH_KEY_ROTATION.md)
- 笔记本，以及手机的 GitHub 密钥：未开始
