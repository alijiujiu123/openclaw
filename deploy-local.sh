#!/bin/bash
# 本地下载并部署到测试服务器的辅助脚本

REMOTE="root@115.191.18.218"
TEMP_DIR="/tmp/deploy-cache"

# 创建临时目录
mkdir -p $TEMP_DIR

# 函数：下载并部署
download_and_deploy() {
    local URL=$1
    local REMOTE_PATH=$2
    local INSTALL_CMD=$3
    
    local FILENAME=$(basename "$URL")
    local LOCAL_PATH="$TEMP_DIR/$FILENAME"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 下载: $URL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 本地下载
    cd $TEMP_DIR
    if [ ! -f "$FILENAME" ]; then
        wget -O "$FILENAME" "$URL" || curl -o "$FILENAME" "$URL"
    fi
    
    echo "✅ 下载完成: $LOCAL_PATH"
    
    # 上传到服务器
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📤 上传到服务器: $REMOTE:$REMOTE_PATH"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    scp "$LOCAL_PATH" "$REMOTE:$REMOTE_PATH"
    
    echo "✅ 上传完成"
    
    # 如果提供了安装命令，执行
    if [ ! -z "$INSTALL_CMD" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔧 执行安装命令"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        ssh $REMOTE "cd $(dirname $REMOTE_PATH) && $INSTALL_CMD"
    fi
}

# 示例使用
echo "使用方法："
echo "  bash deploy-local.sh"
echo ""
echo "示例："
echo "  # Docker 安装脚本"
echo "  download_and_deploy \"https://get.docker.com\" \"/tmp/docker-install.sh\" \"bash /tmp/docker-install.sh\""
echo ""
echo "  # Node.js 二进制"
echo "  download_and_deploy \"https://nodejs.org/dist/v22.10.0/node-v22.10.0-linux-x64.tar.xz\" \"/tmp/node.tar.xz\" \"tar -xf /tmp/node.tar.xz -C /usr/local/\""
