#!/bin/bash
# Claude Code 监控守护进程
# 当 Claude Code 停止时，通过 hook 机制通知并继续执行

TRACKER_FILE="/root/.openclaw/workspace/task-tracker.json"
LOG_FILE="/root/.openclaw/workspace/claude-monitor.log"
HOOK_SCRIPT="/root/.openclaw/workspace/on-claude-stop.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

check_claude() {
    pgrep -f "claude" > /dev/null 2>&1
    return $?
}

get_current_task() {
    jq -r '.task_tracker.current_task // empty' $TRACKER_FILE
}

mark_task_failed() {
    local TASK_ID=$1
    local REASON="Claude Code 进程停止运行"

    log "❌ 标记任务失败: $TASK_ID - $REASON"

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

trigger_hook() {
    local TASK_ID=$1

    log "🔔 触发 hook: Claude Code 停止"

    # 执行 hook 脚本（如果存在）
    if [ -f "$HOOK_SCRIPT" ]; then
        log "执行 hook 脚本: $HOOK_SCRIPT"
        bash "$HOOK_SCRIPT" "$TASK_ID"
    fi

    # 记录到 GitHub Issue（如果配置了）
    local ISSUE_URL=$(jq -r ".github_issues.auto_deploy // empty" $TRACKER_FILE)
    if [ ! -z "$ISSUE_URL" ] && [ "$TASK_ID" == "task_1" ]; then
        local ISSUE_NUM=$(echo $ISSUE_URL | grep -o '[0-9]*$')
        local COMMENT="## ⚠️ Claude Code 停止运行

**任务:** Auto-Deployment Skill ($TASK_ID)
**停止时间:** $(date '+%Y-%m-%d %H:%M:%S')
**原因:** Claude Code 进程意外终止

**处理:** 任务已标记为失败，自动跳过并继续下一个任务。

---
*自动监控 - OpenClaw Claude Monitor*"

        log "记录到 GitHub Issue #$ISSUE_NUM"
        gh issue comment $ISSUE_NUM --body "$COMMENT" --repo alijiujiu123/openclaw 2>/dev/null || log "GitHub API 调用失败"
    fi
}

continue_next_task() {
    log "🚀 继续执行下一个任务"
    nohup bash /root/.openclaw/workspace/task-manager.sh > /tmp/task-manager-restart.log 2>&1 &
}

main() {
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Claude Code 监控守护进程启动"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 检查 Claude Code 初始状态
    if check_claude; then
        log "✅ Claude Code 正在运行"
        CLAUDE_RUNNING=true
    else
        log "⚠️  Claude Code 未运行"
        CLAUDE_RUNNING=false
    fi

    # 监控循环
    while true; do
        sleep 30  # 每30秒检查一次

        if check_claude; then
            if [ "$CLAUDE_RUNNING" != "true" ]; then
                log "✅ Claude Code 已启动"
                CLAUDE_RUNNING=true
            fi
        else
            if [ "$CLAUDE_RUNNING" == "true" ]; then
                log "❌ Claude Code 已停止！"

                # 获取当前任务
                CURRENT_TASK=$(get_current_task)

                if [ ! -z "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "null" ]; then
                    log "当前任务: $CURRENT_TASK"

                    # 标记任务失败
                    mark_task_failed "$CURRENT_TASK"

                    # 触发 hook
                    trigger_hook "$CURRENT_TASK"

                    # 继续下一个任务
                    continue_next_task
                else
                    log "没有活动的任务，跳过"
                fi

                CLAUDE_RUNNING=false
            fi
        fi
    done
}

# 启动监控
main
