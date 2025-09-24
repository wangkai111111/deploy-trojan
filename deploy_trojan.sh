#!/bin/bash

trojan_pwd=/etc/trojan
cert_pwd=$trojan_pwd/ssl
private_file=$cert_pwd/private-key.pem
certificate_file=$cert_pwd/certificate.pem
date=$(date +"%Y%m%d")
ipaddr=$(ip addr show dev $(ip route show default | awk '/default/ {print $5}') | grep -i 'inet' | grep -v 'inet6' | awk '/inet/ {print $2}' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')

function check_env() {
    if [[ $(command -v apt) ]]; then
        if [[ ! $(command -v trojan) ]]; then
            apt update -y && apt install -y trojan
            cp $trojan_pwd/config.json $trojan_pwd/config.json${date}
            update_cert $3
            trojan_config $1 $2
        else
            echo "存在trojan，要想重新安装请先卸载"
            exit 1
        fi
    else
        echo "目前只支持ubuntu18+，暂不支持别的系统"
        exit 1
    fi
}

function update_cert() {
    mkdir -p ${cert_pwd}
    if [[ $(command -v openssl) ]]; then
        echo "正在生成证书，路径为: $cert_pwd"
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout ${private_file} \
            -out ${certificate_file} \
            -subj "/C=CN/ST=/L=/O=/CN=$1"
        chmod 600 ${private_file} ${certificate_file}
    else
        apt update -y && apt install -y openssl
        echo "正在生成证书，路径为: $cert_pwd"
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout ${private_file} \
            -out ${certificate_file} \
            -subj "/C=CN/ST=/L=/O=/CN=$1"
        chmod 600 ${private_file} ${certificate_file}
    fi
}

function trojan_config() {
    cat > /etc/trojan/config.json <<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": $1,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$2"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "${certificate_file}",
        "key": "${private_file}",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
systemctl restart trojan
systemctl enable trojan
systemctl status trojan
}

function generate_clash_config() {
    # 生成Clash配置文件，使用脚本中的端口、密码和IP信息
    cat > ./clash_trojan_config.yaml <<EOF
# Clash 使用 Trojan 协议的配置文件 - 自动生成

port: 7890
socks-port: 7891
tproxy-port: 7892
mixed-port: 7893
authentication: false
allow-lan: true
mode: Rule
log-level: info
external-controller: 127.0.0.1:9090

# 代理服务器配置
proxies:
  - name: "Trojan 节点"
    type: trojan
    server: ${domain}  # 域名
    port: ${port}  # Trojan服务器端口
    password: "${passwd}"  # Trojan密码
    # TLS配置
    tls: true
    sni: ${domain}  # 服务器名称指示，与server相同
    # 可选配置
    # alpn: ["http/1.1"]
    # skip-cert-verify: false

# 代理组配置
proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - "Trojan 节点"

# 规则配置
rules:
  - DOMAIN-SUFFIX,google.com,PROXY
  - DOMAIN-SUFFIX,youtube.com,PROXY
  - DOMAIN-SUFFIX,facebook.com,PROXY
  - DOMAIN-SUFFIX,twitter.com,PROXY
  - DOMAIN-SUFFIX,github.com,PROXY
  - GEOIP,CN,DIRECT
  - MATCH,DIRECT
EOF
    echo "Clash配置文件已生成：./clash_trojan_config.yaml"
}

function generate_random_port() {
    # 生成一个40000-50000范围内的随机未被占用的端口
    while true; do
        # 生成随机端口号
        random_port=$((40000 + RANDOM % 10000))
        
        # 检查端口是否被占用
        if ! ss -tuln | grep -q ":$random_port "; then
            echo "$random_port"
            return
        fi
    done
}

function generate_random_password() {
    # 生成一个包含大小写字母、数字和特殊符号的32位随机密码
    # 使用openssl生成随机字节，然后通过base64转换，再过滤和截取
    password=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*()_+=-[]{}|;:,.<>?~' | head -c 32)
    echo "$password"
}

function main() {
    read -p "设置trojan的外部端口: " port
    
    # 如果端口未设置，生成随机未被占用的端口
    if [[ -z "$port" ]]; then
        echo "端口未设置，正在生成随机未被占用的端口..."
        port=$(generate_random_port)
        echo "已生成随机端口: $port"
    fi
    
    read -p "设置trojan的密码: " passwd
    
    # 如果密码未设置，生成随机密码
    if [[ -z "$passwd" ]]; then
        echo "密码未设置，正在生成随机密码..."
        passwd=$(generate_random_password)
        echo "已生成随机密码: $passwd"
    fi
    
    read -p "设置域名: " domain
    # 如果域名为空，则设置为example.com
    if [[ -z "$domain" ]]; then
        domain="example.com"
        echo "域名未设置，将使用默认域名: $domain"
    fi
    check_env $port $passwd $domain
    
    # 生成Clash配置文件
    generate_clash_config
    
    echo ""
    echo ""
    echo " ======================================="
    echo " trojan连接地址: ${ipaddr}:${port}"
    echo " 密码: ${passwd}"
    echo " 域名: ${domain}"
    echo " Clash配置文件: ./clash_trojan_config.yaml"
    echo " ======================================="
    echo ""
    echo ""
}

main