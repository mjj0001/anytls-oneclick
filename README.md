# 🔐 AnyTLS 一键部署脚本

> 在 Linux 服务器上一键安装 AnyTLS / VLESS / VMess / Trojan 等主流代理协议

---

## 🆕 更新 (v3.4.11)

- 🛡️ **防 BT/PT/滥用 防护**：主菜单 `15)`（可选 iptables 规则 + 可选 Fail2ban）
- 🧩 **TUI 面板模式（实验）**：主菜单 `14)`（whiptail/dialog，脚本可自动安装依赖）

Release: https://github.com/mjj0001/anytls-oneclick/releases/tag/v3.4.11

## ✨ 功能特性

| 特性 | 说明 |
|------|------|
| 🔄 **多核心架构** | Xray 核心 + Sing-box 核心 |
| 📡 **14种协议** | VLESS / VMess / Trojan / Hysteria2 / TUIC / AnyTLS / SS2022 / Snell 等 |
| 👥 **多用户管理** | 添加/删除用户、流量统计、配额管理、到期日期 |
| 📊 **流量监控** | 实时流量统计、Telegram 通知 |
| 📱 **全客户端支持** | Loon / 圈X / Egern / Shadowrocket / Surge / Mihomo / Sing-Box |

---

## 🚀 快速开始

### 完整版 (推荐 · 跟随 main 更新)
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/vless-server.sh)
```

### 稳定版 (推荐 · 跟随 stable 分支)
> 适合希望“版本相对稳定、但也会持续修 bug”的情况
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/stable/vless-server.sh)
```

### 固定版 (固定 Release Tag)
> 完全锁死版本（比如排查问题、复现环境时）
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/v1.0.0/vless-server.sh)
```

### 简单版
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/install.sh) install
```

### 下载 Release 离线包
**最新（推荐）**
- https://github.com/mjj0001/anytls-oneclick/releases/latest/download/anytls-oneclick-latest.tar.gz
- https://github.com/mjj0001/anytls-oneclick/releases/latest/download/anytls-oneclick-latest.zip

**指定版本（v1.0.0）**
- https://github.com/mjj0001/anytls-oneclick/releases/download/v1.0.0/anytls-oneclick-v1.0.0.tar.gz
- https://github.com/mjj0001/anytls-oneclick/releases/download/v1.0.0/anytls-oneclick-v1.0.0.zip

---

## 📋 支持的协议

### TCP/TLS 协议 (Xray 核心)
| 协议 | 说明 | 客户端支持 |
|------|------|------------|
| `VLESS+Reality` | 🔥 最常用 | Loon/圈X/Egern |
| `VLESS+WS+TLS` | 适用于CDN | Loon/圈X/Egern |
| `VMess+WS` | 兼容V2Ray | Loon/圈X/Egern |
| `Trojan` | ⚡ 简单高效 | Loon/圈X/Egern |
| `SS2022` | Shadowsocks 2022 | Loon/圈X/Egern |

### UDP/QUIC 协议 (Sing-box 核心)
| 协议 | 说明 | 客户端支持 |
|------|------|------------|
| `Hysteria2` | 🎯 低延迟高带宽 | Loon/圈X/Egern |
| `TUIC` | QUIC 协议 | Loon/圈X |
| `AnyTLS` | TLS 代理 | Loon/圈X/Egern |
| `Snell v4/v5` | 私有协议 | Loon/圈X |

---

## 📱 客户端配置示例

### Loon
```
[Proxy]
AnyTLS = anytls://password@server:port?sni=example.com&skip-cert-verify=1#AnyTLS
VLESS = vless://uuid@server:port?encryption=none&sni=example.com&skip-cert-verify=1#VLESS
Trojan = trojan://password@server:port?sni=example.com&skip-cert-verify=1#Trojan

[Proxy Group]
Auto = select, AnyTLS, VLESS, Trojan, DIRECT

[Rule]
GEOIP,CN,DIRECT
FINAL,Auto
```

### Quantumult X (圈X)
```
AnyTLS = anytls://password@server:port?sni=example.com&skip-cert-verify=1
VLESS = vless://uuid@server:port?encryption=none&sni=example.com&skip-cert-verify=1
Trojan = trojan://password@server:port?sni=example.com&skip-cert-verify=1
```

### Egern
```yaml
proxies:
  - name: AnyTLS
    type: anytls
    server: server_ip
    port: 8443
    password: "password"
    sni: example.com
    skip-cert-verify: true

  - name: VLESS
    type: vless
    server: server_ip
    port: 443
    uuid: uuid
    tls: true
    servername: example.com
    skip-cert-verify: true

proxy-groups:
  - name: Auto
    type: select
    proxies:
      - AnyTLS
      - VLESS
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,Auto
```

---

## 🖥️ 管理命令

> 推荐使用快捷命令 `vless` 打开主菜单（脚本会自动创建）。

```bash
# 打开主菜单
vless

# 或者直接运行脚本
bash vless-server.sh
```

### 常用子命令（非交互）

```bash
# 查看帮助
./vless-server.sh -h

# 流量同步（用于定时任务）
./vless-server.sh --sync-traffic

# 显示流量统计
./vless-server.sh --show-traffic

# 检查并禁用过期用户（可选通知）
./vless-server.sh --check-expire --notify

# 安装过期检查定时任务
./vless-server.sh --setup-expire-cron
```

### 主菜单新增入口（v3.4.11）

- `14) 界面设置 (TUI面板)`：whiptail/dialog 面板模式（实验）
- `15) 防 BT/PT/滥用 防护`：iptables 规则 + 可选 Fail2ban（按需开启）


## 🛡️ 安全与防滥用（新增）

脚本新增了两项偏“运维”的能力：

1) **防 BT/PT/滥用 防护（可选）**
- 位置：主菜单 → `15) 防 BT/PT/滥用 防护`
- 内容：
  - 一套尽量“不误伤”的 **iptables** 规则（放行 22/80/443，不影响已建立连接，限制新建连接速率，拦截常见 BT 端口段）
  - 可选安装 **Fail2ban**（默认启用 sshd，并对 Nginx 常见 badbots/http-auth 做基础防护）
- 注意：该功能可能影响下载/游戏/某些 UDP 应用；不确定就别开。

2) **TUI 面板模式（实验）**
- 位置：主菜单 → `14) 界面设置 (TUI面板)`
- 功能：启用后主菜单会使用 **whiptail/dialog** 显示“面板式”菜单（更像小白面板）。
- 依赖：Debian/Ubuntu 推荐安装 `whiptail`（脚本可自动安装）。


```bash
# 查看帮助
./vless-server.sh -h

# 安装协议
./vless-server.sh install

# 查看配置
./vless-server.sh view

# 添加用户
./vless-server.sh adduser

# 删除用户
./vless-server.sh deluser

# 查看用户列表
./vless-server.sh list

# 流量统计
./vless-server.sh stats

# Telegram 配置
./vless-server.sh telegram
```

---

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `vless-server.sh` | ⭐ 完整版脚本 (推荐) |
| `install.sh` | 简单版 AnyTLS 安装 |
| `README.md` | 本说明文档 |

---

## ⚠️ 注意事项

1. 请在 **root** 或 **sudo** 环境下运行
2. 支持 **Ubuntu / Debian / CentOS / RHEL / Alpine**
3. 架构支持: **x86_64 (amd64)** / **aarch64 (arm64)**

---

## 📄 许可证

MIT License

---

> ⭐ 如果对你有帮助，请点个 Star 支持一下！
