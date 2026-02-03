#!/bin/bash
# 测试服务器环境准备脚本

SERVER="root@115.191.18.218"
ZHIPU_API_KEY="3101936be6b740899ae7aff4b84807e9.4glgTOraFrWS6wqA"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      🚀 测试服务器环境准备 - 开始                           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🖥️  目标服务器: $SERVER"
echo ""

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

# Step 2: 上传检查脚本
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: 上传环境检查脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
scp /root/.openclaw/workspace/check-env.sh $SERVER:/tmp/check-env.sh
if [ $? -eq 0 ]; then
    echo "✅ 检查脚本已上传"
else
    echo "❌ 上传失败"
    exit 1
fi
echo ""

# Step 3: 运行环境检查
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: 运行环境检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SERVER "bash /tmp/check-env.sh"
echo ""

# Step 4: 检查并安装 Docker
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: 检查 Docker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! ssh $SERVER "command -v docker" > /dev/null 2>&1; then
    echo "⚠️  Docker 未安装，开始安装..."
    ssh $SERVER "curl -fsSL https://get.docker.com | sh"
    ssh $SERVER "systemctl start docker && systemctl enable docker"
    echo "✅ Docker 安装完成"
else
    echo "✅ Docker 已安装: $(ssh $SERVER 'docker --version')"
fi
echo ""

# Step 5: 检查 Node.js
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: 检查 Node.js 版本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
NODE_VERSION=$(ssh $SERVER "node --version 2>/dev/null" || echo "not installed")
if [[ "$NODE_VERSION" == "v22"* ]]; then
    echo "✅ Node.js 版本符合要求: $NODE_VERSION"
elif [[ "$NODE_VERSION" == "not installed" ]]; then
    echo "⚠️  Node.js 未安装，开始安装 v22..."
    ssh $SERVER "curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - && yum install -y nodejs"
    echo "✅ Node.js 安装完成: $(ssh $SERVER 'node --version')"
else
    echo "⚠️  Node.js 版本过低: $NODE_VERSION，需要升级到 v22+"
    echo "建议: curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - && yum install -y nodejs"
fi
echo ""

# Step 6: 检查 Git
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: 检查 Git"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ssh $SERVER "command -v git" > /dev/null 2>&1; then
    echo "✅ Git 已安装: $(ssh $SERVER 'git --version')"
else
    echo "⚠️  Git 未安装，开始安装..."
    ssh $SERVER "yum install -y git"
    echo "✅ Git 安装完成"
fi
echo ""

# Step 7: 配置环境变量
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 7: 配置智谱 API Key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SERVER "echo 'export ZHIPU_API_KEY=$ZHIPU_API_KEY' >> ~/.bashrc"
echo "✅ API Key 已配置到 ~/.bashrc"
echo ""

# Step 8: 验证环境
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 8: 最终验证"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "环境信息："
ssh $SERVER << 'EOF'
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
EOF
echo ""

# Step 9: 创建工作目录
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 9: 创建工作目录"
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
echo "下一步："
echo "  1. Auto-Deployment Skill 开发"
echo "  2. Docker Image 构建"
echo "  3. Daily Briefing System 部署"
echo ""
echo "快速连接："
echo "  ssh $SERVER"
echo ""
