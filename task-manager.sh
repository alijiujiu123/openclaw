#!/bin/bash
# 任务管理器 - 顺序执行任务

TRACKER_FILE="/root/.openclaw/workspace/task-tracker.json"
LOG_FILE="/root/.openclaw/workspace/task-execution.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

start_task() {
    local TASK_ID=$1
    local TASK_NAME=$2
    
    log "🚀 开始任务: $TASK_NAME ($TASK_ID)"
    
    # 更新跟踪器
    jq "
        .task_tracker.current_task = \"$TASK_ID\" |
        .task_tracker.start_time = \"$(date -Iseconds)\" |
        .task_tracker.status = \"running\" |
        (.tasks[] | select(.id == \"$TASK_ID\")) |= {
            status: \"running\",
            start_time: \"$(date -Iseconds)\"
        }
    " $TRACKER_FILE > ${TRACKER_FILE}.tmp
    mv ${TRACKER_FILE}.tmp $TRACKER_FILE
}

complete_task() {
    local TASK_ID=$1
    
    log "✅ 任务完成: $TASK_ID"
    
    # 更新跟踪器
    jq "
        .task_tracker.current_task = null |
        .task_tracker.start_time = null |
        .task_tracker.status = \"ready\" |
        .task_tracker.completed_tasks += [\"$TASK_ID\"] |
        (.tasks[] | select(.id == \"$TASK_ID\")) |= {
            status: \"completed\",
            end_time: \"$(date -Iseconds)\"
        }
    " $TRACKER_FILE > ${TRACKER_FILE}.tmp
    mv ${TRACKER_FILE}.tmp $TRACKER_FILE
}

fail_task() {
    local TASK_ID=$1
    local REASON=$2
    
    log "❌ 任务失败: $TASK_ID - $REASON"
    
    jq "
        .task_tracker.current_task = null |
        .task_tracker.start_time = null |
        .task_tracker.status = \"ready\" |
        .task_tracker.failed_tasks += [\"$TASK_ID\"] |
        (.tasks[] | select(.id == \"$TASK_ID\")) |= {
            status: \"failed\",
            end_time: \"$(date -Iseconds)\"
        }
    " $TRACKER_FILE > ${TRACKER_FILE}.tmp
    mv ${TRACKER_FILE}.tmp $TRACKER_FILE
}

# 主执行流程
execute_tasks() {
    log "╔═══════════════════════════════════════════════════════════════╗"
    log "║      🎯 任务执行管理器 - 顺序执行模式                       ║"
    log "╚═══════════════════════════════════════════════════════════════╝"
    log ""
    
    # 获取所有待执行任务
    TASKS=$(jq -r '.tasks | to_entries[] | select(.value.status == "pending") | .key' $TRACKER_FILE)
    
    for TASK_KEY in $TASKS; do
        TASK_ID=$(jq -r ".tasks[$TASK_KEY].id" $TRACKER_FILE)
        TASK_NAME=$(jq -r ".tasks[$TASK_KEY].name" $TRACKER_FILE)
        
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "准备执行: $TASK_NAME"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        start_task "$TASK_ID" "$TASK_NAME"
        
        # 根据任务ID执行不同逻辑
        case $TASK_ID in
            "task_0")
                bash /root/.openclaw/workspace/prepare-server.sh
                if [ $? -eq 0 ]; then
                    complete_task "$TASK_ID"
                else
                    fail_task "$TASK_ID" "服务器准备失败"
                    continue
                fi
                ;;
            "task_1")
                # Auto-Deployment Skill
                cd /usr/local/lib/node_modules/openclaw/skills
                claude "帮我创建 auto-deploy skill 的完整目录结构和初始代码，参考 /root/.openclaw/workspace/installation-guide.md"
                complete_task "$TASK_ID"
                ;;
            "task_2")
                # Docker Image
                cd /root/openclaw-docker
                mkdir -p /root/openclaw-docker
                claude "帮我创建 Docker 镜像，参考 https://til.simonwillison.net/llms/openclaw-docker"
                complete_task "$TASK_ID"
                ;;
            "task_3")
                # Daily Briefing System
                cd /root/daily-briefing-system
                claude "帮我完成每日简报系统的数据库层和 AI 处理器"
                complete_task "$TASK_ID"
                ;;
            *)
                log "未知任务: $TASK_ID"
                fail_task "$TASK_ID" "未知任务类型"
                ;;
        esac
        
        log "任务 $TASK_NAME 完成，等待5秒后继续..."
        sleep 5
    done
    
    log ""
    log "╔═══════════════════════════════════════════════════════════════╗"
    log "║      ✅ 所有任务执行完成                                     ║"
    log "╚═══════════════════════════════════════════════════════════════╝"
}

# 启动执行
execute_tasks
