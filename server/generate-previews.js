/**
 * Generate preview images for all templates by calling FaceFusion with a test face.
 * Usage: node generate-previews.js
 */
require('dotenv').config();
const tencentcloud = require('tencentcloud-sdk-nodejs');
const fs = require('fs');
const https = require('https');
const Database = require('better-sqlite3');
const path = require('path');

const ACTIVITY_ID = process.env.TENCENT_ACTIVITY_ID;
const DB_PATH = path.join(__dirname, 'data', 'face_swap.db');

const client = new tencentcloud.facefusion.v20181201.Client({
  credential: { secretId: process.env.TENCENT_SECRET_ID, secretKey: process.env.TENCENT_SECRET_KEY },
  region: 'ap-guangzhou',
});

const TEST_FACE_URL = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop&crop=face';
const PREVIEW_DIR = path.join(__dirname, '..', 'uploads', 'previews');

function downloadTestFace() {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(path.join(__dirname, 'test_face.jpg'));
    https.get(TEST_FACE_URL, res => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        https.get(res.headers.location, r => { r.pipe(file); file.on('finish', () => { file.close(); resolve(); }); });
      } else {
        res.pipe(file);
        file.on('finish', () => { file.close(); resolve(); });
      }
    }).on('error', reject);
  });
}

async function main() {
  if (!fs.existsSync(PREVIEW_DIR)) fs.mkdirSync(PREVIEW_DIR, { recursive: true });

  console.log('📥 Downloading test face...');
  await downloadTestFace();
  const faceBase64 = fs.readFileSync(path.join(__dirname, 'test_face.jpg')).toString('base64');
  console.log(`📸 Test face loaded: ${faceBase64.length} chars`);

  const db = new Database(DB_PATH);
  const templates = db.prepare('SELECT id, tencent_model_id, name FROM templates WHERE is_active = 1').all();
  console.log(`📋 Found ${templates.length} templates`);

  for (const t of templates) {
    if (!t.tencent_model_id) {
      console.log(`⏭️  Template ${t.id} (${t.name}): no model ID, skip`);
      continue;
    }
    process.stdout.write(`🎨 Generating preview for template ${t.id} (${t.name})... `);
    try {
      const resp = await client.FaceFusion({
        ProjectId: ACTIVITY_ID,
        ModelId: t.tencent_model_id,
        Image: faceBase64,
        RspImgType: 'base64',
      });
      if (resp.Image) {
        const buf = Buffer.from(resp.Image, 'base64');
        const previewPath = path.join(PREVIEW_DIR, `template_${t.id}.png`);
        fs.writeFileSync(previewPath, buf);
        const webUrl = `/uploads/previews/template_${t.id}.png`;
        // Update DB
        db.prepare('UPDATE templates SET preview_url = ? WHERE id = ?').run(webUrl, t.id);
        console.log(`✅ ${buf.length} bytes -> ${webUrl}`);
      } else {
        console.log('⚠️  No image returned');
      }
    } catch (e) {
      console.log(`❌ ${e.code}: ${e.message}`);
    }
  }

  db.close();
  console.log('\n🎉 Done!');
}

main().catch(e => { console.error('Fatal:', e); process.exit(1); });
