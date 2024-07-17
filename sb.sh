#!/bin/sh

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 安装必要工具
echo -e "${BLUE}更新软件包列表并安装必要工具...${NC}"
apk update
apk add wget logrotate curl

# 获取系统信息
get_system_info() {
    HOSTNAME=$(hostname)
    OS=$(uname -s)
    KERNEL=$(uname -r)
    UPTIME=$(uptime)
    DATE=$(date)
    MEMORY=$(free -m | awk '/Mem:/ {print $3 "MB / " $2 "MB"}')
    CPU=$(grep 'model name' /proc/cpuinfo | uniq | awk -F: '{print $2}')
    DISK=$(df -h / | awk '/\// {print $3 " / " $2}')
}

# 显示系统信息
show_system_info() {
    get_system_info
    echo -e "${GREEN}系统信息:${NC}"
    echo -e "${YELLOW}主机名: ${NC}$HOSTNAME"
    echo -e "${YELLOW}操作系统: ${NC}$OS"
    echo -e "${YELLOW}内核版本: ${NC}$KERNEL"
    echo -e "${YELLOW}运行时间: ${NC}$UPTIME"
    echo -e "${YELLOW}当前时间: ${NC}$DATE"
    echo -e "${YELLOW}内存使用: ${NC}$MEMORY"
    echo -e "${YELLOW}CPU: ${NC}$CPU"
    echo -e "${YELLOW}硬盘使用: ${NC}$DISK"
}

# 显示系统信息
show_system_info

# 主菜单
while true; do
    echo -e "${BLUE}sing-box 安装程序${NC}"
    echo -e "${GREEN}1. 安装 sing-box (vmess + ws)${NC}"
    echo -e "${GREEN}2. 卸载 sing-box${NC}"
    echo -e "${GREEN}3. 退出${NC}"
    read -p "请选择一个操作: " CHOICE

    case $CHOICE in
    1)
        install_singbox() {
            echo -e "${BLUE}开始安装 sing-box...${NC}"

            # 设置版本号
            LATEST_RELEASE=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep "tag_name" | cut -d '"' -f 4)

            if [ -z "$LATEST_RELEASE" ]; then
                echo -e "${RED}无法自动获取最新版本号，请手动输入版本号。${NC}"
                read -p "请输入您想要安装的版本号（例如：1.9.3）: " VERSION
            else
                VERSION=${LATEST_RELEASE#v} # 去掉版本号前的 'v'
                # 提示用户确认版本
                echo -e "${YELLOW}检测到最新版本为: $LATEST_RELEASE${NC}"
                read -p "是否使用该版本？[Y/n] " use_latest

                if [[ "$use_latest" == "n" || "$use_latest" == "N" ]]; then
                    read -p "请输入您想要安装的版本号（例如：1.9.3）: " VERSION
                fi
            fi

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
                echo -e "${RED}不支持的架构: $ARCH${NC}"
                exit 1
                ;;
            esac

            # 拼接下载地址
            DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/v${VERSION}/sing-box-${VERSION}-${OS}-${ARCH}.tar.gz"

            echo -e "${BLUE}下载 sing-box...${NC}"
            # 下载文件
            wget $DOWNLOAD_URL -O sing-box-${VERSION}-${OS}-${ARCH}.tar.gz

            # 检查下载是否成功
            if [ $? -ne 0 ]; then
                echo -e "${RED}下载失败: $DOWNLOAD_URL${NC}"
                exit 1
            fi

            echo -e "${BLUE}解压 sing-box...${NC}"
            # 解压下载的文件
            tar -zxvf sing-box-${VERSION}-${OS}-${ARCH}.tar.gz

            # 检查解压后的目录是否存在
            if [ -d "sing-box-${VERSION}-${OS}-${ARCH}" ]; then
                cd "sing-box-${VERSION}-${OS}-${ARCH}"
            fi

            echo -e "${BLUE}移动 sing-box 文件...${NC}"
            # 移动解压出的sing-box文件到/usr/local/bin
            if [ -f sing-box ]; then
                mv sing-box /usr/local/bin/
            else
                echo -e "${RED}解压后的sing-box文件不存在${NC}"
                exit 1
            fi

            # 返回上级目录
            cd ..

            # 清理下载的tar.gz文件
            rm -rf "sing-box-${VERSION}-${OS}-${ARCH}"
            rm sing-box-${VERSION}-${OS}-${ARCH}.tar.gz

            echo -e "${BLUE}创建配置文件目录...${NC}"
            # 创建配置文件目录
            mkdir -p /usr/local/etc/sing-box

            echo -e "${BLUE}安装完成！${NC}"
            read -p "是否现在创建配置文件？[Y/n] " create_config

            if [[ "$create_config" == "Y" || "$create_config" == "y" || "$create_config" == "" ]]; then
                echo -e "${BLUE}请选择配置文件类型:${NC}"
                echo -e "${GREEN}1. vmess+ws${NC}"
                echo -e "${GREEN}2. shadowsocks${NC}"
                echo -e "${GREEN}3. vless+reality${NC}"
                echo -e "${GREEN}4. Hysteria 2${NC}"
                read -p "请输入选择的数字 (1-4): " config_choice

                case $config_choice in
                1)
                    wget https://raw.githubusercontent.com/hanxin-menglei/singbox-alpine/main/config_vmess_ws.sh -O config_vmess_ws.sh && chmod +x config_vmess_ws.sh && ./config_vmess_ws.sh
                    ;;
                2)
                    wget https://raw.githubusercontent.com/hanxin-menglei/singbox-alpine/main/config_shadowsocks.sh -O config_shadowsocks.sh && chmod +x config_shadowsocks.sh && ./config_shadowsocks.sh
                    ;;
                3)
                    /path/to/config_vless_reality.sh
                    ;;
                4)
                    /path/to/config_hysteria2.sh
                    ;;
                *)
                    echo -e "${RED}无效的选择，请手动运行配置脚本。${NC}"
                    ;;
                esac
            fi

            echo -e "${BLUE}创建日志目录...${NC}"
            # 创建日志目录
            mkdir -p /var/log/sing-box

            echo -e "${BLUE}创建 OpenRC 服务脚本...${NC}"
            # 创建 OpenRC 服务脚本
            if [ -d /etc/init.d ]; then
                cat <<EOF >/etc/init.d/sing-box
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
            else
                echo -e "${RED}/etc/init.d 目录不存在${NC}"
                exit 1
            fi

            echo -e "${BLUE}赋予服务脚本执行权限...${NC}"
            # 赋予服务脚本执行权限
            if [ -f /etc/init.d/sing-box ]; then
                chmod +x /etc/init.d/sing-box
            else
                echo -e "${RED}/etc/init.d/sing-box 文件不存在${NC}"
                exit 1
            fi

            echo -e "${BLUE}添加并启动 sing-box 服务...${NC}"
            # 添加服务到 OpenRC 并启动服务
            rc-update add sing-box default
            rc-service sing-box start

            echo -e "${BLUE}创建 logrotate 配置文件...${NC}"
            # 创建 logrotate 配置文件
            if [ -d /etc/logrotate.d ]; then
                cat <<EOF >/etc/logrotate.d/sing-box
/var/log/sing-box/*.log {
    size 1M
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
    sharedscripts
}
EOF
            else
                echo -e "${RED}/etc/logrotate.d 目录不存在${NC}"
                exit 1
            fi

            echo -e "${BLUE}手动运行 logrotate 以确保配置正确...${NC}"
            # 手动运行 logrotate 以确保配置正确
            if command -v logrotate >/dev/null 2>&1; then
                logrotate -f /etc/logrotate.d/sing-box
            else
                echo -e "${RED}logrotate 命令不存在${NC}"
                exit 1
            fi

            echo -e "${GREEN}sing-box 安装和配置完成！${NC}"
        }
        install_singbox
        ;;
    2)
        uninstall_singbox() {
            echo -e "${BLUE}开始卸载 sing-box...${NC}"

            # 停止并删除服务
            echo -e "${BLUE}停止并删除 sing-box 服务...${NC}"
            rc-service sing-box stop
            rc-update del sing-box

            # 删除文件和目录
            echo -e "${BLUE}删除文件和目录...${NC}"
            rm -f /usr/local/bin/sing-box
            rm -rf /usr/local/etc/sing-box
            rm -rf /var/log/sing-box
            rm -f /etc/init.d/sing-box
            rm -f /etc/logrotate.d/sing-box

            echo -e "${GREEN}sing-box 卸载完成！${NC}"
        }
        uninstall_singbox
        ;;
    3)
        break
        ;;
    *)
        echo -e "${RED}无效的选择，请重试。${NC}"
        ;;
    esac
done

# 清理
clear
