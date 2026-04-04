// 与运维脚本一致：密钥可能在项目根 .env（/var/www/ai-face-swap/.env），也可能在 server/.env；后者优先覆盖
const fs = require('fs');
const path = require('path');
const envServer = path.join(__dirname, '.env');
const envRoot = path.join(__dirname, '..', '.env');
if (fs.existsSync(envRoot)) {
  require('dotenv').config({ path: envRoot });
}
if (fs.existsSync(envServer)) {
  require('dotenv').config({ path: envServer, override: true });
}
if (!fs.existsSync(envRoot) && !fs.existsSync(envServer)) {
  require('dotenv').config();
}
const { getOSSConfigReport, logOSSStartupStatus } = require('./utils/oss');

(function enforceRequireOss() {
  const on = process.env.REQUIRE_OSS === '1' || process.env.REQUIRE_OSS === 'true';
  if (!on) return;
  const r = getOSSConfigReport();
  if (!r.ok) {
    console.error('[FATAL] REQUIRE_OSS=1 但 OSS 未就绪:', r.message);
    process.exit(1);
  }
})();

const express = require('express');
const cors = require('cors');
const { initDb } = require('./data/database');
const templateRoutes = require('./routes/templates');
const generateRoutes = require('./routes/generate');
const userRoutes = require('./routes/user');
const uploadRoutes = require('./routes/upload');
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const favoriteRoutes = require('./routes/favorites');
const subscriptionRoutes = require('./routes/subscription');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
// Parse JSON body with error handling - don't crash on malformed/empty body
app.use((req, res, next) => {
  express.json()(req, res, (err) => {
    if (err) {
      // Invalid JSON body — clear it and continue (don't reject the request)
      req.body = {};
    }
    next();
  });
});
app.use(express.static(path.join(__dirname, '..', 'prototype')));
// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
// Serve admin panel
app.use('/admin', express.static(path.join(__dirname, '..', 'admin')));

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/generate', generateRoutes);
app.use('/api/user', userRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/subscription', subscriptionRoutes);

// Init DB and start
initDb();
logOSSStartupStatus();
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log(`📱 Prototype at http://localhost:${PORT}/index-v3.html`);
});