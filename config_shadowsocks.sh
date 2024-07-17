#!/bin/sh

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 提示用户输入监听端口和Host
read -p "请输入监听端口 (listen_port): " LISTEN_PORT

echo -e "${BLUE}生成 用户密码...${NC}"
# 生成用户密码
if [ -x /usr/local/bin/sing-box ]; then
    PASSWORD=$(/usr/local/bin/sing-box generate rand --base64 16)
else
    echo -e "${RED}/usr/local/bin/sing-box 不存在或不可执行${NC}"
    exit 1
fi

echo -e "${BLUE}创建配置文件...${NC}"
# 创建 config.json 文件
cat <<EOF >/usr/local/etc/sing-box/config.json
{
    "inbounds": [
        {
            "listen": "::",
            "listen_port": $LISTEN_PORT,
            "type": "shadowsocks",
            "tag": "ss-in",
            "method": "2022-blake3-aes-128-gcm",
            "password": "$PASSWORD"
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

echo -e "${GREEN}配置文件创建完成！用户密码: $PASSWORD${NC}"
