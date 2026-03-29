/**
 * User Route — Profile, Favorites, History, Settings
 */

const { Router } = require('express');
const { getDb } = require('../data/database');
const { authMiddleware } = require('../middleware/auth');

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// GET /api/user/profile
router.get('/profile', (req, res) => {
  const db = getDb();
  const user = db.prepare('SELECT id, nickname, avatar, subscription_tier, subscription_expires_at, monthly_usage, monthly_limit, total_generated, auto_save, theme FROM users WHERE id = ?').get(req.userId);

  if (!user) return res.status(404).json({ success: false, error: 'User not found' });

  res.json({
    success: true,
    data: {
      ...user,
      remaining: user.subscription_tier === 'monthly' ? 999 : Math.max(0, user.monthly_limit - user.monthly_usage),
      isVip: user.subscription_expires_at && new Date(user.subscription_expires_at) > new Date()
    }
  });
});

// PUT /api/user/settings — update user settings
router.put('/settings', (req, res) => {
  const db = getDb();
  const { nickname, avatar, auto_save, theme } = req.body;

  // Build dynamic update
  const fields = [];
  const values = [];

  if (nickname !== undefined) {
    fields.push('nickname = ?');
    values.push(nickname);
  }
  if (avatar !== undefined) {
    fields.push('avatar = ?');
    values.push(avatar);
  }
  if (auto_save !== undefined) {
    fields.push('auto_save = ?');
    values.push(auto_save ? 1 : 0);
  }
  if (theme !== undefined) {
    // Only allow 'dark' or 'light'
    const validThemes = ['dark', 'light'];
    const t = validThemes.includes(theme) ? theme : 'dark';
    fields.push('theme = ?');
    values.push(t);
  }

  if (fields.length === 0) {
    return res.status(400).json({ success: false, error: 'No fields to update' });
  }

  values.push(req.userId);
  db.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`).run(...values);

  // Return updated profile
  const user = db.prepare('SELECT id, nickname, avatar, subscription_tier, subscription_expires_at, monthly_usage, monthly_limit, total_generated, auto_save, theme FROM users WHERE id = ?').get(req.userId);
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

  // Helper to convert relative URL to public URL
  const toPublicUrl = (url) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    return `https://aihuantu.oss-cn-beijing.aliyuncs.com${url}`;
  };

  const favs = db.prepare(`
    SELECT t.id, t.name, t.icon, t.bg_gradient as bg, t.scene, t.type, t.usage_count, t.badge, t.rating,
           t.preview_url, t.video_url, t.provider
    FROM favorites f JOIN templates t ON f.template_id = t.id
    WHERE f.user_id = ? AND t.is_active = 1
    ORDER BY f.created_at DESC
  `).all(req.userId);

  res.json({
    success: true,
    data: favs.map(t => ({
      id: t.id,
      name: t.name,
      icon: t.icon,
      bg: t.bg_gradient,
      scene: t.scene,
      type: t.type === '图片' ? 'image' : 'video',
      usage_count: t.usage_count,
      usage: t.usage_count >= 10000 ? (t.usage_count / 1000).toFixed(1) + 'K' : String(t.usage_count),
      badge: t.badge,
      rating: t.rating,
      previewUrl: toPublicUrl(t.preview_url),
      videoUrl: toPublicUrl(t.video_url),
      provider: t.provider,
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
  `).all(req.userId, parseInt(limit), offset);

  res.json({ success: true, data: history, page: parseInt(page) });
});

// GET /api/user/favorite/:templateId — check if favorited
router.get('/favorite/:templateId', (req, res) => {
  const db = getDb();
  const fav = db.prepare('SELECT 1 FROM favorites WHERE user_id = ? AND template_id = ?')
    .get(req.userId, parseInt(req.params.templateId));
  res.json({ success: true, data: { favorited: !!fav } });
});

module.exports = router;
