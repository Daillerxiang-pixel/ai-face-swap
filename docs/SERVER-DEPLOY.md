# AI 换图 — 服务器部署说明（长期）

本文档描述 **线上服务器** 的约定；**正式环境** 与 **测试环境** 分开记录，避免混淆。

---

## 1. 环境角色一览

| 环境 | 状态 | 说明 |
|------|------|------|
| **正式服务器（生产）** | **已部署** | 当前对外提供服务，见下文「§2」 |
| **测试服务器** | **规划中** | 稍后单独部署；部署完成后在本节补充 **IP / 域名 / 分支或标签策略**，并与正式环境区分（勿共用生产库与密钥） |

---

## 2. 正式服务器（生产）

> **定义**：以下信息为当前约定的 **正式（生产）** 部署，后续变更请同步修改本文档。

| 项 | 值 |
|----|-----|
| **公网 IP** | `159.223.152.94` |
| **对外域名** | `test.kanashortplay.com`（HTTPS） |
| **系统** | Ubuntu 22.04 x64（示例：DigitalOcean） |
| **应用根目录** | `/var/www/ai-face-swap` |
| **进程管理** | PM2，应用名 **`ai-face-swap`** |
| **Node 入口** | `server/index.js`（工作目录为仓库根，见 `ecosystem.config.js`） |
| **监听端口** | **8080**（本机；Nginx 反代 `/api`、`/uploads` 等） |
| **数据库** | SQLite：`/var/www/ai-face-swap/server/data/face_swap.db` |
| **上传目录** | `/var/www/ai-face-swap/uploads` |
| **环境变量** | `server/.env`（由 `server/index.js` 加载，**勿提交仓库**） |
| **HTTPS 证书** | Let's Encrypt：`/etc/letsencrypt/live/test.kanashortplay.com/` |
| **Nginx 站点配置** | 仓库内参考：`config/nginx-prod.conf`（HTTPS + 反代）；首次签发前可用 `config/nginx-bootstrap-http.conf`（仅 HTTP） |

### 2.1 正式环境访问示例

- 首页 / 原型静态：`https://test.kanashortplay.com/`
- API：`https://test.kanashortplay.com/api/templates` 等
- 健康检查（示例）：`curl -s -o /dev/null -w "%{http_code}\n" https://test.kanashortplay.com/api/templates`

### 2.2 服务器上目录结构（约定）

```
/var/www/ai-face-swap/
├── server/                 # Node 服务
│   ├── index.js
│   ├── routes/
│   ├── data/face_swap.db   # SQLite（勿误拷到仓库）
│   └── .env                # 生产密钥（仅服务器）
├── admin/                  # 静态管理端
├── prototype/              # 静态原型
├── uploads/                # 用户上传
├── ecosystem.config.js     # PM2
├── logs/                   # PM2 日志（error.log / out.log）
└── ...
```

### 2.3 PM2 启动约定

```bash
cd /var/www/ai-face-swap
export NODE_ENV=production   # 或使用
pm2 start ecosystem.config.js --env production
pm2 save
```

依赖安装在 **`server/`** 目录：`cd server && npm install --production`。

### 2.4 与本仓库脚本的对应关系

| 用途 | 仓库内参考 |
|------|------------|
| 首次安装（Ubuntu） | `scripts/deploy/remote_install.sh`（域名等可用环境变量覆盖） |
| 仅重启后端与同步 `ecosystem` | `scripts/deploy/finish_remote_pm2.py`（需 SSH，见脚本说明） |
| 打包上传部署 | `scripts/deploy/remote_deploy.py` |
| Nginx + Certbot | `scripts/deploy/remote_nginx_ssl.py` |

---

## 3. 测试服务器（占位）

> **状态**：尚未部署；以下条目在测试机就绪后由运维补全。

| 项 | 计划值（待填） |
|----|----------------|
| 公网 IP | _待定_ |
| 域名 | _待定_（建议与正式区分，如 `test-xxx.example.com`） |
| 应用目录 | 建议仍用 `/var/www/ai-face-swap` 或单独路径，与正式区分 |
| Git 分支/标签策略 | _待定_（例如仅 `develop` 或 `release/*` 部署测试机） |
| 数据库 | **禁止使用正式库文件**；应独立 `face_swap.db` 或独立实例 |

**注意**：测试环境 `.env`、JWT、第三方 Key 应与正式隔离，避免误连生产 OSS/支付。

---

## 4. 更新部署（正式机通用步骤）

```bash
cd /var/www/ai-face-swap
git pull origin main   # 或实际使用的分支
cd server && npm install --production && cd ..
pm2 restart ai-face-swap
pm2 save
```

变更数据库结构时，以 `server/data/database.js` 迁移逻辑为准；部署前建议备份：

`cp server/data/face_swap.db /var/www/backups/ai-face-swap/face_swap-$(date +%Y%m%d).db`

---

## 5. 常用运维命令

```bash
pm2 status
pm2 logs ai-face-swap --lines 50
sudo nginx -t && sudo systemctl reload nginx
curl -s http://127.0.0.1:8080/api/templates
```

---

## 6. 历史说明（避免误用旧文档）

早期文档曾出现 **39.102.100.123** 等示例 IP，**不代表当前正式机**。以本文 **§2 正式服务器** 为准；若 `docs/DEPLOY.md` 仍为旧版长篇，请以 **`SERVER-DEPLOY.md` 为权威**。

---

**文档维护**：正式/测试任一端变更（IP、域名、分支策略）时，请更新本节并注明日期。
