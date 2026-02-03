#!/bin/bash
# 通过 SSH 隧道为测试服务器提供代理访问
# 内网流量不走代理，外网流量走代理

SERVER="root@115.191.18.218"
PROXY_PORT=1080

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      🌐 配置测试服务器代理访问                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ 时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🖥️  测试服务器: $SERVER"
echo "🔌 代理端口: $PROXY_PORT (SOCKS5)"
echo ""
echo "工作原理："
echo "  1. 创建 SSH 隧道（本地:1080 → 服务器:1080）"
echo "  2. 服务器通过隧道访问外网"
echo "  3. 内网流量直接访问，不走代理"
echo ""

# 检查是否已有 SSH 隧道
if pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT" > /dev/null 2>&1; then
    echo "⚠️  SSH 隧道已存在"
    TUNNEL_PID=$(pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT")
    echo "PID: $TUNNEL_PID"
    echo ""
    read -p "是否重新创建？(y/N): " choice
    if [[ ! $choice =~ ^[Yy]$ ]]; then
        echo "使用现有隧道"
        TUNNEL_PID=$(pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT" | head -1)
    else
        pkill -f "ssh.*-D.*$SERVER.*$PROXY_PORT"
        sleep 1
    fi
fi

# 如果没有隧道，创建新的
if ! pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT" > /dev/null 2>&1; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 1: 创建 SSH 隧道"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "命令: ssh -D $PROXY_PORT -f -C -q -N $SERVER"
    
    # 创建 SSH 隧道（SOCKS5 代理）
    ssh -D $PROXY_PORT -f -C -q -N $SERVER
    
    sleep 2
    
    # 验证隧道
    if pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT" > /dev/null 2>&1; then
        TUNNEL_PID=$(pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT" | head -1)
        echo "✅ SSH 隧道创建成功"
        echo "PID: $TUNNEL_PID"
        echo "本地端口: $PROXY_PORT"
    else
        echo "❌ SSH 隧道创建失败"
        exit 1
    fi
else
    TUNNEL_PID=$(pgrep -f "ssh.*-D.*$SERVER.*$PROXY_PORT" | head -1)
    echo "✅ SSH 隧道已存在"
    echo "PID: $TUNNEL_PID"
fi
echo ""

# 配置测试服务器使用代理
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: 配置测试服务器使用代理"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ssh $SERVER << 'ENDSSH'
# 配置代理环境变量
cat >> ~/.bashrc << 'EOF'

# 代理配置（用于外网访问）
export http_proxy=socks5h://127.0.0.1:1080
export https_proxy=socks5h://127.0.0.1:1080
export no_proxy=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*
export NO_PROXY=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*

# Git 使用代理
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
EOF

# 立即生效
export http_proxy=socks5h://127.0.0.1:1080
export https_proxy=socks5h://127.0.0.1:1080
export no_proxy=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*
export NO_PROXY=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*

echo "✅ 代理配置已添加到 ~/.bashrc"
echo "代理地址: socks5h://127.0.0.1:1080"
echo "内网直连: 192.168.*, 10.*, 172.16.*"
ENDSSH
echo ""

# 测试代理连接
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: 测试代理连接"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ssh $SERVER << 'ENDSSH'
echo "测试外网访问..."
if curl -s --max-time 10 https://www.google.com > /dev/null 2>&1; then
    echo "✅ 外网访问正常（通过代理）"
else
    echo "⚠️  外网访问测试失败"
fi

echo ""
echo "测试 apt 更新..."
if apt-get update > /dev/null 2>&1; then
    echo "✅ apt-get update 成功"
else
    echo "⚠️  apt-get update 部分失败（可能是正常的）"
fi
ENDSSH
echo ""

# 显示管理信息
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      ✅ 代理配置完成                                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "管理命令"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 查看 SSH 隧道状态："
echo "   ps aux | grep 'ssh.*-D.*$SERVER.*$PROXY_PORT'"
echo ""
echo "2. 停止 SSH 隧道："
echo "   pkill -f 'ssh.*-D.*$SERVER.*$PROXY_PORT'"
echo ""
echo "3. 在测试服务器上使用代理："
echo "   ssh $SERVER"
echo "   export http_proxy=socks5h://127.0.0.1:1080"
echo "   curl https://www.google.com"
echo ""
echo "4. 重启代理隧道："
echo "   bash /root/.openclaw/workspace/setup-proxy.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "注意事项"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ 优点："
echo "  - 测试服务器可以访问外网"
echo "  - 内网流量不受影响"
echo "  - 灵活可控"
echo ""
echo "⚠️  限制："
echo "  - 需要保持 SSH 隧道连接"
echo "  - 隧道断开后需重新启动"
echo "  - 本机关机后代理失效"
echo ""
echo "═══════════════════════════════════════════════════════════════"
