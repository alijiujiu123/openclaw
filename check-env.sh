#!/bin/bash

echo "═══════════════════════════════════════════════════════════════"
echo "         环境检查 - 测试部署服务器"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  系统信息"
echo "   操作系统: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "   内核版本: $(uname -r)"
echo "   架构: $(uname -m)"
echo ""

echo "2️⃣  硬件资源"
echo "   CPU 核心: $(nproc)"
echo "   内存总量: $(free -h | grep Mem | awk '{print $2}')"
echo "   磁盘空间: $(df -h / | tail -1 | awk '{print $4}') 可用"
echo ""

echo "3️⃣  Docker"
if command -v docker &> /dev/null; then
    echo "   ✅ Docker: $(docker --version)"
    if systemctl is-active --quiet docker; then
        echo "   ✅ Docker 服务运行中"
    else
        echo "   ❌ Docker 服务未运行"
    fi
else
    echo "   ❌ Docker 未安装"
fi

if command -v docker-compose &> /dev/null; then
    echo "   ✅ Docker Compose: $(docker-compose --version)"
else
    echo "   ❌ Docker Compose 未安装"
fi
echo ""

echo "4️⃣  Node.js"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   Node.js: $NODE_VERSION"
    if [[ "$NODE_VERSION" == "v22"* ]]; then
        echo "   ✅ 版本符合要求 (22+)"
    else
        echo "   ⚠️  版本过低，需要 v22+"
    fi
    echo "   npm: $(npm --version)"
else
    echo "   ❌ Node.js 未安装"
fi
echo ""

echo "5️⃣  Git"
if command -v git &> /dev/null; then
    echo "   ✅ Git: $(git --version)"
else
    echo "   ❌ Git 未安装"
fi
echo ""

echo "6️⃣  systemd"
if command -v systemctl &> /dev/null; then
    echo "   ✅ systemd 可用"
else
    echo "   ⚠️  systemd 不可用"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "检查完成！"
echo "═══════════════════════════════════════════════════════════════"
