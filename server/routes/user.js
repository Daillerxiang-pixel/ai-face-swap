const { Router } = require('express');
const { getDb } = require('../data/database');

const router = Router();

const MOCK_USER_ID = 'user-mock-001';

// GET /api/user/profile
router.get('/profile', (req, res) => {
  const db = getDb();
  const user = db.prepare('SELECT id, nickname, avatar, subscription_tier, subscription_expires_at, monthly_usage, monthly_limit, total_generated FROM users WHERE id = ?').get(MOCK_USER_ID);

  if (!user) return res.status(404).json({ success: false, error: '用户不存在' });

  res.json({
    success: true,
    data: {
      ...user,
      remaining: user.subscription_tier === 'monthly' ? 999 : Math.max(0, user.monthly_limit - user.monthly_usage),
      isVip: user.subscription_expires_at && new Date(user.subscription_expires_at) > new Date()
    }
  });
});

// GET /api/user/favorites
router.get('/favorites', (req, res) => {
  const db = getDb();
  const favs = db.prepare(`
    SELECT t.id, t.name, t.icon, t.bg_gradient as bg, t.scene, t.type, t.usage_count, t.badge, t.rating
    FROM favorites f JOIN templates t ON f.template_id = t.id
    WHERE f.user_id = ? AND t.is_active = 1
    ORDER BY f.created_at DESC
  `).all(MOCK_USER_ID);

  res.json({
    success: true,
    data: favs.map(t => ({
      ...t,
      usage: t.usage_count >= 10000 ? (t.usage_count / 1000).toFixed(1) + 'K' : String(t.usage_count)
    }))
  });
});

// GET /api/user/history
router.get('/history', (req, res) => {
  const db = getDb();
  const { page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);

  const history = db.prepare(`
    SELECT g.id, g.template_id, g.status, g.progress, g.type, g.created_at, g.completed_at,
           g.result_image as resultUrl, g.error_message as errorMsg,
           t.name as template_name, t.icon as template_icon, t.bg_gradient as template_bg,
           t.preview_url as templatePreview
    FROM generations g
    LEFT JOIN templates t ON g.template_id = t.id
    WHERE g.user_id = ?
    ORDER BY g.created_at DESC
    LIMIT ? OFFSET ?
  `).all(MOCK_USER_ID, parseInt(limit), offset);

  res.json({ success: true, data: history, page: parseInt(page) });
});

// GET /api/user/favorite/:templateId — check if favorited
router.get('/favorite/:templateId', (req, res) => {
  const db = getDb();
  const fav = db.prepare('SELECT 1 FROM favorites WHERE user_id = ? AND template_id = ?')
    .get(MOCK_USER_ID, parseInt(req.params.templateId));
  res.json({ success: true, data: { favorited: !!fav } });
});

module.exports = router;
