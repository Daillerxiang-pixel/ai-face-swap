# AI换图 — 部署手册（索引）

> **权威服务器说明（正式机 / 测试机）请阅读：[SERVER-DEPLOY.md](./SERVER-DEPLOY.md)**  
> **发布顺序**：须先在测试服验证通过，再部署正式服 — 见 `SERVER-DEPLOY.md` 文首「发布流程原则」。  
> 下文保留通用操作备忘；**IP、域名以 `SERVER-DEPLOY.md` 为准**。

## 目录结构（服务器上）

```
/var/www/ai-face-swap/
├── server/
│   ├── index.js
│   ├── routes/
│   └── data/face_swap.db
├── uploads/
├── prototype/
├── admin/
├── ecosystem.config.js
└── logs/
```

## 快速步骤摘要

1. SSH 登录正式服务器（见 [SERVER-DEPLOY.md](./SERVER-DEPLOY.md)）
2. `cd /var/www/ai-face-swap`，`git pull`，`cd server && npm install --production`
3. `pm2 restart ai-face-swap --env production`（或 `ecosystem.config.js --env production`）
4. `curl http://127.0.0.1:8080/api/templates` 验证

## 脚本与配置

- `scripts/deploy/install.sh` — 环境安装
- `scripts/deploy/deploy.sh` — 更新部署（需与当前目录结构一致）
- `scripts/deploy/remote_deploy_test.py` + `remote_install_test.sh` — **测试机**（`test1.kanashortplay.com`，见 [SERVER-DEPLOY.md](./SERVER-DEPLOY.md) §3）
- `ecosystem.test.config.js` — 测试 PM2（`ai-face-swap-test`，端口 **8082**）
- `config/nginx-prod.conf` — 生产 Nginx（域名 `test.kanashortplay.com`）
- `config/nginx-test1.conf` / `nginx-bootstrap-test1-http.conf` — 测试域名 Nginx
- `config/nginx-bootstrap-http.conf` — 仅 HTTP，用于签发证书前

## OSS / 域名扩展

- 对象存储、CDN、正式业务域名等，在 `SERVER-DEPLOY.md` 随环境补充说明即可。
