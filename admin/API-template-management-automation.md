# 模板管理 · 管理端 API（自动化 / 批量上传）

本文档供**另一台机器上的脚本或程序**调用，完成**登录、模板列表、单条增删改、预览图/视频上传、Excel+ZIP 批量导入**等工作。所有路径均相对站点根域名（由运维配置的 HTTPS 入口）。

**前缀**：`/api/admin`（与浏览器管理后台 `admin/components.js` 中 `API_BASE` 一致）

**示例根地址**（按实际环境替换）：

| 环境     | 示例 `BASE_URL` |
|----------|-----------------|
| 本地开发 | `http://127.0.0.1:8080` |
| 测试服   | `https://test1.kanashortplay.com` |
| 正式服   | `https://test.kanashortplay.com` |

下文记 **`API = BASE_URL + '/api/admin'`**，例如：`POST https://test1.kanashortplay.com/api/admin/login`。

---

## 1. 鉴权

除 **`POST /login`** 外，以下接口均需在 HTTP 头携带 JWT：

```http
Authorization: Bearer <token>
```

- Token 由登录接口返回，字段路径：`data.token`。
- 服务端使用 `JWT_SECRET` 签发；默认有效期 **24 小时**（过期后需重新登录）。
- 未携带或无效时返回 **401**，JSON 形如：`{ "success": false, "error": "未登录" }` 或「登录已过期…」。

---

## 2. 通用响应约定

成功时多为：

```json
{ "success": true, "data": { ... } }
```

或带文案：

```json
{ "success": true, "message": "…", "data": { ... } }
```

失败时：

```json
{ "success": false, "error": "错误说明" }
```

HTTP 状态码：业务错误常见 **400**；未登录 **401**；资源不存在 **404**；服务器异常 **500**。

---

## 3. 登录（获取 Token）

**`POST /api/admin/login`**

- **Content-Type**：`application/json`
- **Body**：

| 字段       | 类型   | 说明     |
|------------|--------|----------|
| `username` | string | 管理员账号 |
| `password` | string | 密码（明文；服务端存 SHA256 比对） |

**响应示例**：

```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "admin": { "id": 1, "username": "admin", "nickname": "管理员" }
  }
}
```

**curl 示例**：

```bash
curl -sS -X POST "$BASE_URL/api/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"YOUR_USER","password":"YOUR_PASS"}'
```

脚本中请保存 `data.token` 供后续请求使用。

---

## 4. 模板列表（分页与筛选）

**`GET /api/admin/templates`**

- **鉴权**：需要 Bearer Token。

**Query 参数**：

| 参数       | 说明 |
|------------|------|
| `page`     | 页码，默认 `1` |
| `limit`    | 每页条数，默认 `20` |
| `search`   | 可选；按 **名称** 或 **场景（scene）** 模糊匹配 |
| `type`     | 可选；`图片` 或 `视频` |
| `provider` | 可选；`tencent` / `replicate` / `akool` |

**响应 `data`**：

```json
{
  "list": [ { /* 单条模板，含 id, name, scene, type, provider, preview_url, ... */ } ],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

单条模板字段与数据库 `templates` 表一致（含 `id`, `name`, `icon`, `bg_gradient`, `scene`, `type`, `badge`, `description`, `provider`, `provider_model_id`, `video_url`, `preview_url`, `is_active`, `usage_count`, `rating` 等）。

---

## 5. 新增模板（JSON）

**`POST /api/admin/templates`**

- **Content-Type**：`application/json`
- **鉴权**：需要。

**Body 字段**（与实现一致；未列出的可按需省略，服务端有默认值）：

| 字段                 | 说明 |
|----------------------|------|
| `name`               | **必填**，模板名称 |
| `scene`              | 场景（作**分类**用），默认 `通用` |
| `type`               | `图片` 或 `视频`，默认 `图片` |
| `provider`           | `tencent` / `replicate` / `akool`，默认 `tencent`（后台表单默认常为 akool，以实际提交为准） |
| `badge`              | 标签（**推荐/运营标识**，如 hot、new），非分类 |
| `description`        | 描述 |
| `provider_model_id`  | **腾讯云人脸融合**用的 Model ID；Akool/Replicate 当前实现不依赖此字段，可留空 |
| `preview_url`        | 预览图地址（通常先走「上传接口」拿到 URL 再填入） |
| `video_url`          | 视频模板时的视频地址 |
| `icon`, `bg_gradient`| 可选；客户端展示用 |

**响应**：`data.id` 为新模板自增 ID。

---

## 6. 更新 / 删除模板

**`PUT /api/admin/templates/:id`**

- **鉴权**：需要。
- **Content-Type**：`application/json`
- **Body**：仅提交需要修改的字段；可更新字段包括：  
  `name`, `icon`, `bg_gradient`, `scene`, `type`, `badge`, `description`, `provider`, `provider_model_id`, `video_url`, `preview_url`, `is_active`, `usage_count`, `rating`  
  （至少一项，否则 400「没有更新内容」）

**`DELETE /api/admin/templates/:id`**

- **鉴权**：需要；删除指定 ID 的模板行。

---

## 7. 单文件上传（预览图 / 模板视频）

用于在入库前获得 `preview_url` / `video_url`。服务端优先写 **OSS**（若已配置），否则写入服务器本地 `uploads/` 并返回可访问的相对或绝对 URL。

### 7.1 预览图

**`POST /api/admin/upload/template-preview`**

- **鉴权**：需要。
- **Content-Type**：`multipart/form-data`
- **字段名**：`file`（单文件）
- **允许扩展名**：`.jpg` `.jpeg` `.png` `.webp` `.gif`
- **大小限制**：≤ **20MB**

**成功响应**：

```json
{ "success": true, "data": { "url": "https://... 或 /uploads/template-previews/....jpg" } }
```

### 7.2 模板视频

**`POST /api/admin/upload/template-video`**

- **鉴权**：需要。
- **Content-Type**：`multipart/form-data`
- **字段名**：`file`
- **允许扩展名**：`.mp4` `.webm` `.mov`
- **大小限制**：≤ **200MB**

**成功响应**：同上结构，`data.url` 写入模板的 `video_url`。

**curl 示例（预览图）**：

```bash
curl -sS -X POST "$BASE_URL/api/admin/upload/template-preview" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/preview.jpg"
```

---

## 8. 批量导入：下载 Excel 空模板

**`GET /api/admin/templates/import-excel-template`**

- **鉴权**：需要。
- **响应**：`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` 二进制流（附件名含 `template-import-template.xlsx` / UTF-8 中文名）。

工作表 **「模板列表」** 第一行为表头；**「填写说明」** 为规则说明。自动化时可先下载此文件再填充。

---

## 9. 批量导入：上传 Excel + ZIP

**`POST /api/admin/templates/import-excel`**

- **鉴权**：需要。
- **Content-Type**：`multipart/form-data`
- **字段**（两个都要）：

| 字段名    | 说明 |
|-----------|------|
| `excel`   | `.xlsx` 或 `.xls`，对应「模板列表」数据 |
| `archive` | `.zip`，内含 Excel 中填写的**相对路径**所指向的文件 |

- **总大小限制**：multipart 约 **520MB** 上限（以服务端 multer 配置为准）。

**规则摘要**：

1. Excel **第一行表头**；数据从第二行开始。表头别名见下节「列名映射」。
2. **预览图路径**、**视频路径** 必须是 **ZIP 包内的相对路径**（推荐正斜杠 `/`），**不能**使用 `D:\...` 等本机绝对路径。
3. **类型**：`图片` 或 `视频`；**视频**模板必须填 **视频路径**。
4. **服务商**：`akool` / `tencent` / `replicate`（小写存储）。
5. 导入时会把 ZIP 内文件读出后上传 OSS 或本地，并把最终 URL 写入 `preview_url` / `video_url`。

**成功响应示例**：

```json
{
  "success": true,
  "data": {
    "imported": 2,
    "failed": 0,
    "details": {
      "ok": [
        { "row": 2, "id": 101, "name": "某模板" }
      ],
      "errors": []
    }
  }
}
```

若有失败行，`details.errors` 为 `{ "row": Excel行号, "error": "原因" }[]`（行号为表头下的数据行号，从 2 起）。

**curl 示例**：

```bash
curl -sS -X POST "$BASE_URL/api/admin/templates/import-excel" \
  -H "Authorization: Bearer $TOKEN" \
  -F "excel=@/path/to/data.xlsx" \
  -F "archive=@/path/to/assets.zip"
```

---

## 10. Excel 列名映射（与代码 `HEADER_MAP` 一致）

脚本生成表头时，可使用**中文第一行**（推荐与官方下载模板一致），或下列别名（不区分大小写，部分列）：

| 逻辑字段            | 可识别表头别名示例 |
|---------------------|--------------------|
| `name`              | 模板名称、name、名称 |
| `scene`             | 场景、scene、分类、模板分类 |
| `type`              | 类型、type |
| `provider`          | 服务商、provider、换脸api、换脸API、API服务商 |
| `preview_path`      | 预览图路径、preview_path、预览图、preview、图片路径 |
| `video_path`        | 视频路径、video_path、视频、video |
| `badge`             | 标签、badge |
| `description`       | 描述、description |
| `usage_count`       | 热度、usage_count、使用次数 |
| `rating`            | 评分、rating |
| `icon`              | 图标、icon |
| `bg_gradient`       | 背景渐变、bg_gradient、背景 |
| `provider_model_id` | model_id、provider_model_id、Model ID、模型ID |

---

## 11. 推荐自动化流程（示例）

1. **`POST /login`** → 保存 `token`。
2. **可选**：`GET /templates/import-excel-template` → 保存为本地 xlsx，程序填充「模板列表」并打包 ZIP。
3. **批量路径 A**：`POST /templates/import-excel`（excel + archive）一次导入多行。
4. **批量路径 B**：对每条模板  
   - `POST /upload/template-preview`（及视频时 `POST /upload/template-video`）  
   - `POST /templates` 带上返回的 `url`。
5. **维护**：`GET /templates` 分页拉取；`PUT /templates/:id` 更新；`DELETE /templates/:id` 删除。

---

## 12. 安全与运维提示

- 生产环境务必使用 **HTTPS**；Token 等同账号权限，勿写入公开仓库或日志。
- 若网关对 `client_max_body_size` 有限制，大 ZIP/视频上传失败时需运维调大 Nginx 与超时。
- 服务端 CORS 对浏览器放开；**服务器到服务器**调用一般无浏览器 CORS 问题，注意防火墙仅放行你的自动化出口 IP（若需）。

---

## 13. 相关源码（便于对照行为）

| 文件 | 内容 |
|------|------|
| `server/routes/admin.js` | 登录、上传、模板 CRUD |
| `server/routes/admin-template-import.js` | Excel 模板下载、ZIP 批量导入 |

文档版本与仓库代码同步；若接口变更，请以 `server/routes` 下实现为准并更新本文档。
