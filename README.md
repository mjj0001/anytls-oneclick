# AnyTLS 一键安装脚本

在 Linux 服务器上一键安装 [AnyTLS](https://github.com/anytls/anytls-go) 服务端，并自动生成**主流代理客户端**的配置与**二维码扫描链接**。

## 功能

### 简单版 (install.sh)
- 一键安装 AnyTLS 服务端
- 交互式配置
- 基础客户端配置生成

### 完整版 (vless-server.sh)
- **多核心架构**: Xray 核心 + Sing-box 核心
- **14种代理协议**:
  - TCP/TLS 协议: VLESS+Reality / VLESS+Reality+XHTTP / VLESS+WS / VMess+WS / VLESS-XTLS-Vision / Trojan / SOCKS5 / SS2022
  - UDP/QUIC 协议: Hysteria2 / TUIC / Snell v4 / Snell v5 / AnyTLS
- **多用户管理**: 添加/删除用户、流量统计、配额管理、到期日期
- **Telegram 通知**: 流量告警、到期提醒、每日报告
- **客户端配置**: 支持 Loon / Quantumult X (圈X) / Egern / Shadowrocket / Surge / Mihomo / Sing-Box

## 一键安装

### 完整版 (推荐)
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/vless-server.sh)
```

### 简单版
```bash
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/install.sh) install
```

## 支持的协议

| 协议 | 核心 | 说明 |
|------|------|------|
| VLESS+Reality | Xray | 最常用协议 |
| VLESS+WS+TLS | Xray | 适用于CDN |
| VMess+WS | Xray | 兼容V2Ray |
| Trojan | Xray | 简单高效 |
| SS2022 | Xray | Shadowsocks 2022 |
| Hysteria2 | Sing-box | 低延迟高带宽 |
| TUIC | Sing-box | QUIC协议 |
| AnyTLS | Xray/Sing-box | TLS代理 |
| Snell v4/v5 | Sing-box | 私有协议 |

## 客户端支持

- **Loon**: 直接可用的 anytls:// / vless:// / trojan:// 链接
- **Quantumult X (圈X)**: 直接可用的链接
- **Egern**: YAML 格式配置
- **Shadowrocket**: 扫码或链接导入
- **Surge**: 一行配置
- **Mihomo/Clash Meta**: YAML 节点片段
- **Sing-Box**: JSON outbound

## 管理命令

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

# 查看用户
./vless-server.sh list

# 流量统计
./vless-server.sh stats

# Telegram 配置
./vless-server.sh telegram
```

## 许可证

MIT
