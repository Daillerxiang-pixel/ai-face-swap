# AI换图 - API接口文档

**版本：** v1.0  
**日期：** 2026-03-17  
**Base URL：** `https://api.aifaceswap.com/v1`

---

## 1. 概述

### 1.1 认证方式

所有API请求需要在Header中携带JWT Token：

```
Authorization: Bearer <your_jwt_token>
```

### 1.2 响应格式

统一响应格式：

```json
{
  "code": 0,           // 0=成功，非0=失败
  "message": "success",
  "data": { ... }      // 响应数据
}
```

### 1.3 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1001 | 参数错误 |
| 1002 | 认证失败 |
| 1003 | Token过期 |
| 1004 | 权限不足 |
| 2001 | 用户不存在 |
| 2002 | 密码错误 |
| 2003 | 用户已存在 |
| 3001 | 模板不存在 |
| 3002 | 文件上传失败 |
| 3003 | 未检测到人脸 |
| 3004 | 生成失败 |
| 4001 | 余额不足 |
| 4002 | 次数已用完 |
| 5001 | 服务器内部错误 |

---

## 2. 用户接口

### 2.1 注册

**POST** `/auth/register`

**请求参数：**

```json
{
  "email": "user@example.com",
  "password": "password123",
  "nickname": "用户昵称"
}
```

**响应示例：**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "user_id": "uuid-xxx",
    "email": "user@example.com",
    "nickname": "用户昵称",
    "token": "jwt_token_xxx"
  }
}
```

---

### 2.2 登录

**POST** `/auth/login`

**请求参数：**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应示例：**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "user_id": "uuid-xxx",
    "email": "user@example.com",
    "nickname": "用户昵称",
    "avatar_url": "https://...",
    "subscription": {
      "tier": "monthly",
      "expires_at": "2026-04-17T00:00:00Z",
      "daily_usage": 5,
      "daily_limit": -1
    },
    "token": "jwt_token_xxx"
  }
}
```

---

### 2.3 获取用户信息

**GET** `/user/profile`

**Header：**
```
Authorization: Bearer <token>
```

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "user_id": "uuid-xxx",
    "email": "user@example.com",
    "nickname": "用户昵称",
    "avatar_url": "https://...",
    "subscription": {
      "tier": "monthly",
      "expires_at": "2026-04-17T00:00:00Z",
      "daily_usage": 5,
      "daily_limit": -1,
      "monthly_usage": 50,
      "monthly_limit": -1
    },
    "created_at": "2026-03-17T10:00:00Z"
  }
}
```

---

### 2.4 更新用户信息

**PUT** `/user/profile`

**请求参数：**

```json
{
  "nickname": "新昵称",
  "avatar_url": "https://..."
}
```

**响应示例：**

```json
{
  "code": 0,
  "message": "更新成功",
  "data": {
    "user_id": "uuid-xxx",
    "nickname": "新昵称"
  }
}
```

---

## 3. 模板接口

### 3.1 获取模板列表

**GET** `/templates`

**查询参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | 否 | 分类：movie, celebrity, anime, etc. |
| type | string | 否 | 类型：image, video |
| tag | string | 否 | 标签筛选 |
| sort | string | 否 | 排序：popular, newest |
| page | int | 否 | 页码，默认1 |
| limit | int | 否 | 每页数量，默认20 |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "templates": [
      {
        "id": "uuid-xxx",
        "name": "好莱坞明星",
        "description": "变身好莱坞巨星",
        "category": "celebrity",
        "tags": ["明星", "电影"],
        "thumbnail_url": "https://...",
        "type": "image",
        "is_premium": false,
        "usage_count": 1234,
        "created_at": "2026-03-15T10:00:00Z"
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 20,
    "has_more": true
  }
}
```

---

### 3.2 获取模板详情

**GET** `/templates/{template_id}`

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "id": "uuid-xxx",
    "name": "好莱坞明星",
    "description": "变身好莱坞巨星",
    "category": "celebrity",
    "tags": ["明星", "电影"],
    "thumbnail_url": "https://...",
    "preview_url": "https://...",
    "source_url": "https://...",
    "type": "image",
    "width": 1024,
    "height": 1024,
    "is_premium": false,
    "usage_count": 1234,
    "created_at": "2026-03-15T10:00:00Z"
  }
}
```

---

### 3.3 获取模板分类

**GET** `/templates/categories`

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "categories": [
      {
        "id": "celebrity",
        "name": "明星换脸",
        "icon": "star",
        "count": 50
      },
      {
        "id": "movie",
        "name": "电影角色",
        "icon": "film",
        "count": 30
      },
      {
        "id": "anime",
        "name": "动漫人物",
        "icon": "anime",
        "count": 25
      }
    ]
  }
}
```

---

## 4. 文件接口

### 4.1 上传图片

**POST** `/upload/image`

**请求类型：** `multipart/form-data`

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file | file | 是 | 图片文件 (JPG, PNG, WEBP) |
| type | string | 是 | 用途：source(源图片), template(模板) |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "image_id": "uuid-xxx",
    "url": "https://cdn.example.com/images/xxx.jpg",
    "width": 1024,
    "height": 1024,
    "size": 500000,
    "has_face": true,
    "face_count": 1,
    "face_rectangles": [
      {
        "x": 100,
        "y": 100,
        "width": 200,
        "height": 200
      }
    ]
  }
}
```

---

### 4.2 获取上传URL（直传OSS）

**POST** `/upload/presign`

**请求参数：**

```json
{
  "filename": "image.jpg",
  "content_type": "image/jpeg",
  "type": "source"
}
```

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "upload_url": "https://oss.example.com/...",
    "image_id": "uuid-xxx",
    "expires_in": 300
  }
}
```

---

## 5. 生成接口

### 5.1 创建生成任务

**POST** `/generate`

**请求参数：**

```json
{
  "template_id": "uuid-xxx",
  "source_image_id": "uuid-xxx",
  "options": {
    "face_index": 0,
    "enhance": true
  }
}
```

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "generation_id": "uuid-xxx",
    "status": "pending",
    "estimated_time": 5,
    "queue_position": 3
  }
}
```

---

### 5.2 查询生成状态

**GET** `/generate/{generation_id}`

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "generation_id": "uuid-xxx",
    "status": "completed",
    "progress": 100,
    "result": {
      "url": "https://cdn.example.com/results/xxx.jpg",
      "width": 1024,
      "height": 1024,
      "size": 600000,
      "has_watermark": false
    },
    "processing_time": 3,
    "created_at": "2026-03-17T10:00:00Z",
    "completed_at": "2026-03-17T10:00:03Z"
  }
}
```

**状态说明：**

| 状态 | 说明 |
|------|------|
| pending | 排队中 |
| processing | 处理中 |
| completed | 已完成 |
| failed | 失败 |

---

### 5.3 取消生成任务

**DELETE** `/generate/{generation_id}`

**响应示例：**

```json
{
  "code": 0,
  "message": "任务已取消"
}
```

---

### 5.4 获取生成历史

**GET** `/generate/history`

**查询参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认1 |
| limit | int | 否 | 每页数量，默认20 |
| status | string | 否 | 状态筛选 |

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "generations": [
      {
        "generation_id": "uuid-xxx",
        "template": {
          "id": "uuid-xxx",
          "name": "好莱坞明星",
          "thumbnail_url": "https://..."
        },
        "source_image_url": "https://...",
        "result_url": "https://...",
        "status": "completed",
        "created_at": "2026-03-17T10:00:00Z"
      }
    ],
    "total": 50,
    "page": 1,
    "limit": 20
  }
}
```

---

## 6. 订阅接口

### 6.1 获取订阅方案

**GET** `/subscription/plans`

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "plans": [
      {
        "id": "free",
        "name": "免费版",
        "price": 0,
        "duration": 0,
        "features": {
          "daily_limit": 3,
          "monthly_limit": 90,
          "has_watermark": true,
          "max_resolution": "720p",
          "video_support": false,
          "priority": false
        }
      },
      {
        "id": "monthly",
        "name": "月度会员",
        "price": 39,
        "duration": 30,
        "features": {
          "daily_limit": -1,
          "monthly_limit": -1,
          "has_watermark": false,
          "max_resolution": "1080p",
          "video_support": true,
          "priority": true
        }
      },
      {
        "id": "yearly",
        "name": "年度会员",
        "price": 299,
        "duration": 365,
        "features": {
          "daily_limit": -1,
          "monthly_limit": -1,
          "has_watermark": false,
          "max_resolution": "4K",
          "video_support": true,
          "priority": true,
          "exclusive_templates": true
        }
      }
    ]
  }
}
```

---

### 6.2 创建订阅

**POST** `/subscription/create`

**请求参数：**

```json
{
  "plan_id": "monthly",
  "payment_method": "alipay"
}
```

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "subscription_id": "uuid-xxx",
    "plan_id": "monthly",
    "amount": 39,
    "payment": {
      "method": "alipay",
      "payment_url": "https://alipay.com/...",
      "qr_code": "https://..."
    }
  }
}
```

---

### 6.3 查询订阅状态

**GET** `/subscription/status`

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "subscription_id": "uuid-xxx",
    "plan_id": "monthly",
    "status": "active",
    "start_date": "2026-03-17",
    "end_date": "2026-04-17",
    "auto_renew": true,
    "days_remaining": 30
  }
}
```

---

### 6.4 取消订阅

**POST** `/subscription/cancel`

**响应示例：**

```json
{
  "code": 0,
  "message": "订阅已取消，将在到期后停止续费"
}
```

---

## 7. 支付回调接口

### 7.1 支付宝回调

**POST** `/payment/callback/alipay`

由支付宝服务器调用，处理支付结果。

---

### 7.2 微信支付回调

**POST** `/payment/callback/wechat`

由微信服务器调用，处理支付结果。

---

## 8. 通用接口

### 8.1 健康检查

**GET** `/health`

**响应示例：**

```json
{
  "status": "ok",
  "timestamp": "2026-03-17T10:00:00Z",
  "services": {
    "database": "ok",
    "redis": "ok",
    "storage": "ok",
    "ai_engine": "ok"
  }
}
```

---

## 9. 限流策略

| 用户类型 | 限流规则 |
|----------|----------|
| 游客 | 10次/分钟 |
| 免费用户 | 30次/分钟 |
| 付费用户 | 100次/分钟 |

超过限流返回：

```json
{
  "code": 429,
  "message": "请求过于频繁，请稍后再试"
}
```

---

## 10. Webhook（可选）

### 10.1 配置Webhook

**POST** `/webhook/config`

**请求参数：**

```json
{
  "url": "https://your-server.com/webhook",
  "events": ["generation.completed", "subscription.expired"]
}
```

### 10.2 事件通知

```json
{
  "event": "generation.completed",
  "timestamp": "2026-03-17T10:00:00Z",
  "data": {
    "generation_id": "uuid-xxx",
    "user_id": "uuid-xxx",
    "result_url": "https://..."
  }
}
```

---

## 11. SDK示例

### JavaScript/TypeScript

```typescript
import { AIFaceSwap } from '@aifaceswap/sdk';

const client = new AIFaceSwap({
  apiKey: 'your_api_key'
});

// 上传图片
const upload = await client.upload.image(file, 'source');

// 创建生成任务
const generation = await client.generate.create({
  template_id: 'template-xxx',
  source_image_id: upload.image_id
});

// 轮询结果
const result = await client.generate.waitForResult(generation.generation_id);

console.log(result.result.url);
```

### Python

```python
from aifaceswap import AIFaceSwap

client = AIFaceSwap(api_key='your_api_key')

# 上传图片
upload = client.upload.image('photo.jpg', 'source')

# 创建生成任务
generation = client.generate.create(
    template_id='template-xxx',
    source_image_id=upload['image_id']
)

# 等待结果
result = client.generate.wait_for_result(generation['generation_id'])

print(result['result']['url'])
```