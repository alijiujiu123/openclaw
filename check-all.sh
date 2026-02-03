#!/bin/bash
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      📊 系统状态总览                                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo "⏰ 时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Claude Code 状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if pgrep -f "claude" > /dev/null 2>&1; then
    CLAUDE_PID=$(pgrep -f "claude" | head -1)
    CLAUDE_MEM=$(ps -p $CLAUDE_PID -o rss= | awk '{print int($1/1024)"MB"}')
    echo "  ✅ Claude Code 正在运行"
    echo "  PID: $CLAUDE_PID"
    echo "  内存: $CLAUDE_MEM"
else
    echo "  ❌ Claude Code 未运行"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  监控进程状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if pgrep -f "claude-simple-monitor" > /dev/null 2>&1; then
    MONITOR_PID=$(pgrep -f "claude-simple-monitor")
    echo "  ✅ 监控脚本正在运行"
    echo "  PID: $MONITOR_PID"
    echo "  检查间隔: 30秒"
else
    echo "  ❌ 监控脚本未运行"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  任务管理器状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if pgrep -f "task-manager" > /dev/null 2>&1; then
    TM_PID=$(pgrep -f "task-manager")
    echo "  ✅ 任务管理器正在运行"
    echo "  PID: $TM_PID"
else
    echo "  ⏸️  任务管理器未运行（等待 Claude Code 完成或停止）"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  当前任务"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /root/.openclaw/workspace/task-tracker.json ]; then
    CURRENT_TASK=$(jq -r '.task_tracker.current_task // "无"' /root/.openclaw/workspace/task-tracker.json)
    TASK_STATUS=$(jq -r '.task_tracker.status // "unknown"' /root/.openclaw/workspace/task-tracker.json)
    echo "  当前任务: $CURRENT_TASK"
    echo "  状态: $TASK_STATUS"
    
    if [ "$CURRENT_TASK" != "null" ] && [ ! -z "$CURRENT_TASK" ]; then
        START_TIME=$(jq -r '.task_tracker.start_time // empty' /root/.openclaw/workspace/task-tracker.json)
        if [ ! -z "$START_TIME" ] && [ "$START_TIME" != "null" ]; then
            CURRENT_TIME=$(date +%s)
            START_TIMESTAMP=$(date -d "$START_TIME" +%s 2>/dev/null || echo $START_TIME)
            ELAPSED=$((CURRENT_TIME - START_TIMESTAMP))
            HOURS=$((ELAPSED / 3600))
            MINUTES=$(((ELAPSED % 3600) / 60))
            echo "  已运行: ${HOURS}小时${MINUTES}分钟"
        fi
    fi
else
    echo "  ⚠️  无法读取任务状态"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  最近的日志"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /root/.openclaw/workspace/claude-simple-monitor.log ]; then
    echo "  监控日志（最后3行）:"
    tail -3 /root/.openclaw/workspace/claude-simple-monitor.log | sed 's/^/    /'
else
    echo "  (无日志文件)"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "✅ 状态检查完成"
echo "═══════════════════════════════════════════════════════════════"
