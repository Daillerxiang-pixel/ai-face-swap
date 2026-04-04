const Database = require('better-sqlite3');
const path = require('path');

const DB_PATH = path.join(__dirname, 'face_swap.db');
let db;

function initDb() {
  db = new Database(DB_PATH);

  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');

  // Schema version for migrations
  db.exec(`CREATE TABLE IF NOT EXISTS _schema_version (version INTEGER)`);
  const row = db.prepare('SELECT version FROM _schema_version').get();
  const currentVersion = row ? row.version : 0;

  // Mock user (logged-in, monthly VIP)
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      nickname TEXT,
      avatar TEXT,
      subscription_tier TEXT DEFAULT 'free',
      subscription_expires_at TEXT,
      monthly_usage INTEGER DEFAULT 0,
      monthly_limit INTEGER DEFAULT 50,
      total_generated INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    INSERT OR IGNORE INTO users (id, nickname, avatar, subscription_tier, subscription_expires_at, monthly_usage, monthly_limit, total_generated)
    VALUES ('user-mock-001', '星辰AI创作', '🧑‍🎨', 'monthly', '2026-04-17', 28, 999, 156);

    CREATE TABLE IF NOT EXISTS templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon TEXT,
      bg_gradient TEXT DEFAULT '',
      scene TEXT DEFAULT '通用',
      type TEXT DEFAULT '图片',
      usage_count INTEGER DEFAULT 0,
      rating REAL DEFAULT 4.8,
      badge TEXT DEFAULT '',
      description TEXT DEFAULT '',
      tencent_model_id TEXT DEFAULT '',
      preview_url TEXT DEFAULT '',
      is_active INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    CREATE TABLE IF NOT EXISTS favorites (
      user_id TEXT NOT NULL,
      template_id INTEGER NOT NULL,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      PRIMARY KEY (user_id, template_id)
    );

    CREATE TABLE IF NOT EXISTS generations (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      template_id INTEGER NOT NULL,
      source_image TEXT,
      result_image TEXT,
      status TEXT DEFAULT 'pending',
      progress INTEGER DEFAULT 0,
      type TEXT DEFAULT '图片',
      error_message TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime')),
      completed_at TEXT
    );

    CREATE TABLE IF NOT EXISTS upload_files (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      original_name TEXT,
      file_path TEXT,
      file_size INTEGER,
      mime_type TEXT,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );

    CREATE TABLE IF NOT EXISTS template_models (
      template_id INTEGER PRIMARY KEY,
      tencent_model_id TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now', 'localtime'))
    );
  `);

  // ===== Schema Migrations =====
  // Migration 1: Add provider fields to templates
  const hasProviderCol = db.prepare("PRAGMA table_info(templates)").all().some(c => c.name === 'provider');
  if (!hasProviderCol) {
    db.exec(`
      ALTER TABLE templates ADD COLUMN provider TEXT DEFAULT 'tencent';
      ALTER TABLE templates ADD COLUMN provider_model_id TEXT DEFAULT '';
      ALTER TABLE templates ADD COLUMN video_url TEXT DEFAULT '';
    `);
    // 为现有图片模板设置 provider
    db.prepare("UPDATE templates SET provider = 'tencent', provider_model_id = tencent_model_id WHERE tencent_model_id != ''").run();
    console.log('  [Migration 1] Added provider, provider_model_id, video_url to templates');
  }

  // Migration 2: Add prediction_id to generations (for async providers)
  const hasPredictionCol = db.prepare("PRAGMA table_info(generations)").all().some(c => c.name === 'prediction_id');
  if (!hasPredictionCol) {
    db.exec(`
      ALTER TABLE generations ADD COLUMN prediction_id TEXT DEFAULT '';
      ALTER TABLE generations ADD COLUMN provider TEXT DEFAULT 'tencent';
    `);
    console.log('  [Migration 2] Added prediction_id, provider to generations');
  }

  // Migration 3: Add admin and plans tables
  const hasAdminTable = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='admins'").get();
  if (!hasAdminTable) {
    db.exec(`
      CREATE TABLE admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        nickname TEXT DEFAULT '',
        last_login_at TEXT,
        created_at TEXT DEFAULT (datetime('now', 'localtime'))
      );

      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price_monthly REAL DEFAULT 0,
        price_yearly REAL DEFAULT 0,
        monthly_limit INTEGER DEFAULT 50,
        features TEXT DEFAULT '[]',
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now', 'localtime'))
      );

      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        plan_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        payment_method TEXT DEFAULT '',
        payment_at TEXT,
        expires_at TEXT,
        created_at TEXT DEFAULT (datetime('now', 'localtime'))
      );
    `);

    // Migrate: add auto_save and theme columns to users table
    try { db.exec('ALTER TABLE users ADD COLUMN auto_save INTEGER DEFAULT 1'); } catch(e) { /* column already exists */ }
    try { db.exec("ALTER TABLE users ADD COLUMN theme TEXT DEFAULT 'dark'"); } catch(e) { /* column already exists */ }

    // Seed default admin (password: admin123)
    const crypto = require('crypto');
    const hash = crypto.createHash('sha256').update('admin123').digest('hex');
    db.prepare("INSERT INTO admins (username, password_hash, nickname) VALUES (?, ?, ?)").run('admin', hash, '管理员');

    // Seed default plans
    const planStmt = db.prepare("INSERT INTO plans (name, price_monthly, price_yearly, monthly_limit, features, sort_order) VALUES (?,?,?,?,?,?)");
    const plans = [
      ['免费体验', 0, 0, 5, '["每日5次免费体验","基础图片换脸","标准画质输出"]', 0],
      ['月度会员', 19.9, 0, 200, '["每月200次生成","图片+视频换脸","高清画质输出","无水印","优先队列"]', 1],
      ['年度会员', 168, 0, 500, '["每月500次生成","图片+视频换脸","超高清画质","无水印","优先队列","专属客服","新模板抢先体验"]', 2],
      ['专业版', 39.9, 399, 999, '["每月999次无限生成","全部高级模板","4K超清输出","无水印","最快队列","专属客服","API接口调用","商用授权"]', 3],
    ];
    const insertPlans = db.transaction((items) => { for (const p of items) planStmt.run(...p); });
    insertPlans(plans);

    console.log('  [Migration 3] Added admins, plans, orders tables + seed data');
  }
// Migration 4: Add apple_user_id to users for Apple Sign In
  const hasAppleUserId = db.prepare("PRAGMA table_info(users)").all().some(c => c.name === "apple_user_id");
  if (!hasAppleUserId) {
    db.exec("ALTER TABLE users ADD COLUMN apple_user_id TEXT;");
    console.log("  [Migration 4] Added apple_user_id to users");
  }
// Migration 5: Add receipt_data to users for Apple IAP
  const hasReceiptData = db.prepare("PRAGMA table_info(users)").all().some(c => c.name === "receipt_data");
  if (!hasReceiptData) {
    db.exec("ALTER TABLE users ADD COLUMN receipt_data TEXT;");
    console.log("  [Migration 5] Added receipt_data to users");
  }

  // Migration 6: Email/password auth (routes/auth.js)
  const hasEmailCol = db.prepare("PRAGMA table_info(users)").all().some((c) => c.name === "email");
  if (!hasEmailCol) {
    db.exec("ALTER TABLE users ADD COLUMN email TEXT;");
    db.exec("ALTER TABLE users ADD COLUMN password_hash TEXT;");
    try {
      db.exec(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email) WHERE email IS NOT NULL"
      );
    } catch (e) {
      /* ignore */
    }
    console.log("  [Migration 6] Added email, password_hash to users");
  }

  // Seed templates
  const count = db.prepare('SELECT COUNT(*) as c FROM templates').get().c;
  if (count === 0) {
    const stmt = db.prepare(`
      INSERT INTO templates (name, icon, bg_gradient, scene, type, usage_count, rating, badge, description, tencent_model_id, provider, provider_model_id, video_url, preview_url) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    `);

    // ===== 图片模板 (腾讯云) =====
    const templates = [
      // 图片换脸模板 — 腾讯云
      ['模板一', '🎬', 'linear-gradient(135deg,#667eea,#764ba2)', '电影', '图片', 12500, 4.9, 'hot', 'AI智能换脸，精准融合面部特征。', 'mt_2035647018124681216', 'tencent', 'mt_2035647018124681216', '', '/uploads/previews/template_1.jpg'],
      ['模板二', '🌸', 'linear-gradient(135deg,#f093fb,#f5576c)', '春风', '图片', 8300, 4.8, 'hot', '穿越千年，化身经典角色。', 'mt_2035646985662840832', 'tencent', 'mt_2035646985662840832', '', '/uploads/previews/template_2.jpg'],
      ['模板三', '🎬', 'linear-gradient(135deg,#4facfe,#00f2fe)', '动漫', '图片', 6100, 4.7, 'new', '进入二次元世界，成为主角。', 'mt_2035646952886476800', 'tencent', 'mt_2035646952886476800', '', '/uploads/previews/template_3.jpg'],
      ['模板四', '🎭', 'linear-gradient(135deg,#fa709a,#fee140)', '悬疑', '图片', 9800, 4.9, 'vip', '穿越悬疑，定格最美瞬间。', 'mt_2035646913153835008', 'tencent', 'mt_2035646913153835008', '', '/uploads/previews/template_4.jpg'],
      ['模板五', '🌙', 'linear-gradient(135deg,#a18cd1,#fbc2eb)', '明星', '图片', 7400, 4.6, '', '化身明星，惊艳人生。', 'mt_2035635381514772480', 'tencent', 'mt_2035635381514772480', '', '/uploads/previews/template_5.jpg'],

      // ===== 视频换脸模板 (Replicate) =====
      ['视频模板一', '🎥', 'linear-gradient(135deg,#0c3483,#a2b6df)', '电影', '视频', 3200, 4.7, 'hot', '经典电影场景换脸，感受大银幕魅力。', '', 'replicate', '', 'https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4', '/uploads/previews/template_v1.jpg'],
      ['视频模板二', '🎭', 'linear-gradient(135deg,#6a11cb,#2575fc)', '舞台', '视频', 2800, 4.6, 'new', '化身舞台巨星，在聚光灯下熠熠生辉。', '', 'replicate', '', 'https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4', '/uploads/previews/template_v2.jpg'],
      ['视频模板三', '🔥', 'linear-gradient(135deg,#fc4a1a,#f7b733)', '搞笑', '视频', 4500, 4.8, 'hot', '热门短视频场景，轻松创作爆款内容。', '', 'replicate', '', 'https://replicate.delivery/pbxt/JtTUsVkGnNQDZCQbOTWYgMexYMQXNQjSsUDrbQTbIuIxtsJHA/example.mp4', '/uploads/previews/template_v3.jpg'],
    ];
    const insertMany = db.transaction((items) => {
      for (const t of items) stmt.run(...t);
    });
    insertMany(templates);

    // Seed mock generation history for the mock user
    const histCount = db.prepare("SELECT COUNT(*) as c FROM generations WHERE user_id = 'user-mock-001'").get().c;
    if (histCount === 0) {
      const { v4: uuidv4 } = require('uuid');
      const histStmt = db.prepare(`
        INSERT INTO generations (id, user_id, template_id, source_image, result_image, status, progress, type, created_at, completed_at)
        VALUES (?,?,?,?,?,?,?,?,?,?)
      `);
      const mockHistory = [
        [uuidv4(), 'user-mock-001', 1, '/uploads/mock_src_1.jpg', '/uploads/mock_result_1.jpg', 'completed', 100, '图片', '2026-03-21T14:30:00', '2026-03-21T14:30:12'],
        [uuidv4(), 'user-mock-001', 3, '/uploads/mock_src_2.jpg', '/uploads/mock_result_2.jpg', 'completed', 100, '图片', '2026-03-21T12:15:00', '2026-03-21T12:15:08'],
        [uuidv4(), 'user-mock-001', 2, '/uploads/mock_src_3.jpg', '/uploads/mock_result_3.jpg', 'completed', 100, '图片', '2026-03-20T20:45:00', '2026-03-20T20:45:10'],
        [uuidv4(), 'user-mock-001', 5, '/uploads/mock_src_4.jpg', '/uploads/mock_result_4.jpg', 'completed', 100, '图片', '2026-03-20T16:30:00', '2026-03-20T16:30:09'],
        [uuidv4(), 'user-mock-001', 4, '/uploads/mock_src_5.jpg', '/uploads/mock_result_5.jpg', 'completed', 100, '图片', '2026-03-19T11:20:00', '2026-03-19T11:20:11'],
        [uuidv4(), 'user-mock-001', 1, '/uploads/mock_src_6.jpg', null, 'cancelled', 50, '图片', '2026-03-19T09:10:00', null],
        [uuidv4(), 'user-mock-001', 3, '/uploads/mock_src_7.jpg', '/uploads/mock_result_7.jpg', 'completed', 100, '图片', '2026-03-18T22:00:00', '2026-03-18T22:00:12'],
        [uuidv4(), 'user-mock-001', 2, '/uploads/mock_src_8.jpg', '/uploads/mock_result_8.jpg', 'completed', 100, '图片', '2026-03-17T15:30:00', '2026-03-17T15:30:09'],
      ];
      const insertHistory = db.transaction((items) => {
        for (const h of items) histStmt.run(...h);
      });
      insertHistory(mockHistory);
    }

    // Seed some favorites
    const favCount = db.prepare("SELECT COUNT(*) as c FROM favorites WHERE user_id = 'user-mock-001'").get().c;
    if (favCount === 0) {
      const favStmt = db.prepare('INSERT OR IGNORE INTO favorites (user_id, template_id) VALUES (?, ?)');
      const favInsert = db.transaction((pairs) => {
        for (const p of pairs) favStmt.run(...p);
      });
      favInsert([
        ['user-mock-001', 1],
        ['user-mock-001', 3],
        ['user-mock-001', 5],
      ]);
    }
  }

  // Ensure mock user info is up to date (in case DB existed before rename)
  db.prepare("UPDATE users SET nickname='星辰AI创作', avatar='🧑‍🎨' WHERE id='user-mock-001'").run();

  console.log('✓ Database initialized');
}

function getDb() {
  return db;
}

module.exports = { initDb, getDb };
