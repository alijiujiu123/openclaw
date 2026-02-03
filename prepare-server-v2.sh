#!/bin/bash
# 测试服务器环境准备脚本 - 网络隔离版本
# 使用本地下载 + SCP 上传的方式

SERVER="root@115.191.18.218"
ZHIPU_API_KEY="3101936be6b740899ae7aff4b84807e9.4glgTOraFrWS6wqA"
LOCAL_CACHE="/tmp/docker-deploy-cache"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      🚀 测试服务器环境准备 - 网络隔离版本                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🖥️  目标服务器: $SERVER"
echo "📦 部署模式: 本地下载 → SCP上传 → 服务器安装"
echo ""

# 创建本地缓存目录
mkdir -p $LOCAL_CACHE

# Step 1: 测试 SSH 连接
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: 测试 SSH 连接"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ssh -o ConnectTimeout=10 $SERVER "echo 'SSH 连接成功'" > /dev/null 2>&1; then
    echo "✅ SSH 连接正常"
else
    echo "❌ SSH 连接失败"
    exit 1
fi
echo ""

# Step 2: 本地下载 Docker 安装脚本
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: 本地下载 Docker 安装脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd $LOCAL_CACHE

if [ ! -f "get-docker.sh" ]; then
    echo "下载 get-docker.sh..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    if [ $? -eq 0 ]; then
        echo "✅ 下载完成"
    else
        echo "❌ 下载失败，尝试使用阿里云镜像..."
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg -o docker-keyring
    fi
else
    echo "✅ 文件已存在"
fi
echo ""

# Step 3: 上传到服务器
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: 上传到服务器"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
scp $LOCAL_CACHE/get-docker.sh $SERVER:/tmp/get-docker.sh
if [ $? -eq 0 ]; then
    echo "✅ 上传成功"
else
    echo "❌ 上传失败"
    exit 1
fi
echo ""

# Step 4: 在服务器上安装 Docker
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: 在服务器上安装 Docker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SERVER << 'ENDSSH'
# 检查 Docker 是否已安装
if command -v docker > /dev/null 2>&1; then
    echo "✅ Docker 已安装: $(docker --version)"
else
    echo "⚠️  Docker 未安装，开始安装..."
    
    # 安装依赖
    apt-get update > /dev/null 2>&1
    apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1
    
    # 安装 Docker
    sh /tmp/get-docker.sh
    
    # 启动 Docker
    systemctl start docker
    systemctl enable docker
    
    if command -v docker > /dev/null 2>&1; then
        echo "✅ Docker 安装成功: $(docker --version)"
    else
        echo "❌ Docker 安装失败"
        exit 1
    fi
fi
ENDSSH
echo ""

# Step 5: 验证环境
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: 验证环境"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SERVER << 'ENDSSH'
echo ""
echo "环境信息："
echo "  操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  CPU 核心: $(nproc)"
echo "  内存: $(free -h | grep Mem | awk '{print $2}')"
echo "  磁盘: $(df -h / | tail -1 | awk '{print $4}') 可用"
echo ""
echo "软件版本："
echo "  Docker: $(docker --version 2>/dev/null || echo '未安装')"
echo "  Node.js: $(node --version 2>/dev/null || echo '未安装')"
echo "  Git: $(git --version 2>/dev/null || echo '未安装')"
echo ""
echo "服务状态："
echo "  Docker: $(systemctl is-active docker 2>/dev/null || echo '未运行')"
ENDSSH
echo ""

# Step 6: 配置 API Key
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: 配置智谱 API Key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SERVER "echo 'export ZHIPU_API_KEY=$ZHIPU_API_KEY' >> ~/.bashrc"
echo "✅ API Key 已配置到 ~/.bashrc"
echo ""

# Step 7: 创建工作目录
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 7: 创建工作目录"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SERVER "mkdir -p /root/projects && mkdir -p /root/openclaw"
echo "✅ 工作目录已创建"
echo ""

# 完成
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      ✅ 环境准备完成！                                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ 完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "环境摘要："
ssh $SERVER << 'ENDSSH'
echo "  ✅ Docker: $(docker --version 2>/dev/null || echo '未安装')"
echo "  ✅ Node.js: $(node --version 2>/dev/null || echo '未安装')"
echo "  ✅ Git: $(git --version 2>/dev/null || echo '未安装')"
echo "  ✅ API Key: 已配置"
ENDSSH
echo ""
echo "下一步："
echo "  1. Auto-Deployment Skill 开发"
echo "  2. Docker Image 构建"
echo "  3. Daily Briefing System 部署"
echo ""
echo "快速连接："
echo "  ssh $SERVER"
echo ""
