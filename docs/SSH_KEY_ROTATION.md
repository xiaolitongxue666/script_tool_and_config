# SSH 密钥轮换

每台设备一把 GitHub 密钥，私钥不在设备之间复制，也不入库。当前哪把密钥登录哪里，见 [DEVICE_ACCESS.md](DEVICE_ACCESS.md) 的「密钥与登录关系」。

2026-10-12：本机、VPS、Mac、手机、平板已按 [DEVICE_ACCESS.md](DEVICE_ACCESS.md) 打通。GitHub 认证公钥留 `desktop-win-2026-10-C4`、`vps-2026-10-JM`、`mac-mini-2026-10-5s`、`moicen-alchemy-2026-10-Nc`。标题 `mac mini`（id `50838450`）和 `Work_company_key` 已删除。

先生成并改好配置，确认能登录，再删除旧密钥。任一步登录失败就停，旧私钥留在原地。

## 新设备加入 GitHub

在该设备上生成。文件名、注释和 GitHub 标题都用 `<Tailscale 名>-<YYYY-MM>-<指纹末两位>`。末两位等 `ssh-keygen -lf` 出来后再改注释和改名，密钥材料不变。

```bash
ssh-keygen -t ed25519 -a 100 -C "tmp" -f ~/.ssh/id_ed25519_github_tmp -N ""
chmod 600 ~/.ssh/id_ed25519_github_tmp
# 指纹末两位是 C4 时：
ssh-keygen -c -f ~/.ssh/id_ed25519_github_tmp -C "desktop-win-2026-10-C4"
mv ~/.ssh/id_ed25519_github_tmp ~/.ssh/id_ed25519_desktop-win-2026-10-C4
mv ~/.ssh/id_ed25519_github_tmp.pub ~/.ssh/id_ed25519_desktop-win-2026-10-C4.pub
```

chezmoi 不部署私钥。各设备文件名不同，模板用 `stat` 选择本机存在的那一个。

把公钥加到 GitHub 账号 `xiaolitongxue666`，标题与文件名里 `id_ed25519_` 后面的部分相同，类型是 `authentication`：

```bash
gh ssh-key add ~/.ssh/id_ed25519_desktop-win-2026-10-C4.pub -t "desktop-win-2026-10-C4" --type authentication
```

`~/.ssh/config` 里 `github.com` 只引用这把密钥，并设置 `IdentitiesOnly yes`。然后测试：

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_desktop-win-2026-10-C4 -T git@github.com
```

成功时会看到 `Hi xiaolitongxue666!`。本机仓库的 `github.com` Host 实际连的是 `ssh.github.com:443`。

## 需要登录 VPS 的设备

另生成一把登录密钥，不要把它加到 GitHub：

```bash
ssh-keygen -t ed25519 -a 100 -C "desktop-win-2026-10-j0" -f ~/.ssh/id_ed25519_desktop-win-2026-10-j0 -N ""
chmod 600 ~/.ssh/id_ed25519_desktop-win-2026-10-j0
```

把这一行公钥追加到 VPS `ubuntu@vps` 的 `~/.ssh/authorized_keys`。不要改已经存在的行。然后只用这把新密钥测试：

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_desktop-win-2026-10-j0 ubuntu@vps echo OK
```

VPS 自己访问 GitHub 时，在 VPS 上单独生成 `~/.ssh/id_ed25519_vps-2026-10-JM` 这种带自己设备名的文件，不要把个人电脑的私钥拷上去。

本机 WSL `Ubuntu-24.04`（`/root`）不是另一台 Tailscale 设备。把上面两把 `desktop-win` 私钥和渲染后的 `config` 复制进 WSL 的 ext4，`chmod 600`。不要软链接到 `/mnt/host/c/.../.ssh`。

## 删除旧密钥

下面三项都成功之后才能删：

1. 本机 `ssh -T git@github.com`
2. 本机 `ssh vps`
3. VPS 上用它自己的新密钥 `ssh -T git@github.com`

然后：

1. 从 GitHub 删除已经对上指纹的旧认证公钥。对不上设备的公钥留下。
2. 从 VPS `authorized_keys` 删除已经替换的旧行。指纹 `SHA256:rmAlw93NjZFtTHiTRAqJlNbmMfb4zVzoSMZxleCbyLc` 是 Mac 上的 `~/.ssh/id_ed25519`，仍能登录 VPS，禁止删除。
3. 删掉 VPS 上复制来的 `id_ed25519_github_personal`。
4. 再测一次 VPS 登录和两边的 `ssh -T`。
5. 最后才删除本机旧私钥文件。

## 回家后在 Mac 和平板上生成

私钥在那台设备上生成，只把 `.pub` 追加到已经配好的机器。旧公钥先留着，新登录测通后再删。本机登录 Mac 用的是已经生成的 `id_ed25519_desktop-win-2026-10-A8`，本机登录平板用的是 `id_ed25519_desktop-win-2026-10-Tg`。这两把不是 Mac 或平板上新生成的密钥。

本机与 Mac 可以登录全部设备。手机与平板只登录本机和 Mac。

登录本机（`ssh desktop-win` 或 `Administrator@100.110.122.106`）的 shell 是 Git Bash：`D:\Program Files\Git\usr\bin\bash.exe`。注册表 `HKLM\SOFTWARE\OpenSSH` 的 `DefaultShell` 指向它，`DefaultShellCommandOption` 是 `-lc`，所以交互登录和远程命令都走这把 bash，PATH 含 Git `usr/bin`。不要在客户端再加 `RemoteCommand`，否则带命令的 `ssh` 会失败。以前手动写的 `ssh ... -t "\"D:\\Program Files\\Git\\usr\\bin\\bash.exe\""` 与现在的默认登录是同一把 bash。

### Mac mini

在 Mac 上生成两把，文件名 `id_ed25519_mac-mini-2026-10-<指纹末两位>`：

1. 一把只登录 GitHub。公钥加到账号 `xiaolitongxue666`。标题 `mac mini` 的旧公钥先留着，`ssh -T git@github.com` 成功后再删。
2. 另一把登录本机、手机、平板和 VPS。公钥追加到：
   - 本机 `C:\ProgramData\ssh\administrators_authorized_keys`
   - 手机 `~/.ssh/authorized_keys`（在 Termux 里本地追加；密码登录已关闭）
   - 平板 `~/.ssh/authorized_keys`（`sshd` 起来之后）
   - VPS `ubuntu` 的 `~/.ssh/authorized_keys`。不要删除 `SHA256:rmAlw93NjZFtTHiTRAqJlNbmMfb4zVzoSMZxleCbyLc`

同时把本机 `id_ed25519_desktop-win-2026-10-A8.pub` 和手机 `id_ed25519_phone-personal-android-2026-10-dM.pub` 追加到 Mac 上 `liyong` 的 `authorized_keys`（`/Users/liyong/.ssh/authorized_keys`）。本机没有用户 `leonli`。

### 平板

2026-10-12 已完成。用户 `u0_a71`。密钥 `id_ed25519_personal-pad-android-2026-10-ik`，指纹 `SHA256:xXECkG7eDhSd0Z3bGczxDEiT/TIHf4XRGQXelJW9Dik`。密码登录已关闭。

在平板 Termux 上生成一把。当前 MagicDNS 仍是 `personal-pad-android` 时，文件名用 `id_ed25519_personal-pad-android-2026-10-<指纹末两位>`。打开 Termux 时启动 `sshd`，端口 `8022`。别名只写 `desktop-win` 和 `mac-mini`。

公钥只追加到：

- 本机 `C:\ProgramData\ssh\administrators_authorized_keys`
- Mac 上 `liyong` 的 `authorized_keys`

不装进手机、VPS 或 GitHub。本机用 `id_ed25519_desktop-win-2026-10-Tg` 登录成功之后，再关闭平板的密码登录。用户名以平板上的 `whoami` 为准。

## 生产域名 moicen.com 与 alchemy-studio.cn

这两个域名共用一把密钥，Mac、desktop-pc、laptop-huawei 各放同一份私钥。文件名不用 `mac-mini` 或 `desktop-win`，避免模板里按完整文件名 `stat` 的分支选中它。

2026-10-12 已在 Mac 上生成 `id_ed25519_moicen-alchemy-2026-10-Nc`，指纹 `SHA256:HwrCuLR1DInospwk2130e6GxXYRxqUHP1xEl00PTtNc`，并复制到 desktop-pc `C:\Users\Administrator\.ssh`。2026-10-13 用 `scp -O` 再复制到 `laptop-huawei` 的 `%USERPROFILE%\.ssh`。空密码。`moicen.com` 用户 `xiaoli`，`alchemy-studio.cn` 用户 `leonli`。`IdentitiesOnly yes`，`ForwardAgent no`，登录这两个域名时不回退到 `GY`、`j0` 或 `o4`。不拷进 WSL、手机、平板或 Tailscale VPS。

公钥已加到 GitHub 账号 `xiaolitongxue666`，标题 `moicen-alchemy-2026-10-Nc`（id `166186184`），类型 `authentication`。只用这把密钥测过 `ssh -T`，正文是 `Hi xiaolitongxue666!`。Mac 的 `github.com` 仍用 `5s`，desktop-pc 仍用 `C4`，笔记本仍用 `5A`。模板里只有 `C4`、`5s`、`JM`、`5A` 都不存在时，`github.com` 才指向 `Nc`。

两台都已登录：`xiaoli@moicen.com`（主机名 `moicen.com`），`leonli@alchemy-studio.cn`（主机名 `alchemy`）。`moicen.com` 主机钥已换成 `SHA256:cuIY6e2AY1s8XPMB4JmScEdxzRx3AMpjbl3hg1ac5CI`。管理员还说 `leonli@huiwings.cn` 用同一把公钥，模板未写、未测。要在机器上拉取 GitHub 时，再把这份私钥放到对应用户的 `~/.ssh`，`github.com` 只引用它，然后跑 `ssh -T git@github.com`。传到 desktop-pc 时用 `scp -O`。改 desktop-pc 的 `config` 用 `awk`，不要用 Windows `python` 按默认 gbk 读 UTF-8。

生成方式与上面相同：临时文件、`ssh-keygen -lf` 取指纹末两位、改注释后改名。末两位已经是 `Nc`，不要再生成第二把。
