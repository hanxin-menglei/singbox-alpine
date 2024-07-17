#!/bin/sh

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 提示用户输入监听端口和Host
read -p "请输入监听端口 (listen_port): " LISTEN_PORT
read -p "请输入 Host: " HOST

echo -e "${BLUE}生成 UUID...${NC}"
# 生成UUID
if [ -x /usr/local/bin/sing-box ]; then
    UUID=$(/usr/local/bin/sing-box generate uuid)
else
    echo -e "${RED}/usr/local/bin/sing-box 不存在或不可执行${NC}"
    exit 1
fi

echo -e "${BLUE}创建配置文件...${NC}"
# 创建 config.json 文件
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
                "max_early_data": 2048,
                "early_data_header_name": "Sec-WebSocket-Protocol"
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

echo -e "${GREEN}配置文件创建完成！UUID: $UUID${NC}"
