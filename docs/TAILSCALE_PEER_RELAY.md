# Tailscale peer relay（大陆 VPS）

核对日期：2026-10-12。尾网 `tail926022.ts.net`。设备地址见 [DEVICE_ACCESS.md](DEVICE_ACCESS.md)。

直连仍然优先。Mac 到 desktop-pc 的直连大约 8–13ms，Mac 到这台 VPS 大约 35ms。空闲时打洞还没完成，流量会先落到美国 DERP（desktop-pc 常见 `sfo`，Mac 和 VPS 常见 `lax`），这时延迟是几百毫秒。peer relay 只缩短这条退路：打洞失败时先走大陆 VPS，VPS 也不可用时再退回官方 DERP。它不会比已经打通的直连更快。远程桌面走这条退路时，流量计入 VPS 公网带宽。

SSH 和远程桌面继续用 MagicDNS 或 `100.x`。不要用 `123.207.13.22`，也不要用家里的宽带地址。Mac 上的命令是 `/Applications/Tailscale.app/Contents/MacOS/Tailscale`。登录仍用 OpenSSH，不用 `tailscale ssh`。

`moicen.com`、`alchemy-studio.cn` 不在这个尾网里，不参与中继。不要在这台 VPS 上安装 `derper`，也不要在尾网策略里设置 `OmitDefaultRegions`。

## 当前生效配置

| 项 | 值 |
|---|---|
| 中继 | `vps`，Tailscale `100.74.201.82`，系统地址 `10.1.0.8`，公网 `123.207.13.22` |
| 端口 | UDP `40000` |
| 静态终点 | `123.207.13.22:40000` |
| 版本 | VPS 1.98.10，Mac mini 1.96.5，desktop-pc 1.94.2。客户端至少 1.86。手机和平板 2026-10-12 离线，没有核对版本 |

公网地址变了之后，在 VPS 上重设 `--relay-server-static-endpoints`。关闭中继：`sudo tailscale set --relay-server-port=""`。

## 步骤

按这个顺序做。前两步在 VPS 上，第三步在腾讯云控制台，第四步在 Tailscale 管理后台。

### 1. VPS 主机防火墙和 Tailscale

```bash
sudo ufw allow 40000/udp comment 'tailscale peer relay'
sudo tailscale set --relay-server-port=40000 --relay-server-static-endpoints='123.207.13.22:40000'
```

`tailscale debug prefs` 里 `RelayServerPort` 应为 `40000`，`RelayServerStaticEndpoints` 应为 `123.207.13.22:40000`。`ss -ulnp` 应看到 `tailscaled` 在监听 `udp/40000`。

这台机器的公网地址在云厂商 NAT 上，网卡地址是 `10.1.0.8`。查公网地址时用 `curl -4 --noproxy '*' https://ifconfig.me`，或看 `tailscale netcheck` 的 `IPv4`。不要用没关代理的 `curl`。

### 2. 腾讯云轻量应用服务器防火墙

控制台路径：轻量应用服务器 → 该实例 → 防火墙 → 添加规则。这是实例防火墙，不是只放行 Tailscale 地址 `100.74.201.82`。

| 字段 | 填写 |
|---|---|
| 应用类型 | 自定义 |
| 来源 | 全部 IPv4 地址 |
| 协议 | UDP |
| 端口 | `40000` |
| 策略 | 允许 |
| 备注 | `Tailscale Peer Relay UDP 40000` |

协议必须是 UDP。选成 TCP 时，备注写了 UDP 也不会放行，VPS 的 `eth0` 收不到入站探测。

### 3. 尾网策略

打开 [Access controls](https://login.tailscale.com/admin/acls)，用页面顶部的开关进入 JSON editor。不要用可视化页面的 **Add rule**，那个按钮只能加端口规则。

保留原来的 `{"src": ["*"], "dst": ["*"], "ip": ["*"]}`。在同一个 `grants` 数组里追加：

```json
{
  "src": [
    "100.114.18.98",
    "100.110.122.106",
    "100.65.16.28",
    "100.109.45.51",
    "100.124.252.108"
  ],
  "dst": ["100.74.201.82"],
  "app": {
    "tailscale.com/cap/relay": []
  }
}
```

五个地址依次是 Mac mini、desktop-pc、手机、平板、笔记本。`dst` 是 VPS。`src` 里写 `mac-mini` 这类 MagicDNS 名会报 `invalid address`；这些名字只有先写进策略文件的 `hosts` 段才能当别名。不要把 `src` 写成 `*`，也不要点 **Convert to grants**。

`src` 是需要经中继被访问的设备，`dst` 是中继本身。官方说明：<https://tailscale.com/docs/features/peer-relay>。

## 测试流程和判定

在 Mac 上执行。通过标准是下面三条都成立。

1. 候选列表包含 VPS：

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale debug peer-relay-servers
```

结果里要有 `100.74.201.82`。空列表 `[]` 表示策略还没生效。

2. 路径是直连，或在直连出现之前先出现 peer relay：

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale ping -c 5 --until-direct=false company-pc-win10
```

- 出现 `via 171.213.` 开头的公网地址：直连，优先路径，通过。
- 出现 `via peer-relay(123.207.13.22:40000`：退路，通过。
- 同一次输出里第一行可以是 `DERP(sfo)` 或 `DERP(lax)`，后面必须出现直连或 `peer-relay`。
- 五行全是 DERP：失败。先查候选列表，再查 UDP `40000` 是否到达 `eth0`。

3. 入站 UDP 抽查（改防火墙或改公网地址之后做）。VPS 上：

```bash
sudo tcpdump -ni eth0 -c 1 'udp dst port 40000 and udp[8:4] = 0x70656572'
```

另一台设备向 `123.207.13.22` 的 UDP `40000` 发送以 `peer` 开头的数据。`eth0` 上要看到对端公网地址，而不是只有 VPS 自己发往 `192.73.0.0/16:3478` 的 STUN。

VPS 上 `sudo tailscale debug peer-relay-sessions` 在有人走退路时 `Sessions count` 大于 0。直连恢复后，这个计数可以仍留着旧会话，不能拿它否定直连。

2026-10-12 21:54：候选列表为 `100.74.201.82`；ping 先 `DERP(sfo)` 约 1.4 秒，接着 `peer-relay(123.207.13.22:40000)` 约 68ms，随后直连 `171.213.187.111` 约 10–13ms。21:39 的入站探测来自 `171.213.187.111`，到达 `10.1.0.8:40000`。21:59 复测：候选列表仍是该地址，prefs 仍是 `40000` 与 `123.207.13.22:40000`，ping 第一行 DERP 约 1.7 秒，后四行直连 8–10ms。
