# 手机用 Moshi 登录三台管理机

核对日期：2026-10-14。手机是 Redmi K70（`phone-personal-android`）。地址、用户和指纹以 [DEVICE_ACCESS.md](DEVICE_ACCESS.md) 为准。这里只记操作。私钥不入库，也不写进本文。

这次不改仓库脚本、chezmoi 模板、钥匙文件，也不改两台 Windows 的 OpenSSH `DefaultShell`。

## 三层分工

| 层 | 做什么 |
|---|---|
| Tailscale | 手机到三台管理机的网络。Moshi 没有单独的 Tailscale 开关，VPN 由 Tailscale App 负责 |
| Moshi | 手机上向外连的终端。2026-10-14 已进入 `liyong@liyongdeMac-mini` |
| Termux | 别人登录手机时的 `sshd`，端口 `8022`。划掉 Termux 后这个端口会停。Moshi 不替代它 |

安卓同时只能有一个 VPN。Tailscale 和手机上的代理软件都会占用这条通道。下载语音模型时只开代理；连管理机时只开 Tailscale。

## 三条连接

三条都用 Termux 里已有的私钥 `id_ed25519_phone-personal-android-2026-10-dM`。在 Moshi 里选认证方式「密钥文件」，连接类型选 **SSH**。跳板机留空。`bastion@jump.example.com:22` 是格式示例，保存成真实跳板时会先去连一台不存在的机器。转发 SSH 代理关闭。`moshi-hook` 端口留空。

| 名称 | 主机 | 用户 | 端口 | 2026-10-14 |
|---|---|---|---|---|
| Mac mini | `mac-mini` 或 `100.114.18.98` | `liyong` | `22` | 已进入 shell，提示符 `liyong@liyongdeMac-mini` |
| desktop-pc | `100.110.122.106`。MagicDNS 全名仍是 `company-pc-win10.tail926022.ts.net` | `Administrator` | `22` | SSH 已通。见下文「Windows 上的会话检查」 |
| 笔记本 | `laptop-huawei` 或 `100.124.252.108` | `xiaoli` | `22` | 连接前在 Termux 里再确认一次，见下文 |

本机 Tailscale `RunSSH=False`。端口 22 由系统 sshd 单独监听。`Administrator` 的公钥在 `C:\ProgramData\ssh\administrators_authorized_keys`，不在 `C:\Users\Administrator\.ssh\authorized_keys`。desktop-pc 的登录 shell 是 `D:\Program Files\Git\usr\bin\bash.exe`，选项 `-lc`。笔记本的登录 shell 是 `C:\Program Files\Git\usr\bin\bash.exe`，选项同样是 `-lc`。

笔记本若被拒绝，在一台已经能登录它的管理机上，把 `dM` 的公钥追加进 `C:\ProgramData\ssh\administrators_authorized_keys`。只追加这一行。ACL 保持 `SYSTEM` 与 `Administrators`。Termux 里的确认命令：

```bash
ssh -o BatchMode=yes -i ~/.ssh/id_ed25519_phone-personal-android-2026-10-dM xiaoli@laptop-huawei whoami
```

期望输出 `xiaoli`。

Moshi 里不添加 `vps`、`github.com`、`moicen.com`、`alchemy-studio.cn`。

## Windows 上的会话检查

desktop-pc 连上后会出现「正在检查服务器...」，随后提示：

> 会话检查超时。将在没有多路复用器会话的情况下继续。如果服务器响应较慢，请重试。

这表示 SSH 已经建立。Moshi 在列 tmux / Herdr 会话，第一次大约只给 4 秒。这台的登录 shell 是 Git Bash 加 `-lc`，探测走完登录后往往超过这 4 秒。原生 Windows 上选择器只认 Herdr，这台没有 Herdr，也没有 tmux。仓库在 Windows 上用的是 rmux。

关掉横幅后就是 Git Bash。要持久会话，在这个终端里手动进入已经装好的 rmux。Moshi 不会把它列进会话选择器。

官方给 Windows 的修法是把 `DefaultShell` 改成 PowerShell。这台保持 Git Bash，Termux 和 Mac 的登录都走它。为了消掉这句超时去改注册表，会把那些登录一起改掉。这句横幅可以留着。

同一台机器上也不做这些事：把 sshd 改到 `2222`、安装 `moshi-hook`、为 Mosh 放行 UDP `60000:61000`。连接类型保持 SSH。本机没有 `mosh-server`。

## 语音

语音在手机本地完成，和 SSH 钥匙无关。系统键盘右边的灰色麦克风是输入法的按键，终端不是普通输入框，那个键会一直是灰的。用终端底部黑条上 Moshi 自己的麦克风，黑条上有 **Ctrl**、**Esc**、**Tab**。按住说话，松开后转成文字。

设置路径是 **设置 → 语音**：

1. 引擎选 **Whisper**。说中文时下载下面「多语言」里的 **Small**（468 MB）。「仅英文」那一组不用于中文。Parakeet 只覆盖英语和一部分欧洲语言。
2. 下载时关掉 Tailscale，只开代理软件，并留在 Moshi 里。切到别的应用会暂停下载。
3. 该行从下载箭头变成已安装后，点页面顶部的红色麦克风试一句中文。系统询问麦克风权限时选允许。
4. 关掉代理，重新打开 Tailscale，再连管理机。模型已经在手机上，之后说话不用代理。

「自动发送」保持关闭。文字先出现，确认后再进终端。要先改字再送，打开聊天模式，文字会出现在终端上方的输入条里。

云端听写每次都要联网，会再次和 Tailscale 抢 VPN。日常使用本地 Whisper。
