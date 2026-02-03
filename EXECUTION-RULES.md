# 任务执行规则

## 📋 执行策略

### 1. 顺序执行 ✅
- ✅ 任务依次开始，**不并行**
- 前一个任务完成后才开始下一个
- 如果任务超时，记录到GitHub Issue，然后开始下一个

### 2. 守护任务 ✅
- ⏰ 每30分钟汇报进度
- 📊 显示当前任务状态
- ⚠️ 检查超时任务（4小时限制）

### 3. 超时处理 ✅
- ⏱️ 任务超过4小时未完成 = 超时
- 📝 自动记录到对应的 GitHub Issue 评论
- ⏭️ 跳过当前任务，开始下一个

### 4. 立即开始 ✅
- 🚀 准备完成后立即开始
- 不等待特定时间

---

## 🎯 任务列表

| ID | 任务 | 预期时间 | 超时限制 |
|----|------|----------|----------|
| task_0 | 测试服务器环境准备 | 30分钟 | 1小时 |
| task_1 | Auto-Deployment Skill | 3小时 | 4小时 |
| task_2 | Docker Image | 3小时 | 4小时 |
| task_3 | Daily Briefing System | 4小时 | 4小时 |

---

## 🔧 执行命令

### 立即开始所有任务
```bash
bash /root/.openclaw/workspace/task-manager.sh
```

### 手动检查进度
```bash
bash /root/.openclaw/workspace/progress-monitor.sh
```

### 查看任务状态
```bash
cat /root/.openclaw/workspace/task-tracker.json | jq '.'
```

### 查看执行日志
```bash
tail -f /root/.openclaw/workspace/task-execution.log
```

---

## 📊 进度监控

**守护任务已配置：**
- 每30分钟自动运行 `progress-monitor.sh`
- 汇报当前任务进度
- 检查超时并更新GitHub Issues

**超时处理：**
- 自动检测超过4小时的任务
- 在对应 GitHub Issue 添加评论
- 标记任务为超时状态
- 继续执行下一个任务

---

## 🚀 准备就绪

所有脚本已创建并配置：
- ✅ `task-tracker.json` - 任务跟踪器
- ✅ `task-manager.sh` - 任务管理器
- ✅ `progress-monitor.sh` - 进度监控
- ✅ 30分钟守护任务已配置
- ✅ 超时处理已配置

**立即开始执行！**
