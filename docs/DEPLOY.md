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

## GitHub Actions 与客户端构建

| 平台 | 构建方式 |
|------|----------|
| **iOS（IPA）** | 仓库 **`.github/workflows/ios-build.yml`**：仅在 `main` 上变更 **`app_temp/**`** 或该 workflow 本身时自动跑；也可在 Actions 里 **手动运行**（`workflow_dispatch`）。需要 Apple 证书等 Secrets。 |
| **Android（APK）** | **不在 GitHub 上构建**。一律在本机执行 `flutter build apk`（测试服见 `SERVER-DEPLOY.md` §3.5、本地输出目录约定）。 |

**安装包命名**：所有 APK/IPA 等发布物文件名须含**递增版本号**；测试包使用 `test-` 前缀，详见 **`.cursor/rules/versioned-build-artifacts.mdc`**。

此前若每次 `git push` 都触发构建，多因 **任意文件推送都会跑 iOS 工作流**；现已改为仅 **`app_temp` 或 workflow 有改动** 时才自动触发，文档/后端-only 的推送不再误触 IPA 构建。

## 客户端：测试包与正式包（推荐）

| 包类型 | API 指向 | Flutter 构建示例 |
|--------|------------|-------------------|
| 测试 | `https://test1.kanashortplay.com` | `flutter build apk`（默认即测试域） |
| 正式 | `https://test.kanashortplay.com` | `flutter build apk --release --dart-define=API_BASE=https://test.kanashortplay.com` |

- **服务端**：测试机与正式机共用**同一套仓库代码**；发布流程见 `SERVER-DEPLOY.md`（先测后正式）。
- **环境切换只在客户端**：用 `API_BASE` 区分，勿在服务端为「测试/正式」维护两套分支。
- 正式服上的 `OSS_PUBLIC_BASE_URL` 等仅影响**该机** `.env` 如何拼资源 URL；测试服若已完整配置 OSS SDK，行为与改前一致，不会因正式服加变量而「坏掉」。

## OSS / 域名扩展

- 对象存储、CDN、正式业务域名等，在 `SERVER-DEPLOY.md` 随环境补充说明即可。
