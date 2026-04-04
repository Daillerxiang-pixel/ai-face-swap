# AI 换图 — 部署检查清单

> 每次部署前请逐项检查，确保生产环境稳定  
> **正式服务器 IP、域名以 [SERVER-DEPLOY.md](./SERVER-DEPLOY.md) 为准**（当前正式机：`159.223.152.94`，域名：`test.kanashortplay.com`）。

---

## 部署前检查

### 代码准备
- [ ] 所有功能代码已提交到 Git
- [ ] 已通过本地测试（`npm test` 或手动测试）
- [ ] `.env` 文件已更新（API 密钥、数据库路径）
- [ ] `package.json` 版本已更新（语义化版本）
- [ ] 已创建 Git Tag（如 `v1.0.0`）

### 服务器环境
- [ ] 服务器可 SSH 连接
- [ ] Node.js v22+ 已安装
- [ ] PM2 已安装
- [ ] Nginx 已安装
- [ ] 防火墙规则已配置（80/443 端口）
- [ ] 磁盘空间充足（`df -h`）
- [ ] 内存充足（`free -h`）

### 备份
- [ ] 数据库已备份（`cp face_swap.db backups/face_swap-YYYYMMDD.db`）
- [ ] 用户上传文件已备份（可选）
- [ ] 旧版本代码已备份（可选）

---

## 部署流程

### 方式 A：Git 部署（推荐）

```bash
# 1. SSH 连接服务器
ssh root@159.223.152.94

# 2. 进入应用目录
cd /var/www/ai-face-swap

# 3. 拉取最新代码
git pull origin main

# 4. 安装依赖
cd server
npm install --production

# 5. 重启服务
cd ..
pm2 restart ai-face-swap
pm2 save

# 6. 验证服务
pm2 status
pm2 logs ai-face-swap --lines 20
curl http://127.0.0.1:8080/api/templates
```

### 方式 B：脚本部署

```bash
# 本地执行（上传脚本后）
ssh root@159.223.152.94 "bash -s" < scripts/deploy/deploy.sh

# 或在服务器上执行
ssh root@159.223.152.94
cd /var/www/ai-face-swap
bash scripts/deploy/deploy.sh
```

### 方式 C：手动上传

```bash
# 1. 本地打包（排除 node_modules 和 .git）
tar czf ai-face-swap.tar.gz \
    --exclude=node_modules \
    --exclude=.git \
    --exclude=uploads \
    .

# 2. 上传到服务器
scp ai-face-swap.tar.gz root@159.223.152.94:/tmp/

# 3. 服务器解压
ssh root@159.223.152.94
cd /var/www/ai-face-swap
tar xzf /tmp/ai-face-swap.tar.gz

# 4. 安装依赖并重启
cd server
npm install --production
cd ..
pm2 restart ai-face-swap
```

---

## 部署后验证

### 服务状态
```bash
# 检查 PM2 进程
pm2 status ai-face-swap

# 应该显示：
# ┌────┬───────────┬─────────────┬─────────┬─────────┬──────────┬────────┬──────┬───────────┬──────────┬──────────┬──────────┬──────────┐
# │ id │ name      │ namespace   │ version │ mode    │ pid      │ uptime │ ↺    │ status    │ cpu      │ mem      │ user     │ watching │
# ├────┼───────────┼─────────────┼─────────┼─────────┼──────────┼────────┼──────┼───────────┼──────────┼──────────┼──────────┼──────────┤
# │ 0  │ ai-face-swap │ default   │ 1.0.0   │ fork    │ 12345    │ 10s    │ 0    │ online    │ 0%       │ 120mb    │ root     │ disabled │
# └────┴───────────┴─────────────┴─────────┴─────────┴──────────┴────────┴──────┴───────────┴──────────┴──────────┴──────────┴──────────┘
```

### API 测试
```bash
# 测试模板接口
curl http://127.0.0.1:8080/api/templates

# 测试健康检查
curl http://127.0.0.1:8080/health

# 测试外网访问（浏览器）
# https://test.kanashortplay.com/api/templates
```

### 日志检查
```bash
# 查看实时日志
pm2 logs ai-face-swap

# 查看错误日志
tail -f /var/log/ai-face-swap/error.log

# 查看 Nginx 日志
tail -f /var/log/nginx/ai-face-swap-error.log
```

### Nginx 验证
```bash
# 测试配置
sudo nginx -t

# 重新加载
sudo nginx -s reload

# 检查状态
sudo systemctl status nginx
```

---

## 回滚流程

如果部署后出现问题，立即回滚：

```bash
# 1. 停止新版本
pm2 stop ai-face-swap

# 2. 恢复数据库
cp /var/www/backups/ai-face-swap/face_swap-YYYYMMDD.db /var/www/ai-face-swap/server/data/face_swap.db

# 3. 恢复代码（Git 回滚）
cd /var/www/ai-face-swap
git reset --hard <previous-commit-hash>

# 4. 重启旧版本
pm2 start ai-face-swap
pm2 save

# 5. 验证
pm2 status
curl http://127.0.0.1:8080/api/templates
```

---

## 常见问题

### PM2 进程不断重启
```bash
# 查看日志
pm2 logs ai-face-swap --lines 100

# 检查内存
pm2 monit

# 可能的原因：
# - 内存不足（增加 max_memory_restart）
# - .env 配置错误
# - 端口被占用
```

### Nginx 502 Bad Gateway
```bash
# 检查后端服务
pm2 status ai-face-swap

# 检查 Nginx 配置
sudo nginx -t

# 检查端口
netstat -tlnp | grep 8080
```

### 证书过期
```bash
# 续期 Let's Encrypt 证书
sudo certbot renew

# 重新加载 Nginx
sudo nginx -s reload
```

### 数据库锁定
```bash
# SQLite WAL 模式已启用，通常不会出现锁定问题
# 如果出现问题，检查是否有多个进程同时写入
pm2 scale ai-face-swap 1  # 确保只有一个实例
```

---

## 性能优化

### 启用 Gzip 压缩
已在 Nginx 配置中启用，验证：
```bash
curl -H "Accept-Encoding: gzip" -I https://test.kanashortplay.com
# 应该看到：Content-Encoding: gzip
```

### 启用缓存
静态资源已配置 7 天缓存，验证：
```bash
curl -I https://test.kanashortplay.com/static/app.js
# 应该看到：Cache-Control: public, immutable
```

### 数据库优化
SQLite 已启用 WAL 模式，检查：
```bash
sqlite3 /var/www/ai-face-swap/server/data/face_swap.db "PRAGMA journal_mode;"
# 应该返回：wal
```

---

## 监控告警

### 设置 PM2 监控
```bash
# 安装 pm2-logrotate
pm2 install pm2-logrotate

# 配置日志轮转
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### 系统监控
```bash
# 安装 htop
sudo apt-get install -y htop

# 监控 CPU/内存
htop

# 监控磁盘
df -h

# 监控网络
iftop
```

### 设置告警（后续）
- 使用 Uptime Robot 监控 API 可用性
- 使用 Logtail 收集日志
- 使用 Prometheus + Grafana 监控系统指标

---

**最后更新：** 2026-03-24  
**维护者：** 运维团队
