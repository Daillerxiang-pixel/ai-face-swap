# AI 换图 — 服务器部署说明（长期）

本文档描述 **线上服务器** 的约定；**正式环境** 与 **测试环境** 分开记录，避免混淆。

### 发布流程原则（须遵守）

1. **先在测试环境验证**：变更（代码、依赖、数据库迁移、配置）须先在 **测试服务器**（§3，`test1.kanashortplay.com`）部署，并完成约定测试（接口/页面、客户端连测试服、关键业务流程等）。
2. **测试通过后再上正式**：确认无阻塞问题后，再将 **同一套变更** 部署到 **正式服务器**（§2）。  
3. **禁止**：未在测试环境验证通过即直接修改或发布正式机；不因排期单独跳过测试环节。

客户端与脚本：本地测试 APK 见 §3.5；正式包须使用**未**带测试域 `API_BASE` 的构建。

---

## 1. 环境角色一览

| 环境 | 状态 | 说明 |
|------|------|------|
| **正式服务器（生产）** | **已部署** | 当前对外提供服务，见下文「§2」 |
| **测试服务器** | **已部署** | `39.102.100.123`，域名 `test1.kanashortplay.com`，见下文「§3」；与 **ibooks** 同机，端口与目录隔离 |

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
| 测试机首次安装（与 ibooks 同机、不删 default 站点） | `scripts/deploy/remote_install_test.sh` |
| 仅重启后端与同步 `ecosystem` | `scripts/deploy/finish_remote_pm2.py`（需 SSH，见脚本说明） |
| 打包上传部署（正式机） | `scripts/deploy/remote_deploy.py` |
| 打包上传部署（测试机 `39.102.100.123`） | `scripts/deploy/remote_deploy_test.py` |
| Nginx + Certbot（正式机） | `scripts/deploy/remote_nginx_ssl.py` |
| Nginx + Certbot（测试域名 test1） | `scripts/deploy/remote_nginx_ssl_test.py` |

### 2.5 仓库内与正式 IP 对齐的文件

以下文件中的 **正式机公网 IP** 应与上表 **`159.223.152.94`** 一致（或通过 `DEPLOY_HOST` 覆盖脚本默认值）：

- `scripts/deploy/remote_deploy.py`、`finish_remote_pm2.py`、`remote_nginx_ssl.py`、`check_auth_log_remote.py`（默认 `DEPLOY_HOST=159.223.152.94`）
- `docs/DEPLOY_CHECKLIST.md`、`scripts/deploy/install.sh` 注释、`config/nginx.conf`、`config/security-group.md` 头部说明

---

## 3. 测试服务器（已部署）

> **与 ibooks 同机**：本机同时运行 **ibooks**（PM2 `ibooks-server`，端口 **8081**，目录 `/var/www/ibooks`）。部署/更新 ai-face-swap 测试实例时 **请勿修改** ibooks 的 Nginx 站点、PM2 进程与 `8081` 监听。详见 **ibooks** 仓库内 `docs/DEPLOY.md` **§9（与 ai-face-swap 测试环境同机）**。

| 项 | 值 |
|----|-----|
| **公网 IP** | `39.102.100.123` |
| **对外域名** | `test1.kanashortplay.com`（HTTPS，DNS **A 记录** 指向本 IP） |
| **应用根目录** | `/var/www/ai-face-swap-test`（与正式目录分离） |
| **进程管理** | PM2，应用名 **`ai-face-swap-test`** |
| **Node 监听端口** | **8082**（本机；**禁止**使用 8081，保留给 ibooks） |
| **数据库** | SQLite：`/var/www/ai-face-swap-test/server/data/face_swap.db`（**独立**，勿拷贝正式库） |
| **上传目录** | `/var/www/ai-face-swap-test/uploads` |
| **环境变量** | `/var/www/ai-face-swap-test/server/.env`（**独立** JWT 与密钥） |
| **HTTPS 证书** | Let's Encrypt：`/etc/letsencrypt/live/test1.kanashortplay.com/`（签发成功后） |
| **Nginx 站点** | `/etc/nginx/sites-available/ai-face-swap-test1.conf` → `sites-enabled/`（**仅新增**该文件，不覆盖其他站点） |
| **仓库内参考** | `ecosystem.test.config.js`、`config/nginx-bootstrap-test1-http.conf`（签发前）、`config/nginx-test1.conf`（HTTPS） |

### 3.1 与正式环境的区别（摘要）

| 项 | 正式（§2） | 测试（§3） |
|----|------------|------------|
| IP | `159.223.152.94` | `39.102.100.123` |
| 域名 | `test.kanashortplay.com` | `test1.kanashortplay.com` |
| 目录 | `/var/www/ai-face-swap` | `/var/www/ai-face-swap-test` |
| PM2 名 | `ai-face-swap` | `ai-face-swap-test` |
| 端口 | 8080 | 8082 |

### 3.2 首次部署（本地脚本上传）

1. DNS：将 `test1.kanashortplay.com` **A 记录** 指向 `39.102.100.123`。
2. 在仓库根目录（PowerShell）设置 `DEPLOY_SSH_PASSWORD`，执行：  
   `python scripts/deploy/remote_deploy_test.py`  
   （可选：`DEPLOY_HOST` 覆盖默认测试机 IP。）
3. 若证书未自动签发，DNS 生效后可在服务器上执行 `certbot`，或本地再运行：  
   `python scripts/deploy/remote_nginx_ssl_test.py`

### 3.3 更新测试实例代码

```bash
cd /var/www/ai-face-swap-test
git pull origin main   # 分支以实际为准
cd server && npm install --production && cd ..
pm2 restart ai-face-swap-test
pm2 save
```

或在本机再次执行 `remote_deploy_test.py` 覆盖上传（会重新执行安装脚本；注意备份 `server/.env` 与数据库）。

### 3.4 验证

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8082/api/templates
curl -s -o /dev/null -w "%{http_code}\n" https://test1.kanashortplay.com/api/templates
```

**注意**：测试环境 `.env`、JWT、第三方 Key 与正式隔离；禁止将正式 `face_swap.db` 用于测试机覆盖，除非明确在做数据迁移演练。

### 3.5 Android 客户端（指向测试服 API）

Flutter 工程内 `AppConfig.apiBaseUrl` 支持编译期注入 **`API_BASE`**。在含 `android/` 的工程根目录（如 `app_temp`）执行：

```text
flutter build apk --release --dart-define=API_BASE=https://test1.kanashortplay.com
```

本地固定产出目录约定（Windows）：**`F:\work\And\test`** — APK 直接放在该目录根下 **`face-swap-test1-release.apk`**；可用同目录 **`build-test-apk.bat`** 重新构建（脚本内 `FACE_SWAP_FLUTTER_ROOT` 指到本机 `app_temp`）。勿与生产包混用同一 `dart-define`。

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

**39.102.100.123** 现为 **§3 测试服务器** 正式 IP（与 ibooks 同机），**不是** §2 生产机。生产机公网 IP 以 **§2** 的 **`159.223.152.94`** 为准。若其他旧文档仍写「示例 IP」，请以 **`SERVER-DEPLOY.md`** 为准。

---

**文档维护**：正式/测试任一端变更（IP、域名、分支策略）时，请更新本节并注明日期。
