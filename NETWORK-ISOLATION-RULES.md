# 测试服务器约束和注意事项

**服务器：** 115.191.18.218
**用户：** root

## 🔒 网络隔离约束

**重要：测试服务器无法直接访问外网**

### ✅ 正确的部署流程

```bash
# 1. 本地下载
wget https://example.com/file.tar.gz

# 2. 上传到服务器
scp file.tar.gz root@115.191.18.218:/tmp/

# 3. 在服务器上安装
ssh root@115.191.18.218 "cd /tmp && tar -xzf file.tar.gz && ./install.sh"
```

### ❌ 错误的做法

```bash
# 直接在服务器上下载（会失败）
ssh root@115.191.18.218 "wget https://example.com/file.tar.gz"
# 错误：Failed to connect / Connection timeout
```

---

## 📦 需要本地下载的资源

### 1. Docker 安装
```bash
# 本地下载
curl -fsSL https://get.docker.com -o /tmp/docker-install.sh
# 或使用阿里云镜像
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg -o /tmp/docker-gpg

# 上传
scp /tmp/docker-install.sh root@115.191.18.218:/tmp/

# 服务器安装
ssh root@115.191.18.218 "bash /tmp/docker-install.sh"
```

### 2. Node.js 包
```bash
# 本地打包
cd /root/openclaw-docker
npm pack

# 上传
scp *.tgz root@115.191.18.218:/tmp/

# 服务器安装
ssh root@115.191.18.218 "npm install -g /tmp/*.tgz"
```

### 3. Git 仓库
```bash
# 本地克隆
git clone https://github.com/user/repo.git

# 打包上传
tar -czf repo.tar.gz repo/
scp repo.tar.gz root@115.191.18.218:/root/

# 服务器解压
ssh root@115.191.18.218 "cd /root && tar -xzf repo.tar.gz"
```

### 4. Docker 镜像
```bash
# 本地构建
docker build -t myimage:latest .

# 保存为 tar
docker save myimage:latest -o myimage.tar

# 上传
scp myimage.tar root@115.191.18.218:/tmp/

# 服务器加载
ssh root@115.191.18.218 "docker load -i /tmp/myimage.tar"
```

### 5. 脚本和配置文件
```bash
# 直接上传
scp script.sh root@115.191.18.218:/root/
scp config.json root@115.191.18.218:/root/
```

---

## 🛠️ 实用脚本

### 自动化部署脚本模板
```bash
#!/bin/bash
# deploy-with-network-isolation.sh

REMOTE="root@115.191.18.218"
LOCAL_DIR="/tmp/downloads"
REMOTE_DIR="/tmp"

echo "📦 步骤 1: 本地下载"
mkdir -p $LOCAL_DIR
cd $LOCAL_DIR
wget $1

echo "📤 步骤 2: 上传到服务器"
scp $LOCAL_DIR/* $REMOTE:$REMOTE_DIR/

echo "🔧 步骤 3: 服务器安装"
ssh $REMOTE "cd $REMOTE_DIR && $2"
```

### 批量下载和上传
```bash
#!/bin/bash
# batch-deploy.sh

FILES=(
  "https://get.docker.com"
  "https://nodejs.org/dist/v22.10.0/node-v22.10.0-linux-x64.tar.xz"
  "https://github.com/user/repo/archive/refs/heads/main.zip"
)

REMOTE="root@115.191.18.218"

for URL in "${FILES[@]}"; do
  FILE=$(basename $URL)
  echo "下载 $FILE"
  curl -O $URL
  
  echo "上传 $FILE"
  scp $FILE $REMOTE:/tmp/
done
```

---

## 📝 检查清单

部署前检查：
- [ ] 确认资源已在本地下载
- [ ] 验证文件完整性（MD5/SHA256）
- [ ] 测试 SSH 连接
- [ ] 确认目标目录权限

部署后验证：
- [ ] 检查文件是否成功上传
- [ ] 验证安装/配置是否成功
- [ ] 测试服务是否正常运行

---

## 🚨 常见问题

### Q: 为什么会网络隔离？
A: 测试服务器位于内网环境，防火墙限制外网访问，出于安全考虑。

### Q: 可以配置代理吗？
A: 可以，但需要与服务器管理员确认。当前策略是本地下载后上传。

### Q: 如何验证文件完整性？
A: 使用 checksum：
```bash
# 本地
sha256sum file.tar.gz

# 服务器
sha256sum file.tar.gz
# 对比两次输出
```

### Q: 大文件传输很慢怎么办？
A:
1. 压缩文件：`tar -czf file.tar.gz file/`
2. 使用 rsync：`rsync -avz --progress file.tar.gz root@115.191.18.218:/tmp/`
3. 分割文件：`split -b 100M large.tar.gz large.tar.gz.part`

---

**记住：本地下载 → SCP上传 → 服务器安装**

**更新时间：** 2026-02-02 20:19
