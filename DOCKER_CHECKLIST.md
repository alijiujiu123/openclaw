# OpenClaw Docker 数据持久化检查清单

## ✅ 首次设置检查清单

- [ ] 复制 `.env.example` 到 `.env`
- [ ] 配置至少一个模型 API Key（ZHIPU_API_KEY 或 OPENAI_API_KEY）
- [ ] 设置 GATEWAY_TOKEN（可选，默认 auto）
- [ ] 运行 `./docker-dev.sh start` 启动环境
- [ ] 运行 `./docker-dev.sh status` 检查状态
- [ ] 进入容器 `./docker-dev.sh shell`
- [ ] 运行 `openclaw status` 验证配置
- [ ] 运行 `openclaw doctor` 检查健康状态

## 🛡️ 日常使用检查清单

### 版本更新前

- [ ] 备份当前数据：`./docker-dev.sh backup`
- [ ] 验证备份文件：`ls -lh backups/`
- [ ] 记录当前版本：`git rev-parse HEAD`
- [ ] 拉取最新代码：`git pull origin main`
- [ ] 重新构建镜像：`./docker-dev.sh rebuild`
- [ ] 重启容器：`./docker-dev.sh restart`
- [ ] 验证数据完整性：`openclaw status`
- [ ] 测试关键功能是否正常

### 日常开发结束前

- [ ] 提交代码更改：`git commit`
- [ ] 备份重要数据：`./docker-dev.sh backup`
- [ ] 检查容器状态：`./docker-dev.sh status`
- [ ] 查看日志是否有错误：`./docker-dev.sh logs`

## 🔍 数据验证检查清单

### 每周验证

- [ ] 检查数据卷大小：`docker system df -v | grep openclaw`
- [ ] 验证配置完整性：`openclaw doctor`
- [ ] 列出所有 Agent：`openclaw agents list`
- [ ] 检查会话文件：`ls -la ~/.openclaw/agents/*/sessions/`
- [ ] 测试备份恢复流程（在测试环境）

### 每月维护

- [ ] 清理旧备份（保留最近 7 天）
- [ ] 备份到远程：`rsync -avz backups/ user@remote:/backups/`
- [ ] 检查磁盘空间使用
- [ ] 审查 API 密钥安全性
- [ ] 更新依赖（如果需要）

## 🚨 紧急恢复检查清单

### 数据丢失场景

- [ ] 立即停止容器：`./docker-dev.sh stop`
- [ ] 不要写入任何数据
- [ ] 查找最近备份：`ls -lt backups/`
- [ ] 验证备份完整性：`./docker-restore.sh`
- [ ] 选择恢复点：`./docker-restore.sh <backup-name>`
- [ ] 验证恢复结果：`openclaw status`
- [ ] 测试关键功能

### 容器无法启动

- [ ] 查看错误日志：`docker logs openclaw-dev`
- [ ] 检查配置文件：`cat ~/.openclaw/openclaw.json | jq .`
- [ ] 运行诊断：`openclaw doctor --fix`
- [ ] 检查数据卷：`docker volume ls`
- [ ] 尝试重启：`./docker-dev.sh restart`
- [ ] 如果失败，从备份恢复

## 📋 数据分类检查

### 核心数据（必须备份）

- [ ] `~/.openclaw/openclaw.json` - 主配置文件
- [ ] `~/.openclaw/agents/` - 所有 Agent 配置和记忆
- [ ] `~/.openclaw/channels/` - 所有渠道配置
- [ ] `~/.openclaw/credentials/` - API 凭证
- [ ] `~/.openclaw/sessions/` - 会话历史

### 工作数据（建议备份）

- [ ] `./workspace/` - 工作空间文件
- [ ] 自定义技能和工具
- [ ] 重要的会话日志

### 临时数据（无需备份）

- [ ] `/app/node_modules/` - 可重新安装
- [ ] `/app/dist/` - 可重新构建
- [ ] 容器内临时文件

## 🔐 安全检查清单

### 备份安全

- [ ] 备份文件权限正确：`chmod 600 backups/*`
- [ ] 备份目录权限正确：`chmod 700 backups/`
- [ ] 敏感数据已加密（可选）
- [ ] 备份存储在安全位置
- [ ] 远程备份使用加密传输

### 访问控制

- [ ] .env 文件不在版本控制中
- [ ] API Keys 定期轮换
- [ ] Gateway Token 使用强密码
- [ ] 容器不以 root 用户运行
- [ ] 数据卷权限正确（1001:1001）

## 📊 性能检查清单

### 存储管理

- [ ] 监控数据卷增长率
- [ ] 定期清理旧会话日志
- [ ] 归档不常用的数据
- [ ] 检查磁盘空间使用率

### 备份优化

- [ ] 评估备份大小是否合理
- [ ] 增量备份 vs 完整备份
- [ ] 压缩备份文件
- [ ] 清理过期备份

## 🎯 特殊场景检查

### 迁移到新机器

- [ ] 最后一次备份：`./docker-dev.sh backup`
- [ ] 同步备份到新机器
- [ ] 在新机器安装 Docker
- [ ] 克隆代码仓库
- [ ] 配置 .env 文件
- [ ] 恢复数据：`./docker-restore.sh <backup>`
- [ ] 验证功能正常

### 多人协作

- [ ] 各自使用独立的数据卷
- [ ] 不共享个人配置
- [ ] 代码共享，数据隔离
- [ ] 定期同步开发环境配置

### 生产部署

- [ ] 使用生产级配置文件
- [ ] 配置自动备份
- [ ] 设置监控告警
- [ ] 准备灾难恢复计划
- [ ] 定期演练恢复流程

## 📝 快速参考

### 常用命令速查

```bash
# 启动环境
./docker-dev.sh start

# 备份数据
./docker-dev.sh backup

# 查看状态
./docker-dev.sh status

# 进入容器
./docker-dev.sh shell

# 查看日志
./docker-dev.sh logs

# 停止环境
./docker-dev.sh stop

# 恢复数据
./docker-restore.sh <backup-name>

# 重建镜像
./docker-dev.sh rebuild
```

### 数据位置速查

```bash
# 核心数据（Docker Volume）
docker volume inspect openclaw-dev-data
docker volume inspect openclaw-dev-skills

# 工作空间（本地）
ls -la ./workspace/

# 备份文件（本地）
ls -la ./backups/

# 容器内数据
docker compose -f docker-compose.dev.yml exec openclaw-dev ls -la ~/.openclaw/
```

### 紧急恢复速查

```bash
# 1. 查看可用备份
./docker-restore.sh

# 2. 恢复最新备份
./docker-restore.sh $(ls -t backups/ | grep -oP 'openclaw-backup-\d{8}_\d{6}' | head -1)

# 3. 验证恢复
openclaw status
openclaw agents list
```

## 🆘 获取帮助

- 运行诊断：`openclaw doctor`
- 查看日志：`./docker-dev.sh logs`
- 查看帮助：`./docker-dev.sh help`
- 查看文档：`DOCKER_PERSISTENCE.md`

---

**定期使用此清单确保数据安全！**

**建议频率：**
- 日常检查：每周
- 完整检查：每月
- 恢复演练：每季度
