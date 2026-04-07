const { Router } = require('express');
const { getDb } = require('../data/database');
const { toPublicMediaUrl } = require('../utils/oss');

const router = Router();

function formatUsage(n) {
  if (n >= 10000) return (n / 1000).toFixed(1) + 'K';
  if (n >= 1000) return (n / 1000).toFixed(1) + 'K';
  return String(n);
}

function mapTemplate(t) {
  return {
    id: t.id,
    name: t.name,
    icon: t.icon,
    bg: t.bg_gradient,
    scene: t.scene,
    type: t.type,
    usage: formatUsage(t.usage_count),
    usageNum: t.usage_count,
    badge: t.badge,
    desc: t.description,
    rating: t.rating,
    provider: t.provider || 'tencent',
    previewUrl: toPublicMediaUrl(t.preview_url),
    videoUrl: toPublicMediaUrl(t.video_url),
  };
}

// GET /api/templates?type=图片&scene=电影&page=1&limit=20
router.get('/', (req, res) => {
  const { type, scene, sort, search, page = 1, limit = 20 } = req.query;
  const db = getDb();

  let sql = 'SELECT * FROM templates WHERE is_active = 1';
  const params = [];

  if (type) { sql += ' AND type = ?'; params.push(type); }
  if (scene && scene !== '全部') { sql += ' AND scene = ?'; params.push(scene); }
  if (search) { sql += ' AND (name LIKE ? OR description LIKE ?)'; params.push(`%${search}%`, `%${search}%`); }

  if (sort === 'usage') sql += ' ORDER BY usage_count DESC';
  else if (sort === 'rating') sql += ' ORDER BY rating DESC';
  else if (sort === 'new') sql += ' ORDER BY created_at DESC';
  else sql += ' ORDER BY usage_count DESC';

  const offset = (parseInt(page) - 1) * parseInt(limit);
  sql += ' LIMIT ? OFFSET ?';
  params.push(parseInt(limit), offset);

  const templates = db.prepare(sql).all(...params);
  const result = templates.map(mapTemplate);

  res.json({ success: true, data: result, page: parseInt(page), limit: parseInt(limit) });
});

// GET /api/templates/list/hot?page=1&limit=6
router.get('/list/hot', (req, res) => {
  const db = getDb();
  const { page = 1, limit = 6 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);
  const templates = db.prepare(
    'SELECT * FROM templates WHERE is_active = 1 ORDER BY usage_count DESC LIMIT ? OFFSET ?'
  ).all(parseInt(limit), offset);

  res.json({
    success: true,
    data: templates.map(mapTemplate)
  });
});

// GET /api/templates/meta/scenes
router.get('/meta/scenes', (req, res) => {
  const db = getDb();
  const { type } = req.query;
  let sql = 'SELECT DISTINCT scene FROM templates WHERE is_active = 1';
  const params = [];
  if (type) { sql += ' AND type = ?'; params.push(type); }
  sql += ' ORDER BY scene';
  const scenes = db.prepare(sql).all(...params).map(r => r.scene);
  res.json({ success: true, data: scenes });
});

// GET /api/templates/meta/counts — 全库图片/视频模板数（首页展示用，勿用分页列表推算）
router.get('/meta/counts', (req, res) => {
  const db = getDb();
  const rows = db.prepare(
    'SELECT type, COUNT(*) AS c FROM templates WHERE is_active = 1 GROUP BY type'
  ).all();
  let image = 0;
  let video = 0;
  for (const r of rows) {
    if (r.type === '图片') image = r.c;
    if (r.type === '视频') video = r.c;
  }
  res.json({ success: true, data: { image, video } });
});

// GET /api/templates/:id — MUST be after named routes
router.get('/:id', (req, res) => {
  const db = getDb();
  const t = db.prepare('SELECT * FROM templates WHERE id = ? AND is_active = 1').get(req.params.id);

  if (!t) return res.status(404).json({ success: false, error: 'Template not found' });

  res.json({
    success: true,
    data: mapTemplate(t)
  });
});

// POST /api/templates/:id/favorite  (toggle)
router.post('/:id/favorite', (req, res) => {
  const db = getDb();
  const userId = 'user-mock-001';
  const templateId = parseInt(req.params.id);

  const existing = db.prepare('SELECT * FROM favorites WHERE user_id = ? AND template_id = ?').get(userId, templateId);
  if (existing) {
    db.prepare('DELETE FROM favorites WHERE user_id = ? AND template_id = ?').run(userId, templateId);
    res.json({ success: true, data: { favorited: false } });
  } else {
    db.prepare('INSERT INTO favorites (user_id, template_id) VALUES (?, ?)').run(userId, templateId);
    res.json({ success: true, data: { favorited: true } });
  }
});

module.exports = router;
