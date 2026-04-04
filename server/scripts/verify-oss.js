#!/usr/bin/env node
/**
 * 校验 .env 中 OSS 是否可启用（不访问网络）。
 * 用法（在 server 目录）: npm run verify:oss
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { getOSSConfigReport } = require('../utils/oss');

const r = getOSSConfigReport();
if (r.ok) {
  console.log('✓ OSS OK');
  console.log('  bucket :', r.bucket);
  console.log('  region :', r.region);
  console.log('  baseUrl:', r.baseUrl);
  process.exit(0);
}
console.error('✗ OSS 未就绪:', r.message);
console.error('  code:', r.code);
process.exit(1);
