# OpenClaw Docker 数据持久化指南

## 🎯 概述

本指南说明如何在 Docker 开发环境中安全地保存和管理所有个人数据，确保版本更新不会丢失任何重要信息。

## 📂 数据持久化架构

### 数据分类

```
┌─────────────────────────────────────────────────────────┐
│                   OpenClaw 数据分层                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1️⃣ 核心配置层 (openclaw-dev-data Volume)              │
│     ├─ openclaw.json          # 主配置文件              │
│     ├─ channels/              # 渠道配置                │
│     │  ├─ telegram/           # Telegram Bot 配置       │
│     │  ├─ discord/            # Discord Bot 配置        │
│     │  └─ ...                 # 其他渠道                 │
│     ├─ credentials/           # API 凭证                │
│     ├─ agents/                # Agent 配置和记忆         │
│     │  ├─ <agent-id>/         # 每个独立 Agent          │
│     │  │  ├─ agent.json       # Agent 配置              │
│     │  │  └─ sessions/        # 会话记忆                │
│     │  │     └─ *.jsonl       # 会话日志                │
│     └─ sessions/              # 全局会话                │
│                                                         │
│  2️⃣ 技能工具层 (openclaw-dev-skills Volume)            │
│     ├─ skills/                # 自定义技能              │
│     └─ tools/                 # 自定义工具              │
│                                                         │
│  3️⃣ 工作空间层 (本地目录挂载)                           │
│     └─ workspace/             # Agent 生成的文件        │
│                                                         │
│  4️⃣ 配置层 (宿主机文件)                                 │
│     ├─ .env                   # 环境变量                │
│     └─ .openclaw/             # 宿主机本地配置（可选）  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 💾 数据卷详解

### 1. openclaw-dev-data（核心数据卷）

**位置：** Docker Volume（命名卷）

**包含内容：**
- ✅ 所有 Gateway 配置
- ✅ 所有 Agent 配置和记忆
- ✅ 所有会话历史
- ✅ 所有渠道配置和凭证
- ✅ 用户偏好设置

**生命周期：** 永久保存，除非手动删除

**备份频率：** 建议每次重大更改前备份

### 2. openclaw-dev-skills（技能数据卷）

**位置：** Docker Volume（命名卷）

**包含内容：**
- ✅ 自定义技能定义
- ✅ 自定义工具脚本
- ✅ 技能配置文件

**生命周期：** 永久保存

### 3. workspace（工作空间）

**位置：** 宿主机 `./workspace` 目录

**包含内容：**
- ✅ Agent 生成的代码文件
- ✅ 用户上传的文档
- ✅ 临时工作文件

**生命周期：** 持久化到宿主机

## 🔄 版本更新流程

### 场景 1：代码更新（不影响数据）

**适用于：** 修改源代码、添加新功能

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 重新构建镜像
./docker-dev.sh rebuild

# 3. 重启容器
./docker-dev.sh restart

# ✅ 数据完全保留，无需额外操作
```

### 场景 2：配置更新（影响数据结构）

**适用于：** 配置 schema 变更、数据格式变化

```bash
# 1. 备份当前数据
./docker-backup.sh

# 2. 拉取最新代码
git pull origin main

# 3. 重新构建和启动
./docker-dev.sh rebuild
./docker-dev.sh start

# 4. 进入容器迁移数据
./docker-dev.sh shell
openclaw doctor --fix    # 自动迁移配置

# 5. 验证数据
openclaw status
openclaw agents list
```

### 场景 3：完全重置（清除所有数据）

**适用于：** 开发测试、清理环境

```bash
# 1. 备份数据（可选）
./docker-backup.sh

# 2. 停止并删除容器
docker compose -f docker-compose.dev.yml down

# 3. 删除数据卷
docker volume rm openclaw-dev-data openclaw-dev-skills

# 4. 重新构建和启动
./docker-dev.sh rebuild
./docker-dev.sh start

# ⚠️ 所有数据将被清除
```

## 🛡️ 备份策略

### 自动备份

**推荐：** 设置定时任务（cron）每日备份

```bash
# 编辑 crontab
crontab -e

# 添加每日备份任务（每天凌晨 2 点）
0 2 * * * cd /path/to/openclaw && ./docker-backup.sh > /dev/null 2>&1
```

### 手动备份

```bash
# 快速备份
./docker-backup.sh

# 查看备份
ls -lh backups/

# 备份清单
cat backups/openclaw-backup-*/-manifest.txt | head -20
```

### 备份到远程

```bash
# 同步到云存储
rsync -avz backups/ user@remote-server:/backups/openclaw/

# 或使用 rclone（支持多种云存储）
rclone sync backups/ remote:openclaw-backups
```

## 📥 恢复流程

### 完整恢复

```bash
# 1. 查看可用备份
./docker-restore.sh

# 2. 恢复指定备份
./docker-restore.sh openclaw-backup-20260205_143000

# 3. 验证恢复
./docker-dev.sh shell
openclaw status
```

### 部分恢复

```bash
# 仅恢复配置
docker run --rm \
  -v openclaw-dev-data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "tar xzf /backup/openclaw-backup-*-data.tar.gz -C /data"

# 仅恢复 workspace
tar xzf backups/openclaw-backup-*-workspace.tar.gz
```

## 🔍 数据验证

### 检查数据完整性

```bash
# 1. 进入容器
./docker-dev.sh shell

# 2. 检查配置
openclaw doctor

# 3. 检查 Gateway 状态
openclaw status --all

# 4. 检查 Agent 列表
openclaw agents list

# 5. 检查会话历史
ls -la ~/.openclaw/agents/*/sessions/

# 6. 检查渠道配置
openclaw channels status --probe
```

### 数据一致性检查

```bash
# 验证配置文件
cat ~/.openclaw/openclaw.json | jq .

# 检查会话文件
wc -l ~/.openclaw/agents/*/sessions/*.jsonl

# 验证凭证
openclaw models auth list
```

## 🚨 数据安全

### 访问控制

```bash
# 备份目录权限
chmod 700 backups/
chmod 600 backups/*

# Docker Volume 权限
docker run --rm -v openclaw-dev-data:/data alpine ls -la /data
```

### 加密备份

```bash
# 加密备份
gpg --symmetric --cipher-algo AES256 backups/openclaw-backup-*.tar.gz

# 解密备份
gpg --decrypt backups/openclaw-backup-*.tar.gz.gpg > backups/openclaw-backup-*.tar.gz
```

### 敏感数据保护

```bash
# 不要备份 .env 文件（已在 .gitignore）
# 或使用加密方式备份
tar czf - .env | gpg --symmetric --cipher-algo AES256 > env-backup.tar.gz.gpg
```

## 📊 监控和维护

### 定期检查

```bash
# 查看数据卷大小
docker system df -v | grep openclaw

# 查看备份大小
du -sh backups/*

# 清理旧备份（保留最近 7 天）
find backups/ -name "openclaw-backup-*" -mtime +7 -exec rm {} \;
```

### 数据卷维护

```bash
# 清理未使用的卷
docker volume prune

# 备份所有数据卷
docker run --rm -v openclaw-dev-data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/volume-backup-$(date +%Y%m%d).tar.gz /data
```

## 🐛 故障排除

### 问题 1：数据丢失

**症状：** 配置、会话等数据消失

**解决：**
```bash
# 1. 立即停止容器
./docker-dev.sh stop

# 2. 从备份恢复
./docker-restore.sh <backup-name>

# 3. 验证恢复
openclaw status
```

### 问题 2：权限错误

**症状：** 无法写入数据卷

**解决：**
```bash
# 修复权限
docker run --rm -v openclaw-dev-data:/data alpine chown -R 1001:1001 /data
```

### 问题 3：数据卷损坏

**症状：** 容器无法启动，数据卷错误

**解决：**
```bash
# 1. 备份当前数据（如果可能）
./docker-backup.sh

# 2. 删除并重建数据卷
docker volume rm openclaw-dev-data openclaw-dev-skills
docker volume create openclaw-dev-data
docker volume create openclaw-dev-skills

# 3. 从备份恢复
./docker-restore.sh <backup-name>
```

### 问题 4：配置迁移失败

**症状：** 更新后出现 "Invalid config" 错误

**解决：**
```bash
# 1. 运行配置修复
openclaw doctor --fix

# 2. 如果失败，手动修复
jq 'del(.agents.list[].invalidField)' ~/.openclaw/openclaw.json > /tmp/config.json
mv /tmp/config.json ~/.openclaw/openclaw.json

# 3. 重启 Gateway
./docker-dev.sh restart
```

## 📋 最佳实践

### ✅ DO（推荐做法）

1. **定期备份**
   - 每天自动备份
   - 重大更改前手动备份
   - 备份到多个位置（本地 + 远程）

2. **版本更新前备份**
   ```bash
   ./docker-backup.sh      # 备份
   git pull origin main    # 更新代码
   ./docker-dev.sh rebuild # 重建镜像
   ```

3. **验证备份**
   - 定期测试恢复流程
   - 验证备份文件完整性
   - 检查备份清单

4. **监控数据增长**
   - 定期检查数据卷大小
   - 清理旧的会话日志
   - 归档不常用的数据

5. **使用版本控制**
   - 配置文件可以版本控制（去除敏感信息）
   - 技能和工具脚本应该版本控制

### ❌ DON'T（避免做法）

1. **不要删除数据卷**
   ```bash
   # ❌ 错误：会丢失所有数据
   docker compose down -v

   # ✅ 正确：只删除容器
   docker compose down
   ```

2. **不要跳过备份**
   - 更新前必须备份
   - 删除数据前必须备份
   - 实验性操作前必须备份

3. **不要忽略错误**
   - 配置验证失败立即修复
   - 数据卷错误立即处理
   - 不要带着错误运行

4. **不要手动编辑数据卷**
   - 使用 CLI 命令修改配置
   - 不要直接编辑容器内的文件
   - 让 OpenClaw 管理数据结构

## 📚 相关文档

- [Docker 开发环境指南](DOCKER_DEV.md)
- [OpenClaw 运维指南](../openclaw-ops/README.md)
- [备份恢复脚本](docker-backup.sh, docker-restore.sh)

## 🆘 获取帮助

- 数据恢复问题：运行 `openclaw doctor`
- 备份问题：检查 `backups/` 目录中的清单文件
- 配置问题：查看 `~/.openclaw/openclaw.json`

---

**更新时间：** 2026-02-05
**维护者：** OpenClaw Community
