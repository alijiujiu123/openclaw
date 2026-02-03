# 测试部署服务器 - 环境要求

**目标：** 测试三个项目的部署和运行

---

## 🖥️ 最低配置

**CPU:** 2 核心或更多
**内存:** 2GB RAM (推荐 4GB)
**磁盘:** 20GB 可用空间
**系统:** Linux (推荐 Ubuntu 20.04+ / CentOS 8+ / OpenCloudOS 9+)

---

## 📦 必需软件

### 1. Docker & Docker Compose

**用途：** 测试 Docker 镜像部署

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh

# 启动 Docker
systemctl start docker
systemctl enable docker

# 安装 Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 验证
docker --version
docker-compose --version
```

**预期版本：**
- Docker: 20.10+
- Docker Compose: 2.0+

---

### 2. Node.js 22+

**用途：** 运行 OpenClaw 和 Daily Briefing System

```bash
# 使用 NodeSource 仓库
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# 或 RHEL/CentOS
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
yum install -y nodejs

# 验证
node --version  # 应该是 v22.x.x
npm --version
```

---

### 3. Git

**用途：** 克隆代码仓库

```bash
# Ubuntu/Debian
apt install -y git

# RHEL/CentOS
yum install -y git

# 验证
git --version
```

---

### 4. 智谱 AI API Key

**用途：** AI 模型调用

1. 访问: https://open.bigmodel.cn/usercenter/apikeys
2. 注册/登录
3. 创建 API Key
4. 保存供配置使用

**费用：**
- 新用户有免费额度
- GLM-4.7: 按量计费
- 建议预充值 ¥50-100 用于测试

---

## 🔧 可选但推荐

### 5. systemd

**用途：** 服务管理（通常已预装）

```bash
systemctl --version
```

### 6. curl/wget

**用途：** 下载脚本

```bash
apt install -y curl wget  # Ubuntu/Debian
yum install -y curl wget  # RHEL/CentOS
```

### 7. 文本编辑器

```bash
# 任选其一
apt install -y vim nano  # Ubuntu/Debian
yum install -y vim nano  # RHEL/CentOS
```

---

## 🚀 快速验证脚本

保存为 `check-env.sh` 并运行：

```bash
#!/bin/bash

echo "═══════════════════════════════════════════════════════════════"
echo "         环境检查 - 测试部署服务器"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  系统信息"
echo "   操作系统: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "   内核版本: $(uname -r)"
echo "   架构: $(uname -m)"
echo ""

echo "2️⃣  硬件资源"
echo "   CPU 核心: $(nproc)"
echo "   内存总量: $(free -h | grep Mem | awk '{print $2}')"
echo "   磁盘空间: $(df -h / | tail -1 | awk '{print $4}') 可用"
echo ""

echo "3️⃣  Docker"
if command -v docker &> /dev/null; then
    echo "   ✅ Docker: $(docker --version)"
    if systemctl is-active --quiet docker; then
        echo "   ✅ Docker 服务运行中"
    else
        echo "   ❌ Docker 服务未运行"
    fi
else
    echo "   ❌ Docker 未安装"
fi

if command -v docker-compose &> /dev/null; then
    echo "   ✅ Docker Compose: $(docker-compose --version)"
else
    echo "   ❌ Docker Compose 未安装"
fi
echo ""

echo "4️⃣  Node.js"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   Node.js: $NODE_VERSION"
    if [[ "$NODE_VERSION" == "v22"* ]]; then
        echo "   ✅ 版本符合要求 (22+)"
    else
        echo "   ⚠️  版本过低，需要 v22+"
    fi
    echo "   npm: $(npm --version)"
else
    echo "   ❌ Node.js 未安装"
fi
echo ""

echo "5️⃣  Git"
if command -v git &> /dev/null; then
    echo "   ✅ Git: $(git --version)"
else
    echo "   ❌ Git 未安装"
fi
echo ""

echo "6️⃣  systemd"
if command -v systemctl &> /dev/null; then
    echo "   ✅ systemd 可用"
else
    echo "   ⚠️  systemd 不可用"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "检查完成！"
echo "═══════════════════════════════════════════════════════════════"
```

---

## 📋 安装清单

给服务器管理员的清单：

### ✅ 基础环境
- [ ] Linux 系统 (Ubuntu/CentOS/OpenCloudOS)
- [ ] 2+ CPU 核心
- [ ] 2GB+ 内存
- [ ] 20GB+ 磁盘空间
- [ ] Root 或 sudo 权限

### ✅ 软件安装
- [ ] Docker 20.10+
- [ ] Docker Compose 2.0+
- [ ] Node.js 22+
- [ ] Git
- [ ] curl/wget
- [ ] vim/nano

### ✅ 外部服务
- [ ] 智谱 AI API Key
- [ ] （可选）Telegram Bot Token

### ✅ 网络要求
- [ ] 可访问外网
- [ ] 开放端口：18789 (OpenClaw Dashboard)
- [ ] 开放端口：8888 (SSH 隧道，如需)

---

## 🔑 SSH 访问信息

**需要提供：**
```bash
# 服务器信息
服务器 IP: _____________
SSH 端口: _____________ (默认 22)

# 认证方式
□ 密码: _____________
□ SSH 密钥路径: _____________

# 登录命令示例
ssh root@SERVER_IP
# 或
ssh -i /path/to/key.pem root@SERVER_IP
```

---

## 🚀 准备好后

服务器准备就绪后，将进行以下测试：

### 测试 1: Auto-Deployment Skill
```bash
# 运行自动部署
bash /path/to/auto-deploy/install.sh
```

### 测试 2: Docker 部署
```bash
# 拉取镜像并运行
docker run -d --name openclaw \
  -e ZHIPU_API_KEY=xxx \
  -p 18789:18789 \
  openclaw/openclaw:latest
```

### 测试 3: Daily Briefing System
```bash
# 克隆并运行
git clone https://github.com/alijiujiu123/daily-briefing-system.git
cd daily-briefing-system
npm install
npm start
```

---

**创建时间：** 2026-02-02 19:37
**准备时间：** 约 30 分钟
**测试开始：** 20:30
