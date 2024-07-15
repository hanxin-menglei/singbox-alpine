#!/bin/sh

# 安装 dialog 工具
apk update
apk add dialog

# 获取系统信息
get_system_info() {
    HOSTNAME=$(hostname)
    OS=$(uname -o)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p)
    DATE=$(date)
    MEMORY=$(free -m | awk '/Mem:/ {print \$3 "MB / " \$2 "MB"}')
    CPU=$(grep 'model name' /proc/cpuinfo | uniq | awk -F: '{print \$2}')
    DISK=$(df -h / | awk '/\// {print \$3 " / " \$2}')
}

# 显示系统信息
show_system_info() {
    get_system_info
    dialog --title "系统信息" --msgbox "主机名: $HOSTNAME\n操作系统: $OS\n内核版本: $KERNEL\n运行时间: $UPTIME\n当前时间: $DATE\n内存使用: $MEMORY\nCPU: $CPU\n硬盘使用: $DISK" 15 50
}

# 安装 sing-box
install_singbox() {
    # 设置版本号
    VERSION="1.9.3"
    
    # 获取操作系统和架构信息
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # 根据架构信息调整下载文件名
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            dialog --msgbox "不支持的架构: $ARCH" 10 30
            exit 1
            ;;
    esac
    
    # 拼接下载地址
    DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/v${VERSION}/sing-box-${VERSION}-${OS}-${ARCH}.tar.gz"
    
    # 下载文件
    wget $DOWNLOAD_URL -O sing-box-${VERSION}-${OS}-${ARCH}.tar.gz
    
    # 检查下载是否成功
    if [ $? -ne 0 ]; then
        dialog --msgbox "下载失败: $DOWNLOAD_URL" 10 30
        exit 1
    fi
    
    # 解压下载的文件
    tar -zxvf sing-box-${VERSION}-${OS}-${ARCH}.tar.gz
    
    # 移动解压出的sing-box文件到/usr/local/bin
    mv sing-box /usr/local/bin/
    
    # 清理下载的tar.gz文件
    rm sing-box-${VERSION}-${OS}-${ARCH}.tar.gz
    
    # 创建配置文件目录
    mkdir -p /usr/local/etc/sing-box
    
    # 让用户输入listen_port和Host
    LISTEN_PORT=$(dialog --inputbox "请输入监听端口 (listen_port):" 10 30 3>&1 1>&2 2>&3 3>&-)
    HOST=$(dialog --inputbox "请输入Host:" 10 30 3>&1 1>&2 2>&3 3>&-)
    
    # 生成UUID
    UUID=$(/usr/local/bin/sing-box generate uuid)
    
    # 创建config.json文件
    cat <<EOF > /usr/local/etc/sing-box/config.json
{
    "inbounds": [
        {
            "type": "vmess",
            "listen": "::",
            "listen_port": $LISTEN_PORT,
            "tag":"vmess-sb",
            "users": [
                {
                    "uuid": "$UUID",
                    "alterId": 0
                }
            ],
            "transport": {
                "type": "ws",
                "path": "/",
                "headers": {
                    "Host": "$HOST"
                },
                "max_early_data": 2048
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
    
    # 创建日志目录
    mkdir -p /var/log/sing-box
    
    # 创建 OpenRC 服务脚本
    cat <<EOF > /etc/init.d/sing-box
#!/sbin/openrc-run

name="sing-box"
description="sing-box service"
command="/usr/local/bin/sing-box"
command_args="run -c /usr/local/etc/sing-box/config.json"
pidfile="/run/sing-box.pid"
command_background="yes"
output_log="/var/log/sing-box/sing-box.log"
error_log="/var/log/sing-box/sing-box.err.log"

depend() {
    need net
    use dns logger
    after firewall
}

start_pre() {
    checkpath -d -m 0755 /run/sing-box
    checkpath -f -m 0644 -o root:root \$output_log
    checkpath -f -m 0644 -o root:root \$error_log
}

start() {
    ebegin "Starting \$name"
    start-stop-daemon --start --exec \$command -- \$command_args >> \$output_log 2>> \$error_log &
    eend \$?
}

stop() {
    ebegin "Stopping \$name"
    start-stop-daemon --stop --pidfile \$pidfile
    eend \$?
}
EOF
    
    # 赋予服务脚本执行权限
    chmod +x /etc/init.d/sing-box
    
    # 添加服务到 OpenRC 并启动服务
    rc-update add sing-box default
    rc-service sing-box start
    
    # 创建 logrotate 配置文件
    cat <<EOF > /etc/logrotate.d/sing-box
/var/log/sing-box/*.log {
    size 1M
    rotate 5
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        /etc/init.d/sing-box restart > /dev/null
    endscript
}
EOF
    
    # 手动运行 logrotate 以确保配置正确
    logrotate -f /etc/logrotate.d/sing-box
    
    dialog --msgbox "sing-box 安装和配置完成！UUID: $UUID" 10 50
}

# 卸载 sing-box
uninstall_singbox() {
    # 停止并删除服务
    rc-service sing-box stop
    rc-update del sing-box
    
    # 删除文件和目录
    rm -f /usr/local/bin/sing-box
    rm -rf /usr/local/etc/sing-box
    rm -rf /var/log/sing-box
    rm -f /etc/init.d/sing-box
    rm -f /etc/logrotate.d/sing-box
    
    dialog --msgbox "sing-box 卸载完成！" 10 30
}

# 主菜单
while true; do
    CHOICE=$(dialog --clear --title "sing-box 安装程序" \
        --menu "请选择一个操作:" 15 50 4 \
        1 "安装 sing-box (vmess + ws)" \
        2 "卸载 sing-box" \
        3 "查看系统信息" \
        4 "退出" \
        3>&1 1>&2 2>&3 3>&-)
    
    case $CHOICE in
        1)
            install_singbox
            ;;
        2)
            uninstall_singbox
            ;;
        3)
            show_system_info
            ;;
        4)
            break
            ;;
        *)
            dialog --msgbox "无效的选择，请重试。" 10 30
            ;;
    esac
done

# 清理
clear
