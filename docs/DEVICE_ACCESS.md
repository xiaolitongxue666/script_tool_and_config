# 设备访问清单

核对日期：2026-10-12。尾网 `tail926022.ts.net`，账号 `leonpa1987@gmail.com`。

这里只记录地址、用户、端口、密钥文件名和指纹。私钥、公钥全文和 token 不入库。

`100.x` 是 Tailscale 地址，改 MagicDNS 名不会改这些地址。系统主机名也不会因为 `tailscale set --hostname` 改变。

## Tailscale 设备

| 设备 | 系统主机名 | 目标 MagicDNS | 当前 MagicDNS | IP | 状态 |
|---|---|---|---|---|---|
| 本机 Windows | `LeonLi-DESKTOP` | `desktop-win` | `company-pc-win10.tail926022.ts.net` | `100.110.122.106` | 客户端主机名已设为 `desktop-win`。管理后台里的手动名仍是 `company-pc-win10`，MagicDNS 未跟着变。本次没有 Tailscale API token，管理后台需要登录，所以没有改掉这个显示名 |
| VPS | `vps` | `vps` | `vps.tail926022.ts.net` | `100.74.201.82` | 2026-10-12 已改名。本机 `ssh vps` 经 Tailscale 登录成功（源地址 `100.110.122.106`）。ICMP 仍无回复 |
| Mac mini | 李勇的Mac mini | `mac-mini` | `mac-mini.tail926022.ts.net` | `100.114.18.98` | 在线。SSH 用户是 `liyong`，本机没有 `leonli` |
| 笔记本 | `LAPTOP-ANFCJ3NJ` | `laptop-huawei` | `laptop-huawei.tail926022.ts.net` | `100.124.252.108` | 2026-10-13 在线。SSH 用户 `xiaoli`。Git 在 `C:\Program Files\Git`。sshd `DefaultShell` 为 `C:\Program Files\Git\usr\bin\bash.exe`，选项 `-lc` |
| 平板 | `Xiaomi Pad 6S Pro 12` | `pad-android` | `personal-pad-android.tail926022.ts.net` | `100.109.45.51` | Termux 用户 `u0_a71`，SSH 端口 `8022`。打开 Termux 时 `~/.bashrc` 会启动 `sshd`。密码登录已关闭。提示符字体与手机相同，见「Termux 字体」 |
| 手机 | `Redmi K70` | `phone-android` | `phone-personal-android.tail926022.ts.net` | `100.65.16.28` | Termux 用户 `u0_a0`，SSH 端口 `8022`。打开 Termux 时 `~/.bashrc` 会启动 `sshd`。密码登录已关闭。提示符字体见「Termux 字体」 |

离线设备不要只在管理后台改显示名。设备下次上线可能用自己的主机名盖回去。上线后在设备上执行：

```bash
tailscale set --hostname=<目标名>
```

名称只能是小写字母、数字和连字符。

## 大陆 VPS 作为 peer relay

2026-10-12 已在 `vps`（`100.74.201.82`，公网 `123.207.13.22`）打开 UDP `40000`，轻量应用服务器防火墙和尾网 `grants` 都已生效。直连仍然优先。打洞失败时先经这台 VPS（约 68ms），再退回官方 DERP。没有安装 `derper`，也没有关闭默认 DERP。`moicen.com` 与 `alchemy-studio.cn` 不在尾网里。步骤见 [TAILSCALE_PEER_RELAY.md](TAILSCALE_PEER_RELAY.md)。

## 密钥与登录关系

文件名是 `id_ed25519_<Tailscale 名>-<YYYY-MM>-<指纹末两位>`。末两位取指纹字符串的最后两个字符。

- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-C4` 只登录 GitHub 账号 `xiaolitongxue666`。Host 名 `github.com`，实际地址 `ssh.github.com:443`。GitHub 标题同为 `desktop-win-2026-10-C4`。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-j0` 只登录 VPS。Host 名 `vps`（`xiaolitongxue-vps` 是同一条）。这把私钥不加到 GitHub。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-6c` 只登录手机 Termux。Host 名 `phone-personal-android`，端口 `8022`，用户 `u0_a0`。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-A8` 只登录 Mac mini。Host 名 `mac-mini`，用户 `liyong`。
- Mac mini `~/.ssh/id_ed25519_mac-mini-2026-10-5s` 只登录 GitHub。指纹 `SHA256:E/CX31DdB/iQHbCcrO8HCtuqOWz0Gjk/klJxbdHwG5s`。私钥只在 Mac 上。
- Mac mini `~/.ssh/id_ed25519_mac-mini-2026-10-GY` 登录 desktop-win、手机、平板和 VPS，不加到 GitHub。指纹 `SHA256:AQSe/V8Mm/5LlJMibVD7cEbsM+HDbFQMvkYLVn4XVGY`。私钥只在 Mac 上。
- Mac mini 旧 GitHub 公钥标题 `mac mini`（id `50838450`，指纹 `SHA256:YebAJXn40LJ4I0vm4k/YUySEr0PseF2k86j40UZFmNA`）已从 GitHub 删除。对应私钥 `~/.ssh/id_rsa` 移到仓库外备份，不再作为 `github.com` 回退。
- Mac mini `~/.ssh/id_ed25519` 指纹 `SHA256:rmAlw93NjZFtTHiTRAqJlNbmMfb4zVzoSMZxleCbyLc`。这是 VPS `authorized_keys` 里原先未识别的那一行，私钥在 Mac 上，不在 desktop-win 上。新登录密钥测通之前不从 VPS 删除这一行。
- 本机 `~/.ssh/id_ed25519_desktop-win-2026-10-Tg` 只登录平板。Host 名 `personal-pad-android`，端口 `8022`，用户 `u0_a71`。
- 手机 `~/.ssh/id_ed25519_phone-personal-android-2026-10-dM` 登录本机和 Mac。Host 名 `desktop-win` 的实际地址是 `company-pc-win10`，用户 `Administrator`。`mac-mini` 用户是 `liyong`。公钥已在 Mac `liyong` 的 `authorized_keys`。
- 平板 `~/.ssh/id_ed25519_personal-pad-android-2026-10-ik` 登录本机和 Mac。私钥只在平板上。指纹 `SHA256:xXECkG7eDhSd0Z3bGczxDEiT/TIHf4XRGQXelJW9Dik`。
- 笔记本 `laptop-huawei` 与 desktop-pc、Mac mini 同一档。GitHub 钥匙 `id_ed25519_laptop-huawei-2026-10-5A`，登录钥匙 `id_ed25519_laptop-huawei-2026-10-o4`。私钥只在这台笔记本上。用户 `xiaoli` 属于 Administrators，公钥在 `C:\ProgramData\ssh\administrators_authorized_keys`。主机私钥所有者须为 Administrators，否则 sshd 以 1067 退出。
- desktop-pc 与 Mac mini 可以登录 desktop-pc、Mac、笔记本、手机、平板、VPS、GitHub。手机与平板登录这三台，不登录 VPS。新设备的私钥在那台设备上生成，只把公钥追加到已经配好的机器。步骤见 [SSH_KEY_ROTATION.md](SSH_KEY_ROTATION.md)。
- VPS 自己的 `~/.ssh/id_ed25519_vps-2026-10-JM` 只登录同一个 GitHub 账号。私钥不复制到本机。GitHub 标题同为 `vps-2026-10-JM`。
- `id_ed25519_moicen-alchemy-2026-10-Nc` 登录 `xiaoli@moicen.com` 与 `leonli@alchemy-studio.cn`，并且是 GitHub 认证公钥，标题 `moicen-alchemy-2026-10-Nc`（id `166186184`）。指纹 `SHA256:HwrCuLR1DInospwk2130e6GxXYRxqUHP1xEl00PTtNc`。同一份私钥在 Mac `~/.ssh`、desktop-pc `C:\Users\Administrator\.ssh` 和 `laptop-huawei` 的 `%USERPROFILE%\.ssh`。Mac 的 `github.com` 仍用 `5s`，desktop-pc 仍用 `C4`，笔记本仍用 `5A`。两台生产 VPS 上用这把拉取和提交。不拷进 WSL、手机、平板或 Tailscale VPS。管理员还说 `leonli@huiwings.cn` 也用这把公钥，该机没有 `xiaoli`。模板里没有 `huiwings.cn`，也还没测。
- `ci.moicen.com`、`alchemy-vnc`、`moicen-vnc` 已从 chezmoi 的 SSH 模板删掉。不要把它们加回来。

## SSH 与 Git

| 用途 | 地址 | 用户 | 端口 | 密钥文件 | 状态 |
|---|---|---|---|---|---|
| GitHub | `ssh.github.com` | `git` | `443` | 本机 `id_ed25519_desktop-win-2026-10-C4`；Mac `id_ed25519_mac-mini-2026-10-5s`；VPS `id_ed25519_vps-2026-10-JM`；生产域名 `id_ed25519_moicen-alchemy-2026-10-Nc` | 账号 `xiaolitongxue666`。Mac 与本机不改用 `Nc`。`Nc` 供两台生产 VPS 拉取和提交 |
| 登录 VPS | Tailscale `vps` / `100.74.201.82` | `ubuntu` | `22` | 本机 `id_ed25519_desktop-win-2026-10-j0`；Mac `id_ed25519_mac-mini-2026-10-GY`；Mac `id_ed25519` | Host 名 `vps`，`xiaolitongxue-vps` 是同一条。公网名 `xiaolitongxue.com.cn` 仍接受同一把主机钥 |
| `moicen.com` | `moicen.com` | `xiaoli` | `22` | Mac、desktop-pc、laptop-huawei 同一份 `id_ed25519_moicen-alchemy-2026-10-Nc` | 2026-10-12 已登录。`whoami` 为 `xiaoli`，主机名 `moicen.com`。主机钥已换成 ED25519 `SHA256:cuIY6e2AY1s8XPMB4JmScEdxzRx3AMpjbl3hg1ac5CI` |
| `alchemy-studio.cn` | `alchemy-studio.cn` | `leonli` | `22` | 同上 `Nc` | 2026-10-12 已登录。`whoami` 为 `leonli`，主机名 `alchemy` |
| 登录本机 | Tailscale `company-pc-win10` / `100.110.122.106` | `Administrator` | `22` | Mac `id_ed25519_mac-mini-2026-10-GY`；手机 `id_ed25519_phone-personal-android-2026-10-dM`；平板 `id_ed25519_personal-pad-android-2026-10-ik` | 管理员公钥在 `C:\ProgramData\ssh\administrators_authorized_keys`。登录 shell 是 Git Bash |
| 登录手机 | Tailscale `phone-personal-android` / `100.65.16.28` | `u0_a0` | `8022` | 本机 `id_ed25519_desktop-win-2026-10-6c`；Mac `id_ed25519_mac-mini-2026-10-GY` | 密码登录已关闭。划掉 Termux 后 `sshd` 会停 |
| 登录 Mac | Tailscale `mac-mini` / `100.114.18.98` | `liyong` | `22` | 本机 `id_ed25519_desktop-win-2026-10-A8`；手机 `id_ed25519_phone-personal-android-2026-10-dM`；平板 `id_ed25519_personal-pad-android-2026-10-ik` | 公钥写入 `/Users/liyong/.ssh/authorized_keys` |
| 登录平板 | Tailscale `personal-pad-android` / `100.109.45.51` | `u0_a71` | `8022` | 本机 `id_ed25519_desktop-win-2026-10-Tg`；Mac `id_ed25519_mac-mini-2026-10-GY` | 密码登录已关闭。划掉 Termux 后 `sshd` 会停 |

## 指纹

当前密钥：

- 本机 GitHub `id_ed25519_desktop-win-2026-10-C4`：`SHA256:JvlWYJhbN2XqE8Nee1H6PmNGlEl55CKZdbl++BVhRC4`。GitHub 标题 `desktop-win-2026-10-C4`（id `166149938`）
- 本机登录 VPS `id_ed25519_desktop-win-2026-10-j0`：`SHA256:DZJ19Ia0hOQPD0CL0TpFPPYJNcxma/LIJTLge6Mddj0`
- 本机登录手机 `id_ed25519_desktop-win-2026-10-6c`：`SHA256:QG42wuukVk+SwHs6hBWSNu5RtpGvsQbaIalVW0ph+6c`
- 本机登录 Mac `id_ed25519_desktop-win-2026-10-A8`：`SHA256:C0tE4jNB8pEh4i847nxu0Y/ZBFVvv7LLLBlyM66EPA8`
- 本机登录平板 `id_ed25519_desktop-win-2026-10-Tg`：`SHA256:08+p0yDspInT0d7JnU7+RyHLZhq5pTX4qkBcm7C3QTg`
- 手机登录本机 `id_ed25519_phone-personal-android-2026-10-dM`：`SHA256:56gmjE1TyWhlEqa9phBsq3WX9E+rHGId3xCtA2SyEdM`。私钥只在手机上
- 平板登录本机 `id_ed25519_personal-pad-android-2026-10-ik`：`SHA256:xXECkG7eDhSd0Z3bGczxDEiT/TIHf4XRGQXelJW9Dik`。私钥只在平板上
- VPS GitHub `id_ed25519_vps-2026-10-JM`：`SHA256:nEhVyEo0fs1q/tfxDCjDShSAT2E6MydxteWK9KjsgJM`。私钥只在 VPS 上。GitHub 标题 `vps-2026-10-JM`（id `166149945`）
- 生产域名 `id_ed25519_moicen-alchemy-2026-10-Nc`：`SHA256:HwrCuLR1DInospwk2130e6GxXYRxqUHP1xEl00PTtNc`。Mac、desktop-pc、laptop-huawei 各一份

已从本机删除、备份仍在 `~/.ssh-key-backup-20261012`（仓库外）：

- `id_ed25519_github_personal`：`SHA256:iD2pVkbJt/cJfY2TcUYBl1WEuJZxAsa9cPQnXVoR9BM`。已从 GitHub 删除（原标题 `VPS RSS personal leonpa1987 2026-05-21`）
- `id_ed25519`（tencent-cloud）：`SHA256:VnzXG8fdsIHdxlQE2hd+HVeof6NXuBebj5BIvN9WB1E`
- `id_rsa`：`SHA256:SpqzZfj+gI3OeL+4ykMk1tc04jV6iSAlLnTOSaG4LIg`。GitHub 标题 `Work_company_key` 已于 2026-10-12 删除

VPS `ubuntu` 的 `authorized_keys` 现在是这三行，都不要删：

- `SHA256:rmAlw93NjZFtTHiTRAqJlNbmMfb4zVzoSMZxleCbyLc`：Mac `~/.ssh/id_ed25519`
- `SHA256:DZJ19Ia0hOQPD0CL0TpFPPYJNcxma/LIJTLge6Mddj0`：本机 `id_ed25519_desktop-win-2026-10-j0`
- `SHA256:AQSe/V8Mm/5LlJMibVD7cEbsM+HDbFQMvkYLVn4XVGY`：Mac `id_ed25519_mac-mini-2026-10-GY`

GitHub 认证公钥保留 `desktop-win-2026-10-C4`、`vps-2026-10-JM`、`mac-mini-2026-10-5s`、`moicen-alchemy-2026-10-Nc`（id `166186184`）。标题 `mac mini`（id `50838450`）已删除。`Work_company_key` 此前已删除。

MSYS2 的 `ssh` 经目录联接使用 `%USERPROFILE%\.ssh`（本机 `C:\Users\Administrator\.ssh`），不再另维护一份 config。`run_once_windows-link-msys-ssh.sh` 把 `C:\msys64\home\<用户>\.ssh` 接到该目录；原来的 MSYS 目录改名为同级 `.ssh.bak-日期`，不删除。其中曾有 `192.168.1.211`（Gitblit，用户 `liyong`，端口 `29418`），2026-10-12 用已删除的 `id_ed25519` 和 `id_rsa` 登录被拒绝，未并入 chezmoi 模板。

WSL `Ubuntu-24.04` 的默认用户是 `root`，家目录 `/root`。2026-10-12 已把本机 GitHub、VPS、手机、Mac、平板这几把私钥和渲染后的 `~/.ssh/config` 复制进去（权限 600）。平板 Host `personal-pad-android` 已补上，用户 `u0_a71`，端口 `8022`，密钥 `id_ed25519_desktop-win-2026-10-Tg`。旧的 `id_rsa`（`SHA256:SpqzZfj+gI3OeL+4ykMk1tc04jV6iSAlLnTOSaG4LIg`）和 `id_ed25519`（`SHA256:VnzXG8fdsIHdxlQE2hd+HVeof6NXuBebj5BIvN9WB1E`）已从该目录删除。

## 本次轮换状态

- 本机：完成。密钥文件已改成 `desktop-win-2026-10-C4` / `desktop-win-2026-10-j0`
- VPS：完成。GitHub 密钥文件已改成 `id_ed25519_vps-2026-10-JM`。复制来的 `id_ed25519_github_personal` 已删除
- 本机 → VPS：2026-10-12 联接后重测。`ssh vps` 与 `ssh xiaolitongxue-vps` 都登录成功（`100.110.122.106 → 100.74.201.82:22`，主机名 `VM-0-8-ubuntu`）
- WSL → VPS：已测通，出口仍是本机 Tailscale 地址
- 2026-10-12 已测通：Mac ↔ 本机、Mac ↔ 手机、Mac ↔ 平板、Mac → VPS、Mac → GitHub；本机 → GitHub、VPS、Mac、手机、平板；手机 → 本机、Mac；平板 → 本机、Mac；VPS → GitHub；WSL → GitHub、VPS、平板
- 手机和平板的 `8022` 只在 Termux 还开着时才听。Tailscale 在线不能当成 `sshd` 已起来
- VPS 和 WSL 没有登录本机的密钥。WSL 自己没有 `sshd`
- 笔记本，以及手机、平板的 GitHub 密钥：未开始

## SSH 别名

模板是 `.chezmoi/dot_ssh/config.tmpl`。手机和平板的 `~/.ssh/config` 只写 `desktop-win` 和 `mac-mini`，私钥留在各自 Termux 里。

| 别名 | HostName | 用户 | 端口 | 身份文件 |
|---|---|---|---|---|
| `github.com` | `ssh.github.com` | `git` | `443` | 本机 `C4`；Mac `5s`；VPS `JM`。只有这三把都不在时才用 `Nc`。`IdentitiesOnly yes` |
| `vps`、`xiaolitongxue-vps` | `vps` | `ubuntu` | `22` | 本机 `j0`；Mac `GY`，没有 `j0` 时才用 `GY` |
| `desktop-win` | `company-pc-win10` | `Administrator` | `22` | Mac `GY`；手机 `dM`；平板 `ik` |
| `mac-mini` | `mac-mini` | `liyong` | `22` | 本机 `A8`；手机 `dM`；平板 `ik`。没有用户 `leonli` |
| `phone-personal-android` | `phone-personal-android` | `u0_a0` | `8022` | 本机 `6c`；Mac 没有 `6c` 时用 `GY` |
| `personal-pad-android` | `personal-pad-android` | `u0_a71` | `8022` | 本机 `Tg`；Mac 没有 `Tg` 时用 `GY` |
| `moicen.com` | `moicen.com` | `xiaoli` | `22` | `moicen-alchemy-2026-10-Nc`。`IdentitiesOnly yes`，`ForwardAgent no` |
| `alchemy-studio.cn` | `alchemy-studio.cn` | `leonli` | `22` | 同上 `Nc`。`IdentitiesOnly yes`，`ForwardAgent no` |
| `huiwings.cn` | 未写入模板 | `leonli` | `22` | 管理员说用同一把 `Nc`。该机没有 `xiaoli`。未测 |

`ssh desktop-win` 的 shell 是 `D:\Program Files\Git\usr\bin\bash.exe`（`HKLM\SOFTWARE\OpenSSH` 的 `DefaultShell`，远程命令选项 `-lc`）。客户端不要写 `RemoteCommand`。

## Termux 字体

核对日期：2026-10-13。手机 Redmi K70（`phone-personal-android`，用户 `u0_a0`）已确认：从 Termux SSH 到 Mac mini 和 desktop-pc，提示符符号都正常。平板 Xiaomi Pad 6S Pro（`personal-pad-android`，用户 `u0_a71`）已写入同一份字体。2026-10-13 用户确认平板上的显示正常。

### 现象

Termux 里 `ssh mac-mini` 之后，提示符上很多符号变成方框。连 desktop-pc 是同一类问题。

### 原因

SSH 只传输字符，字形由客户端绘制。手机当时没有 `~/.termux`，也就没有 `font.ttf`，Termux 用系统等宽字体。这套字体没有 Powerline 私用区符号。

| 连接 | 提示符 | 每行都会出现的符号 |
|---|---|---|
| Mac mini（用户 `liyong`） | zsh 主题 agnoster。`~/.zshrc` 里 Starship 的 `eval` 仍是注释，没有接管提示符 | `` U+E0B0、`` U+E0A0 |
| desktop-pc（Git Bash） | Starship，配置在 `~/.config/starship/starship.toml` | `` U+E0B6、`` U+E0B0、`` U+E0A0 |

当时手机 `LANG=en_US.UTF-8`，不是编码错误。Mac 上的 FiraMono、Windows Terminal 和 mintty 的 CaskaydiaCove NFM 只影响那台机器自己的窗口。

### 处理

Termux 只读一个字体文件：`~/.termux/font.ttf`。写好后执行 `termux-reload-settings`（向 `com.termux` 发 `com.termux.app.reload_style`）。画面不刷新时，划掉 Termux 再打开。划掉后 `sshd` 会停，需要重新进入 Termux。

选用 Maple Mono NL NF CN Regular（maple-font v7.9）：

- NL：无连字，提示符对齐不被合字拉开
- NF：含 Nerd Font / Powerline。cmap 里有 U+E0A0、U+E0B0、U+E0B6
- CN：同一文件含简体中文。Termux 用 `Typeface.createFromFile` 把这个文件设成主字体，中文放在同一文件里

下载整包后只取出 Regular：

```text
https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMonoNL-NF-CN-unhinted.zip
```

包内文件 `MapleMonoNL-NF-CN-Regular.ttf`，20541416 字节，TTF 头 `00 01 00 00`。安装位置：

```text
/data/data/com.termux/files/home/.termux/font.ttf
```

权限 `644`。手机当时 Termux 版本 `googleplay.2026.06.21`，Android 16。字体包不入库。

2026-10-13 平板写入同一路径，文件 20541416 字节，TTF 头 `00 01 00 00`。写入后 sshd 一度不再发 banner，`chmod 644` 和 `termux-reload-settings` 没跑成。文件属主是 `u0_a71`，当时模式是 `600`，Termux 自己能读。划掉 Termux 再打开后字形换上。用户确认平板显示正常。

`✚`（U+271A）、`⚙`（U+2699）、`➦`（U+27A6）和彩色 emoji 不在这份字体里。缺的码位由 Android 绘制时回退到系统字体。2026-10-13 用户确认两条 SSH 的显示都正常。

### 不要做的事

- 不要为了手机上的方框去改 Mac 或 desktop-pc 的字体
- 不要把 CaskaydiaCove 拷进 Termux 当作唯一字体：它没有简体中文
- 平板如果出现同样的方框，只改那台 Termux 的 `~/.termux/font.ttf`

## 测试

失败就停，留下命令输出。`BatchMode=yes`。设备密钥不要拷进另一台设备的 `~/.ssh`。例外只有 `id_ed25519_moicen-alchemy-2026-10-Nc`：Mac、desktop-pc、laptop-huawei 各放同一份，不拷进 WSL、手机、平板或 Tailscale VPS。

规则：

- Tailscale 在线不等于端口开着。手机和平板先 `nc -z -G 5 <IP> 8022`，拒绝或超时就不要当 SSH 已通。
- `ssh -T git@github.com` 成功的正文是 `Hi xiaolitongxue666!`。退出码可能是 1，这是 GitHub 不给 shell。
- 往 `known_hosts` 追加名字之前，主机钥指纹必须和下表一致。
- `chezmoi apply` 会把 `~/.ssh` 收成 `755`、`config` 收成 `644`。做完后改回 `700` 和 `600`。
- Windows 管理员公钥只改 `C:\ProgramData\ssh\administrators_authorized_keys`，ACL 保持 `SYSTEM` 与 `Administrators`。
- 生产域名：`Permission denied (publickey)` 表示登录公钥还没写入。主机钥与下表不一致时停止。用户确认新指纹之后才 `ssh-keygen -R <域名>`，核对指纹再写入。`ssh-keygen -R` 会在 `~/.ssh` 留下 `known_hosts.old`，不入库。
- 传到 desktop-pc 用 `scp -O`，目标是 Git Bash 的 `/c/Users/Administrator/.ssh/`。默认 SFTP 认不出 `/c/...`。这份私钥的 ACL 与 `id_ed25519_desktop-win-2026-10-C4` 对齐。改 desktop-pc 的 `config` 用 `awk`，不要用 Windows 的 `python` 按默认 gbk 读这份 UTF-8 文件。

主机钥：

| 名字 | 指纹 |
|---|---|
| Mac `mac-mini` | `SHA256:vOL3XBx+VIR+nObw7S4dPkvjhWxzGORPlMghSxIfXqk` |
| 本机 `company-pc-win10` | `SHA256:SdKBdSYsC2xAyFKb0VP0UTRpxGYzoUMuAAPWh8ijGAc` |
| 手机 `phone-personal-android:8022` | `SHA256:S80fT4qc9lQWVAhb9EQZotRvoYxBzlUSaLxYZhm6KoU` |
| 平板 `personal-pad-android:8022` | `SHA256:7qvNYjIaY7zbXy4gSJC61H4tzEqZQ1easd9TD1mgZic` |
| VPS `vps` | `SHA256:Eg62mCFe6kPCKTHrvos5ROZtDD1eL9wmSxkRkKNvyK0` |
| `alchemy-studio.cn` | `SHA256:Ho8TIH8AhgunMZGzfuK5Cjey+0hlggBA779AeYGpWjo` |
| `moicen.com`（已接受） | `SHA256:cuIY6e2AY1s8XPMB4JmScEdxzRx3AMpjbl3hg1ac5CI` |

从 Mac 测（手机和平板的 `8022` 开着时）：

```bash
ssh -T git@github.com
ssh vps hostname
ssh desktop-win 'echo "$BASH_VERSION"; whoami'
ssh phone-personal-android whoami
ssh personal-pad-android whoami
ssh desktop-win 'ssh -n -T git@github.com; ssh -n vps hostname; ssh -n mac-mini whoami; ssh -n phone-personal-android whoami; ssh -n personal-pad-android whoami'
ssh phone-personal-android 'ssh -n mac-mini whoami; ssh -n desktop-win whoami'
ssh personal-pad-android 'ssh -n mac-mini whoami; ssh -n desktop-win "echo \$BASH_VERSION"'
```

期望：GitHub 正文含 `Hi xiaolitongxue666!`；VPS 主机名 `VM-0-8-ubuntu`；本机 `BASH_VERSION` 是 Git Bash，`whoami` 为 `Administrator`；Mac 上是 `liyong`；手机 `u0_a0`；平板 `u0_a71`。笔记本不在这套测试里。

### 生产域名

2026-10-12 已登录。私钥仍不拷进这两台，要在机器上拉取 GitHub 时再放。

- `moicen.com`：用户 `xiaoli`，主机名 `moicen.com`。主机钥已换成 ED25519 `SHA256:cuIY6e2AY1s8XPMB4JmScEdxzRx3AMpjbl3hg1ac5CI`。
- `alchemy-studio.cn`：用户 `leonli`，主机名 `alchemy`。主机钥 ED25519 `SHA256:Ho8TIH8AhgunMZGzfuK5Cjey+0hlggBA779AeYGpWjo`。
- `huiwings.cn`：管理员说用户 `leonli`、同一把公钥、没有 `xiaoli`。未写入模板，未测。

在机器上拉取 GitHub 时，把 `id_ed25519_moicen-alchemy-2026-10-Nc` 放到对应用户的 `~/.ssh`（权限 600），`github.com` 只引用它（`ssh.github.com` 端口 `443`，`IdentitiesOnly yes`）。然后 `ssh -T git@github.com`，成功正文是 `Hi xiaolitongxue666!`。退出码可能是 1。

登录检查：

```bash
ssh -o BatchMode=yes moicen.com 'whoami; hostname'
ssh -o BatchMode=yes alchemy-studio.cn 'whoami; hostname'
```

`moicen.com` 的 `whoami` 应为 `xiaoli`。`alchemy-studio.cn` 的 `whoami` 应为 `leonli`。

本地核对配置、不连这两台机器：

```bash
ssh -G moicen.com
ssh -G alchemy-studio.cn
ssh -G github.com
ssh -G vps
ssh -G desktop-win
```

`moicen.com` 与 `alchemy-studio.cn` 的 `identityfile` 只能是 `id_ed25519_moicen-alchemy-2026-10-Nc`。Mac 上 `github.com` 仍是 `5s`，desktop-pc 上仍是 `C4`，laptop-huawei 上仍是 `5A`。`vps` 与 `desktop-win` 保持原样。
