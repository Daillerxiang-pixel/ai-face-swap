# AI换图 — 部署手册

> 服务器: 39.102.100.123 | 系统: Ubuntu 22.04 x64

## 目录结构（服务器上）

```
/var/www/ai-face-swap/          ← 应用主目录
├── server/
│   ├── index.js                ← 入口
│   ├── routes/
│   ├── providers/
│   └── data/
│       └── face_swap.db        ← SQLite 数据库
├── uploads/                    ← 用户上传的图片
├── prototype/                  ← 前端原型（开发阶段）
├── .env                        ← 环境变量（手动创建）
├── ecosystem.config.js         ← PM2 配置
├── package.json
└── node_modules/

/var/log/ai-face-swap/          ← 应用日志
├── out.log
├── error.log
└── deploy-*.log

/var/www/backups/ai-face-swap/  ← 数据库备份
└── face_swap-20260323.db
```

## 部署步骤

### 第一步：SSH 连接服务器

```bash
ssh root@39.102.100.123
# 或使用密钥: ssh -i ~/.ssh/your-key.pem root@39.102.100.123
```

### 第二步：安装环境（仅首次）

```bash
# 方式 A：上传脚本执行
# 先把 scripts/deploy/install.sh 传到服务器
chmod +x install.sh
sudo bash install.sh

# 方式 B：一行命令远程执行
# 本地执行（如果脚本已上传到 GitHub）：
ssh root@39.102.100.123 "bash -s" < scripts/deploy/install.sh
```

### 第三步：上传代码

```bash
# 方式 A：Git Clone（推荐）
cd /var/www/ai-face-swap
git init
git remote add origin <你的仓库地址>
git pull origin main

# 方式 B：本地打包上传
# 本地打包
tar czf ai-face-swap.tar.gz --exclude=node_modules --exclude=.git .
# 上传到服务器
scp ai-face-swap.tar.gz root@39.102.100.123:/tmp/
# 服务器解压
cd /var/www/ai-face-swap
tar xzf /tmp/ai-face-swap.tar.gz
```

### 第四步：配置环境变量

```bash
cd /var/www/ai-face-swap
cp .env.example .env
nano .env  # 填入真实 API 密钥
```

### 第五步：启动服务

```bash
cd /var/www/ai-face-swap
npm install --production
pm2 start ecosystem.config.js
pm2 save
```

### 第六步：配置 Nginx

```bash
# 生成自签名证书（测试用）
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/selfsigned.key \
    -out /etc/nginx/ssl/selfsigned.crt

# 复制配置
sudo cp config/nginx.conf /etc/nginx/conf.d/ai-face-swap.conf
sudo nginx -t
sudo systemctl restart nginx
```

### 第七步：配置防火墙

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
sudo ufw status
```

### 第八步：验证

```bash
# 检查 PM2 进程
pm2 status

# 检查日志
pm2 logs ai-face-swap --lines 20

# 测试 API
curl http://127.0.0.1:8080/api/templates

# 测试外网（浏览器访问）
# http://39.102.100.123/api/templates
```

## 后续更新部署

```bash
cd /var/www/ai-face-swap
bash scripts/deploy/deploy.sh
```

## 常用运维命令

```bash
# 查看服务状态
pm2 status

# 查看实时日志
pm2 logs ai-face-swap

# 重启服务
pm2 restart ai-face-swap

# 停止服务
pm2 stop ai-face-swap

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 查看磁盘使用
df -h

# 查看内存
free -h
```

## 域名配置（后续）

1. 阿里云域名解析 → A 记录指向 39.102.100.123
2. 申请 Let's Encrypt 免费证书：
   ```bash
   sudo certbot --nginx -d aihuantu.com
   ```
3. 修改 nginx.conf 中的 `server_name _` 为你的域名
4. 取消注释 Let's Encrypt 证书路径，删除自签名证书配置

## OSS 对象存储（后续）

当日活增长，建议将 uploads 迁移到阿里云 OSS：
- 按量付费 ¥0.12/GB/月
- 代码中上传接口改为 OSS SDK
- Nginx uploads location 改为 OSS 域名
