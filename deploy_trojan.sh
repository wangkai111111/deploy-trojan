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

function main() {
    read -p "设置trojan的外部端口: " port
    read -p "设置trojan的密码: " passwd
    read -p "设置域名: " domain
    check_env $port $passwd $domain
    echo ""
    echo ""
    echo " ======================================="
    echo " trojan连接地址: ${ipaddr}:${port}"
    echo " 密码: ${passwd}"
    echo " ======================================="
    echo ""
    echo ""
}

main