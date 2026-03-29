/**
 * Favorites Route — POST / DELETE收藏接口
 * 
 * POST /api/favorites          — 收藏模板
 * DELETE /api/favorites/:id    — 取消收藏
 */

const { Router } = require('express');
const { getDb } = require('../data/database');
const { authMiddleware } = require('../middleware/auth');

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// POST /api/favorites — 收藏模板
router.post('/', (req, res) => {
  const { template_id } = req.body;
  if (!template_id) {
    return res.status(400).json({ success: false, error: 'template_id is required' });
  }

  const db = getDb();

  // 检查模板是否存在
  const template = db.prepare('SELECT id FROM templates WHERE id = ? AND is_active = 1').get(template_id);
  if (!template) {
    return res.status(404).json({ success: false, error: 'Template not found' });
  }

  // 检查是否已收藏
  const existing = db.prepare('SELECT 1 FROM favorites WHERE user_id = ? AND template_id = ?')
    .get(req.userId, template_id);

  if (existing) {
    return res.json({ success: true, data: { favorited: true } });
  }

  db.prepare('INSERT INTO favorites (user_id, template_id) VALUES (?, ?)').run(req.userId, template_id);
  res.status(201).json({ success: true, data: { favorited: true } });
});

// DELETE /api/favorites/:templateId — 取消收藏
router.delete('/:templateId', (req, res) => {
  const templateId = parseInt(req.params.templateId);
  const db = getDb();

  const result = db.prepare('DELETE FROM favorites WHERE user_id = ? AND template_id = ?')
    .run(req.userId, templateId);

  res.json({ success: true, data: { favorited: false, deleted: result.changes > 0 } });
});

module.exports = router;
