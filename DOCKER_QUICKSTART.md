# OpenClaw Docker 开发环境 - 快速开始

## 🎯 核心特性

✅ **数据持久化** - 所有配置、记忆、工具、会话永久保存
✅ **版本隔离** - 代码更新不影响个人数据
✅ **快速备份** - 一键备份和恢复所有数据
✅ **开发友好** - 代码热更新，实时测试

## 📦 创建的文件

| 文件 | 说明 |
|------|------|
| `Dockerfile.dev` | 开发环境 Docker 镜像 |
| `docker-compose.dev.yml` | Docker Compose 配置 |
| `docker-dev.sh` | 快速启动脚本 ⭐ |
| `docker-backup.sh` | 数据备份脚本 |
| `docker-restore.sh` | 数据恢复脚本 |
| `DOCKER_DEV.md` | 完整开发指南 |
| `DOCKER_PERSISTENCE.md` | 数据持久化指南 |

## 🚀 5 分钟快速开始

### 1️⃣ 配置环境

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置（添加 API Key）
vim .env
```

**最小配置：**
```bash
ZHIPU_API_KEY=your_api_key_here
GATEWAY_TOKEN=auto
```

### 2️⃣ 启动环境

```bash
# 一键启动
./docker-dev.sh start
```

**首次启动需要 5-10 分钟构建镜像**

### 3️⃣ 开始开发

```bash
# 进入容器
./docker-dev.sh shell

# 运行命令
openclaw status
pnpm test
pnpm build
pnpm gateway:dev
```

## 🛡️ 数据保护

### 自动保护

所有个人数据自动保存到 Docker Volume：
- ✅ 配置文件
- ✅ Agent 记忆
- ✅ 会话历史
- ✅ 工具和技能
- ✅ 渠道配置

### 手动备份

```bash
# 备份所有数据
./docker-dev.sh backup

# 查看备份
ls -lh backups/
```

### 数据恢复

```bash
# 查看可用备份
./docker-restore.sh

# 恢复指定备份
./docker-restore.sh openclaw-backup-20260205_143000
```

## 🔄 版本更新

### 安全更新流程

```bash
# 1. 备份当前数据
./docker-dev.sh backup

# 2. 拉取最新代码
git pull origin main

# 3. 重新构建
./docker-dev.sh rebuild

# 4. 重启环境
./docker-dev.sh restart

# ✅ 数据完全保留！
```

## 📋 常用命令

```bash
./docker-dev.sh start      # 启动环境
./docker-dev.sh stop       # 停止环境
./docker-dev.sh restart    # 重启环境
./docker-dev.sh shell      # 进入容器
./docker-dev.sh logs       # 查看日志
./docker-dev.sh status     # 查看状态
./docker-dev.sh backup     # 备份数据
./docker-dev.sh restore    # 恢复数据
./docker-dev.sh rebuild    # 重建镜像
./docker-dev.sh clean      # 清理环境
```

## 📂 数据位置

```
Docker Volume（持久化）:
├── openclaw-dev-data       # 核心数据（配置、记忆、会话）
└── openclaw-dev-skills     # 技能和工具

本地目录:
├── ./workspace             # 工作空间
└── ./backups               # 备份文件
```

## 🔍 验证数据

```bash
# 进入容器
./docker-dev.sh shell

# 检查状态
openclaw status
openclaw agents list

# 查看数据卷
ls -la ~/.openclaw/
```

## ⚠️ 重要提示

1. **更新前必须备份**
   ```bash
   ./docker-dev.sh backup
   ```

2. **不要删除数据卷**
   ```bash
   # ❌ 错误（会删除所有数据）
   docker compose down -v

   # ✅ 正确（保留数据）
   docker compose down
   ```

3. **定期备份到远程**
   ```bash
   rsync -avz backups/ user@server:/backups/
   ```

## 📚 详细文档

- **DOCKER_DEV.md** - 完整开发环境指南
- **DOCKER_PERSISTENCE.md** - 数据持久化深度指南

## 🆘 获取帮助

```bash
# 查看帮助
./docker-dev.sh help

# 运行诊断
openclaw doctor

# 查看日志
./docker-dev.sh logs
```

## ✨ 数据持久化保证

| 操作 | 数据影响 |
|------|---------|
| 代码更新 | ✅ 完全保留 |
| 重新构建镜像 | ✅ 完全保留 |
| 重启容器 | ✅ 完全保留 |
| 删除容器 | ✅ 完全保留（在数据卷中） |
| 删除数据卷 | ❌ **数据丢失** |

---

**开始使用：** `./docker-dev.sh start`

**遇到问题？** 查看 [DOCKER_DEV.md](DOCKER_DEV.md) 或 [DOCKER_PERSISTENCE.md](DOCKER_PERSISTENCE.md)
