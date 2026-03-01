# AnyTLS 一键安装脚本

在 Linux 服务器上一键安装 [AnyTLS](https://github.com/anytls/anytls-go) 服务端，并自动生成**主流代理客户端**的配置与**二维码扫描链接**。

## 功能

- 一键安装 AnyTLS 服务端（自动检测架构与最新版本）
- 交互式配置：监听端口、密码（可自动生成）、SNI
- 自动配置 systemd 服务与防火墙放行
- **代理协议管理**：支持安装 Xray、Trojan-Go、Sing-Box
- 生成以下客户端配置与链接：
  - **通用分享链接**（`anytls://...`）
  - **二维码链接**（复制到浏览器打开即可扫码）
  - **Shadowrocket / 小火箭**：直接使用分享链接或扫码
  - **Surge**：一行配置
  - **Mihomo / Clash Meta**：YAML 节点片段
  - **Sing-Box**：outbound JSON
  - **Nekoray**：URI 链接
  - **Loon**：直接可用的配置
  - **Quantumult X (圈X)**：直接可用的配置
  - **Egern**：YAML 格式配置

所有生成文件保存在服务器 `/etc/anytls/clients/` 目录，便于复制到本地或二次修改。

## 系统要求

- **系统**：Ubuntu、Debian、CentOS、RHEL 等（脚本会检测并安装依赖）
- **权限**：需 root 或 sudo
- **架构**：x86_64 (amd64) / aarch64 (arm64)

## 一键安装

```bash
# 下载并执行安装（推荐）
bash <(curl -sL https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/install.sh) install

# 或先下载再执行
wget -qO install.sh https://raw.githubusercontent.com/mjj0001/anytls-oneclick/main/install.sh
chmod +x install.sh
sudo ./install.sh install
```

安装过程中会提示输入：

- **监听端口**：默认 `8443`，可改为其他 1–65535 未占用端口
- **密码**：留空则自动生成并显示

安装完成后会输出：

- 服务端参数（端口、密码、SNI）
- **anytls:// 分享链接**（所有支持 AnyTLS 的客户端通用）
- **二维码链接**（在浏览器打开即可扫码添加节点）
- 各客户端配置文件路径说明

## 常用命令

| 命令 | 说明 |
|------|------|
| `sudo ./install.sh install` | 一键安装并配置 |
| `sudo ./install.sh view` | 查看当前配置、分享链接与二维码链接 |
| `sudo ./install.sh uninstall` | 卸载服务与二进制（保留 `/etc/anytls` 配置） |
| `sudo ./install.sh proxy` | 代理协议管理 (安装 Xray/Trojan-Go/Sing-Box，生成客户端配置) |

服务管理（安装后）：

```bash
sudo systemctl status anytls   # 状态
sudo systemctl restart anytls  # 重启
sudo systemctl stop anytls     # 停止
```

## 代理协议管理

运行 `sudo ./install.sh proxy` 可以：

1. **安装 Xray** - 支持 VLESS/VMess/Trojan/SS 协议
2. **安装 Trojan-Go** - Trojan 协议
3. **安装 Sing-Box** - 多协议支持
4. **生成 AnyTLS 客户端配置** - 支持 Loon/圈X/Egern
5. **生成 VLESS 客户端配置** - 支持 Loon/圈X/Egern
6. **生成 Trojan 客户端配置** - 支持 Loon/圈X/Egern
7. **生成 VMess 客户端配置** - 支持 Loon/圈X/Egern
8. **生成 Sing-Box 客户端配置** - 支持 VLESS/Trojan/VMess

## 客户端配置与二维码

- **分享链接**：安装完成或执行 `view` 时会在终端输出 `anytls://...`，复制到支持 AnyTLS 的客户端即可（如 Shadowrocket、Nekoray、Mihomo、Sing-Box 等）。
- **二维码**：脚本会输出一个「二维码链接」，在手机或电脑浏览器中打开该链接，页面会显示二维码；用客户端扫描即可添加节点。
- 各客户端详细说明见：[clients/README.md](clients/README.md)。

## 生成文件位置（服务器）

| 路径 | 说明 |
|------|------|
| `/usr/local/bin/anytls-server` | 服务端二进制 |
| `/etc/anytls/config` | 服务端配置（端口、密码、SNI 等） |
| `/etc/anytls/clients/share_links.txt` | 分享链接与二维码链接 |
| `/etc/anytls/clients/mihomo_clash_meta.yaml` | Mihomo/Clash Meta 节点 |
| `/etc/anytls/clients/singbox_outbound.json` | Sing-Box 出站 |
| `/etc/anytls/clients/surge.txt` | Surge 一行配置 |
| `/etc/anytls/clients/nekoray_uri.txt` | 通用 anytls:// 链接 |

## Loon 配置示例

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

## Quantumult X (圈X) 配置示例

```
AnyTLS = anytls://password@server:port?sni=example.com&skip-cert-verify=1
VLESS = vless://uuid@server:port?encryption=none&sni=example.com&skip-cert-verify=1
Trojan = trojan://password@server:port?sni=example.com&skip-cert-verify=1
```

## Egern 配置示例

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

  - name: Trojan
    type: trojan
    server: server_ip
    port: 443
    password: password
    sni: example.com
    skip-cert-verify: true

proxy-groups:
  - name: Auto
    type: select
    proxies:
      - AnyTLS
      - VLESS
      - Trojan
      - DIRECT

rules:
  - GEOIP,CN,DIRECT
  - MATCH,Auto
```

## 协议说明

本脚本支持安装 **AnyTLS**、**Xray (VLESS/VMess/Trojan/SS)**、**Trojan-Go**、**Sing-Box** 协议。  
AnyTLS 适用于需要缓解「TLS in TLS」、追求低延迟与连接复用的场景。

## 许可证

MIT。AnyTLS 项目以 [anytls/anytls-go](https://github.com/anytls/anytls-go) 为准。
