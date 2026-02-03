#!/bin/bash
# 手动汇报当前进度

TRACKER_FILE="/root/.openclaw/workspace/task-tracker.json"
CURRENT_TIME=$(date +%s)

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      📊 任务进度汇报 - 手动触发                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ 时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 读取任务跟踪器
CURRENT_TASK=$(jq -r '.task_tracker.current_task' $TRACKER_FILE)
STATUS=$(jq -r '.task_tracker.status' $TRACKER_FILE)
START_TIME=$(jq -r '.task_tracker.start_time // empty' $TRACKER_FILE)

echo "📈 当前状态:"
echo "  当前任务: $CURRENT_TASK"
echo "  状态: $STATUS"

if [ ! -z "$START_TIME" ] && [ "$START_TIME" != "null" ]; then
    START_TIMESTAMP=$(date -d "$START_TIME" +%s 2>/dev/null || echo $START_TIME)
    ELAPSED=$((CURRENT_TIME - START_TIMESTAMP))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    echo "  已运行: ${HOURS}小时${MINUTES}分钟"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "任务详情:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

jq -r '.tasks[] | "
\(.id // "N/A"): \(.name // "未命名")
  状态: \(.status)
  预期: \(.duration_expected // "未知")
  超时: \(.timeout // "未知")
  开始: \(.start_time // "未开始")
  结束: \(.end_time // "进行中")"' $TRACKER_FILE

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查超时任务
echo "检查超时..."
jq -r '.tasks[] | select(.status == "running") | "\(.id // "N/A")|\(.name // "未命名")|\(.start_time // "null")"' $TRACKER_FILE | while IFS='|' read -r ID NAME START; do
    if [ ! -z "$START" ] && [ "$START" != "null" ]; then
        START_TIMESTAMP=$(date -d "$START" +%s 2>/dev/null || echo $START)
        ELAPSED=$((CURRENT_TIME - START_TIMESTAMP))
        TIMEOUT_HOURS=$(jq -r ".tasks[] | select(.id == \"$ID\" or .id == empty) | .timeout // \"4 hours\"" $TRACKER_FILE | sed 's/ hours//')
        TIMEOUT_SECONDS=$((TIMEOUT_HOURS * 3600))
        
        if [ $ELAPSED -gt $TIMEOUT_SECONDS ]; then
            echo "⚠️  任务超时: $NAME"
            echo "   运行时长: $((ELAPSED / 3600))小时 $((ELAPSED % 3600 / 60))分钟"
            echo "   超时限制: $TIMEOUT_HOURS 小时"
        else
            echo "✓ $NAME 正常运行中 (${ELAPSED}s / ${TIMEOUT_SECONDS}s)"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "进程状态:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ps aux | grep -E "claude|task-manager" | grep -v grep | awk '{printf "  %-15s PID:%-6s MEM:%sMB CPU:%s%%\n", $11, $2, int($6/1024), $3}'

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ 进度汇报完成"
echo "═══════════════════════════════════════════════════════════════"
