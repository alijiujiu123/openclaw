# OpenClaw Docker 开发环境指南

## 🎯 目的

本配置用于在 Docker 容器中搭建 OpenClaw 的本地开发环境，方便测试新功能和调试代码。

## 📋 前置要求

- Docker 已安装（推荐 Docker Desktop）
- Docker Compose 已安装
- 至少一个模型 API Key（智谱 AI、OpenAI 等）

## 🚀 快速开始

### 1. 准备环境配置

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，添加你的 API keys
vim .env
```

**最小配置（在 .env 文件中）：**
```bash
# 选择一个模型提供商
ZHIPU_API_KEY=your_zhipu_api_key_here
# 或
OPENAI_API_KEY=your_openai_api_key_here

# Gateway token（可以留空使用 auto）
GATEWAY_TOKEN=auto
```

### 2. 构建开发镜像

```bash
# 使用 docker-compose 构建镜像
docker compose -f docker-compose.dev.yml build

# 查看构建进度
docker compose -f docker-compose.dev.yml build --progress=plain
```

**预计时间：**
- 首次构建：5-10 分钟（取决于网络速度）
- 后续构建：1-2 分钟（使用缓存）

### 3. 启动开发容器

```bash
# 启动容器（后台运行）
docker compose -f docker-compose.dev.yml up -d

# 查看日志
docker compose -f docker-compose.dev.yml logs -f

# 进入容器进行开发
docker compose -f docker-compose.dev.yml exec openclaw-dev sh
```

## 💻 开发工作流

### 方式 1：交互式开发（推荐）

```bash
# 1. 启动容器
docker compose -f docker-compose.dev.yml up -d

# 2. 进入容器
docker compose -f docker-compose.dev.yml exec openclaw-dev sh

# 3. 在容器内运行命令
openclaw status                    # 检查状态
pnpm test                          # 运行测试
pnpm build                         # 构建项目
pnpm dev                           # 开发模式
```

### 方式 2：直接执行命令

```bash
# 在宿主机直接执行容器内的命令
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm test

# 启动 Gateway
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm gateway:dev

# 运行特定测试
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm test agent.test.ts
```

### 方式 3：实时开发（代码热更新）

```bash
# 1. 在宿主机编辑代码
vim src/commands/status.ts

# 2. 在容器内重新构建
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm build

# 3. 重启 Gateway 测试修改
docker compose -f docker-compose.dev.yml restart openclaw-dev
```

## 🔧 常用开发命令

### 项目构建与测试

```bash
# 在容器内执行
pnpm install              # 安装依赖
pnpm build               # 构建项目
pnpm check               # 代码检查（lint + format）
pnpm test                # 运行所有测试
pnpm test:coverage       # 测试覆盖率
pnpm test:e2e            # E2E 测试
pnpm dev                 # 开发模式（监听文件变化）
```

### Gateway 管理

```bash
# 启动 Gateway（开发模式）
pnpm gateway:dev

# 检查 Gateway 状态
openclaw status

# 查看 Gateway 日志
openclaw logs --follow

# 添加 Agent
openclaw agents add --name test-agent --model zhipu/GLM-4.7
```

### 容器管理

```bash
# 查看容器状态
docker compose -f docker-compose.dev.yml ps

# 查看实时日志
docker compose -f docker-compose.dev.yml logs -f

# 停止容器
docker compose -f docker-compose.dev.yml stop

# 启动容器
docker compose -f docker-compose.dev.yml start

# 重启容器
docker compose -f docker-compose.dev.yml restart

# 完全删除容器（保留数据卷）
docker compose -f docker-compose.dev.yml down

# 完全删除容器和数据卷（⚠️ 会删除所有数据）
docker compose -f docker-compose.dev.yml down -v
```

## 📂 目录结构说明

```
.
├── Dockerfile.dev              # 开发环境 Dockerfile
├── docker-compose.dev.yml      # 开发环境 Compose 配置
├── .env                        # 环境变量配置（需自行创建）
├── src/                        # 源代码（挂载到容器）
│   ├── commands/              # CLI 命令
│   ├── gateway/               # Gateway 核心逻辑
│   ├── agents/                # Agent 运行时
│   └── ...
├── dist/                       # 编译输出（挂载到容器）
├── test/                       # 测试文件
└── workspace/                  # Agent 工作空间
```

## 🔍 调试技巧

### 1. 查看 Gateway 日志

```bash
# 在容器内
tail -f /tmp/openclaw/openclaw-*.log

# 或使用 OpenClaw CLI
openclaw logs --follow
```

### 2. 进入容器调试

```bash
# 交互式 Shell
docker compose -f docker-compose.dev.yml exec openclaw-dev sh

# 查看进程
ps aux

# 查看端口监听
netstat -tlnp

# 测试 API
curl http://localhost:18789/health
```

### 3. 运行单个测试

```bash
# 在容器内
pnpm test agent.test.ts

# 调试模式（带 console.log）
NODE_ENV=test pnpm test agent.test.ts

# 监听模式（自动重新运行）
pnpm test --watch
```

### 4. 类型检查

```bash
# TypeScript 类型检查
pnpm tsc --noEmit

# 查看特定文件类型
pnpm tsc --noEmit src/commands/status.ts
```

## 🧪 测试新功能

### 场景 1：修改 CLI 命令

```bash
# 1. 宿主机：编辑代码
vim src/commands/my-new-command.ts

# 2. 容器内：重新构建
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm build

# 3. 容器内：测试新命令
docker compose -f docker-compose.dev.yml exec openclaw-dev openclaw my-new-command
```

### 场景 2：添加新的 Agent 工具

```bash
# 1. 宿主机：编辑工具定义
vim src/agents/tools/my-tool.ts

# 2. 容器内：构建并测试
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm build
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm test my-tool.test.ts

# 3. 容器内：启动 Gateway 并测试
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm gateway:dev
```

### 场景 3：运行 E2E 测试

```bash
# 在容器内运行完整的 E2E 测试套件
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm test:e2e

# 或运行单个 E2E 测试
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm test onboarding.e2e.test.ts
```

## 🐛 常见问题

### 1. 容器构建失败

**问题：** `pnpm install` 失败

**解决：**
```bash
# 清理缓存重新构建
docker compose -f docker-compose.dev.yml down
docker system prune -f
docker compose -f docker-compose.dev.yml build --no-cache
```

### 2. 端口已被占用

**问题：** `18789` 端口被占用

**解决：**
```bash
# 查看占用进程
lsof -i :18789

# 修改 docker-compose.dev.yml 中的端口映射
ports:
  - "18790:18789"  # 使用 18790 端口
```

### 3. 权限问题

**问题：** 容器内无法写入文件

**解决：**
```bash
# 修复 node_modules 权限
docker compose -f docker-compose.dev.yml exec openclaw-dev chown -R openclaw:nodejs /app/node_modules
```

### 4. 代码修改不生效

**问题：** 修改代码后看不到效果

**解决：**
```bash
# 1. 确认卷挂载正确
docker compose -f docker-compose.dev.yml exec openclaw-dev ls -la /app

# 2. 重新构建项目
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm build

# 3. 重启 Gateway
docker compose -f docker-compose.dev.yml restart openclaw-dev
```

## 📊 性能优化

### 加速构建

```bash
# 使用 BuildKit（更快的构建）
DOCKER_BUILDKIT=1 docker compose -f docker-compose.dev.yml build

# 使用构建缓存
docker compose -f docker-compose.dev.yml build --build-arg BUILDKIT_INLINE_CACHE=1
```

### 减少镜像大小

```bash
# 清理不需要的依赖
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm prune

# 清理构建缓存
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm build --clean
```

## 🔄 更新环境

### 拉取最新代码

```bash
# 宿主机：拉取最新代码
git pull origin main

# 容器内：重新安装依赖（如果 package.json 变化）
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm install

# 容器内：重新构建
docker compose -f docker-compose.dev.yml exec openclaw-dev pnpm build
```

### 重建镜像

```bash
# 当 Dockerfile.dev 或依赖发生变化时
docker compose -f docker-compose.dev.yml build --no-cache

# 或删除旧的镜像后重新构建
docker rmi openclaw-dev:latest
docker compose -f docker-compose.dev.yml build
```

## 📚 参考资料

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [开发指南](CONTRIBUTING.md)
- [测试文档](docs/testing.md)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 🆘 获取帮助

- 查看日志：`docker compose -f docker-compose.dev.yml logs -f`
- 运行诊断：`docker compose -f docker-compose.dev.yml exec openclaw-dev openclaw doctor`
- 提交 Issue：[GitHub Issues](https://github.com/openclaw/openclaw/issues)

---

**更新时间：** 2026-02-05
**维护者：** OpenClaw Community
