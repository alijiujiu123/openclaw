#!/bin/bash
# 启动 Claude Code 监控守护进程

echo "启动 Claude Code 监控守护进程..."
echo ""

# 检查是否已经在运行
if pgrep -f "claude-monitor.sh" > /dev/null; then
    echo "⚠️  监控进程已在运行"
    echo "PID: $(pgrep -f 'claude-monitor.sh')"
    echo ""
    echo "如需重启，请先 kill 掉旧进程:"
    echo "  pkill -f claude-monitor.sh"
    exit 1
fi

# 后台启动监控
nohup bash /root/.openclaw/workspace/claude-monitor.sh > /root/.openclaw/workspace/claude-monitor.out 2>&1 &

MONITOR_PID=$!
sleep 1

# 验证启动成功
if ps -p $MONITOR_PID > /dev/null; then
    echo "✅ 监控守护进程已启动"
    echo "PID: $MONITOR_PID"
    echo ""
    echo "日志文件:"
    echo "  - 标准输出: /root/.openclaw/workspace/claude-monitor.out"
    echo "  - 监控日志: /root/.openclaw/workspace/claude-monitor.log"
    echo ""
    echo "停止监控:"
    echo "  pkill -f claude-monitor.sh"
    echo "  或 kill $MONITOR_PID"
    echo ""
    echo "查看实时日志:"
    echo "  tail -f /root/.openclaw/workspace/claude-monitor.log"
else
    echo "❌ 启动失败"
    exit 1
fi
