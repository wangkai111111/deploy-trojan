# Deploy Trojan

这是一个在 Ubuntu 上一键部署 Trojan 的脚本。

## 介绍

Trojan 是一种利用 HTTPS 加密协议来传输流量的代理软件，能够有效地避免网络封锁和流量监控。此脚本旨在简化在 Ubuntu 上安装和配置 Trojan 的过程。

## 安装步骤

1. **克隆仓库到本地：**

    ```bash
    git clone git@github.com:wangkai111111/deploy-trojan.git
    cd deploy-trojan
    ```

2. **运行安装脚本：**

    ```bash
    ./install.sh
    ```

## Clash 配置

在 Clash 的配置文件中添加以下内容：

```yaml
- {type: trojan, name: '113.31.112.200', server: '113.31.112.200', port: 26578, password: 'eqwlOdsn%2.ds782(dlscw&sKL0kksdn&sds', skip-cert-verify: true}
```
**说明**
- name: 为 Trojan 设置的名字
- server: Trojan 所在的公网 IP 地址
- port: Trojan 开放的公共端口
- password: 设置的密码
- skip-cert-verify: 是否跳过证书验证（默认为 true）