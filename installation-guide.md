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
