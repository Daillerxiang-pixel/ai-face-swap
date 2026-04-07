#!/usr/bin/env node
/**
 * 将项目根 .env 复制到 server/.env（与 sync-env.sh 相同，Windows 可双击/node 运行）
 */
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');
const src = path.join(root, '.env');
const dest = path.join(root, 'server', '.env');
if (!fs.existsSync(src)) {
  console.log('Skip: no .env at project root');
  process.exit(0);
}
fs.copyFileSync(src, dest);
console.log('OK: synced', src, '->', dest);
