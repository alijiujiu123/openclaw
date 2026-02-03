# Claude Code 监控守护进程

## 🎯 功能

自动监控 Claude Code 进程，当检测到停止时：

1. ✅ **自动检测** - 每30秒检查一次
2. ✅ **触发 Hook** - 执行自定义脚本
3. ✅ **标记失败** - 更新任务状态
4. ✅ **GitHub 记录** - 在 Issue 添加评论
5. ✅ **继续执行** - 自动开始下一个任务

---

## 📁 文件说明

### 1. claude-monitor.sh
**主监控脚本** - 后台运行，持续监控 Claude Code

功能：
- 检测 Claude Code 进程
- 识别进程停止
- 触发 hook
- 更新任务跟踪器
- 继续执行下一个任务

### 2. on-claude-stop.sh
**Hook 脚本** - 当 Claude Code 停止时执行

功能：
- 清理残留文件
- 记录失败原因
- 准备继续执行

### 3. start-claude-monitor.sh
**启动脚本** - 启动监控守护进程

### 4. CLAUDE-MONITOR-README.md
**文档** - 本文件

---

## 🚀 使用方法

### 启动监控
```bash
bash /root/.openclaw/workspace/start-claude-monitor.sh
```

### 查看状态
```bash
# 检查进程
ps aux | grep claude-monitor

# 查看日志
tail -f /root/.openclaw/workspace/claude-monitor.log

# 查看完整输出
cat /root/.openclaw/workspace/claude-monitor.out
```

### 停止监控
```bash
pkill -f claude-monitor.sh
```

### 重启监控
```bash
pkill -f claude-monitor.sh
bash /root/.openclaw/workspace/start-claude-monitor.sh
```

---

## 🔄 工作流程

```
Claude Code 运行中
        ↓
监控脚本每30秒检查
        ↓
检测到进程停止
        ↓
触发 hook (on-claude-stop.sh)
        ↓
标记当前任务失败
        ↓
记录到 GitHub Issue
        ↓
启动 task-manager.sh
        ↓
继续下一个任务
```

---

## 📊 监控日志

日志位置：`/root/.openclaw/workspace/claude-monitor.log`

示例输出：
```
[2026-02-02 21:30:00] Claude Code 监控守护进程启动
[2026-02-02 21:30:00] ✅ Claude Code 正在运行
[2026-02-02 21:32:30] ❌ Claude Code 已停止！
[2026-02-02 21:32:30] 当前任务: task_1
[2026-02-02 21:32:30] ❌ 标记任务失败: task_1
[2026-02-02 21:32:30] 🔔 触发 hook: Claude Code 停止
[2026-02-02 21:32:30] 🚀 继续执行下一个任务
```

---

## ⚙️ 自定义 Hook

编辑 `on-claude-stop.sh` 来自定义停止时的行为：

```bash
case $TASK_ID in
    "task_1")
        # Task 1 的自定义处理
        echo "清理 Task 1 残留文件"
        ;;
    "task_2")
        # Task 2 的自定义处理
        echo "清理 Task 2 残留文件"
        ;;
esac
```

---

## 🎯 当前状态

**监控进程 PID:** 1145274
**启动时间:** 已运行
**状态:** ✅ 活跃

**监控目标:** Claude Code (PID: 1119631)

---

## 📝 与任务管理器的集成

### 正常流程
```
task-manager.sh 启动任务
        ↓
启动 Claude Code
        ↓
Claude Code 处理任务
        ↓
Claude Code 完成
        ↓
task-manager.sh 继续下一个任务
```

### 异常流程（监控介入）
```
Claude Code 运行中
        ↓
Claude Code 意外停止
        ↓
claude-monitor.sh 检测到
        ↓
触发 hook
        ↓
标记任务失败
        ↓
重启 task-manager.sh
        ↓
继续下一个任务
```

---

## 🔧 故障排除

### 监控未检测到停止
```bash
# 检查监控进程是否运行
ps aux | grep claude-monitor

# 检查日志
tail -50 /root/.openclaw/workspace/claude-monitor.log

# 手动测试检测
pgrep -f "claude" && echo "运行中" || echo "已停止"
```

### Hook 未执行
```bash
# 手动测试 hook
bash /root/.openclaw/workspace/on-claude-stop.sh task_1

# 检查权限
ls -la /root/.openclaw/workspace/on-claude-stop.sh
```

### 任务未继续
```bash
# 检查 task-manager
ps aux | grep task-manager

# 手动启动
bash /root/.openclaw/workspace/task-manager.sh
```

---

**创建时间:** 2026-02-02 21:33
**状态:** ✅ 运行中
