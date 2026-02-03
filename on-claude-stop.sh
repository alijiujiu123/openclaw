#!/bin/bash
# Hook 脚本：当 Claude Code 停止时执行

TASK_ID=$1

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      🔔 Hook 触发: Claude Code 已停止                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ 时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📋 任务: $TASK_ID"
echo ""

case $TASK_ID in
    "task_1")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Task 1: Auto-Deployment Skill"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "清理操作:"
        echo "  - 检查是否有残留文件"
        echo "  - 记录失败状态"
        echo ""

        # 检查是否有部分完成的文件
        if [ -d "/usr/local/lib/node_modules/openclaw/skills/auto-deploy" ]; then
            echo "  ⚠️  发现残留目录: auto-deploy"
            ls -la /usr/local/lib/node_modules/openclaw/skills/auto-deploy/ 2>/dev/null || echo "    (空目录或无法访问)"
        fi
        ;;

    "task_2")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Task 2: Docker Image"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "清理操作:"
        echo "  - 检查 Docker 构建缓存"
        echo "  - 记录失败状态"
        echo ""
        ;;

    *)
        echo "未知任务: $TASK_ID"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Hook 执行完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "下一步: 任务管理器将自动继续下一个任务"
