# Deploy Trojan

这是一个在 Ubuntu 上一键部署 Trojan 的脚本，具有自动配置和优化功能。

## 介绍

Trojan 是一种利用 HTTPS 加密协议来传输流量的代理软件，能够有效地避免网络封锁和流量监控。此脚本旨在简化在 Ubuntu 上安装和配置 Trojan 的过程，并提供了以下增强功能：

- 自动生成随机未被占用的外部端口
- 自动生成高强度随机密码（包含大小写字母、数字和特殊符号）
- 自动设置默认域名
- 自动生成 Clash 配置文件，无需手动编写

## 系统要求

- Ubuntu 18.04 及以上版本
- CentOS 7/8 及以上版本
- Rocky Linux 8 及以上版本

## 安装步骤

### 方法一：一键部署（推荐）

直接执行以下命令进行一键部署：

```bash
bash <(curl -L https://raw.githubusercontent.com/wangkai111111/deploy-trojan/master/deploy_trojan.sh)
```

### 方法二：克隆仓库安装

1. **克隆仓库到本地：**

    ```bash
    git clone https://github.com/wangkai111111/deploy-trojan.git
    cd deploy-trojan
    ```

2. **运行安装脚本：**

    ```bash
    bash deploy_trojan.sh
    ```

## 使用说明

运行脚本后，您将被提示输入以下信息：

1. **外部端口**：
   - 可自定义输入一个未被占用的端口号
   - 直接回车将自动生成一个40000-50000范围内的随机未被占用端口

2. **密码**：
   - 可自定义输入密码
   - 直接回车将自动生成一个32位的高强度随机密码（包含大小写字母、数字和特殊符号）

3. **域名**：
   - 可输入您的域名
   - 直接回车将使用默认域名 `example.com`

## 自动生成的内容

安装完成后，脚本会自动生成以下内容：

1. **Trojan 配置文件**：位于 `/etc/trojan/config.json`

2. **Clash 配置文件**：位于当前目录 `./clash_trojan_config.yaml`
   - 已包含正确的服务器信息、端口、密码和域名
   - 包含常用网站规则配置
   - 可直接导入 Clash 客户端使用

## 安装完成信息

安装完成后，脚本会显示以下重要信息：

```
=======================================
 trojan连接地址: [服务器IP]:[端口]
 密码: [您设置或自动生成的密码]
 域名: [您设置或默认的域名]
 Clash配置文件: ./clash_trojan_config.yaml
=======================================
```

## 注意事项

1. 确保您的服务器已开放相应的端口（防火墙设置）
2. 如果使用自定义域名，请确保域名已正确解析到您的服务器IP
3. Clash 配置文件包含了您的连接信息，请妥善保管
4. 如需重新安装，请先卸载已有的 Trojan：`apt remove -y trojan`

## Clash 客户端使用方法

1. 打开 Clash 客户端
2. 点击配置 -> 从文件导入
3. 选择生成的 `clash_trojan_config.yaml` 文件
4. 在代理组中选择 "PROXY" 开始使用

## 常见问题

- **端口被占用**：脚本会自动检测端口占用情况，生成未被占用的端口
- **密码忘记**：可以查看 `/etc/trojan/config.json` 文件获取密码
- **服务无法启动**：可以使用 `systemctl status trojan` 查看服务状态和错误信息
- **CentOS/Rocky Linux相关问题**：
  - 确保已启用EPEL仓库：`yum install epel-release` 或 `dnf install epel-release`
  - 如果找不到trojan包，请检查EPEL仓库是否已正确启用
