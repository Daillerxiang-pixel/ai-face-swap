/**
 * Admin API — 内部管理后台接口
 * 
 * 所有接口需要 JWT 鉴权（除 /login 外）
 * 路径前缀: /api/admin
 */

const { Router } = require('express');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../data/database');
const { uploadToOSS, isOSSAvailable } = require('../utils/oss');

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'ai-face-swap-admin-jwt-secret-2026';

// ===== Auth Middleware =====
function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ success: false, error: '未登录' });
  try {
    req.admin = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ success: false, error: '登录已过期，请重新登录' });
  }
}

function shouldTryOSSUpload() {
  if (process.env.SKIP_OSS_UPLOAD === '1' || process.env.SKIP_OSS_UPLOAD === 'true') return false;
  return isOSSAvailable();
}

function mimeFromExt(ext) {
  const e = String(ext).toLowerCase();
  const m = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
    '.mp4': 'video/mp4',
    '.webm': 'video/webm',
    '.mov': 'video/quicktime',
  };
  return m[e] || 'application/octet-stream';
}

/** 模板预览图 / 视频：OSS 优先，失败或未配置则写入本地 uploads */
async function storeTemplateMedia(buffer, originalName, subfolder, mimeType) {
  const ext = path.extname(originalName) || '.bin';
  const filename = `${uuidv4()}${ext}`;
  const ossKey = `uploads/${subfolder}/${filename}`;

  if (shouldTryOSSUpload()) {
    try {
      const url = await uploadToOSS(buffer, ossKey, mimeType || mimeFromExt(ext));
      return { url };
    } catch (e) {
      console.error('[AdminUpload] OSS 失败，改存本地:', e.message || e);
    }
  }

  const uploadsRoot = path.join(__dirname, '..', '..', 'uploads', subfolder);
  if (!fs.existsSync(uploadsRoot)) fs.mkdirSync(uploadsRoot, { recursive: true });
  const abs = path.join(uploadsRoot, filename);
  fs.writeFileSync(abs, buffer);
  return { url: `/uploads/${subfolder}/${filename}` };
}

const uploadTemplatePreview = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext)) return cb(null, true);
    cb(new Error('请上传 JPG/PNG/WEBP/GIF 图片'));
  },
});

const uploadTemplateVideo = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 200 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.mp4', '.webm', '.mov'].includes(ext)) return cb(null, true);
    cb(new Error('请上传 MP4/WEBM/MOV 视频'));
  },
});

// POST /api/admin/upload/template-preview — 本地上传预览图 → OSS 或本地，返回可写入 templates.preview_url 的地址
router.post('/upload/template-preview', authMiddleware, (req, res, next) => {
  uploadTemplatePreview.single('file')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ success: false, error: '图片不能超过 20MB' });
      }
      return res.status(400).json({ success: false, error: err.message || '上传失败' });
    }
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, error: '请选择图片文件' });
    const { url } = await storeTemplateMedia(req.file.buffer, req.file.originalname, 'template-previews', req.file.mimetype);
    res.json({ success: true, data: { url } });
  } catch (e) {
    console.error('[AdminUpload] preview', e);
    res.status(500).json({ success: false, error: e.message || '上传失败' });
  }
});

// POST /api/admin/upload/template-video — 本地上传模板视频 → OSS 或本地
router.post('/upload/template-video', authMiddleware, (req, res, next) => {
  uploadTemplateVideo.single('file')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ success: false, error: '视频不能超过 200MB' });
      }
      return res.status(400).json({ success: false, error: err.message || '上传失败' });
    }
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, error: '请选择视频文件' });
    const { url } = await storeTemplateMedia(req.file.buffer, req.file.originalname, 'template-videos', req.file.mimetype);
    res.json({ success: true, data: { url } });
  } catch (e) {
    console.error('[AdminUpload] video', e);
    res.status(500).json({ success: false, error: e.message || '上传失败' });
  }
});

// ===== POST /api/admin/login =====
router.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ success: false, error: '请输入用户名和密码' });

  const db = getDb();
  const admin = db.prepare('SELECT * FROM admins WHERE username = ?').get(username);
  if (!admin) return res.status(400).json({ success: false, error: '用户名或密码错误' });

  const hash = crypto.createHash('sha256').update(password).digest('hex');
  if (hash !== admin.password_hash) return res.status(400).json({ success: false, error: '用户名或密码错误' });

  const token = jwt.sign({ id: admin.id, username: admin.username }, JWT_SECRET, { expiresIn: '24h' });
  db.prepare("UPDATE admins SET last_login_at = datetime('now', 'localtime') WHERE id = ?").run(admin.id);

  res.json({
    success: true,
    data: {
      token,
      admin: { id: admin.id, username: admin.username, nickname: admin.nickname }
    }
  });
});

// ===== POST /api/admin/change-password =====
router.post('/change-password', authMiddleware, (req, res) => {
  const { oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) return res.status(400).json({ success: false, error: '请输入旧密码和新密码' });
  if (newPassword.length < 6) return res.status(400).json({ success: false, error: '新密码至少6位' });

  const db = getDb();
  const admin = db.prepare('SELECT * FROM admins WHERE id = ?').get(req.admin.id);
  const oldHash = crypto.createHash('sha256').update(oldPassword).digest('hex');
  if (oldHash !== admin.password_hash) return res.status(400).json({ success: false, error: '旧密码错误' });

  const newHash = crypto.createHash('sha256').update(newPassword).digest('hex');
  db.prepare('UPDATE admins SET password_hash = ? WHERE id = ?').run(newHash, admin.id);

  res.json({ success: true, message: '密码修改成功' });
});

// ===== GET /api/admin/dashboard =====
router.get('/dashboard', authMiddleware, (req, res) => {
  const db = getDb();

  const totalUsers = db.prepare('SELECT COUNT(*) as c FROM users').get().c;
  const todayUsers = db.prepare("SELECT COUNT(*) as c FROM users WHERE date(created_at) = date('now')").get().c;
  const totalTemplates = db.prepare('SELECT COUNT(*) as c FROM templates WHERE is_active = 1').get().c;
  const totalGenerations = db.prepare("SELECT COUNT(*) as c FROM generations").get().c;
  const todayGenerations = db.prepare("SELECT COUNT(*) as c FROM generations WHERE date(created_at) = date('now')").get().c;
  const completedGenerations = db.prepare("SELECT COUNT(*) as c FROM generations WHERE status = 'completed'").get().c;
  const vipUsers = db.prepare("SELECT COUNT(*) as c FROM users WHERE subscription_tier != 'free'").get().c;

  // 最近 7 天生成趋势
  const trend = db.prepare(`
    SELECT date(created_at) as day, COUNT(*) as count
    FROM generations
    WHERE created_at >= datetime('now', 'localtime', '-7 days')
    GROUP BY date(created_at)
    ORDER BY day
  `).all();

  // 最近 10 条生成记录
  const recentGenerations = db.prepare(`
    SELECT g.id, g.status, g.type, g.progress, g.created_at, g.completed_at,
           u.nickname as user_name, t.name as template_name
    FROM generations g
    LEFT JOIN users u ON g.user_id = u.id
    LEFT JOIN templates t ON g.template_id = t.id
    ORDER BY g.created_at DESC
    LIMIT 10
  `).all();

  // 套餐统计
  const planStats = db.prepare(`
    SELECT p.name, COUNT(u.id) as user_count
    FROM plans p
    LEFT JOIN users u ON u.subscription_tier = LOWER(p.name)
    GROUP BY p.id
    ORDER BY p.sort_order
  `).all();

  res.json({
    success: true,
    data: {
      stats: { totalUsers, todayUsers, totalTemplates, totalGenerations, todayGenerations, completedGenerations, vipUsers },
      trend,
      recentGenerations,
      planStats
    }
  });
});

// ===== 用户管理 =====

// GET /api/admin/users?page=1&limit=20&search=xxx&tier=free
router.get('/users', authMiddleware, (req, res) => {
  const { page = 1, limit = 20, search, tier } = req.query;
  const db = getDb();
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let sql = 'SELECT * FROM users WHERE 1=1';
  let countSql = 'SELECT COUNT(*) as total FROM users WHERE 1=1';
  const params = [];
  const countParams = [];

  if (search) {
    sql += ' AND (id LIKE ? OR nickname LIKE ?)';
    countSql += ' AND (id LIKE ? OR nickname LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
    countParams.push(`%${search}%`, `%${search}%`);
  }
  if (tier) {
    sql += ' AND subscription_tier = ?';
    countSql += ' AND subscription_tier = ?';
    params.push(tier);
    countParams.push(tier);
  }

  sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit), offset);

  const users = db.prepare(sql).all(...params);
  const { total } = db.prepare(countSql).get(...countParams);

  // 隐藏敏感信息
  const safeUsers = users.map(u => ({
    id: u.id,
    nickname: u.nickname,
    avatar: u.avatar,
    subscription_tier: u.subscription_tier,
    subscription_expires_at: u.subscription_expires_at,
    monthly_usage: u.monthly_usage,
    monthly_limit: u.monthly_limit,
    total_generated: u.total_generated,
    created_at: u.created_at,
  }));

  res.json({ success: true, data: { list: safeUsers, total, page: parseInt(page), limit: parseInt(limit) } });
});

// PUT /api/admin/users/:id — 修改用户信息
router.put('/users/:id', authMiddleware, (req, res) => {
  const { nickname, subscription_tier, monthly_limit, is_banned } = req.body;
  const db = getDb();
  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ success: false, error: '用户不存在' });

  if (nickname !== undefined) db.prepare('UPDATE users SET nickname = ? WHERE id = ?').run(nickname, req.params.id);
  if (subscription_tier) db.prepare('UPDATE users SET subscription_tier = ? WHERE id = ?').run(subscription_tier, req.params.id);
  if (monthly_limit) db.prepare('UPDATE users SET monthly_limit = ? WHERE id = ?').run(monthly_limit, req.params.id);
  if (is_banned !== undefined) {
    // 简单的封禁机制：将 monthly_limit 设为 0
    if (is_banned) db.prepare('UPDATE users SET monthly_limit = 0 WHERE id = ?').run(req.params.id);
    else db.prepare('UPDATE users SET monthly_limit = 50 WHERE id = ?').run(req.params.id);
  }

  res.json({ success: true, message: '用户信息已更新' });
});

// ===== 模板管理 =====

// GET /api/admin/templates?page=1&limit=20&search=xxx&type=图片
router.get('/templates', authMiddleware, (req, res) => {
  const { page = 1, limit = 20, search, type, provider } = req.query;
  const db = getDb();
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let sql = 'SELECT * FROM templates WHERE 1=1';
  let countSql = 'SELECT COUNT(*) as total FROM templates WHERE 1=1';
  const params = [];
  const countParams = [];

  if (search) {
    sql += ' AND (name LIKE ? OR scene LIKE ?)';
    countSql += ' AND (name LIKE ? OR scene LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
    countParams.push(`%${search}%`, `%${search}%`);
  }
  if (type) {
    sql += ' AND type = ?';
    countSql += ' AND type = ?';
    params.push(type);
    countParams.push(type);
  }
  if (provider) {
    sql += ' AND provider = ?';
    countSql += ' AND provider = ?';
    params.push(provider);
    countParams.push(provider);
  }

  sql += ' ORDER BY id DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit), offset);

  const templates = db.prepare(sql).all(...params);
  const { total } = db.prepare(countSql).get(...countParams);

  res.json({ success: true, data: { list: templates, total, page: parseInt(page), limit: parseInt(limit) } });
});

// POST /api/admin/templates — 新增模板
router.post('/templates', authMiddleware, (req, res) => {
  const { name, icon, bg_gradient, scene, type, badge, description, provider, provider_model_id, video_url, preview_url } = req.body;
  if (!name) return res.status(400).json({ success: false, error: '模板名称不能为空' });

  const db = getDb();
  const result = db.prepare(`
    INSERT INTO templates (name, icon, bg_gradient, scene, type, badge, description, provider, provider_model_id, video_url, preview_url)
    VALUES (?,?,?,?,?,?,?,?,?,?,?)
  `).run(name, icon || '', bg_gradient || '', scene || '通用', type || '图片', badge || '', description || '', provider || 'tencent', provider_model_id || '', video_url || '', preview_url || '');

  res.json({ success: true, data: { id: result.lastInsertRowid }, message: '模板创建成功' });
});

// PUT /api/admin/templates/:id — 编辑模板
router.put('/templates/:id', authMiddleware, (req, res) => {
  const fields = ['name', 'icon', 'bg_gradient', 'scene', 'type', 'badge', 'description', 'provider', 'provider_model_id', 'video_url', 'preview_url', 'is_active', 'usage_count', 'rating'];
  const updates = [];
  const values = [];

  for (const f of fields) {
    if (req.body[f] !== undefined) {
      updates.push(`${f} = ?`);
      values.push(req.body[f]);
    }
  }

  if (updates.length === 0) return res.status(400).json({ success: false, error: '没有更新内容' });

  const db = getDb();
  const template = db.prepare('SELECT id FROM templates WHERE id = ?').get(req.params.id);
  if (!template) return res.status(404).json({ success: false, error: '模板不存在' });

  values.push(req.params.id);
  db.prepare(`UPDATE templates SET ${updates.join(', ')} WHERE id = ?`).run(...values);

  res.json({ success: true, message: '模板已更新' });
});

// DELETE /api/admin/templates/:id — 删除模板
router.delete('/templates/:id', authMiddleware, (req, res) => {
  const db = getDb();
  const template = db.prepare('SELECT id FROM templates WHERE id = ?').get(req.params.id);
  if (!template) return res.status(404).json({ success: false, error: '模板不存在' });

  db.prepare('DELETE FROM templates WHERE id = ?').run(req.params.id);
  res.json({ success: true, message: '模板已删除' });
});

// ===== 套餐管理 =====

// GET /api/admin/plans
router.get('/plans', authMiddleware, (req, res) => {
  const db = getDb();
  const plans = db.prepare('SELECT * FROM plans ORDER BY sort_order').all();
  // 解析 features JSON
  const result = plans.map(p => ({ ...p, features: JSON.parse(p.features || '[]') }));
  res.json({ success: true, data: result });
});

// POST /api/admin/plans — 新增套餐
router.post('/plans', authMiddleware, (req, res) => {
  const { name, price_monthly, price_yearly, monthly_limit, features, is_active, sort_order } = req.body;
  if (!name) return res.status(400).json({ success: false, error: '套餐名称不能为空' });

  const db = getDb();
  db.prepare(`
    INSERT INTO plans (name, price_monthly, price_yearly, monthly_limit, features, is_active, sort_order)
    VALUES (?,?,?,?,?,?,?)
  `).run(name, price_monthly || 0, price_yearly || 0, monthly_limit || 0, JSON.stringify(features || []), is_active !== false ? 1 : 0, sort_order || 0);

  res.json({ success: true, message: '套餐创建成功' });
});

// PUT /api/admin/plans/:id — 编辑套餐
router.put('/plans/:id', authMiddleware, (req, res) => {
  const db = getDb();
  const plan = db.prepare('SELECT id FROM plans WHERE id = ?').get(req.params.id);
  if (!plan) return res.status(404).json({ success: false, error: '套餐不存在' });

  const fields = ['name', 'price_monthly', 'price_yearly', 'monthly_limit', 'features', 'is_active', 'sort_order'];
  const updates = [];
  const values = [];

  for (const f of fields) {
    if (req.body[f] !== undefined) {
      updates.push(`${f} = ?`);
      values.push(f === 'features' ? JSON.stringify(req.body[f]) : req.body[f]);
    }
  }

  if (updates.length === 0) return res.status(400).json({ success: false, error: '没有更新内容' });

  values.push(req.params.id);
  db.prepare(`UPDATE plans SET ${updates.join(', ')} WHERE id = ?`).run(...values);

  res.json({ success: true, message: '套餐已更新' });
});

// DELETE /api/admin/plans/:id
router.delete('/plans/:id', authMiddleware, (req, res) => {
  const db = getDb();
  db.prepare('DELETE FROM plans WHERE id = ?').run(req.params.id);
  res.json({ success: true, message: '套餐已删除' });
});

// ===== 生成记录 =====

// GET /api/admin/generations?page=1&limit=20&status=completed&user_id=xxx
router.get('/generations', authMiddleware, (req, res) => {
  const { page = 1, limit = 20, status, user_id, type } = req.query;
  const db = getDb();
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let sql = `
    SELECT g.id, g.user_id, g.template_id, g.status, g.type, g.progress,
           g.error_message, g.created_at, g.completed_at,
           u.nickname as user_name, t.name as template_name
    FROM generations g
    LEFT JOIN users u ON g.user_id = u.id
    LEFT JOIN templates t ON g.template_id = t.id
    WHERE 1=1
  `;
  let countSql = 'SELECT COUNT(*) as total FROM generations WHERE 1=1';
  const params = [];
  const countParams = [];

  if (status) {
    sql += ' AND g.status = ?';
    countSql += ' AND status = ?';
    params.push(status);
    countParams.push(status);
  }
  if (user_id) {
    sql += ' AND g.user_id = ?';
    countSql += ' AND user_id = ?';
    params.push(user_id);
    countParams.push(user_id);
  }
  if (type) {
    sql += ' AND g.type = ?';
    countSql += ' AND type = ?';
    params.push(type);
    countParams.push(type);
  }

  sql += ' ORDER BY g.created_at DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit), offset);

  const generations = db.prepare(sql).all(...params);
  const { total } = db.prepare(countSql).get(...countParams);

  res.json({ success: true, data: { list: generations, total, page: parseInt(page), limit: parseInt(limit) } });
});

// ===== 订单管理（预留） =====

router.get('/orders', authMiddleware, (req, res) => {
  const { page = 1, limit = 20, status } = req.query;
  const db = getDb();
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let sql = 'SELECT * FROM orders WHERE 1=1';
  let countSql = 'SELECT COUNT(*) as total FROM orders WHERE 1=1';
  const params = [];
  const countParams = [];

  if (status) {
    sql += ' AND status = ?';
    countSql += ' AND status = ?';
    params.push(status);
    countParams.push(status);
  }

  sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
  params.push(parseInt(limit), offset);

  const orders = db.prepare(sql).all(...params);
  const { total } = db.prepare(countSql).get(...countParams);

  res.json({ success: true, data: { list: orders, total, page: parseInt(page), limit: parseInt(limit) } });
});

module.exports = router;
