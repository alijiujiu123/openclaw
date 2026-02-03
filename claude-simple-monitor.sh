#!/bin/bash
# 简化版 Claude Code 监控脚本
# 当 Claude Code 停止时，继续执行下一个任务

TRACKER_FILE="/root/.openclaw/workspace/task-tracker.json"
LOG_FILE="/root/.openclaw/workspace/claude-simple-monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

check_claude() {
    pgrep -f "claude" > /dev/null 2>&1
    return $?
}

get_current_task() {
    jq -r '.task_tracker.current_task // empty' $TRACKER_FILE 2>/dev/null || echo ""
}

mark_task_failed() {
    local TASK_ID=$1
    log "标记任务失败: $TASK_ID"
    
    # 简单的标记逻辑
    if [ -f "$TRACKER_FILE" ]; then
        jq "(.tasks[] | select(.id == \"$TASK_ID\")) |= .status = \"failed\"" $TRACKER_FILE > ${TRACKER_FILE}.tmp 2>/dev/null
        mv ${TRACKER_FILE}.tmp $TRACKER_FILE 2>/dev/null
    fi
}

continue_next_task() {
    log "启动任务管理器继续执行..."
    nohup bash /root/.openclaw/workspace/task-manager.sh > /tmp/task-manager-auto.log 2>&1 &
}

main() {
    log "简化版 Claude Code 监控启动"
    
    CLAUDE_RUNNING=false
    
    while true; do
        sleep 30
        
        if check_claude; then
            if [ "$CLAUDE_RUNNING" != "true" ]; then
                log "Claude Code 运行中"
                CLAUDE_RUNNING=true
            fi
        else
            if [ "$CLAUDE_RUNNING" == "true" ]; then
                log "Claude Code 已停止！"
                
                CURRENT_TASK=$(get_current_task)
                
                if [ ! -z "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "null" ]; then
                    log "当前任务: $CURRENT_TASK，标记失败并继续"
                    mark_task_failed "$CURRENT_TASK"
                    continue_next_task
                fi
                
                CLAUDE_RUNNING=false
            fi
        fi
    done
}

main
