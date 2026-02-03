# Skill 开发完整流程

**基于 Task 1 (Auto-Deployment Skill) 的实战经验总结**

---

## 📋 前期准备

### 1. 需求分析
- **来源**: GitHub Issue
- **关键步骤**:
  ```bash
  # 使用 web_fetch 获取 issue 内容
  web_fetch https://github.com/user/repo/issues/1
  ```
- **提取要点**:
  - 功能需求（Phase 1-6）
  - 成功标准（7 项）
  - 技术要求（支持的 OS、模块结构等）

### 2. 环境准备
- **测试服务器**: 通过 SSH 隧道访问
- **网络隔离**: 使用 SOCKS5 代理解决方案
- **代理配置**:
  ```bash
  # 创建 SSH 隧道
  ssh -D 1080 -f -C -q -N root@server-ip
  
  # 设置环境变量
  export http_proxy=socks5h://127.0.0.1:1080
  export https_proxy=socks5h://127.0.0.1:1080
  ```

---

## 🏗️ 架构设计

### Skill 标准结构
```
skills/
├── skill-name/
│   ├── SKILL.md              # 技能文档（供 OpenClaw 读取）
│   ├── README.md             # 用户文档（详细使用指南）
│   ├── index.js              # 主入口（编排所有阶段）
│   ├── lib/                  # 核心模块
│   │   ├── module1.cjs       # 使用 .cjs 避免 ES 模块问题
│   │   ├── module2.cjs
│   │   └── ...
│   ├── templates/            # 配置模板
│   └── tests/                # 测试文件
│       ├── functional-test.sh
│       ├── unit.test.mjs     # ES 模块测试
│       └── unit.test.cjs     # CommonJS 测试
```

### 模块设计原则
1. **单一职责**: 每个模块只负责一个功能领域
2. **独立可测**: 模块可以单独运行和测试
3. **清晰导出**: 使用 `module.exports` 明确导出函数
4. **错误处理**: 每个函数都有 try-catch
5. **文档注释**: 每个函数都有 JSDoc 注释

---

## 💻 开发流程

### Step 1: 创建基础结构
```bash
# 创建目录
mkdir -p /usr/local/lib/node_modules/openclaw/skills/skill-name/{lib,templates,tests}

# 创建文档
touch SKILL.md README.md
```

### Step 2: 实现核心模块

**模块模板**:
```javascript
#!/usr/bin/env node

/**
 * 模块功能描述
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

/**
 * 函数功能描述
 * @returns {object} 返回值说明
 */
function mainFunction() {
  try {
    // 实现代码
    return result;
  } catch (error) {
    console.error(`Error: ${error.message}`);
    return null;
  }
}

/**
 * 辅助函数
 */
function helperFunction() {
  // 实现
}

// 导出函数
module.exports = {
  mainFunction,
  helperFunction
};

// 如果直接运行，执行主函数
if (require.main === module) {
  const result = mainFunction();
  console.log(result);
}
```

**关键点**:
- 使用 `.cjs` 扩展名（避免 ES 模块冲突）
- 使用 `require/module.exports`（CommonJS）
- 包含 `if (require.main === module)` 用于独立运行

### Step 3: 编写主入口 (index.js)

**模板**:
```javascript
#!/usr/bin/env node

/**
 * Skill 主入口
 * 编排所有阶段的执行
 */

// 导入模块（使用 .cjs）
const { func1 } = require('./lib/module1.cjs');
const { func2 } = require('./lib/module2.cjs');

/**
 * 主执行函数
 */
async function main(options = {}) {
  const { skipStep1 = false, skipStep2 = false } = options;
  
  console.log('╔═══════════════════════════════════════════════════════════════╗');
  console.log('║          Skill Title                                         ║');
  console.log('╚═══════════════════════════════════════════════════════════════╝');
  
  // Phase 1
  if (!skipStep1) {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Phase 1: Description');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const result1 = await func1();
    if (!result1) {
      console.error('❌ Phase 1 failed');
      process.exit(1);
    }
  }
  
  // Phase 2
  // ...
  
  console.log('\n✅ Complete!');
  return true;
}

// 导出
module.exports = { main };

// 如果直接运行
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {
    skipStep1: args.includes('--skip-step1')
  };
  
  main(options)
    .then(() => process.exit(0))
    .catch(error => {
      console.error('❌ Error:', error.message);
      process.exit(1);
    });
}
```

### Step 4: 编写测试

**功能测试 (functional-test.sh)**:
```bash
#!/bin/bash

echo "╔═════════════════════════════════════════"
echo "🧪 Functional Tests"
echo "╚═════════════════════════════════════════"

PASSED=0
FAILED=0

test() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing: $name ... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL"
        ((FAILED++))
    fi
}

# 文件结构测试
test "SKILL.md exists" "[ -f SKILL.md ]"
test "README.md exists" "[ -f README.md ]"

# 模块执行测试
test "module.cjs runs" "node lib/module.cjs"

# 功能测试
OUTPUT=$(node lib/module.cjs)
if echo "$OUTPUT" | grep -q "Expected Output"; then
    echo "Testing: Function X ... ✅ PASS"
    ((PASSED++))
else
    echo "Testing: Function X ... ❌ FAIL"
    ((FAILED++))
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ $FAILED -eq 0 ] && exit 0 || exit 1
```

**单元测试 (unit.test.mjs)**:
```javascript
import { func1, func2 } from '../lib/module.cjs';

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`✅ ${name}`);
    passed++;
  } catch (error) {
    console.log(`❌ ${name}`);
    console.log(`   ${error.message}`);
    failed++;
  }
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

// 测试用例
test('func1 returns object', () => {
  const result = func1();
  assert(typeof result === 'object', 'Should return object');
});

// 输出结果
console.log(`\nPassed: ${passed}`);
console.log(`Failed: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
```

---

## 🧪 测试验证流程

### 本地测试
```bash
# 1. 检查文件结构
ls -la skill-name/

# 2. 运行功能测试
bash skill-name/tests/functional-test.sh

# 3. 单独测试模块
node skill-name/lib/module.cjs

# 4. 测试主流程
node skill-name/index.js
```

### 远程测试服务器验证
```bash
# 1. 打包
cd /usr/local/lib/node_modules/openclaw/skills
tar czf skill-name.tar.gz skill-name/

# 2. 上传
scp skill-name.tar.gz root@test-server:/tmp/

# 3. 在测试服务器上解压测试
ssh root@test-server << 'ENDSSH'
export http_proxy=socks5h://127.0.0.1:1080
export https_proxy=socks5h://127.0.0.1:1080

cd /usr/local/lib/node_modules/openclaw/skills
tar xzf /tmp/skill-name.tar.gz
cd skill-name
bash tests/functional-test.sh
ENDSSH
```

---

## 📝 Git 提交流程

### 标准提交流程

**1. 克隆仓库**
```bash
cd /root
rm -rf openclaw-temp
git clone https://github.com/username/openclaw.git openclaw-temp
cd openclaw-temp
```

**2. 创建功能分支**
```bash
# 从 main 分支创建
git checkout main
git checkout -b feature/skill-name

# 注意：主分支是 main，不是 master
```

**3. 复制技能文件**
```bash
# 从开发位置复制
cp -r /usr/local/lib/node_modules/openclaw/skills/skill-name skills/
```

**4. 提交变更**
```bash
# 添加文件
git add skills/skill-name/

# 查看状态
git status

# 提交（使用详细的提交信息）
git commit -m "feat: Add Skill Name

Brief description of what the skill does.

Features:
- Feature 1 description
- Feature 2 description
- Feature 3 description

Resolves: #1

Code stats:
- ~X,XXX lines total
- X core modules
- X test cases

Tested on:
- Environment 1
- Environment 2

Co-authored-by: Your Name <your@email.com>"
```

**5. 推送到 GitHub**
```bash
# 首次推送
git push -u origin feature/skill-name

# 如果需要强制推送（重新创建分支后）
git push -f origin feature/skill-name
```

### 提交信息规范

**格式**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型**:
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例**:
```
feat(auto-deploy): Add installation automation

Implements automatic Node.js and OpenClaw installation.

Features:
- Detects OS distribution
- Installs Node.js 22+ automatically
- Configures systemd service

Resolves: #1
```

---

## 🔀 Pull Request 创建

### 使用 GitHub CLI

```bash
cd /root/openclaw-temp

# 创建 PR
gh pr create \
  --title "feat: Add Skill Name (Issue #X)" \
  --body "## 🎯 Summary

Brief description of the PR.

## ✨ Features

- Feature 1
- Feature 2
- Feature 3

## 📊 Code Stats

- Lines: X,XXX
- Modules: X
- Tests: X

## 🧪 Testing

- ✅ Environment 1
- ✅ Environment 2

## 🔗 Related

Resolves: #X
Based on: docs/guide.md

---
**All success criteria met:** ✅" \
  --base main

# 输出 PR URL
# https://github.com/username/repo/pull/X
```

### 手动创建 PR

1. 访问 GitHub
2. 点击 "Compare & pull request"
3. 填写标题和描述
4. 链接相关 Issue
5. 提交 PR

---

## 📌 Issue 更新

### 使用 GitHub CLI 更新

```bash
cd /root/openclaw-temp

# 更新 Issue 状态和内容
gh issue edit X \
  --body "## 🎯 Objective

Original objective description.

## ✅ Status

**COMPLETED** - Implementation done, PR submitted for review

## 🔗 Pull Request

**PR #Y:** https://github.com/username/repo/pull/Y

## 📦 What Was Implemented

### Core Modules (X)
1. **module1.cjs** - Description
2. **module2.cjs** - Description
...

### Features Delivered
- ✅ Feature 1
- ✅ Feature 2
...

### Code Statistics
- **Total:** ~X,XXX lines
- **Modules:** X core modules
- **Tests:** X test cases

## 🧪 Testing

- ✅ Environment 1
- ✅ Environment 2

## 📝 Documentation

- SKILL.md: Complete documentation
- README.md: User guide

## 🎯 Success Criteria - ALL MET ✅

- ✅ Criterion 1
- ✅ Criterion 2
...

## 📚 Reference

Based on: commit XYZ

---
**Status:** Ready for review in PR #Y"
```

---

## 🎯 最佳实践总结

### 开发阶段
1. **需求先行**: 充分理解 Issue 要求
2. **架构设计**: 先设计结构，再写代码
3. **模块化**: 每个模块单一职责
4. **文档同步**: 代码和文档同步更新

### 测试阶段
1. **单元测试**: 每个模块独立测试
2. **功能测试**: 端到端流程测试
3. **环境验证**: 多个环境测试
4. **持续修复**: 发现问题立即修复

### 提交流程
1. **分支管理**: 从 main 创建功能分支
2. **提交规范**: 使用详细的提交信息
3. **PR 描述**: 完整的功能说明和测试结果
4. **Issue 链接**: PR 和 Issue 双向链接

### 代码质量
1. **错误处理**: 每个 try-catch 都有清晰的错误消息
2. **日志输出**: 使用 emoji 和格式化输出
3. **注释文档**: 每个函数都有文档注释
4. **可读性**: 变量命名清晰，代码缩进一致

---

## 📚 相关资源

### 工具
- **GitHub CLI**: `gh` - 命令行 GitHub 操作
- **Git**: 版本控制
- **Node.js**: 运行环境
- **SSH**: 远程访问

### 模板
- Skill 结构模板
- 模块代码模板
- 测试脚本模板
- 提交信息模板

### 文档
- OpenClaw 文档
- SKILL.md 规范
- Git 提交规范
- GitHub PR 指南

---

## ⚡ 快速参考

### 常用命令
```bash
# 测试
bash tests/functional-test.sh
node lib/module.cjs

# Git
git status
git add .
git commit -m "message"
git push

# GitHub
gh pr create
gh issue edit
gh pr view
```

### 目录结构
```bash
/usr/local/lib/node_modules/openclaw/skills/skill-name/
```

### 测试服务器
```bash
ssh root@115.191.18.218
export http_proxy=socks5h://127.0.0.1:1080
```

---

**创建时间**: 2026-02-02 23:15
**基于**: Task 1 (Auto-Deployment Skill) 开发经验
**作者**: javaer
**状态**: ✅ 已验证

---

这个 skill 可以作为所有未来 OpenClaw skill 开发的标准流程参考。
