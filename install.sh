#!/usr/bin/env bash
# AnyTLS 一键安装脚本 - 支持主流代理协议客户端配置与二维码
# 适用于: Ubuntu / Debian / CentOS / RHEL
# 客户端: Shadowrocket / Surge / Mihomo(Clash Meta) / Sing-Box / Loon / Quantumult X / Egern 等
# 代理协议: AnyTLS / Xray (VLESS/VMess/Trojan/SS) / Trojan-Go / Sing-Box

set -e
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

# 颜色
readonly Green="\033[32m"
readonly Red="\033[31m"
readonly Yellow="\033[0;33m"
readonly Cyan="\033[0;36m"
readonly RESET="\033[0m"
readonly INFO="${Green}[信息]${RESET}"
readonly ERR="${Red}[错误]${RESET}"
readonly WARN="${Yellow}[警告]${RESET}"

# 路径与默认值
readonly INSTALL_DIR="/usr/local/bin"
readonly BINARY_NAME="anytls-server"
readonly CONFIG_DIR="/etc/anytls"
readonly CONFIG_FILE="${CONFIG_DIR}/config"
readonly CLIENT_CONFIG_DIR="${CONFIG_DIR}/clients"
readonly SERVICE_FILE="/etc/systemd/system/anytls.service"
readonly TMP_DIR="/tmp/anytls_install_$$"
LISTEN_ADDR="[::]"
LISTEN_PORT="8443"
PASSWORD=""
SNI=""
INSECURE="1"
RELEASE=""
VERSION=""

# 二维码生成 API（可选多个，脚本会选可用的）
QR_APIS=(
  "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data"
  "https://api.cl2wm.cn/api/qrcode/code?text"
)

check_root() {
  [[ $EUID -eq 0 ]] || { echo -e "${ERR} 请使用 root 或 sudo 运行"; exit 1; }
}

check_os() {
  if [[ -f /etc/redhat-release ]] || grep -qEi "centos|red hat|redhat" /etc/issue 2>/dev/null; then
    RELEASE="centos"
  elif grep -qEi "debian|ubuntu" /etc/issue 2>/dev/null || grep -qEi "debian|ubuntu" /proc/version 2>/dev/null; then
    RELEASE="debian"
  else
    RELEASE="unknown"
  fi
  [[ "$RELEASE" != "unknown" ]] || { echo -e "${ERR} 未识别的系统"; exit 1; }
  echo -e "${INFO} 系统: $RELEASE"
}

install_deps() {
  local tools=(curl wget unzip openssl)
  local missing=()
  for t in "${tools[@]}"; do command -v "$t" &>/dev/null || missing+=("$t"); done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  echo -e "${INFO} 安装依赖: ${missing[*]}"
  if [[ "$RELEASE" == "debian" ]]; then
    apt-get update -qq && apt-get install -y "${missing[@]}"
  else
    (command -v dnf &>/dev/null && dnf install -y "${missing[@]}") || yum install -y "${missing[@]}"
  fi
}

get_arch() {
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo -e "${ERR} 不支持的架构: $(uname -m)"; exit 1 ;;
  esac
}

get_latest_version() {
  local v
  v=$(curl -sL "https://api.github.com/repos/anytls/anytls-go/releases/latest" 2>/dev/null | grep -oP '"tag_name": "\K[^"]+' | sed 's/^v//')
  echo "${v:-0.0.12}"
}

get_server_ip() {
  local ipv4 ipv6
  if command -v ip &>/dev/null; then
    ipv4=$(ip -4 addr show scope global 2>/dev/null | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | grep -v '^127\.' | head -n1)
    ipv6=$(ip -6 addr show scope global 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^fe80:' | head -n1)
  fi
  [[ -z "$ipv4" ]] && ipv4=$(curl -sL --connect-timeout 3 -4 ip.sb 2>/dev/null || true)
  [[ -z "$ipv6" ]] && ipv6=$(curl -sL --connect-timeout 3 -6 ip.sb 2>/dev/null || true)
  if [[ -n "$ipv4" && -n "$ipv6" ]]; then echo "$ipv4 $ipv6"; elif [[ -n "$ipv4" ]]; then echo "$ipv4"; elif [[ -n "$ipv6" ]]; then echo "$ipv6"; else echo -e "${ERR} 无法获取公网 IP"; return 1; fi
}

check_port() {
  (command -v ss &>/dev/null && ss -ltnH "sport = :$1" 2>/dev/null | grep -q .) || \
  (command -v netstat &>/dev/null && netstat -tln 2>/dev/null | grep -q ":$1 ")
}

download_install() {
  VERSION=$(get_latest_version)
  local arch=$(get_arch)
  local zip="anytls_${VERSION}_linux_${arch}.zip"
  local url="https://github.com/anytls/anytls-go/releases/download/v${VERSION}/${zip}"
  mkdir -p "$TMP_DIR"
  echo -e "${INFO} 下载 anytls v${VERSION} ..."
  wget -qO "${TMP_DIR}/${zip}" "$url" || { echo -e "${ERR} 下载失败"; exit 1; }
  unzip -o -q "${TMP_DIR}/${zip}" -d "$TMP_DIR"
  mv "${TMP_DIR}/anytls-server" "${INSTALL_DIR}/${BINARY_NAME}"
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
  rm -rf "$TMP_DIR"
  echo -e "${INFO} 已安装 ${INSTALL_DIR}/${BINARY_NAME}"
}

firewall_allow() {
  local port=$1
  if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "active"; then
    ufw allow "${port}/tcp" && echo -e "${INFO} 已放行 ${port}/tcp (ufw)"
  elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    firewall-cmd --add-port="${port}/tcp" --permanent && firewall-cmd --reload && echo -e "${INFO} 已放行 ${port}/tcp (firewalld)"
  else
    echo -e "${WARN} 请手动放行端口 ${port}/tcp"
  fi
}

configure_interactive() {
  local default_port=8443
  local input_port input_pass

  while true; do
    read -rp "监听端口 [默认 ${default_port}]: " input_port
    input_port=${input_port:-$default_port}
    if [[ "$input_port" =~ ^[0-9]+$ ]] && (( input_port >= 1 && input_port <= 65535 )); then
      if check_port "$input_port"; then
        echo -e "${ERR} 端口 ${input_port} 已被占用"
      else
        LISTEN_PORT=$input_port
        break
      fi
    else
      echo -e "${ERR} 请输入 1-65535 的端口"
    fi
  done

  read -rp "AnyTLS 密码 [留空自动生成]: " input_pass
  if [[ -z "$input_pass" ]]; then
    PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 16)
    echo -e "${Cyan}自动密码: ${PASSWORD}${RESET}"
  else
    PASSWORD=$input_pass
  fi

  local ips
  ips=$(get_server_ip) || exit 1
  SNI=$(echo "$ips" | awk '{print $1}')
  INSECURE="1"
  firewall_allow "$LISTEN_PORT"
  echo -e "${INFO} 端口: ${LISTEN_PORT}  密码: ${PASSWORD}  SNI: ${SNI}"
}

save_config() {
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" << EOF
listen_addr=${LISTEN_ADDR}
listen_port=${LISTEN_PORT}
password=${PASSWORD}
sni=${SNI}
insecure=${INSECURE}
version=${VERSION}
EOF
}

write_systemd() {
  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=AnyTLS Server
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${BINARY_NAME} -addr ${LISTEN_ADDR}:${LISTEN_PORT} -password ${PASSWORD}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable anytls
  systemctl start anytls
  echo -e "${INFO} systemd 服务已启用"
}

# 生成 AnyTLS 分享链接
share_link() {
  local ip=$1
  local port=$2
  local pass=$3
  local sni=$4
  local insecure=$5
  local display_ip=$ip
  [[ "$ip" == *:* ]] && display_ip="[${ip}]"
  local params=""
  [[ -n "$sni" ]] && params="sni=${sni}"
  [[ "$insecure" == "1" ]] && params="${params:+$params&}insecure=1"
  if [[ -n "$params" ]]; then
    echo "anytls://${pass}@${display_ip}:${port}?${params}"
  else
    echo "anytls://${pass}@${display_ip}:${port}"
  fi
}

# 二维码网页链接（用于扫码或复制到浏览器）
qr_url() {
  local link=$1
  local encoded
  encoded=$(echo -n "$link" | sed 's/ /%20/g')
  # 使用通用 QR API
  echo "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encoded}"
}

# 生成所有客户端配置与二维码链接，并写入文件
generate_all_clients() {
  local listen_port=$1
  local password=$2
  local sni=$3
  local insecure=$4
  local server_ips
  server_ips=$(get_server_ip) || return 1

  mkdir -p "$CLIENT_CONFIG_DIR"
  local base_link
  base_link=$(share_link "$(echo "$server_ips" | awk '{print $1}')" "$listen_port" "$password" "$sni" "$insecure")
  local qr_link
  qr_link=$(qr_url "$base_link")

  # 保存分享链接与二维码链接
  cat > "${CLIENT_CONFIG_DIR}/share_links.txt" << EOF
# AnyTLS 分享链接与二维码
# 生成时间: $(date -Iseconds 2>/dev/null || date)

## 通用分享链接 (anytls://)
${base_link}

## 二维码链接 (复制到浏览器打开可扫码)
${qr_link}

EOF

  local surge_insecure="false"
  [[ "$insecure" == "1" ]] && surge_insecure="true"

  # Mihomo / Clash Meta
  local mihomo_yaml="${CLIENT_CONFIG_DIR}/mihomo_clash_meta.yaml"
  cat > "$mihomo_yaml" << EOF
# Mihomo / Clash Meta 节点 (复制到 proxies 下)
proxies:
  - name: anytls-proxy
    type: anytls
    server: $(echo "$server_ips" | awk '{print $1}')
    port: ${listen_port}
    password: "${password}"
    client-fingerprint: chrome
    udp: true
    sni: "${sni}"
    alpn:
      - h2
      - http/1.1
    skip-cert-verify: ${insecure}
EOF

  # Sing-Box outbound
  local singbox_json="${CLIENT_CONFIG_DIR}/singbox_outbound.json"
  local first_ip
  first_ip=$(echo "$server_ips" | awk '{print $1}')
  cat > "$singbox_json" << EOF
{
  "type": "anytls",
  "tag": "anytls-out",
  "server": "${first_ip}",
  "server_port": ${listen_port},
  "password": "${password}",
  "tls": {
    "enabled": true,
    "server_name": "${sni}",
    "insecure": $( [[ "$insecure" == "1" ]] && echo "true" || echo "false" )
  }
}
EOF

  # Surge
  local surge_txt="${CLIENT_CONFIG_DIR}/surge.txt"
  first_ip=$(echo "$server_ips" | awk '{print $1}')
  [[ "$first_ip" == *:* ]] && first_ip="[${first_ip}]"
  echo "AnyTLS = anytls, ${first_ip}, ${listen_port}, password=${password}, sni=${sni}, skip-cert-verify=${surge_insecure}" > "$surge_txt"

  # Nekoray / 通用 URI
  echo "${base_link}" > "${CLIENT_CONFIG_DIR}/nekoray_uri.txt"

  echo -e "${INFO} 客户端配置已写入: ${CLIENT_CONFIG_DIR}/"
}

print_config_summary() {
  local listen_port=$1
  local password=$2
  local sni=$3
  local insecure=$4
  local server_ips
  server_ips=$(get_server_ip) || return 1

  echo ""
  echo -e "${Yellow}=============== AnyTLS 服务端配置 ===============${RESET}"
  echo -e "  端口: ${listen_port}  密码: ${password}  SNI: ${sni}  跳过证书: $([ "$insecure" = "1" ] && echo "是" || echo "否")"
  echo -e "${Yellow}=============== 分享链接 (所有客户端通用) ===============${RESET}"
  local link
  link=$(share_link "$(echo "$server_ips" | awk '{print $1}')" "$listen_port" "$password" "$sni" "$insecure")
  echo -e "${Green}${link}${RESET}"
  echo -e "${Yellow}=============== 二维码链接 (复制到浏览器打开扫码) ===============${RESET}"
  echo -e "${Green}$(qr_url "$link")${RESET}"
  echo -e "${Yellow}=============== 客户端配置说明 ===============${RESET}"
  echo -e "  • Shadowrocket / 小火箭: 复制上方 anytls:// 链接，在 Shadowrocket 中从剪贴板添加"
  echo -e "  • Surge: 使用 ${CLIENT_CONFIG_DIR}/surge.txt 中的一行"
  echo -e "  • Mihomo / Clash Meta: 使用 ${CLIENT_CONFIG_DIR}/mihomo_clash_meta.yaml 中 proxies 节点"
  echo -e "  • Sing-Box: 将 ${CLIENT_CONFIG_DIR}/singbox_outbound.json 加入 outbounds"
  echo -e "  • Nekoray: 复制 anytls:// 链接，从剪贴板导入"
  echo -e "${Yellow}================================================${RESET}"
  echo ""
}

do_install() {
  check_root
  check_os
  install_deps
  download_install
  configure_interactive
  save_config
  write_systemd
  generate_all_clients "$LISTEN_PORT" "$PASSWORD" "$SNI" "$INSECURE"
  print_config_summary "$LISTEN_PORT" "$PASSWORD" "$SNI" "$INSECURE"
  echo -e "${INFO} 安装完成。查看配置: cat ${CLIENT_CONFIG_DIR}/share_links.txt"
  echo -e "${INFO} 管理: systemctl status anytls | start | stop | restart"
}

do_uninstall() {
  check_root
  systemctl stop anytls 2>/dev/null || true
  systemctl disable anytls 2>/dev/null || true
  rm -f "$SERVICE_FILE"
  systemctl daemon-reload
  rm -f "${INSTALL_DIR}/${BINARY_NAME}"
  echo -e "${WARN} 已卸载服务与二进制。配置保留在 ${CONFIG_DIR}，如需删除请手动: rm -rf ${CONFIG_DIR}"
}

do_view() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${ERR} 未找到配置，请先安装"
    exit 1
  fi
  LISTEN_PORT=$(grep '^listen_port=' "$CONFIG_FILE" | cut -d= -f2)
  PASSWORD=$(grep '^password=' "$CONFIG_FILE" | cut -d= -f2)
  SNI=$(grep '^sni=' "$CONFIG_FILE" | cut -d= -f2)
  INSECURE=$(grep '^insecure=' "$CONFIG_FILE" | cut -d= -f2)
  print_config_summary "$LISTEN_PORT" "$PASSWORD" "$SNI" "$INSECURE"
  if [[ -d "$CLIENT_CONFIG_DIR" ]]; then
    echo -e "${INFO} 详细配置目录: ${CLIENT_CONFIG_DIR}"
    ls -la "$CLIENT_CONFIG_DIR" 2>/dev/null || true
  fi
}

usage() {
  echo "用法: $0 install | uninstall | view | proxy"
  echo "  install   - 一键安装并配置 AnyTLS 服务端，生成客户端配置与二维码链接"
  echo "  uninstall - 卸载服务与二进制"
  echo "  view      - 查看当前配置与分享链接"
  echo "  proxy     - 代理协议管理 (安装 Xray/Trojan-Go/Sing-Box，生成客户端配置)"
}

main() {
  case "${1:-install}" in
    install)  do_install ;;
    uninstall) do_uninstall ;;
    view)     do_view ;;
    proxy)    do_proxy_menu ;;
    -h|--help) usage ;;
    *) echo -e "${ERR} 未知参数"; usage; exit 1 ;;
  esac
}

# ============ 代理协议管理 ============

do_proxy_menu() {
  while true; do
    echo ""
    echo -e "${Cyan}=============== 代理协议管理 ===============${RESET}"
    echo ""
    echo "1. 安装 Xray (VLESS/VMess/Trojan/SS)"
    echo "2. 安装 Trojan-Go"
    echo "3. 安装 Sing-Box"
    echo "4. 生成 AnyTLS 客户端配置 (Loon/圈X/Egern)"
    echo "5. 生成 VLESS 客户端配置"
    echo "6. 生成 Trojan 客户端配置"
    echo "7. 生成 VMess 客户端配置"
    echo "8. 生成 Sing-Box 客户端配置"
    echo "0. 返回"
    echo ""
    read -rp "请选择 [0-8]: " choice
    
    case $choice in
      1) install_xray ;;
      2) install_trojan ;;
      3) install_singbox ;;
      4) generate_anytls_clients ;;
      5) generate_vless_clients ;;
      6) generate_trojan_clients ;;
      7) generate_vmess_clients ;;
      8) generate_singbox_clients ;;
      0) break ;;
      *) echo -e "${ERR} 无效选择" ;;
    esac
  done
}

install_xray() {
  check_root
  echo -e "${INFO} 安装 Xray..."
  bash <(curl -Ls https://raw.githubusercontent.com/mjj001/mjj/main/xray-install.sh)
  echo -e "${INFO} Xray 安装完成"
}

install_trojan() {
  check_root
  echo -e "${INFO} 安装 Trojan-Go..."
  bash <(curl -Ls https://raw.githubusercontent.com/mjj001/mjj/main/trojan-install.sh)
  echo -e "${INFO} Trojan-Go 安装完成"
}

install_singbox() {
  check_root
  echo -e "${INFO} 安装 Sing-Box..."
  bash <(curl -Ls https://raw.githubusercontent.com/mjj001/mjj/main/singbox-install.sh)
  echo -e "${INFO} Sing-Box 安装完成"
}

generate_anytls_clients() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${ERR} AnyTLS 未安装，请先运行 install"
    return
  fi
  
  source "$CONFIG_FILE"
  
  local server_ip
  server_ip=$(get_server_ip | awk '{print $1}')
  
  echo ""
  echo -e "${Cyan}=============== AnyTLS 客户端配置 ===============${RESET}"
  
  # Loon
  echo ""
  echo -e "${Yellow}--- Loon ---${RESET}"
  echo "anytls://${password}@${server_ip}:${listen_port}?sni=${sni}&skip-cert-verify=${insecure}#AnyTLS"
  
  # Quantumult X
  echo ""
  echo -e "${Yellow}--- Quantumult X (圈X) ---${RESET}"
  echo "anytls://${password}@${server_ip}:${listen_port}?sni=${sni}&skip-cert-verify=${insecure}"
  
  # Egern
  echo ""
  echo -e "${Yellow}--- Egern ---${RESET}"
  cat << EOF
proxies:
  - name: AnyTLS
    type: anytls
    server: ${server_ip}
    port: ${listen_port}
    password: "${password}"
    sni: "${sni}"
    skip-cert-verify: $([ "$insecure" = "1" ] && echo "true" || echo "false")

proxy-groups:
  - name: AnyTLS
    type: select
    proxies:
      - AnyTLS

rules:
  - GEOIP,CN,DIRECT
  - MATCH,AnyTLS
EOF
}

generate_vless_clients() {
  if [[ ! -f /usr/local/bin/xray ]] && [[ ! -f /usr/local/xray/xray ]]; then
    echo -e "${ERR} Xray 未安装，请先安装"
    return
  fi
  
  echo ""
  echo -e "${Cyan}=============== VLESS 配置 ===============${RESET}"
  echo ""
  read -rp "VLESS 端口: " vless_port
  read -rp "VLESS ID (UUID): " vless_id
  read -rp "域名 (SNI): " vless_sni
  
  [[ -z "$vless_id" ]] && vless_id=$(cat /proc/sys/kernel/random/uuid)
  [[ -z "$vless_sni" ]] && vless_sni=$(get_server_ip | awk '{print $1}')
  
  local server_ip
  server_ip=$(get_server_ip | awk '{print $1}')
  
  echo ""
  echo -e "${Yellow}--- Loon ---${RESET}"
  echo "vless://${vless_id}@${server_ip}:${vless_port}?encryption=none&sni=${vless_sni}&skip-cert-verify=1#VLESS"
  
  echo ""
  echo -e "${Yellow}--- Quantumult X (圈X) ---${RESET}"
  echo "vless://${vless_id}@${server_ip}:${vless_port}?encryption=none&sni=${vless_sni}&skip-cert-verify=1"
  
  echo ""
  echo -e "${Yellow}--- Egern ---${RESET}"
  cat << EOF
proxies:
  - name: VLESS
    type: vless
    server: ${server_ip}
    port: ${vless_port}
    uuid: ${vless_id}
    tls: true
    servername: ${vless_sni}
    skip-cert-verify: true

proxy-groups:
  - name: VLESS
    type: select
    proxies:
      - VLESS

rules:
  - GEOIP,CN,DIRECT
  - MATCH,VLESS
EOF
}

generate_trojan_clients() {
  local trojan_bin="/usr/local/bin/trojan"
  [[ ! -f $trojan_bin ]] && trojan_bin="/usr/local/trojan/trojan"
  
  if [[ ! -f $trojan_bin ]]; then
    echo -e "${ERR} Trojan-Go 未安装，请先安装"
    return
  fi
  
  echo ""
  echo -e "${Cyan}=============== Trojan 配置 ===============${RESET}"
  echo ""
  read -rp "Trojan 端口: " trojan_port
  read -rp "Trojan 密码: " trojan_pass
  read -rp "域名 (SNI): " trojan_sni
  
  [[ -z "$trojan_sni" ]] && trojan_sni=$(get_server_ip | awk '{print $1}')
  
  local server_ip
  server_ip=$(get_server_ip | awk '{print $1}')
  
  echo ""
  echo -e "${Yellow}--- Loon ---${RESET}"
  echo "trojan://${trojan_pass}@${server_ip}:${trojan_port}?sni=${trojan_sni}&skip-cert-verify=1#Trojan"
  
  echo ""
  echo -e "${Yellow}--- Quantumult X (圈X) ---${RESET}"
  echo "trojan://${trojan_pass}@${server_ip}:${trojan_port}?sni=${trojan_sni}&skip-cert-verify=1"
  
  echo ""
  echo -e "${Yellow}--- Egern ---${RESET}"
  cat << EOF
proxies:
  - name: Trojan
    type: trojan
    server: ${server_ip}
    port: ${trojan_port}
    password: ${trojan_pass}
    sni: ${trojan_sni}
    skip-cert-verify: true

proxy-groups:
  - name: Trojan
    type: select
    proxies:
      - Trojan

rules:
  - GEOIP,CN,DIRECT
  - MATCH,Trojan
EOF
}

generate_vmess_clients() {
  if [[ ! -f /usr/local/bin/xray ]] && [[ ! -f /usr/local/xray/xray ]]; then
    echo -e "${ERR} Xray 未安装，请先安装"
    return
  fi
  
  echo ""
  echo -e "${Cyan}=============== VMess 配置 ===============${RESET}"
  echo ""
  read -rp "VMess 端口: " vmess_port
  read -rp "VMess ID (UUID): " vmess_id
  read -rp "域名 (SNI): " vmess_sni
  
  [[ -z "$vmess_id" ]] && vmess_id=$(cat /proc/sys/kernel/random/uuid)
  [[ -z "$vmess_sni" ]] && vmess_sni=$(get_server_ip | awk '{print $1}')
  
  local server_ip
  server_ip=$(get_server_ip | awk '{print $1}')
  
  local vmess_config="{\"v\":\"2\",\"ps\":\"VMess\",\"add\":\"${server_ip}\",\"port\":\"${vmess_port}\",\"id\":\"${vmess_id}\",\"aid\":0,\"net\":\"ws\",\"type\":\"none\",\"host\":\"${vmess_sni}\",\"path\":\"/vmess\",\"tls\":\"tls\",\"sni\":\"${vmess_sni}\"}"
  local vmess_link="vmess://$(echo -n "$vmess_config" | base64)"
  
  echo ""
  echo -e "${Yellow}--- VMess 链接 ---${RESET}"
  echo "$vmess_link"
  
  echo ""
  echo -e "${Yellow}--- Loon ---${RESET}"
  echo "请使用转换工具将 VMess 链接转换为 Loon 格式"
  
  echo ""
  echo -e "${Yellow}--- Quantumult X ---${RESET}"
  echo "$vmess_link"
  
  echo ""
  echo -e "${Yellow}--- Egern ---${RESET}"
  cat << EOF
proxies:
  - name: VMess
    type: vmess
    server: ${server_ip}
    port: ${vmess_port}
    uuid: ${vmess_id}
    alterId: 0
    tls: true
    servername: ${vmess_sni}
    skip-cert-verify: true

proxy-groups:
  - name: VMess
    type: select
    proxies:
      - VMess

rules:
  - GEOIP,CN,DIRECT
  - MATCH,VMess
EOF
}

generate_singbox_clients() {
  local singbox_bin="/usr/local/bin/sing-box"
  [[ ! -f $singbox_bin ]] && singbox_bin="/usr/local/sing-box/sing-box"
  
  if [[ ! -f $singbox_bin ]]; then
    echo -e "${ERR} Sing-Box 未安装，请先安装"
    return
  fi
  
  echo ""
  echo -e "${Cyan}=============== Sing-Box 配置 ===============${RESET}"
  echo ""
  read -rp "端口: " sb_port
  read -rp "UUID: " sb_uuid
  read -rp "域名 (SNI): " sb_sni
  
  [[ -z "$sb_uuid" ]] && sb_uuid=$(cat /proc/sys/kernel/random/uuid)
  [[ -z "$sb_sni" ]] && sb_sni=$(get_server_ip | awk '{print $1}')
  
  local server_ip
  server_ip=$(get_server_ip | awk '{print $1}')
  
  echo ""
  echo -e "${Yellow}--- VLESS ---${RESET}"
  cat << EOF
{
  "outbounds": [
    {
      "type": "vless",
      "tag": "vless-out",
      "server": "${server_ip}",
      "server_port": ${sb_port},
      "uuid": "${sb_uuid}",
      "tls": {
        "enabled": true,
        "server_name": "${sb_sni}"
      }
    }
  ]
}
EOF
  
  echo ""
  echo -e "${Yellow}--- Trojan ---${RESET}"
  read -rp "Trojan 密码: " sb_pass
  cat << EOF
{
  "outbounds": [
    {
      "type": "trojan",
      "tag": "trojan-out",
      "server": "${server_ip}",
      "server_port": ${sb_port},
      "password": "${sb_pass}",
      "tls": {
        "enabled": true,
        "server_name": "${sb_sni}"
      }
    }
  ]
}
EOF
  
  echo ""
  echo -e "${Yellow}--- VMess ---${RESET}"
  cat << EOF
{
  "outbounds": [
    {
      "type": "vmess",
      "tag": "vmess-out",
      "server": "${server_ip}",
      "server_port": ${sb_port},
      "uuid": "${sb_uuid}",
      "tls": {
        "enabled": true,
        "server_name": "${sb_sni}"
      }
    }
  ]
}
EOF
}

main "$@"
