# Claude Code + Superpowers 使用指南

## ✅ 已完成配置

### 1. Claude Code 安装
- 版本: 2.1.29
- 位置: /usr/local/bin/claude
- 配置: ~/.claude/

### 2. Superpowers 技能已安装
14 个开发工作流技能：

**📋 规划阶段**
- brainstorming - 头脑风暴
- writing-plans - 编写计划

**🚀 开发阶段**
- executing-plans - 执行计划
- subagent-driven-development - 子代理驱动开发
- test-driven-development - 测试驱动开发
- systematic-debugging - 系统化调试
- using-git-worktrees - 使用 git worktrees

**👥 协作阶段**
- dispatching-parallel-agents - 调度并行代理
- receiving-code-review - 接收代码审查
- requesting-code-review - 请求代码审查

**✅ 完成阶段**
- finishing-a-development-branch - 完成开发分支
- verification-before-completion - 完成前验证

**🛠️ 其他**
- writing-skills - 编写技能
- using-superpowers - 使用指南

## 🎯 开发任务

### 任务 1: Auto-Deployment Skill (20:30-23:30)

**启动命令：**
```bash
cd /usr/local/lib/node_modules/openclaw/skills
claude "帮我创建 auto-deploy skill 的完整目录结构"
```

**开发要点：**
- 参考 installation-guide.md
- 创建检测器、安装器、配置器
- 实现验证测试
- 支持 OpenCloudOS/RHEL/CentOS/Ubuntu

### 任务 2: Docker Image (23:30-02:30)

**启动命令：**
```bash
cd /root/openclaw-docker
claude "帮我创建优化的 Dockerfile 和 docker-compose.yml"
```

**开发要点：**
- Multi-stage 构建
- 多架构支持 (amd64/arm64)
- 环境变量配置
- 健康检查

### 任务 3: Daily Briefing System (02:30-06:30)

**启动命令：**
```bash
cd /root/daily-briefing-system
claude "帮我完成数据库层和 AI 处理器"
```

**开发要点：**
- SQLite 数据库
- 智谱 API 集成
- Telegram 推送
- 定时任务

## 💡 Claude Code 使用技巧

### 交互模式
```bash
# 直接对话
claude "帮我分析这个代码"

# 编辑模式
claude --edit file.js

# 查看文件
claude "显示 README.md"
```

### Superpowers 工作流

**1. 开始新功能**
```
"I want to build an auto-deploy skill for OpenClaw"
```
→ brainstorming 技能会触发

**2. 制定计划**
```
"Create a detailed implementation plan"
```
→ writing-plans 技能会触发

**3. 执行开发**
```
"Execute the plan step by step"
```
→ executing-plans + subagent-driven-development

**4. 代码审查**
```
"Review my changes"
```
→ requesting-code-review

**5. 测试**
```
"Write tests for this feature"
```
→ test-driven-development

**6. 完成**
```
"Finish this development branch"
```
→ finishing-a-development-branch

## 📝 进度跟踪

每个任务完成后：
```bash
# 提交代码
git add .
git commit -m "feat: complete [task name]"
git push

# 更新 TODO-Queue.md
# 标记已完成
```

## ⏰ 时间提醒

- 20:30 - 开始任务 1
- 23:30 - 开始任务 2
- 02:30 - 开始任务 3

## 🔧 故障排除

**如果 Claude Code 无响应：**
```bash
# 检查状态
claude --version

# 查看日志
tail -f ~/.claude/debug/*.log
```

**如果 Superpowers 未生效：**
```bash
# 检查技能安装
ls ~/.agents/skills/

# 重新安装
npx skills add /usr/local/lib/node_modules/openclaw/skills/superpowers --agent claude-code --global --all -y
```

---

**创建时间：** 2026-02-02 19:30
**开始时间：** 2026-02-02 20:30
