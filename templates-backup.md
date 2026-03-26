# AI换图项目 — 模板列表备份
# 抓取时间: 2026-03-26 17:21
# 来源: https://test.kanashortplay.com/api/templates

## 图片模板 (5个，Provider: 腾讯云)

| ID | 名称 | 场景 | Provider | 使用次数 | 评分 | 徽章 | 预览图 |
|----|------|------|----------|---------|------|------|--------|
| 1 | 模板一 | 电影 | tencent | 12,505 | 4.9 | hot | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_1.jpg |
| 2 | 模板二 | 古风 | tencent | 8,306 | 4.8 | hot | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_2.jpg |
| 3 | 模板三 | 动漫 | tencent | 6,100 | 4.7 | new | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_3.jpg |
| 4 | 模板四 | 婚纱 | tencent | 9,801 | 4.9 | vip | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_4.jpg |
| 5 | 模板五 | 明星 | tencent | 7,401 | 4.6 | - | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_5.jpg |

## 视频模板 (3个，Provider: Replicate)

| ID | 名称 | 场景 | Provider | 使用次数 | 评分 | 徽章 | 预览图 | 视频URL |
|----|------|------|----------|---------|------|------|--------|---------|
| 6 | 视频模板一 | 电影 | replicate | 3,201 | 4.7 | hot | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_v1.jpg | https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4 |
| 7 | 视频模板二 | 舞蹈 | replicate | 2,802 | 4.6 | new | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_v2.jpg | https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4 |
| 8 | 视频模板三 | 搞笑 | replicate | 4,500 | 4.8 | hot | https://aihuantu.oss-cn-beijing.aliyuncs.com/uploads/previews/template_v3.jpg | https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4 |

## 注意事项
- 图片模板目前使用腾讯云 provider，后续可切换到 akool
- 视频模板使用 replicate provider，后续可切换到 akool video
- 模板详细数据在 SQLite 数据库 `templates` 表中
- 腾讯云模板有 `tencent_model_id` 和 `provider_model_id` 字段
