# MEMORY.md - 永久记忆

**OpenClaw AI Agent 长期记忆存储**

---

## 🛠️ Skill 开发标准流程

**基于 Task 1 (Auto-Deployment Skill) 实战经验**

### 完整开发文档
详见: `/root/.openclaw/workspace/skill-development-workflow.md`

### 核心要点

#### 1. Skill 标准结构
```
skills/skill-name/
├── SKILL.md              # 技能文档
├── README.md             # 用户指南
├── index.js              # 主入口
├── lib/
│   ├── module1.cjs       # 使用 .cjs (CommonJS)
│   ├── module2.cjs
│   └── ...
├── templates/
└── tests/
    ├── functional-test.sh
    ├── unit.test.mjs
    └── unit.test.cjs
```

#### 2. 关键技术决策

**使用 .cjs 扩展名**
- 原因: OpenClaw 的 package.json 设置了 `"type": "module"`
- 避免: ES 模块导入/导出冲突
- 使用: `require/module.exports` (CommonJS)

**模块模板**
```javascript
#!/usr/bin/env node

/**
 * 模块描述
 */

const { execSync } = require('child_process');

function mainFunction() {
  try {
    // 实现
    return result;
  } catch (error) {
    console.error(`Error: ${error.message}`);
    return null;
  }
}

module.exports = { mainFunction };

if (require.main === module) {
  const result = mainFunction();
  console.log(result);
}
```

#### 3. 测试验证流程

**本地测试**
```bash
# 功能测试
bash tests/functional-test.sh

# 模块测试
node lib/module.cjs

# 主流程
node index.js
```

**远程测试服务器**
```bash
# 1. 打包
cd /usr/local/lib/node_modules/openclaw/skills
tar czf skill-name.tar.gz skill-name/

# 2. 上传
scp skill-name.tar.gz root@test-server:/tmp/

# 3. 测试
ssh root@test-server << 'ENDSSH'
export http_proxy=socks5h://127.0.0.1:1080
cd /usr/local/lib/node_modules/openclaw/skills
tar xzf /tmp/skill-name.tar.gz
cd skill-name
bash tests/functional-test.sh
ENDSSH
```

#### 4. Git 提交流程

**标准流程**
```bash
# 1. 克隆并创建分支
cd /root
git clone https://github.com/username/openclaw.git openclaw-temp
cd openclaw-temp
git checkout main
git checkout -b feature/skill-name

# 2. 复制技能
cp -r /usr/local/lib/node_modules/openclaw/skills/skill-name skills/

# 3. 提交
git add skills/skill-name/
git commit -m "feat: Add Skill Name

Features:
- Feature 1
- Feature 2

Resolves: #1

Code stats:
- ~X,XXX lines
- X modules
- X tests"

# 4. 推送
git push -u origin feature/skill-name
```

**提交信息规范**
```
<type>(<scope>): <subject>

<body>

<footer>
```

类型: feat, fix, docs, refactor, test, chore

#### 5. Pull Request 创建

```bash
gh pr create \
  --title "feat: Add Skill Name (Issue #X)" \
  --body "Summary, Features, Code Stats, Testing, Related Issues" \
  --base main
```

#### 6. GitHub Issue 更新

```bash
gh issue edit X \
  --body "Status, PR link, What was implemented, Code stats, Testing, Success criteria"
```

### 网络隔离环境解决方案

**SSH SOCKS5 隧道**
```bash
# 创建隧道
ssh -D 1080 -f -C -q -N root@server-ip

# 设置代理
export http_proxy=socks5h://127.0.0.1:1080
export https_proxy=socks5h://127.0.0.1:1080
export no_proxy=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*
```

**Docker 代理配置**
```bash
# 创建 systemd 配置
mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=socks5h://127.0.0.1:1080"
Environment="HTTPS_PROXY=socks5h://127.0.0.1:1080"
Environment="NO_PROXY=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*"
EOF

systemctl daemon-reload
systemctl restart docker
```

### 测试服务器信息

**服务器**: 115.191.18.218
**用户**: root
**配置**: Ubuntu 24.04, Node.js v22.22.0, Git 2.43.0, Docker 29.2.0

**SSH 访问**:
```bash
ssh root@115.191.18.218
```

**代理端口**: 1080 (SOCKS5)

### 常见问题处理

**11 个常见问题** (来自 Task 1):
1. Node.js 版本过低
2. Gateway 认证 Token 缺失
3. Gateway 认证模式配置错误
4. 目录权限问题
5. 必需目录缺失
6. 旧配置残留
7. systemd 用户服务未运行
8. SSH 隧道端口被占用
9. Git 未安装
10. Dashboard 认证错误
11. Gateway 服务未运行

详见: `/usr/local/lib/node_modules/openclaw/skills/auto-deploy/lib/troubleshooter.cjs`

---

## 📊 项目状态

### 已完成任务

**Task 0** ✅ (2026-02-02 22:05)
- 测试服务器环境准备
- Docker 安装（通过代理）
- 网络隔离解决方案

**Task 1** ✅ (2026-02-02 22:50)
- Auto-Deployment Skill 开发
- 5 个核心模块，~2,500 行代码
- 支持 5 种 Linux 发行版
- 11 个常见问题自动修复
- **开发方式**: 手动实现（未使用 Claude Code）
- PR #3: https://github.com/alijiujiu123/openclaw/pull/3
- Issue #1: https://github.com/alijiujiu123/openclaw/issues/1

**Task 2** ✅ (2026-02-02 23:35)
- Docker Image Support
- Multi-stage Dockerfile (node:22-alpine)
- Multi-platform support (amd64, arm64)
- Environment-based configuration
- Health checks & volume mounting
- GitHub Actions CI/CD
- Comprehensive documentation (5,000+ words)
- **开发方式**: 手动实现
- PR #4: https://github.com/alijiujiu123/openclaw/pull/4
- Issue #2: https://github.com/alijiujiu123/openclaw/issues/2

**Task 3** ✅ (2026-02-02 23:40)
- Daily Briefing System MVP
- RSS 抓取器 (100+ 技术博客)
- AI 摘要生成 (GLM-4.7)
- 智能分类 (AI/ML, 创业, 安全, 开发等)
- 重要性评分
- 多格式输出 (Markdown, Telegram, HTML, Slack)
- 多渠道推送
- SQLite 数据库
- Cron 调度器
- **代码量**: ~6,000 行，6 个模块
- **仓库**: https://github.com/alijiujiu123/daily-briefing-system
- **提交**: 0214354

**Task 4** 🚧 (2026-02-03 19:04 - Phase 1 完成)
- Self-Evolution System
- 持续学习系统（5个监控器）
- AI 双层分析（快速分类+深度分析）
- 自主优化引擎
- Token 双重优化（效率+吞吐）
- 弹性计算引擎（Docker/K8s/Cloud）
- **状态**: Phase 1/7 完成（核心基础设施）
- **代码量**: ~1,663 行，7 个模块
- **分支**: feature/self-evolution-system
- **Issue**: https://github.com/alijiujiu123/openclaw/issues/5
- **PR**: https://github.com/alijiujiu123/openclaw/pull/6
- **设计文档**: docs/plans/2026-02-03-self-evolution-design.md (25KB)

**Phase 1 完成** ✅:
- 配置管理系统
- 结构化日志系统
- SQLite 存储层
- 监控器基类
- 主系统编排器
- 功能测试套件
- 完整文档

**Phase 2-7 待完成**:
- 监控器实现
- AI 分析引擎
- 执行引擎
- Token 优化器
- 弹性计算
- 部署和优化

---

## 🔧 工具配置

### GitHub CLI
```bash
git config --global user.name "javaer"
git config --global user.email "javaer@openclaw.ai"
gh auth status
```

### Node.js 版本
- 开发环境: v22.10.0
- 测试服务器: v22.22.0
- 要求: v22+

### 工作目录
- Workspace: `/root/.openclaw/workspace`
- Skills: `/usr/local/lib/node_modules/openclaw/skills`

---

## 💡 最佳实践

### Claude Code 使用策略

**何时使用 CC**:
- ✅ 小型 skill（< 500 行）
- ✅ 快速原型开发
- ✅ 生成模板代码
- ✅ 编写单元测试
- ✅ 生成文档

**何时不使用 CC**:
- ❌ 复杂 skill（如 Task 1，需要精确控制）
- ❌ 安全相关代码
- ❌ 性能关键代码
- ❌ 复杂业务逻辑

**开发时间对比**（Task 1 实测）:
- 手动开发：2 小时
- 使用 CC：1.5-2 小时（多轮迭代）
- **结论**：复杂 skill 手动开发更可靠

详见: `/root/.openclaw/workspace/claude-code-guide.md`

### 代码质量
- ✅ 每个函数都有文档注释
- ✅ 错误处理（try-catch）
- ✅ 清晰的错误消息
- ✅ 日志输出（使用 emoji）
- ✅ 模块化设计

### 测试覆盖
- ✅ 功能测试脚本
- ✅ 单元测试
- ✅ 本地验证
- ✅ 远程服务器验证

### 文档完整
- ✅ SKILL.md（技能文档）
- ✅ README.md（用户指南）
- ✅ 代码注释
- ✅ 开发文档

### Git 规范
- ✅ 功能分支开发
- ✅ 详细提交信息
- ✅ PR 描述完整
- ✅ Issue 链接

---

## 📚 参考资源

### 文档
- OpenClaw 完整安装指南: `/root/.openclaw/workspace/installation-guide.md`
- Skill 开发流程: `/root/.openclaw/workspace/skill-development-workflow.md`
- Claude Code 使用指南: `/root/.openclaw/workspace/claude-code-guide.md`
- PROXY-SOLUTION: `/root/.openclaw/workspace/PROXY-SOLUTION.md`

### 仓库
- OpenClaw: https://github.com/alijiujiu123/openclaw
- Daily Briefing: https://github.com/alijiujiu123/daily-briefing-system

### Issues
- Issue #1 (Auto-Deploy): https://github.com/alijiujiu123/openclaw/issues/1
- Issue #2 (Docker): https://github.com/alijiujiu123/openclaw/issues/2
- PR #3: https://github.com/alijiujiu123/openclaw/pull/3

---

**更新时间**: 2026-02-02 23:15
**状态**: ✅ 已验证
**下次更新**: Task 2 完成后
