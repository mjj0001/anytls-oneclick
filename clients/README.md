# 客户端配置说明

安装脚本会在服务器上生成以下配置，并输出 **分享链接** 与 **二维码链接**。各客户端用法如下。

## 支持的代理协议

本脚本安装的是 **AnyTLS** 服务端。AnyTLS 是一种 TLS 代理协议，缓解「TLS in TLS」问题，支持连接复用与低延迟。

| 协议   | 说明           | 支持客户端 |
|--------|----------------|------------|
| AnyTLS | 本脚本安装协议 | Mihomo / Sing-Box / Shadowrocket / Surge / Nekoray 等 |

其他主流协议（VLESS、VMess、Trojan、Shadowsocks）需配合 Xray/sing-box 等另行部署；本仓库仅提供 AnyTLS 一键安装与客户端配置生成。

---

## 各客户端配置方式

### 1. Shadowrocket（小火箭 / iOS）

- **方式一**：复制脚本输出的 `anytls://...` 分享链接，在 Shadowrocket 中「从剪贴板添加」或「扫描二维码」。
- **方式二**：将脚本输出的「二维码链接」在浏览器打开，用 Shadowrocket 扫页面上的二维码。

### 2. Surge

- 使用服务器上生成的 `Surge` 配置行（见安装完成时的输出或 `/etc/anytls/clients/surge.txt`）。
- 格式示例：`AnyTLS = anytls, 服务器IP, 端口, password=xxx, sni=xxx, skip-cert-verify=true`
- 在 Surge 的 Proxy 配置中加入该行即可。

### 3. Mihomo / Clash Meta（Windows / macOS / Linux）

- 使用服务器上生成的 YAML 片段：`/etc/anytls/clients/mihomo_clash_meta.yaml`。
- 将其中 `proxies` 下的节点复制到你的 Clash/Mihomo 配置文件的 `proxies` 中，并在 `proxy-groups` 中引用该节点名称（如 `anytls-proxy`）。

### 4. Sing-Box

- 使用服务器上生成的 JSON：`/etc/anytls/clients/singbox_outbound.json`。
- 将该 outbound 加入你 Sing-Box 配置的 `outbounds` 数组，并在路由或 DNS 等需要出站的地方引用其 `tag`（如 `anytls-out`）。

### 5. Nekoray（Windows）

- 复制 `anytls://...` 分享链接，在 Nekoray 中通过「从剪贴板导入」或「添加」→「从链接」粘贴即可。

### 6. 其他支持 AnyTLS 的客户端

- 凡支持 **anytls://** URI 或 **AnyTLS** 出站的客户端，均可使用脚本输出的分享链接或对应格式的配置片段。

---

## 二维码链接

安装完成后会输出类似：

```
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=anytls%3A%2F%2F...
```

- **用法**：复制该链接在手机或电脑浏览器中打开，页面会显示二维码；用客户端（如 Shadowrocket、v2rayNG 等）扫描即可添加节点。
- 若该域名不可用，可自行将 `anytls://...` 分享链接粘贴到任意「文本转二维码」网页生成二维码后扫描。

---

## 查看已生成配置（在服务器上）

安装后配置与客户端文件位于：

- 服务端配置：`/etc/anytls/config`
- 客户端配置目录：`/etc/anytls/clients/`
  - `share_links.txt`：分享链接与二维码链接
  - `mihomo_clash_meta.yaml`：Mihomo/Clash Meta
  - `singbox_outbound.json`：Sing-Box
  - `surge.txt`：Surge
  - `nekoray_uri.txt`：通用 anytls:// 链接

在服务器上执行 `bash install.sh view` 可再次打印分享链接与二维码链接（与安装时相同）。
