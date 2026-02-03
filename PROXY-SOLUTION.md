# 🌐 代理解决方案 - 完整指南

## 🎯 方案概述

**问题：** 测试服务器网络隔离，无法直接访问外网

**解决方案：** 通过 SSH 隧道提供 SOCKS5 代理

**工作原理：**
```
测试服务器 → SSH隧道(1080) → 本机 → 外网
内网流量 → 直连
```

---

## 🚀 快速开始

### 1. 配置代理（一键脚本）
```bash
bash /root/.openclaw/workspace/setup-proxy.sh
```

这个脚本会：
- ✅ 创建 SSH 隧道（SOCKS5）
- ✅ 配置测试服务器使用代理
- ✅ 设置内网直连例外
- ✅ 测试代理连接

### 2. 安装 Docker（通过代理）
```bash
bash /root/.openclaw/workspace/install-docker-with-proxy.sh
```

---

## 🔧 工作原理详解

### SSH 隧道（SOCKS5）
```bash
ssh -D 1080 -f -C -q -N root@115.191.18.218
```

**参数说明：**
- `-D 1080` - 创建动态端口转发（SOCKS5 代理）
- `-f` - 后台运行
- `-C` - 压缩数据
- `-q` - 静默模式
- `-N` - 不执行远程命令

**效果：**
- 本地端口 1080 转发到服务器的 localhost:1080
- 服务器上 localhost:1080 是 SOCKS5 代理
- 服务器通过这个代理访问外网

### 环境变量配置
```bash
# 在测试服务器上
export http_proxy=socks5h://127.0.0.1:1080
export https_proxy=socks5h://127.0.0.1:1080
export no_proxy=localhost,127.0.0.1,::1,192.168.*,10.*,172.16.*
```

**说明：**
- `socks5h://` - SOCKS5 协议（h 表示主机名解析也通过代理）
- `127.0.0.1:1080` - 本地 SOCKS5 代理
- `no_proxy` - 内网直连（不走代理）

---

## 📊 流量路由

### 外网访问（走代理）
```
测试服务器 → curl https://google.com
           ↓
      检查 $http_proxy
           ↓
      通过 socks5h://127.0.0.1:1080
           ↓
      SSH 隧道 → 本机
           ↓
      本机 → 外网
```

### 内网访问（直连）
```
测试服务器 → curl http://192.168.1.1
           ↓
      检查 $no_proxy
           ↓
      直连，不走代理
```

---

## 🛠️ 管理命令

### 查看隧道状态
```bash
ps aux | grep "ssh.*-D.*root@115.191.18.218.*1080"
```

### 停止隧道
```bash
pkill -f "ssh.*-D.*root@115.191.18.218.*1080"
```

### 重启隧道
```bash
pkill -f "ssh.*-D.*root@115.191.18.218.*1080"
bash /root/.openclaw/workspace/setup-proxy.sh
```

### 测试代理
```bash
# SSH 到测试服务器
ssh root@115.191.18.218

# 测试外网
curl https://www.google.com

# 测试 apt
apt-get update
```

---

## ✅ 优势

1. **无需修改服务器网络配置**
   - 不需要添加路由
   - 不需要配置网关

2. **灵活可控**
   - 需要时启动，不需要时停止
   - 可以随时断开

3. **内网不受影响**
   - 内网服务访问速度不受影响
   - 内网流量不经过代理

4. **安全**
   - 通过 SSH 加密隧道
   - 不需要开放额外端口

---

## ⚠️ 限制

1. **依赖 SSH 连接**
   - SSH 断开，代理失效
   - 本机关机，代理失效

2. **性能**
   - 代理会增加一些延迟
   - 大文件传输可能较慢

3. **单点故障**
   - 本机故障，代理失效

---

## 📝 使用场景

### 场景 1：安装 Docker
```bash
# 1. 启动代理
bash /root/.openclaw/workspace/setup-proxy.sh

# 2. 安装 Docker
bash /root/.openclaw/workspace/install-docker-with-proxy.sh
```

### 场景 2：Git 操作
```bash
ssh root@115.191.18.218
export https_proxy=socks5h://127.0.0.1:1080
git clone https://github.com/user/repo.git
```

### 场景 3：Apt 更新
```bash
ssh root@115.191.18.218
export http_proxy=socks5h://127.0.0.1:1080
apt-get update
apt-get install -y package-name
```

### 场景 4：Curl 下载
```bash
ssh root@115.191.18.218
export https_proxy=socks5h://127.0.0.1:1080
curl -O https://example.com/file.tar.gz
```

---

## 🎯 推荐流程

### Task 0 完整流程
```bash
# 1. 配置代理
bash /root/.openclaw/workspace/setup-proxy.sh

# 2. 安装 Docker
bash /root/.openclaw/workspace/install-docker-with-proxy.sh

# 3. 验证环境
ssh root@115.191.18.218
docker --version
node --version
git --version
```

---

## 🔍 故障排除

### 代理不工作
```bash
# 检查 SSH 隧道
ps aux | grep ssh

# 检查端口占用
netstat -tuln | grep 1080

# 测试 SSH 隧道
telnet 127.0.0.1 1080
```

### Docker 安装失败
```bash
# 检查代理设置
ssh root@115.191.18.218
echo $http_proxy
echo $https_proxy

# 测试外网访问
curl -v https://download.docker.com
```

### Git 不使用代理
```bash
# 配置 Git 代理
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
```

---

**创建时间：** 2026-02-02 21:44  
**状态：** ✅ 脚本已准备就绪  
**下一步：** 运行 setup-proxy.sh 配置代理
