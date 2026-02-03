#!/bin/bash
# 在测试服务器上使用代理安装 Docker

SERVER="root@115.191.18.218"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      🐳 通过代理安装 Docker                                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

ssh $SERVER << 'ENDSSH'
# 设置代理环境变量
export http_proxy=socks5h://127.0.0.1:1080
export https_proxy=socks5h://127.0.0.1:1080
export no_proxy=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "环境检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "代理设置:"
echo "  http_proxy=$http_proxy"
echo "  https_proxy=$https_proxy"
echo "  no_proxy=$no_proxy"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "更新 apt (通过代理)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get update
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "安装 Docker (通过代理)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查是否已安装
if command -v docker > /dev/null 2>&1; then
    echo "✅ Docker 已安装: $(docker --version)"
else
    echo "安装 Docker..."
    
    # 安装依赖
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    # 添加 Docker GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.asc
    cat <<EOF > /etc/apt/sources.list.d/docker.list
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF
    
    # 安装 Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    # 启动 Docker
    systemctl start docker
    systemctl enable docker
    
    echo "✅ Docker 安装完成"
    docker --version
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "验证 Docker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker run --rm hello-world
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "最终环境"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Docker: $(docker --version)"
echo "  Node.js: $(node --version)"
echo "  Git: $(git --version)"
echo "  代理: $http_proxy"
ENDSSH
echo ""

echo "✅ 安装完成"
