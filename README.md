# 🔐 AnyTLS 一键部署脚本

> 在 Linux 服务器上一键安装 AnyTLS / VLESS / VMess / Trojan 等主流代理协议

---

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

### 完整版 (推荐)
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/vless-server.sh)
```

### 简单版
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/install.sh) install
```

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
