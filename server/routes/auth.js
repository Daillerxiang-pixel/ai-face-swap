const { Router } = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const appleSignin = require('apple-signin-auth');
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

// POST /api/auth/apple - Apple Sign In
// Body: { identityToken, authorizationCode?, firstName?, lastName?, email? }
// Response: { success: true, data: { token, user } }
router.post('/apple', async (req, res) => {
  const { identityToken, authorizationCode, firstName, lastName, email: clientEmail } = req.body;

  if (!identityToken) {
    return res.status(400).json({ success: false, error: 'identityToken is required' });
  }

  try {
    // 1. Verify Apple identityToken (validates JWT signature with Apple's public keys)
    const appleUser = await appleSignin.verifyIdToken(identityToken, {
      audience: process.env.APPLE_BUNDLE_ID || 'com.aihuantu.faceswap',
    });

    // appleUser.sub = Apple unique user ID
    // appleUser.email = user email (only returned on first authorization, may be null afterwards)
    const appleSub = appleUser.sub;
    const appleEmail = clientEmail || appleUser.email;

    console.log('[Apple Sign In] sub=' + appleSub + ', email=' + (appleEmail || 'hidden'));

    const db = getDb();

    // 2. Find existing user by apple_user_id
    let user = db.prepare('SELECT * FROM users WHERE apple_user_id = ?').get(appleSub);

    if (!user) {
      // 3. No linked account - check if same email exists (merge with email-registered account)
      if (appleEmail) {
        user = db.prepare('SELECT * FROM users WHERE email = ?').get(appleEmail.toLowerCase());
        if (user) {
          // Link Apple ID to existing account
          db.prepare('UPDATE users SET apple_user_id = ? WHERE id = ?').run(appleSub, user.id);
          console.log('[Apple Sign In] Linked Apple ID to existing user: ' + user.id);
        }
      }

      if (!user) {
        // 4. Create new user
        const userId = uuidv4();
        let nickname = firstName
          ? firstName + (lastName ? ' ' + lastName : '')
          : (appleEmail ? appleEmail.split('@')[0] : 'Apple_' + appleSub.substring(0, 8));

        db.prepare(
          'INSERT INTO users (id, email, nickname, avatar, apple_user_id, subscription_tier, monthly_limit) VALUES (?, ?, ?, ?, ?, ?, ?)'
        ).run(
          userId,
          appleEmail ? appleEmail.toLowerCase() : null,
          nickname,
          null,
          appleSub,
          'free',
          10
        );

        user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
        console.log('[Apple Sign In] Created new user: ' + userId);
      }
    }

    // 5. Update nickname if Apple provided name (first authorization only)
    if (firstName && (!user.nickname || user.nickname.startsWith('Apple_'))) {
      const newNickname = firstName + (lastName ? ' ' + lastName : '');
      db.prepare('UPDATE users SET nickname = ? WHERE id = ?').run(newNickname.trim(), user.id);
      user.nickname = newNickname.trim();
    }

    // 6. Issue JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    const { password_hash, apple_user_id, ...safeUser } = user;

    res.json({
      success: true,
      data: { token, user: safeUser }
    });

  } catch (error) {
    console.error('[Apple Sign In] Error:', error.message);
    res.status(401).json({
      success: false,
      error: 'Apple Sign In verification failed: ' + (error.message || 'Unknown error')
    });
  }
});

module.exports = router;