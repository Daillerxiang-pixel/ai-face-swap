require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDb } = require('./data/database');
const templateRoutes = require('./routes/templates');
const generateRoutes = require('./routes/generate');
const userRoutes = require('./routes/user');
const uploadRoutes = require('./routes/upload');
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const favoriteRoutes = require('./routes/favorites');

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

// Init DB and start
initDb();
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log(`📱 Prototype at http://localhost:${PORT}/index-v3.html`);
});
