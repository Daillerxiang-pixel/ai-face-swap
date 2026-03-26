# AI换图 - Design Token 设计规范

## 1. 设计风格定位

**风格**: 现代 AI 暗色主题，参考 FaceApp、Reface、美图秀秀
**关键词**: 科技感、高级感、沉浸式、渐变光效
**目标平台**: 移动端优先（未来 Android/iOS 原生应用）

---

## 2. 色彩系统

### 2.1 基础色板

| Token | 色值 | 用途 |
|-------|------|------|
| --bg-primary | #0B0B10 | 主背景 |
| --bg-secondary | #14141F | 次级背景（卡片、弹窗） |
| --bg-tertiary | #1C1C2E | 三级背景（输入框、悬停） |
| --bg-elevated | #252538 | 浮层背景 |
| --bg-overlay | rgba(0,0,0,0.6) | 遮罩层 |

### 2.2 文字色

| Token | 色值 | 用途 |
|-------|------|------|
| --text-primary | #FFFFFF | 主文字 |
| --text-secondary | #A0A0B8 | 次级文字 |
| --text-tertiary | #6B6B80 | 辅助文字 |
| --text-inverse | #0B0B10 | 反色文字（按钮上） |

### 2.3 强调色渐变

| Token | 渐变值 | 用途 |
|-------|--------|------|
| --gradient-primary | linear-gradient(135deg, #7C3AED, #3B82F6) | 主按钮、CTA |
| --gradient-secondary | linear-gradient(135deg, #EC4899, #8B5CF6) | 徽章、标签 |
| --gradient-gold | linear-gradient(135deg, #F59E0B, #EF4444) | VIP、热门 |
| --gradient-success | linear-gradient(135deg, #10B981, #06B6D4) | 成功状态 |
| --gradient-card | linear-gradient(135deg, rgba(124,58,237,0.15), rgba(59,130,246,0.1)) | 卡片背景光效 |

### 2.4 功能色

| Token | 色值 | 用途 |
|-------|------|------|
| --color-success | #10B981 | 成功 |
| --color-error | #EF4444 | 错误 |
| --color-warning | #F59E0B | 警告 |
| --color-info | #3B82F6 | 信息 |

---

## 3. 字体系统

### 3.1 字体栈

```css
--font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'PingFang SC', 'Microsoft YaHei', sans-serif;
--font-mono: 'SF Mono', 'Menlo', monospace;
```

### 3.2 字号层级

| Token | 大小 | 行高 | 字重 | 用途 |
|-------|------|------|------|------|
| --text-h1 | 28px | 34px | 700 | 大标题 |
| --text-h2 | 22px | 28px | 600 | 页面标题 |
| --text-h3 | 18px | 24px | 600 | 区块标题 |
| --text-lg | 16px | 22px | 500 | 卡片标题 |
| --text-md | 15px | 21px | 400 | 正文 |
| --text-sm | 13px | 18px | 400 | 辅助文字 |
| --text-xs | 11px | 15px | 500 | 标签、徽章 |

---

## 4. 间距系统（4px 基准）

| Token | 值 | 用途 |
|-------|-----|------|
| --space-1 | 4px | 紧凑间距 |
| --space-2 | 8px | 小间距 |
| --space-3 | 12px | 元素内间距 |
| --space-4 | 16px | 卡片内间距 |
| --space-5 | 20px | 区块间距 |
| --space-6 | 24px | 大间距 |
| --space-8 | 32px | 页面边距 |
| --space-10 | 40px | 章节间距 |
| --space-12 | 48px | 超大间距 |

---

## 5. 圆角系统

| Token | 值 | 用途 |
|-------|-----|------|
| --radius-sm | 8px | 标签、小按钮 |
| --radius-md | 12px | 卡片 |
| --radius-lg | 16px | 大卡片、弹窗 |
| --radius-xl | 20px | 底部弹窗 |
| --radius-2xl | 24px | 全圆卡片 |
| --radius-full | 9999px | 胶囊按钮、头像 |

---

## 6. 阴影系统

```css
--shadow-sm: 0 2px 8px rgba(0,0,0,0.3);
--shadow-md: 0 4px 16px rgba(0,0,0,0.4);
--shadow-lg: 0 8px 32px rgba(0,0,0,0.5);
--shadow-glow: 0 0 20px rgba(124,58,237,0.3);
--shadow-glow-pink: 0 0 20px rgba(236,72,153,0.3);
```

---

## 7. 动效规范

```css
--ease-out: cubic-bezier(0.16, 1, 0.3, 1);
--ease-in-out: cubic-bezier(0.83, 0, 0.17, 1);
--duration-fast: 150ms;
--duration-normal: 250ms;
--duration-slow: 400ms;
```

---

## 8. 组件设计要点

### 8.1 模板卡片
- 暗色背景 + 渐变覆盖层
- 圆角 12px
- 悬停时微上移 + 发光阴影
- 使用次数显示在左下角

### 8.2 底部导航栏
- 毛玻璃效果 (backdrop-filter: blur)
- 高度 64px
- 选中态：图标 + 文字变为主题渐变色
- 5个 Tab：首页、发现、创作(+号)、作品、我的

### 8.3 页面头部
- 透明背景，滚动后变半透明暗色
- 标题居中
- 左侧返回箭头，右侧操作按钮

### 8.4 按钮
- 主按钮：渐变背景 + 按压缩放效果
- 次按钮：描边 + 半透明背景
- 高度 48px，圆角 24px

### 8.5 进度条
- 背景暗色，前景渐变
- 高度 4px，圆角 2px
- 动画过渡

### 8.6 弹窗/底部面板
- 从底部滑入
- 顶部有拖拽指示条
- 毛玻璃遮罩
- 圆角顶部 24px

---

## 9. 页面结构

### 首页
- 顶部：问候语 + 用户头像 + 通知
- Banner：轮播推广（渐变背景 + 文案）
- 热门模板：横向滚动卡片
- 分类入口：网格图标
- 推荐模板：瀑布流

### 模板详情
- 顶部大图预览（高度 320px）
- 模板信息区（名称、描述、使用量、评分）
- 操作按钮（立即使用）
- 相关推荐

### 创作流程
- Step 1: 选择模板（横向滚动）
- Step 2: 上传照片（拖拽区域 + 人脸检测提示）
- Step 3: 生成中 → 结果展示

### 个人中心
- 头像 + 昵称 + VIP 状态
- 数据统计（创作数、使用次数）
- 功能列表（作品、收藏、VIP、设置）
