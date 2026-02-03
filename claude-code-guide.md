# Claude Code 在 Skill 开发中的使用指南

**如何集成 Claude Code (cc) 到 Skill 开发流程中**

---

## 🤖 什么是 Claude Code

Claude Code (cc) 是 Anthropic 的 AI 编程助手，可以帮助：
- 自动生成代码
- 调试和修复错误
- 重构和优化代码
- 编写测试用例
- 生成文档

---

## 🚀 何时使用 Claude Code

### 适合使用的场景

**1. 快速原型开发**
```bash
cd /usr/local/lib/node_modules/openclaw/skills
mkdir my-skill
cd my-skill

# 使用 CC 生成基础结构
cc "Create a skill structure with SKILL.md, README.md, index.js, and lib/ directory with 5 modules"
```

**2. 代码生成**
```bash
# 生成特定模块
cc "Create a detector.js module that detects OS, Node.js version, and system resources"
```

**3. 单元测试生成**
```bash
# 为模块生成测试
cc "Generate comprehensive unit tests for lib/detector.cjs"
```

**4. Bug 修复**
```bash
# 修复错误
cc "Fix this error: ReferenceError: require is not defined"
```

**5. 代码重构**
```bash
# 优化代码
cc "Refactor this module to be more modular and testable"
```

### 不适合使用的场景

- **需要精确控制的代码**（如安全相关）
- **复杂的架构决策**（需要人工判断）
- **性能关键代码**（需要优化）
- **与现有系统集成**（需要了解上下文）

---

## 📝 Claude Code 使用流程

### Step 1: 环境准备

```bash
# 确认 cc 已安装
which cc
cc --version

# 配置 cc（如果需要）
cc config set editor vim
```

### Step 2: 使用 CC 创建基础结构

```bash
# 创建 skill 目录
mkdir -p /usr/local/lib/node_modules/openclaw/skills/my-skill/{lib,templates,tests}
cd /usr/local/lib/node_modules/openclaw/skills/my-skill

# 让 CC 生成基础结构
cc <<EOF
Create an OpenClaw skill with the following structure:
- SKILL.md (skill documentation)
- README.md (user guide)
- index.js (main entry point)
- lib/ with 5 modules:
  1. detector.cjs - environment detection
  2. installer.cjs - installation automation
  3. configurator.cjs - configuration wizard
  4. validator.cjs - verification checks
  5. troubleshooter.cjs - issue detection and fixing

Each module should:
- Use CommonJS (require/module.exports)
- Include try-catch error handling
- Have JSDoc comments
- Be independently runnable

Based on the requirements in issue #1.
EOF
```

### Step 3: 迭代开发

```bash
# 生成特定模块
cc "Create the detector.cjs module with functions:
- detectOS() - detect Linux distribution
- checkNodeVersion() - check if Node.js 22+ is installed
- checkDiskSpace() - verify at least 10GB available
- checkRAM() - verify at least 1GB RAM
- checkNetwork() - test internet connectivity

Include error handling and logging."

# 生成测试
cc "Create functional-test.sh that tests:
1. All files exist
2. All modules run without errors
3. Environment detection works
4. Troubleshooting runs

Use emoji in output and track passed/failed tests."

# 修复问题
cc "Fix this error in detector.cjs: 
Error: Cannot find module 'fs'
Make sure to use require() correctly for CommonJS."
```

### Step 4: 代码审查和优化

```bash
# 让 CC 审查代码
cc "Review the auto-deploy skill and suggest improvements for:
1. Code modularity
2. Error handling
3. User experience
4. Performance

Focus on the troubleshooter module."
```

### Step 5: 文档生成

```bash
# 生成 README
cc "Create a comprehensive README.md for the auto-deploy skill including:
- Feature overview
- Installation instructions
- Usage examples
- Troubleshooting guide
- Contributing guidelines

Use clear formatting and examples."
```

---

## 💡 最佳实践

### 1. 分阶段使用 CC

**不要一次性让 CC 生成所有代码**，而是分阶段：

```bash
# ❌ 不好的做法
cc "Create a complete auto-deploy skill with all features"

# ✅ 好的做法
cc "Create the skill directory structure"
cc "Create the detector module with OS detection"
cc "Create the installer module"
cc "Create the troubleshooter module"
cc "Generate tests for all modules"
```

### 2. 提供清晰的上下文

```bash
# ❌ 上下文不足
cc "Fix the bug"

# ✅ 上下文清晰
cc <<EOF
I'm getting this error when running detector.cjs:

Error: Cannot read property 'id' of undefined
    at detectOS (/usr/local/lib/node_modules/openclaw/skills/auto-deploy/lib/detector.cjs:15:25)

The error happens when /etc/os-release doesn't exist.
The code is:
function detectOS() {
  const osRelease = fs.readFileSync('/etc/os-release', 'utf8');
  const info = JSON.parse(osRelease);  // This line fails
  return { id: info.ID };
}

How should I fix this?
EOF
```

### 3. 验证 CC 生成的代码

```bash
# CC 生成代码后，立即验证
cc "Create the detector module"

# 测试它
node lib/detector.cjs

# 如果有错误，让 CC 修复
cc "Fix the error in detector.cjs"
```

### 4. 保持人工审查

```bash
# CC 生成后，人工审查
cc "Create the installer module"

# 人工审查代码
cat lib/installer.cjs

# 如果需要修改
cc "Refactor the installer module to:
1. Add more error handling
2. Improve logging
3. Add support for CentOS"
```

---

## 🔄 CC vs 手动开发对比

### Task 1 实际情况

**手动开发**（实际采用）:
- ⏱️ 时间：约 2 小时
- ✅ 完全控制
- ✅ 代码质量高
- ❌ 需要逐行编写

**如果使用 CC**（假设）:
- ⏱️ 时间：约 30-45 分钟
- ✅ 快速生成
- ❌ 需要多轮迭代
- ❌ 可能需要大量修复

### 推荐策略

**小型 Skill（< 500 行）**
→ 使用 CC 加速开发

**中型 Skill（500-2000 行）**
→ CC 生成基础结构 + 手动完善核心逻辑

**大型 Skill（> 2000 行）**
→ 手动设计架构 + CC 生成模块 + 手动整合

**复杂 Skill（如 Task 1）**
→ 手动开发（需要精确控制）

---

## 🎯 Task 1 如果使用 CC 的流程

### Phase 1: 需求分析（手动）
```bash
# 读取 Issue
web_fetch https://github.com/alijiujiu123/openclaw/issues/1

# 提取关键功能
# - 环境检测
# - 自动安装
# - 配置向导
# - 故障排除
```

### Phase 2: 架构设计（手动）
```bash
# 设计模块结构
# - detector
# - installer
# - configurator
# - validator
# - troubleshooter
```

### Phase 3: 代码生成（CC）
```bash
# 生成 detector 模块
cc <<EOF
Create detector.cjs with these functions:
1. detectEnvironment() - main function
2. detectOS() - detect Linux distribution
3. checkNodeVersion() - verify Node.js 22+
4. checkGit() - verify Git installed
5. checkDiskSpace() - check disk space
6. checkRAM() - check memory
7. checkNetwork() - test connectivity

Requirements:
- Use CommonJS (require/module.exports)
- Include try-catch for all functions
- Add JSDoc comments
- Return consistent object format
EOF

# 测试
node lib/detector.cjs

# 如果有问题，修复
cc "Fix detector.cjs - it's throwing an error about fs module"
```

### Phase 4: 迭代开发（CC + 手动）
```bash
# 对每个模块重复
cc "Create installer.cjs with Node.js and Git installation"
# 测试 → 修复 → 完善

cc "Create configurator.cjs with interactive wizard"
# 测试 → 修复 → 完善

# ...
```

### Phase 5: 集成测试（手动）
```bash
# 手动编写主流程（index.js）
# 因为需要精确控制阶段顺序

# 手动编写测试脚本
# 因为需要测试特定场景
```

---

## 📚 CC 命令参考

### 基础命令

```bash
# 启动 CC 会话
cc

# 直接执行命令
cc "message"

# 编辑文件
cc -e file.js

# 查看差异
cc --diff

# 使用特定模型
cc --model claude-sonnet "message"
```

### 常用模式

**生成代码**
```bash
cc "Create a function that does X"
```

**修复错误**
```bash
cc "Fix this error: [paste error]"
```

**添加功能**
```bash
cc "Add error handling to this function"
```

**重构代码**
```bash
cc "Refactor this to be more readable"
```

**生成测试**
```bash
cc "Generate unit tests for this module"
```

**解释代码**
```bash
cc "Explain how this code works"
```

---

## ⚡ 快速参考

### Task 1 如果用 CC 的时间线

| 阶段 | 手动 | 使用 CC |
|------|------|---------|
| 需求分析 | 15 min | 15 min |
| 架构设计 | 15 min | 15 min |
| 代码实现 | 90 min | 30-45 min |
| 测试验证 | 30 min | 30 min |
| 文档编写 | 10 min | 5 min |
| **总计** | **2 小时** | **1.5-2 小时** |

**结论**: 对于 Task 1 这种复杂 skill，手动开发更可靠。

### 推荐使用 CC 的场景

✅ **推荐**:
- 生成模板代码
- 编写单元测试
- 生成文档
- 快速原型
- 修复简单 bug

❌ **不推荐**:
- 复杂业务逻辑
- 安全相关代码
- 性能关键代码
- 需要精确控制的流程

---

## 🔗 相关资源

- Claude Code 文档: (如有)
- Task 1 完整开发流程: `/root/.openclaw/workspace/skill-development-workflow.md`
- MEMORY.md: `/root/.openclaw/workspace/MEMORY.md`

---

**更新时间**: 2026-02-02 23:20
**基于**: Task 1 实战经验
**作者**: javaer
**状态**: ✅ 补充文档
