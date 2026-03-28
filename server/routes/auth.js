const { Router } = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../data/database');

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'aihuantu-jwt-secret-2026';
const SALT_ROUNDS = 10;

// POST /api/auth/register
router.post('/register', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ success: false, error: 'Email and password are required' });
  if (password.length < 6) return res.status(400).json({ success: false, error: 'Password must be at least 6 characters' });

  const db = getDb();
  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase());
  if (existing) return res.status(409).json({ success: false, error: 'Email already registered' });

  const hashedPassword = bcrypt.hashSync(password, SALT_ROUNDS);
  const nickname = email.split('@')[0];
  const userId = uuidv4();

  db.prepare('INSERT INTO users (id, email, password_hash, nickname, avatar, subscription_tier, monthly_limit) VALUES (?, ?, ?, ?, ?, ?, ?)').run(
    userId, email.toLowerCase(), hashedPassword, nickname, null, 'free', 10
  );

  const user = db.prepare('SELECT id, email, nickname, avatar, subscription_tier, subscription_expires_at, monthly_usage, monthly_limit, total_generated FROM users WHERE id = ?').get(userId);

  const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });

  res.status(201).json({
    success: true,
    data: { token, user }
  });
});

// POST /api/auth/login
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ success: false, error: 'Email and password are required' });

  const db = getDb();
  const user = db.prepare('SELECT id, email, nickname, avatar, password_hash, subscription_tier, subscription_expires_at, monthly_usage, monthly_limit, total_generated FROM users WHERE email = ?').get(email.toLowerCase());

  if (!user || !user.password_hash) return res.status(401).json({ success: false, error: 'Invalid email or password' });

  if (!bcrypt.compareSync(password, user.password_hash)) return res.status(401).json({ success: false, error: 'Invalid email or password' });

  const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });

  const { password_hash, ...safeUser } = user;
  res.json({
    success: true,
    data: { token, user: safeUser }
  });
});

module.exports = router;
