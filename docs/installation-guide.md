# OpenClaw 完整安装指南 - DigitalOcean/OpenCloudOS

本文档记录了在 OpenCloudOS 9.2 服务器上安装 OpenClaw 并配置智谱 GLM-4.7 模型的完整过程，包括遇到的所有坑点和解决方案。

---

## 📋 目录

- [服务器信息](#服务器信息)
- [前置要求](#前置要求)
- [安装步骤](#安装步骤)
- [配置模型](#配置模型)
- [配置 Gateway](#配置-gateway)
- [访问 Dashboard](#访问-dashboard)
- [常见问题与坑点](#常见问题与坑点)
- [验证清单](#验证清单)
- [维护与监控](#维护与监控)

---

## 🖥️ 服务器信息

**服务器配置：**
- 主机名: YOUR_SERVER_NAME (YOUR_SERVER_IP)
- 操作系统: OpenCloudOS 9.2 (基于 RHEL/CentOS)
- 内核版本: 6.6.47-12.oc9.x86_64
- 架构: x86_64

**已安装软件：**
- Node.js: v22.10.0 ✅
- Git: 已安装 ✅

---

## ✅ 前置要求

### 系统要求

1. **操作系统**: Linux (OpenCloudOS/RHEL/CentOS/Ubuntu)
2. **Node.js**: 22+ (本文使用 v22.10.0)
3. **内存**: 最少 1GB RAM（推荐 2GB+）
4. **磁盘**: 至少 10GB 可用空间
5. **网络**: 需要访问外网（下载依赖和调用 API）

### SSH 访问

确保可以通过 SSH 访问服务器：

```bash
# 直接密码访问
ssh root@YOUR_SERVER_IP

# 或使用密钥访问
ssh -i /path/to/key.pem root@YOUR_SERVER_IP
```

---

## 📦 安装步骤

### 步骤 1: 连接到服务器

```bash
# SSH 连接
ssh root@YOUR_SERVER_IP
```

### 步骤 2: 检查系统环境

```bash
# 查看系统信息
uname -a
cat /etc/os-release

# 检查 Node.js 版本
node --version

# 如果没有 Node.js，需要安装（见附录 A）
```

**预期输出：**
```
Linux VM-12-9-opencloudos 6.6.47-12.oc9.x86_64 #1 SMP PREEMPT_DYNAMIC Tue Sep 24 16:15:42 CST 2024 x86_64 GNU/Linux
PRETTY_NAME="OpenCloudOS 9.2"
v22.10.0
```

### 步骤 3: 安装 OpenClaw

```bash
# 使用官方安装脚本
curl -fsSL https://openclaw.ai/install.sh | bash
```

**安装过程输出：**
```
🦞 OpenClaw Installer
✓ Detected: linux
✓ Node.js v22.10.0 found
✓ Git already installed
→ Installing OpenClaw 2026.1.30...
✓ OpenClaw installed
```

**验证安装：**
```bash
openclaw --version
```

**预期输出：**
```
2026.1.30
```

---

### ⚠️ 坑点 1: 安装脚本警告

**问题：**
安装过程中会看到以下警告：
```
ExperimentalWarning: Importing JSON modules is an experimental feature
[DEP0040] DeprecationWarning: The `punycode` module is deprecated
```

**解决方案：**
这些是 Node.js 的警告，**不影响功能**，可以安全忽略。

---

### 步骤 4: 修复目录权限和结构

安装脚本会自动运行 doctor，可能检测到以下问题：

```bash
# 手动修复（如果 doctor 没有自动修复）
chmod 700 ~/.openclaw
mkdir -p ~/.openclaw/agents/main/sessions
mkdir -p ~/.openclaw/credentials
```

**坑点说明：**
- `~/.openclaw/` 目录权限必须是 700
- 会话目录和 OAuth 目录必须手动创建
- 否则后续启动会报错

---

### 步骤 5: 配置 Gateway 模式

```bash
# 设置 Gateway 为本地模式
openclaw config set gateway.mode local
```

**输出：**
```
Updated gateway.mode. Restart the gateway to apply.
```

---

### 步骤 6: 安装 Gateway 服务

```bash
# 安装 systemd 服务
openclaw gateway install

# 启动服务
openclaw gateway start
```

**坑点 2: Gateway 启动失败**

**问题：**
```bash
Gateway auth is set to token, but no token is configured.
Set gateway.auth.token (or OPENCLAW_GATEWAY_TOKEN), or pass --token.
```

**原因：**
OpenClaw Gateway 默认需要配置认证令牌。

---

## 🔑 配置 Gateway 认证

### 方法 1: 使用配置文件（推荐）

编辑配置文件：
```bash
vi ~/.openclaw/openclaw.json
```

添加 Gateway 认证配置：
```json
{
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "token": "你的自定义token"
    }
  }
}
```

### 方法 2: 使用 systemd 服务文件

**坑点 3: systemd 服务配置**

如果通过 systemd 启动，需要编辑服务文件：

```bash
# 编辑服务文件
vi ~/.config/systemd/user/openclaw-gateway.service
```

**完整的服务文件内容：**
```ini
[Unit]
Description=OpenClaw Gateway (v2026.1.30)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart="/usr/local/bin/node" "/usr/local/lib/node_modules/openclaw/dist/index.js" gateway --port 18789
Restart=always
RestartSec=5
KillMode=process
Environment=HOME=/root
Environment="PATH=/root/.local/bin:/root/.npm-global/bin:/root/bin:/root/.nvm/current/bin:/root/.fnm/current/bin:/root/.volta/bin:/root/.asdf/shims:/root/.local/share/pnpm:/root/.bun/bin:/usr/local/bin:/usr/bin:/bin"
Environment=OPENCLAW_GATEWAY_PORT=18789
Environment="OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
Environment=OPENCLAW_SERVICE_MARKER=openclaw
Environment=OPENCLAW_SERVICE_KIND=gateway
Environment=OPENCLAW_SERVICE_VERSION=2026.1.30

[Install]
WantedBy=default.target
```

**重载并重启：**
```bash
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user restart openclaw-gateway.service
```

---

### 步骤 7: 验证 Gateway 运行状态

```bash
# 检查服务状态
systemctl --user status openclaw-gateway.service

# 检查 Gateway 状态
openclaw gateway status

# 查看日志
journalctl --user -u openclaw-gateway.service -f
```

**预期输出（服务状态）：**
```
● openclaw-gateway.service - OpenClaw Gateway (v2026.1.30)
   Loaded: loaded (/root/.config/systemd/user/openclaw-gateway.service; enabled)
   Active: active (running) since Mon 2026-02-02 16:58:45 CST
```

**预期输出（Gateway 状态）：**
```
Gateway: bind=loopback (127.0.0.1), port=18789
Runtime: running (pid 1079167, state active)
RPC probe: ok
Listening: 127.0.0.1:18789
```

---

## 🤖 配置智谱 GLM-4.7 模型

### 步骤 1: 获取智谱 API Key

1. 访问智谱开放平台：https://open.bigmodel.cn/usercenter/apikeys
2. 注册/登录账户
3. 创建 API Key
4. 复制保存（格式类似：`YOUR_ZHIPU_API_KEY`）

**费用说明：**
- GLM-4.7: 最新最强模型
- GLM-4.6: 性价比高
- GLM-4.5-air: 轻量版，速度快
- 新用户有免费额度

### 步骤 2: 配置 OpenClaw 使用智谱模型

编辑配置文件：
```bash
vi ~/.openclaw/openclaw.json
```

**完整配置文件示例：**
```json
{
  "meta": {
    "lastTouchedVersion": "2026.1.30",
    "lastTouchedAt": "2026-02-02T07:20:40.217Z"
  },
  "wizard": {
    "lastRunAt": "2026-02-02T07:20:09.791Z",
    "lastRunVersion": "2026.1.30",
    "lastRunCommand": "doctor",
    "lastRunMode": "remote"
  },
  "env": {
    "ZHIPU_API_KEY": "你的智谱APIKey"
  },
  "agents": {
    "defaults": {
      "compaction": {
        "mode": "safeguard"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      },
      "model": {
        "primary": "zhipu/GLM-4.7"
      }
    }
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "models": {
    "providers": {
      "zhipu": {
        "baseUrl": "https://open.bigmodel.cn/api/coding/paas/v4",
        "apiKey": "${ZHIPU_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "GLM-4.7",
            "name": "GLM-4.7"
          },
          {
            "id": "GLM-4.6",
            "name": "GLM-4.6"
          },
          {
            "id": "GLM-4.5-air",
            "name": "GLM-4.5-air"
          }
        ]
      }
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "token": "YOUR_GATEWAY_TOKEN"
    },
    "remote": {
      "url": "ws://127.0.0.1:18789",
      "token": "YOUR_REMOTE_TOKEN"
    }
  }
}
```

**配置说明：**
- `env.ZHIPU_API_KEY`: 智谱 API 密钥
- `agents.defaults.model.primary`: 默认使用 GLM-4.7
- `models.providers.zhipu`: 自定义 provider 配置
  - `baseUrl`: 智谱 OpenAI 兼容 API 地址
  - `api`: 使用 OpenAI 兼容协议
  - `models`: 支持的模型列表
- `gateway.auth.token`: Dashboard 访问令牌

### 步骤 3: 重启 Gateway 应用配置

```bash
# 重启服务
systemctl --user restart openclaw-gateway.service

# 等待几秒让服务完全启动
sleep 3

# 验证配置
openclaw status | grep "GLM-4.7"
```

**预期输出：**
```
Sessions: 1 active · default GLM-4.7 (200k ctx)
```

---

## 🌐 访问 Dashboard

### 步骤 1: 建立 SSH 隧道

由于 Gateway 绑定到本地回环地址（127.0.0.1），需要通过 SSH 隧道访问。

**在本地电脑运行：**

```bash
# 使用端口 8888（推荐）
ssh -L 8888:localhost:18789 root@YOUR_SERVER_IP

# 或使用其他端口
ssh -L 8080:localhost:18789 root@YOUR_SERVER_IP
ssh -L 3000:localhost:18789 root@YOUR_SERVER_IP
```

**命令说明：**
- `-L 8888:localhost:18789`:
  - `8888` = 本地电脑端口
  - `localhost:18789` = 服务器上的 Gateway 地址
- 这个 SSH 窗口需要保持打开

**后台运行（可选）：**
```bash
# 在本地电脑的新终端窗口运行
ssh -N -L 8888:localhost:18789 root@YOUR_SERVER_IP
```
- `-N`: 不执行远程命令，只做端口转发
- 这个窗口可以最小化，但不能关闭

### 步骤 2: 访问 Dashboard

**在浏览器中打开：**
```
http://localhost:8888
```

### 步骤 3: 配置 Dashboard Token

**坑点 4: Dashboard 认证错误**

**问题：**
打开聊天页面时显示：
```
Disconnected (1008): unauthorized: gateway token missing
```

**解决方案：**

**方法 1: 在 Dashboard 设置中配置**
1. 点击右上角 **⚙️ 设置图标**
2. 找到 **Gateway** 或 **Connection** 设置
3. 在 **Token** 输入框中粘贴：`YOUR_GATEWAY_TOKEN`
4. 保存并刷新页面

**方法 2: 使用带 Token 的 URL（推荐）**
```
http://localhost:8888/chat?session=main&token=YOUR_GATEWAY_TOKEN
```

将此 URL 加入书签，以后直接使用。

---

## ⚠️ 常见问题与坑点

### 坑点 1: Node.js 版本过低

**问题：**
```
Error: Node.js version 22 or higher is required
```

**解决方案：**

在 OpenCloudOS/RHEL/CentOS 上安装 Node.js 22：

```bash
# 使用 NodeSource 仓库
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
# 或
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -

# 安装 Node.js
apt install -y nodejs  # Ubuntu/Debian
# 或
yum install -y nodejs  # RHEL/CentOS/OpenCloudOS

# 验证版本
node --version
```

### 坑点 2: Gateway 启动失败 - 缺少 Token

**问题：**
```
Gateway auth is set to token, but no token is configured.
```

**原因：**
配置文件中没有设置 `gateway.auth.token`。

**解决方案：**

**选项 A: 在配置文件中设置**
```bash
vi ~/.openclaw/openclaw.json
```

添加：
```json
{
  "gateway": {
    "auth": {
      "token": "你的自定义token"
    }
  }
}
```

**选项 B: 通过命令行参数**
```bash
vi ~/.config/systemd/user/openclaw-gateway.service
```

修改 `ExecStart`：
```ini
ExecStart="/usr/local/bin/node" "/usr/local/lib/node_modules/openclaw/dist/index.js" gateway --port 18789 --token 你的自定义token
```

然后重载并重启：
```bash
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway.service
```

### 坑点 3: Gateway 认证模式配置错误

**问题：**
```
gateway.auth.mode: Invalid input
```

**原因：**
`gateway.auth.mode` 不支持 `"none"` 值。

**解决方案：**
- 删除 `gateway.auth.mode` 配置
- 或使用 `gateway.auth.token` 设置 token
- 或使用 `gateway.auth.password` 设置密码

### 坑点 4: 目录权限问题

**问题：**
```
State directory permissions are too open (~/.openclaw)
```

**解决方案：**
```bash
chmod 700 ~/.openclaw
chmod 700 ~/.openclaw/credentials
```

### 坑点 5: 旧配置残留

**问题：**
从旧的 clawdbot 升级后，配置文件路径变化导致问题。

**解决方案：**
```bash
# 运行 doctor 自动迁移
openclaw doctor --fix

# 或手动清理
rm -rf ~/.clawdbot
rm -rf ~/.openclaw
# 重新安装
```

### 坑点 6: systemd 用户服务未启用

**问题：**
```bash
systemctl: command not found
# 或
Failed to connect to bus: No such file or directory
```

**原因：**
用户级 systemd 未正确初始化。

**解决方案：**
```bash
# 确保 systemd 用户服务运行
export XDG_RUNTIME_DIR=/run/user/$(id -u)
systemctl --user daemon-reload

# 登出并重新登录可能需要
```

### 坑点 7: SSH 隧道端口被占用

**问题：**
```
ssh: bind port 8888: Address already in use
```

**解决方案：**

**方法 1: 使用其他端口**
```bash
ssh -L 8080:localhost:18789 root@YOUR_SERVER_IP
ssh -L 3000:localhost:18789 root@YOUR_SERVER_IP
```

**方法 2: 查找并释放端口**
```bash
# macOS/Linux
lsof -ti:8888 | xargs kill -9

# 或
lsof -i :8888
# 找到进程 ID
kill -9 <PID>
```

### 坑点 8: Gateway 日志中的警告

**问题：**
```
ExperimentalWarning: Importing JSON modules is an experimental feature
[DEP0040] DeprecationWarning: The `punycode` module is deprecated
```

**说明：**
这些是 Node.js 的警告，**不影响功能**，可以安全忽略。

如果不想看到这些警告，可以设置环境变量：
```bash
export NODE_OPTIONS="--no-warnings"
```

但在生产环境中建议保留警告以监控潜在问题。

### 坑点 9: Dashboard 无法连接 Gateway

**问题：**
Dashboard 显示 "Disconnected" 或 "Connection failed"

**排查步骤：**

1. **检查 Gateway 是否运行：**
   ```bash
   ssh root@YOUR_SERVER_IP
   systemctl --user status openclaw-gateway.service
   ```

2. **检查端口是否监听：**
   ```bash
   ss -ltnp | grep 18789
   ```

3. **检查 SSH 隧道是否建立：**
   ```bash
   # 在本地电脑
   lsof -i :8888
   ```

4. **检查防火墙：**
   ```bash
   # 服务器上
   firewall-cmd --list-all
   # 或
   iptables -L -n
   ```

5. **查看 Gateway 日志：**
   ```bash
   journalctl --user -u openclaw-gateway.service -f
   ```

### 坑点 10: 模型调用失败

**问题：**
Dashboard 中发送消息无响应或报错。

**排查步骤：**

1. **检查 API Key 是否正确：**
   ```bash
   cat ~/.openclaw/openclaw.json | grep ZHIPU_API_KEY
   ```

2. **测试模型连接：**
   ```bash
   # 手动测试 API
   curl https://open.bigmodel.cn/api/paas/v4/chat/completions \
     -H "Authorization: Bearer 你的APIKey" \
     -H "Content-Type: application/json" \
     -d '{"model":"glm-4.7","messages":[{"role":"user","content":"你好"}]}'
   ```

3. **检查网络连接：**
   ```bash
   curl -I https://open.bigmodel.cn
   ping open.bigmodel.cn
   ```

4. **查看详细日志：**
   ```bash
   journalctl --user -u openclaw-gateway.service -n 100 --no-pager
   ```

---

## ✅ 验证清单

安装完成后，使用此清单验证所有组件正常工作。

### 1. 系统级检查

```bash
# SSH 到服务器
ssh root@YOUR_SERVER_IP

# 检查 Node.js 版本
node --version
# 应该输出: v22.10.0 或更高

# 检查 OpenClaw 版本
openclaw --version
# 应该输出: 2026.1.30

# 检查配置文件语法
cat ~/.openclaw/openclaw.json | jq .
# 应该是有效的 JSON
```

### 2. 服务状态检查

```bash
# 检查 Gateway 服务
systemctl --user status openclaw-gateway.service
# 应该显示: Active: active (running)

# 检查端口监听
ss -ltnp | grep 18789
# 应该显示: 127.0.0.1:18789 和 [::1]:18789

# 检查 Gateway 状态
openclaw gateway status
# 应该显示: Runtime: running
```

### 3. 配置验证

```bash
# 检查模型配置
openclaw status | grep "GLM-4.7"
# 应该显示: default GLM-4.7 (200k ctx)

# 检查认证配置
cat ~/.openclaw/openclaw.json | grep -A 2 '"auth"'
# 应该显示 token 配置

# 检查 API Key 配置
cat ~/.openclaw/openclaw.json | grep ZHIPU_API_KEY
# 应该显示你的 API Key
```

### 4. Dashboard 访问检查

```bash
# 在本地电脑建立 SSH 隧道
ssh -L 8888:localhost:18789 root@YOUR_SERVER_IP

# 在浏览器打开
open http://localhost:8888
# 或
chrome http://localhost:8888
```

**检查项：**
- [ ] Dashboard 页面正常加载
- [ ] 可以访问聊天页面（带 token）
- [ ] 可以发送消息
- [ ] AI 能够正常回复
- [ ] 可以看到模型名称（GLM-4.7）
- [ ] 可以查看会话历史

### 5. 功能测试

**测试对话：**
1. 打开 http://localhost:8888/chat?session=main&token=YOUR_GATEWAY_TOKEN
2. 发送测试消息："你好"
3. 等待 AI 回复
4. 检查回复是否使用 GLM-4.7

**测试命令行：**
```bash
# SSH 到服务器
ssh root@YOUR_SERVER_IP

# 测试模型列表
openclaw models list
# 应该显示: zhipu/GLM-4.7, zhipu/GLM-4.6, zhipu/GLM-4.5-air

# 查看完整状态
openclaw status
# 检查所有部分是否正常
```

---

## 🔧 维护与监控

### 日常维护命令

```bash
# SSH 到服务器
ssh root@YOUR_SERVER_IP

# 查看服务状态
systemctl --user status openclaw-gateway.service

# 查看实时日志
journalctl --user -u openclaw-gateway.service -f

# 查看最近 100 条日志
journalctl --user -u openclaw-gateway.service -n 100 --no-pager

# 重启服务
systemctl --user restart openclaw-gateway.service

# 查看 OpenClaw 状态
openclaw status

# 查看会话历史
ls -lh ~/.openclaw/agents/main/sessions/

# 备份配置和数据
tar -czvf openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw
```

### 监控资源使用

```bash
# 查看内存使用
free -h

# 查看 CPU 和内存（实时）
htop
# 或
top

# 查看 Gateway 进程资源使用
ps aux | grep openclaw-gateway

# 查看磁盘使用
df -h

# 查看日志文件大小
du -sh /tmp/openclaw/
ls -lh /tmp/openclaw/openclaw-*.log
```

### 日志管理

```bash
# 日志位置
/tmp/openclaw/openclaw-YYYY-MM-DD.log  # 文件日志
journalctl --user -u openclaw-gateway.service  # systemd 日志

# 清理旧日志（保留最近 7 天）
find /tmp/openclaw/ -name "openclaw-*.log" -mtime +7 -delete

# 或使用 logrotate
vi /etc/logrotate.d/openclaw
```

**logrotate 配置示例：**
```
/tmp/openclaw/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
```

### 更新 OpenClaw

```bash
# SSH 到服务器
ssh root@YOUR_SERVER_IP

# 检查更新
openclaw --version

# 更新到最新版本
npm update -g openclaw

# 或使用安装脚本重新安装
curl -fsSL https://openclaw.ai/install.sh | bash

# 重启服务
systemctl --user restart openclaw-gateway.service

# 验证更新
openclaw --version
openclaw status
```

### 备份与恢复

**备份：**
```bash
# 创建备份脚本
cat > ~/backup-openclaw.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=/root/backups
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# 备份配置和数据
tar -czvf $BACKUP_DIR/openclaw-$DATE.tar.gz ~/.openclaw

# 保留最近 30 天的备份
find $BACKUP_DIR -name "openclaw-*.tar.gz" -mtime +30 -delete

echo "Backup completed: openclaw-$DATE.tar.gz"
EOF

chmod +x ~/backup-openclaw.sh

# 手动备份
~/backup-openclaw.sh

# 添加到 crontab（每天凌晨 2 点备份）
crontab -e
# 添加以下行：
# 0 2 * * * /root/backup-openclaw.sh >> /var/log/openclaw-backup.log 2>&1
```

**恢复：**
```bash
# 停止服务
systemctl --user stop openclaw-gateway.service

# 备份当前配置
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak

# 解压备份
tar -xzvf /root/backups/openclaw-YYYYMMDD_HHMMSS.tar.gz -C /

# 重启服务
systemctl --user start openclaw-gateway.service
```

### 故障排查流程

**问题：服务无法启动**

```bash
# 1. 检查服务状态
systemctl --user status openclaw-gateway.service

# 2. 查看详细日志
journalctl --user -u openclaw-gateway.service -n 50 --no-pager

# 3. 检查配置文件
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# 4. 验证配置
openclaw doctor --non-interactive

# 5. 手动运行（查看详细错误）
/usr/local/bin/node /usr/local/lib/node_modules/openclaw/dist/index.js gateway --port 18789
```

**问题：Dashboard 无法连接**

```bash
# 1. 检查 Gateway 是否运行
systemctl --user is-active openclaw-gateway.service

# 2. 检查端口监听
ss -ltnp | grep 18789

# 3. 检查防火墙
firewall-cmd --list-all
iptables -L -n

# 4. 测试本地连接
curl http://127.0.0.1:18789

# 5. 检查 SSH 隧道
# 在本地电脑运行
lsof -i :8888
```

**问题：模型调用失败**

```bash
# 1. 检查 API Key
cat ~/.openclaw/openclaw.json | grep ZHIPU_API_KEY

# 2. 测试 API 连接
curl https://open.bigmodel.cn/api/paas/v4/models \
  -H "Authorization: Bearer 你的APIKey"

# 3. 查看 Gateway 日志
journalctl --user -u openclaw-gateway.service -f | grep -i error

# 4. 检查网络
ping open.bigmodel.cn
curl -I https://open.bigmodel.cn
```

---

## 📚 附录

### 附录 A: 在 OpenCloudOS 上安装 Node.js 22

如果服务器没有 Node.js 或版本过低：

```bash
# 方法 1: 使用 NodeSource 官方仓库（推荐）
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
yum install -y nodejs

# 验证安装
node --version
npm --version

# 方法 2: 使用 NVM（推荐用于开发环境）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 22
nvm use 22

# 方法 3: 从官网下载二进制包
cd /usr/local/src
wget https://nodejs.org/dist/v22.10.0/node-v22.10.0-linux-x64.tar.xz
tar -xf node-v22.10.0-linux-x64.tar.xz
ln -s /usr/local/src/node-v22.10.0-linux-x64/bin/node /usr/local/bin/node
ln -s /usr/local/src/node-v22.10.0-linux-x64/bin/npm /usr/local/bin/npm
```

### 附录 B: systemd 服务配置详解

**服务文件路径：**
```
~/.config/systemd/user/openclaw-gateway.service
```

**关键字段说明：**

| 字段 | 说明 |
|------|------|
| `After=network-online.target` | 等待网络就绪后启动 |
| `Wants=network-online.target` | 依赖网络服务 |
| `ExecStart=` | 启动命令及参数 |
| `Restart=always` | 总是自动重启 |
| `RestartSec=5` | 重启前等待 5 秒 |
| `Environment=` | 环境变量设置 |
| `WantedBy=default.target` | 安装到默认运行级别 |

**常用命令：**
```bash
# 重载配置
systemctl --user daemon-reload

# 启用服务（开机自启）
systemctl --user enable openclaw-gateway.service

# 禁用服务
systemctl --user disable openclaw-gateway.service

# 启动服务
systemctl --user start openclaw-gateway.service

# 停止服务
systemctl --user stop openclaw-gateway.service

# 重启服务
systemctl --user restart openclaw-gateway.service

# 查看状态
systemctl --user status openclaw-gateway.service

# 查看日志
journalctl --user -u openclaw-gateway.service
```

### 附录 C: 配置文件完整参考

**配置文件路径：**
```
~/.openclaw/openclaw.json
```

**完整配置示例（带注释）：**
```json
{
  // 元数据（自动生成，不要手动修改）
  "meta": {
    "lastTouchedVersion": "2026.1.30",
    "lastTouchedAt": "2026-02-02T07:20:40.217Z"
  },

  // 向导配置（自动生成）
  "wizard": {
    "lastRunAt": "2026-02-02T07:20:09.791Z",
    "lastRunVersion": "2026.1.30",
    "lastRunCommand": "doctor",
    "lastRunMode": "remote"
  },

  // 环境变量
  "env": {
    "ZHIPU_API_KEY": "你的智谱APIKey"
  },

  // Agent 配置
  "agents": {
    "defaults": {
      // 会话压缩模式
      "compaction": {
        "mode": "safeguard"
      },
      // 最大并发 agent 数
      "maxConcurrent": 4,
      // 子 agent 配置
      "subagents": {
        "maxConcurrent": 8
      },
      // 默认模型
      "model": {
        "primary": "zhipu/GLM-4.7"
      }
    }
  },

  // 消息配置
  "messages": {
    "ackReactionScope": "group-mentions"
  },

  // 命令配置
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },

  // 模型 provider 配置
  "models": {
    "providers": {
      "zhipu": {
        "baseUrl": "https://open.bigmodel.cn/api/coding/paas/v4",
        "apiKey": "${ZHIPU_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "GLM-4.7",
            "name": "GLM-4.7"
          },
          {
            "id": "GLM-4.6",
            "name": "GLM-4.6"
          },
          {
            "id": "GLM-4.5-air",
            "name": "GLM-4.5-air"
          }
        ]
      }
    }
  },

  // Gateway 配置
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "token": "YOUR_GATEWAY_TOKEN"
    },
    "remote": {
      "url": "ws://127.0.0.1:18789",
      "token": "YOUR_REMOTE_TOKEN"
    }
  }
}
```

### 附录 D: 常用端口说明

| 端口 | 用途 | 说明 |
|------|------|------|
| 18789 | Gateway 服务 | 绑定到 127.0.0.1，仅本地访问 |
| 8888 | SSH 隧道本地端口 | 可自定义，建议使用 8080/8888/3000 |
| 22 | SSH | 远程登录服务器 |

### 附录 E: 目录结构说明

```
~/.openclaw/                    # OpenClaw 主目录
├── openclaw.json               # 主配置文件
├── canvas/                     # Canvas 相关数据
├── workspace/                  # 工作空间（SOUL.md 等）
├── agents/                     # Agent 配置和会话
│   └── main/
│       └── sessions/
│           └── sessions.json   # 会话历史
└── credentials/                # 凭据存储（OAuth 等）

~/.config/systemd/user/         # systemd 用户服务
└── openclaw-gateway.service    # Gateway 服务文件

/tmp/openclaw/                  # 临时文件和日志
└── openclaw-YYYY-MM-DD.log     # 按日期滚动的日志
```

### 附录 F: 快速参考命令卡

```bash
# === 基本操作 ===
openclaw --version              # 查看版本
openclaw status                 # 查看状态
openclaw doctor                 # 诊断问题
openclaw doctor --fix           # 自动修复

# === 服务管理 ===
systemctl --user start openclaw-gateway.service     # 启动
systemctl --user stop openclaw-gateway.service      # 停止
systemctl --user restart openclaw-gateway.service   # 重启
systemctl --user status openclaw-gateway.service    # 状态

# === 日志查看 ===
journalctl --user -u openclaw-gateway.service -f    # 实时日志
journalctl --user -u openclaw-gateway.service -n 100 # 最近 100 行
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log # 文件日志

# === 配置管理 ===
openclaw config set <key> <value>  # 设置配置
openclaw config get <key>           # 获取配置
openclaw config delete <key>        # 删除配置

# === 模型管理 ===
openclaw models list                # 列出模型
openclaw models set <provider/model> # 设置默认模型
openclaw model test <model>         # 测试模型

# === 更新 ===
npm update -g openclaw              # 更新 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash # 重新安装
```

---

## 📞 获取帮助

**官方文档：**
- 主文档: https://docs.openclaw.ai
- 故障排查: https://docs.openclaw.ai/troubleshooting
- 配置参考: https://docs.openclaw.ai/gateway/configuration

**社区资源：**
- GitHub Issues: https://github.com/openclaw/openclaw/issues
- Discord 社区: https://discord.gg/openclaw

**常用诊断命令：**
```bash
# 完整诊断
openclaw doctor

# 安全审计
openclaw security audit

# 深度探测
openclaw channels status --probe

# 查看完整状态
openclaw status --all
```

---

## 🎯 总结

本文档涵盖了 OpenClaw 在 OpenCloudOS 服务器上的完整安装过程，包括：

1. ✅ 系统环境准备
2. ✅ OpenClaw 安装
3. ✅ Gateway 配置和启动
4. ✅ 智谱 GLM-4.7 模型配置
5. ✅ Dashboard 访问配置
6. ✅ 10+ 个常见坑点和解决方案
7. ✅ 完整的验证清单
8. ✅ 日常维护和监控指南
9. ✅ 故障排查流程

**关键要点：**
- Node.js 22+ 是必需的
- Gateway 必须配置认证 token
- Dashboard 访问需要 SSH 隧道
- 智谱模型使用 OpenAI 兼容协议
- 定期备份配置和会话数据

**服务器信息：**
- 主机: YOUR_SERVER_NAME (YOUR_SERVER_IP)
- 系统: OpenCloudOS 9.2
- OpenClaw: 2026.1.30
- 模型: 智谱 GLM-4.7
- Dashboard: http://localhost:8888 (需要 SSH 隧道)
- Token: YOUR_GATEWAY_TOKEN

祝你使用愉快！🦞
