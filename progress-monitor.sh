#!/bin/bash
# 进度汇报守护任务 - 每30分钟运行一次

TRACKER_FILE="/root/.openclaw/workspace/task-tracker.json"
GITHUB_TOKEN=$(gh auth token)
CURRENT_TIME=$(date +%s)

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      📊 进度汇报守护任务                                     ║"
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
echo "任务进度:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

jq -r '.tasks[] | "  \(.id): \(.name)\n    状态: \(.status)\n    预期: \(.duration_expected)\n    超时: \(.timeout)"' $TRACKER_FILE

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查超时任务
echo "检查超时..."
jq -r '.tasks[] | select(.status == "running") | "\(.id)|\(.name)|\(.start_time)"' $TRACKER_FILE | while IFS='|' read -r ID NAME START; do
    if [ ! -z "$START" ] && [ "$START" != "null" ]; then
        START_TIMESTAMP=$(date -d "$START" +%s 2>/dev/null || echo $START)
        ELAPSED=$((CURRENT_TIME - START_TIMESTAMP))
        TIMEOUT_HOURS=$(jq -r ".tasks[] | select(.id == \"$ID\") | .timeout" $TRACKER_FILE | sed 's/ hours//')
        TIMEOUT_SECONDS=$((TIMEOUT_HOURS * 3600))
        
        if [ $ELAPSED -gt $TIMEOUT_SECONDS ]; then
            echo "⚠️  任务超时: $NAME (${ELAPSED}秒 > ${TIMEOUT_SECONDS}秒)"
            
            # 记录到 GitHub Issue
            ISSUE_URL=$(jq -r ".tasks[] | select(.id == \"$ID\") | .issue_url // empty" $TRACKER_FILE)
            if [ ! -z "$ISSUE_URL" ]; then
                echo "记录超时到 GitHub Issue: $ISSUE_URL"
                
                COMMENT="## ⚠️ 任务超时报告

**任务:** $NAME  
**超时时间:** $(date '+%Y-%m-%d %H:%M:%S')  
**运行时长:** $((ELAPSED / 3600))小时 $((ELAPSED % 3600 / 60))分钟  
**超时限制:** $TIMEOUT_HOURS 小时

**状态:** 任务已超过时间限制，将跳过并开始下一个任务。

---
*自动报告 - OpenClaw Task Tracker*"
                
                # 提取 issue number
                ISSUE_NUM=$(echo $ISSUE_URL | grep -o '[0-9]*$')
                
                gh issue comment $ISSUE_NUM --body "$COMMENT" --repo alijiujiu123/openclaw
                
                # 更新任务状态为超时
                jq "(.tasks[] | select(.id == \"$ID\")) |= .status = \"timeout\"" $TRACKER_FILE > ${TRACKER_FILE}.tmp
                mv ${TRACKER_FILE}.tmp $TRACKER_FILE
            fi
        fi
    fi
done

echo ""
echo "✅ 进度汇报完成"
echo "下次汇报: $(date -d '+30 minutes' '+%Y-%m-%d %H:%M:%S')"
